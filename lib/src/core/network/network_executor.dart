// lib/src/core/network/network_executor.dart
import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:dio/dio.dart';

import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/network/dio_failure_mapper.dart';
import 'package:movi/src/core/network/network_failures.dart';

typedef NetworkCall<T> =
    Future<Response<T>> Function(Dio client, CancelToken? cancelToken);
typedef NetworkRetryEvaluator = bool Function(DioException error, int attempt);
typedef AttemptHook = void Function(int attempt, DioException? error);

/// Exécuteur générique et résilient pour les appels réseau.
///
/// Responsabilités :
/// - limite la concurrence par clé logique ;
/// - déduplique les appels identiques déjà en cours ;
/// - applique retry + backoff ;
/// - applique un cache mémoire LRU + TTL ;
/// - mappe les erreurs Dio vers les failures du projet.
///
/// Contraintes de conception :
/// - aucune connaissance métier spécifique ;
/// - join des requêtes in-flight sans consommer inutilement un slot de concurrence ;
/// - suppression sûre des waiters en cas de timeout / annulation / dispose.
class NetworkExecutor {
  NetworkExecutor(
    this._client, {
    this.logger,
    this.defaultConcurrencyKey,
    this.defaultMaxConcurrent = 6,
    this.memoryCacheMaxEntries = 256,
    this.memoryCacheDefaultTtl = const Duration(seconds: 45),
    this.inflightJoinTimeout = const Duration(seconds: 15),
    this.limiterAcquireTimeout = const Duration(seconds: 10),
    Random? random,
  }) : assert(defaultMaxConcurrent > 0, 'defaultMaxConcurrent must be > 0'),
       assert(memoryCacheMaxEntries > 0, 'memoryCacheMaxEntries must be > 0'),
       _limiters = <String, _Limiter>{},
       _inflight = <String, _InflightEntry>{},
       _memoryCache = _LruCache<String, _CachedPayload>(
         capacity: memoryCacheMaxEntries,
       ),
       _random = random ?? Random();

  final Dio _client;
  final AppLogger? logger;
  final Random _random;

  /// Clé de concurrence appliquée si `concurrencyKey` n’est pas fournie.
  final String? defaultConcurrencyKey;

  /// Capacité cible par défaut pour un nouveau limiteur.
  final int defaultMaxConcurrent;

  /// Paramètres du mini cache mémoire.
  final int memoryCacheMaxEntries;
  final Duration memoryCacheDefaultTtl;

  /// Garde-fous anti-blocage.
  Duration inflightJoinTimeout;
  Duration limiterAcquireTimeout;

  final Map<String, _Limiter> _limiters;
  final Map<String, _InflightEntry> _inflight;
  final _LruCache<String, _CachedPayload> _memoryCache;

  bool _isDisposed = false;

  String? _typedDedupKey<T>(String? dedupKey) {
    if (dedupKey == null) return null;
    return '$dedupKey|T=${T.toString()}';
  }

  /// Configure ou met à jour la capacité cible d’un limiteur.
  ///
  /// L’adaptation dynamique ne dépassera pas cette capacité cible.
  void configureConcurrency(String key, int maxConcurrent) {
    assert(maxConcurrent > 0, 'maxConcurrent must be > 0');

    final limiter = _limiters[key];
    if (limiter == null) {
      _limiters[key] = _Limiter(maxConcurrent);
      return;
    }

    limiter.targetCapacity = maxConcurrent;
  }

  void configureLimiterAcquireTimeout(Duration timeout) {
    limiterAcquireTimeout = timeout;
  }

  void configureInflightJoinTimeout(Duration timeout) {
    inflightJoinTimeout = timeout;
  }

  LimiterStats? getLimiterStats(String key) => _limiters[key]?.stats;

  /// Réinitialise l’état interne.
  ///
  /// Utilisable en test ou lors d’un redémarrage applicatif.
  void resetLimiters() {
    _failInflightEntries(
      StateError('NetworkExecutor state has been reset'),
      StackTrace.current,
    );

    for (final limiter in _limiters.values) {
      limiter.dispose();
    }

    _limiters.clear();
    _memoryCache.clear();
  }

  Future<R> run<T, R>({
    required NetworkCall<T> request,
    required R Function(Response<T> response) mapper,
    String? concurrencyKey,
    int? maxConcurrent,
    Duration? timeout,

    // Résilience / retry
    int retries = 0,
    NetworkRetryEvaluator? retryIf,
    Duration baseDelay = const Duration(milliseconds: 300),
    Duration maxDelay = const Duration(seconds: 5),
    bool jitter = true,

    // Dédup & cache mémoire
    String? dedupKey,
    Duration? cacheTtl,

    // Contrat de réponse
    bool requireResponseBody = true,

    // Annulation & hooks
    CancelToken? cancelToken,
    AttemptHook? onAttemptStart,
    AttemptHook? onAttemptEnd,
  }) async {
    if (_isDisposed) {
      throw StateError('NetworkExecutor has been disposed');
    }

    final concurrencyBucket = concurrencyKey ?? defaultConcurrencyKey;
    final typedDedupKey = _typedDedupKey<T>(dedupKey);
    final limiter = _resolveLimiter(concurrencyBucket, maxConcurrent);
    final requestTimeout = timeout ?? _timeoutFromDio();

    // 1) Cache mémoire.
    if (typedDedupKey != null) {
      final cached = _memoryCache.getIfFresh(
        typedDedupKey,
        now: DateTime.now(),
      );

      if (cached != null) {
        final cachedResponse = cached.tryAsResponse<T>();
        if (cachedResponse != null) {
          _ensureResponseBody(cachedResponse, requireResponseBody);
          return mapper(cachedResponse);
        }

        logger?.warn(
          '[Network] action=read_cache result=degraded '
          'code=incompatible_cached_payload context=dedupKey=$dedupKey',
        );
      }
    }

    // 2) Join direct d’une requête déjà en cours, sans prendre un slot de limiter.
    if (typedDedupKey != null) {
      final existing = _inflight[typedDedupKey];
      if (existing != null) {
        logger?.debug('Reusing in-flight request for dedupKey=$dedupKey');

        try {
          final response = await _awaitSharedResponse<T>(
            existing.future,
            dedupKey: dedupKey,
          );
          _ensureResponseBody(response, requireResponseBody);
          return mapper(response);
        } on TimeoutException {
          logger?.warn(
            '[Network] action=join_inflight result=timeout '
            'code=inflight_join_timeout context=dedupKey=$dedupKey strategy=run_independent',
          );
        } on DioException catch (error) {
          throw mapDioToFailure(error);
        } on EmptyResponseFailure {
          rethrow;
        } on UnknownFailure {
          rethrow;
        } catch (error) {
          throw UnknownFailure(error.toString());
        }
      }
    }

    // 3) Enregistrement owner/joiner avant toute attente.
    _InflightRegistration? inflightRegistration;
    if (typedDedupKey != null) {
      inflightRegistration = _registerInflight(typedDedupKey);

      if (!inflightRegistration.isOwner) {
        try {
          final response = await _awaitSharedResponse<T>(
            inflightRegistration.entry.future,
            dedupKey: dedupKey,
          );
          _ensureResponseBody(response, requireResponseBody);
          return mapper(response);
        } on TimeoutException {
          logger?.warn(
            '[Network] action=join_inflight result=timeout '
            'code=late_inflight_join_timeout context=dedupKey=$dedupKey strategy=run_independent',
          );
          inflightRegistration = null;
        } on DioException catch (error) {
          throw mapDioToFailure(error);
        } on EmptyResponseFailure {
          rethrow;
        } on UnknownFailure {
          rethrow;
        } catch (error) {
          throw UnknownFailure(error.toString());
        }
      }
    }

    try {
      for (int attempt = 0; ; attempt++) {
        final stopwatch = Stopwatch()..start();
        final effectiveCancelToken = _linkCancelToken(cancelToken);
        DioException? dioError;
        var limiterAcquired = false;

        onAttemptStart?.call(attempt, null);

        try {
          if (limiter != null) {
            await _acquireLimiterSlot(
              limiter,
              concurrencyBucket: concurrencyBucket,
              cancelToken: effectiveCancelToken,
            );
            limiterAcquired = true;
          }

          final response = await request(_client, effectiveCancelToken).timeout(
            requestTimeout,
            onTimeout: () {
              if (!effectiveCancelToken.isCancelled) {
                effectiveCancelToken.cancel(
                  'NetworkExecutor timeout after ${requestTimeout.inSeconds}s',
                );
              }

              logger?.warn(
                '[Network] action=run_request result=timeout '
                'code=request_timeout context=timeoutS=${requestTimeout.inSeconds} '
                'concurrencyKey=$concurrencyBucket dedupKey=$dedupKey',
              );

              throw DioException(
                requestOptions: RequestOptions(path: _client.options.baseUrl),
                type: DioExceptionType.receiveTimeout,
                error: 'Request timeout after ${requestTimeout.inSeconds}s',
              );
            },
          );

          if (cancelToken?.isCancelled == true) {
            throw _buildCancellationException('Cancelled by caller');
          }

          _ensureResponseBody(response, requireResponseBody);

          stopwatch.stop();
          limiter?.recordSuccess(stopwatch.elapsed);
          _logPerformance(concurrencyBucket, stopwatch.elapsed, success: true);

          if (typedDedupKey != null) {
            final ttl = cacheTtl ?? memoryCacheDefaultTtl;
            _memoryCache.put(
              typedDedupKey,
              _CachedPayload.fromResponse(response),
              ttl: ttl,
              now: DateTime.now(),
            );
          }

          inflightRegistration?.complete(response);
          onAttemptEnd?.call(attempt, null);

          return mapper(response);
        } on DioException catch (error, stackTrace) {
          stopwatch.stop();
          dioError = error;

          final statusCode = error.response?.statusCode;
          _logNetworkFailure(error, stackTrace);
          limiter?.recordFailure(stopwatch.elapsed, statusCode: statusCode);
          _logPerformance(concurrencyBucket, stopwatch.elapsed, success: false);

          final shouldRetryCurrentAttempt =
              attempt < retries && _shouldRetry(error, attempt, retryIf);

          if (shouldRetryCurrentAttempt) {
            onAttemptEnd?.call(attempt, error);

            final retryDelay = _computeBackoff(
              attempt: attempt,
              base: baseDelay,
              max: maxDelay,
              jitter: jitter,
            );

            try {
              await _delayWithCancellation(retryDelay, cancelToken);
            } on DioException catch (cancelError, cancelStackTrace) {
              inflightRegistration?.completeError(
                cancelError,
                cancelStackTrace,
              );
              throw mapDioToFailure(cancelError);
            }

            continue;
          }

          inflightRegistration?.completeError(error, stackTrace);
          onAttemptEnd?.call(attempt, error);
          throw mapDioToFailure(error);
        } on EmptyResponseFailure catch (failure, stackTrace) {
          stopwatch.stop();
          _logPerformance(concurrencyBucket, stopwatch.elapsed, success: false);

          inflightRegistration?.completeError(failure, stackTrace);
          onAttemptEnd?.call(attempt, dioError);
          rethrow;
        } on _LimiterAcquireTimeout catch (error, stackTrace) {
          stopwatch.stop();

          logger?.warn(
            '[Network] action=acquire_limiter result=timeout '
            'code=limiter_acquire_timeout context=concurrencyKey=$concurrencyBucket',
          );
          _logPerformance(concurrencyBucket, stopwatch.elapsed, success: false);

          final failure = UnknownFailure(error.message);
          inflightRegistration?.completeError(failure, stackTrace);
          onAttemptEnd?.call(attempt, null);
          throw failure;
        } on _LimiterAcquireCancelled catch (error, stackTrace) {
          stopwatch.stop();

          final cancelException = _buildCancellationException(error.message);
          _logPerformance(concurrencyBucket, stopwatch.elapsed, success: false);

          inflightRegistration?.completeError(cancelException, stackTrace);
          onAttemptEnd?.call(attempt, cancelException);
          throw mapDioToFailure(cancelException);
        } on _LimiterDisposed catch (error, stackTrace) {
          stopwatch.stop();

          logger?.warn(
            '[Network] action=acquire_limiter result=degraded '
            'code=limiter_disposed context=concurrencyKey=$concurrencyBucket',
          );
          _logPerformance(concurrencyBucket, stopwatch.elapsed, success: false);

          final failure = UnknownFailure(error.message);
          inflightRegistration?.completeError(failure, stackTrace);
          onAttemptEnd?.call(attempt, null);
          throw failure;
        } on UnknownFailure catch (failure, stackTrace) {
          stopwatch.stop();

          logger?.error(
            '[Network] action=run_request result=failure '
            'code=unexpected_network_failure',
            failure,
            stackTrace,
          );
          _logPerformance(concurrencyBucket, stopwatch.elapsed, success: false);

          inflightRegistration?.completeError(failure, stackTrace);
          onAttemptEnd?.call(attempt, dioError);
          rethrow;
        } catch (error, stackTrace) {
          stopwatch.stop();

          logger?.error(
            '[Network] action=run_request result=failure '
            'code=unexpected_network_error',
            error,
            stackTrace,
          );
          _logPerformance(concurrencyBucket, stopwatch.elapsed, success: false);

          final failure = UnknownFailure(error.toString());
          inflightRegistration?.completeError(failure, stackTrace);
          onAttemptEnd?.call(attempt, dioError);
          throw failure;
        } finally {
          if (limiterAcquired) {
            limiter?.release();
          }
        }
      }
    } finally {
      if (inflightRegistration?.isOwner == true) {
        _inflight.remove(inflightRegistration!.key);
      }
    }
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    _failInflightEntries(
      StateError('NetworkExecutor has been disposed'),
      StackTrace.current,
    );

    for (final limiter in _limiters.values) {
      limiter.dispose();
    }

    _limiters.clear();
    _memoryCache.clear();
  }

  _Limiter? _resolveLimiter(String? key, int? maxConcurrent) {
    if (key == null) return null;

    final limiter = _limiters.putIfAbsent(
      key,
      () => _Limiter(maxConcurrent ?? defaultMaxConcurrent),
    );

    if (maxConcurrent != null && maxConcurrent > 0) {
      limiter.targetCapacity = maxConcurrent;
    }

    return limiter;
  }

  Future<Response<T>> _awaitSharedResponse<T>(
    Future<Response<dynamic>> sharedFuture, {
    required String? dedupKey,
  }) async {
    final dynamicResponse = await sharedFuture.timeout(
      inflightJoinTimeout,
      onTimeout: () {
        throw TimeoutException(
          'In-flight request timeout after ${inflightJoinTimeout.inSeconds}s for dedupKey=$dedupKey',
          inflightJoinTimeout,
        );
      },
    );

    return dynamicResponse as Response<T>;
  }

  _InflightRegistration _registerInflight(String typedDedupKey) {
    final existing = _inflight[typedDedupKey];
    if (existing != null) {
      return _InflightRegistration.joiner(key: typedDedupKey, entry: existing);
    }

    final entry = _InflightEntry();
    _inflight[typedDedupKey] = entry;

    return _InflightRegistration.owner(key: typedDedupKey, entry: entry);
  }

  Future<void> _acquireLimiterSlot(
    _Limiter limiter, {
    required String? concurrencyBucket,
    required CancelToken? cancelToken,
  }) async {
    _throwIfCancelled(
      cancelToken,
      'Request cancelled before acquiring limiter slot',
    );

    try {
      await limiter.acquire(
        timeout: limiterAcquireTimeout,
        cancelSignal: cancelToken?.whenCancel,
      );
    } on TimeoutException catch (_) {
      final stats = limiter.stats;
      throw _LimiterAcquireTimeout(
        'Timed out after ${limiterAcquireTimeout.inSeconds}s while waiting for '
        'concurrencyKey=$concurrencyBucket (stats: $stats)',
      );
    } on _LimiterAcquireCancelled {
      throw const _LimiterAcquireCancelled(
        'Request cancelled during limiter acquire',
      );
    } on _LimiterDisposed {
      rethrow;
    }
  }

  Future<void> _delayWithCancellation(
    Duration delay,
    CancelToken? cancelToken,
  ) async {
    if (delay <= Duration.zero) return;

    _throwIfCancelled(cancelToken, 'Request cancelled before retry backoff');

    if (cancelToken == null) {
      await Future<void>.delayed(delay);
      return;
    }

    await Future.any<void>([
      Future<void>.delayed(delay),
      cancelToken.whenCancel.then<void>((_) {
        throw _buildCancellationException(
          'Request cancelled during retry backoff',
        );
      }),
    ]);
  }

  void _ensureResponseBody<T>(Response<T> response, bool requireResponseBody) {
    if (!requireResponseBody) return;
    if (response.data == null) {
      throw const EmptyResponseFailure();
    }
  }

  void _throwIfCancelled(CancelToken? cancelToken, String message) {
    if (cancelToken?.isCancelled == true) {
      throw _buildCancellationException(message);
    }
  }

  DioException _buildCancellationException(String message) {
    return DioException(
      requestOptions: RequestOptions(path: _client.options.baseUrl),
      type: DioExceptionType.cancel,
      error: message,
    );
  }

  Duration _timeoutFromDio() {
    final receiveTimeout = _client.options.receiveTimeout;
    if (receiveTimeout != null && receiveTimeout > Duration.zero) {
      return receiveTimeout;
    }

    final connectTimeout = _client.options.connectTimeout;
    if (connectTimeout != null && connectTimeout > Duration.zero) {
      return connectTimeout;
    }

    return const Duration(seconds: 15);
  }

  CancelToken _linkCancelToken(CancelToken? source) {
    if (source == null) return CancelToken();

    final linked = CancelToken();

    if (source.isCancelled) {
      linked.cancel(source.cancelError);
      return linked;
    }

    unawaited(
      source.whenCancel
          .then((_) {
            if (!linked.isCancelled) {
              linked.cancel(source.cancelError ?? 'Cancelled by caller');
            }
          })
          .catchError((_) {}),
    );

    return linked;
  }

  bool _shouldRetry(
    DioException error,
    int attempt,
    NetworkRetryEvaluator? customEvaluator,
  ) {
    if (customEvaluator != null) {
      return customEvaluator(error, attempt);
    }

    const retryableStatus = <int>{408, 425, 429, 500, 502, 503, 504};
    final statusCode = error.response?.statusCode;
    if (statusCode != null && retryableStatus.contains(statusCode)) {
      return true;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return true;
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
        return false;
    }
  }

  Duration _computeBackoff({
    required int attempt,
    required Duration base,
    required Duration max,
    required bool jitter,
  }) {
    final factor = 1 << attempt;
    final milliseconds = base.inMilliseconds * factor;
    final clamped = min(milliseconds, max.inMilliseconds);

    if (!jitter) {
      return Duration(milliseconds: clamped);
    }

    return Duration(milliseconds: _random.nextInt(clamped + 1));
  }

  void _logNetworkFailure(DioException error, StackTrace stackTrace) {
    final statusCode = error.response?.statusCode;

    if (statusCode == 404) {
      logger?.debug('Resource not found (404)', category: 'network');
      return;
    }

    logger?.error(
      '[Network] action=call result=failure code=network_call_failed',
      error,
      stackTrace,
    );
  }

  void _logPerformance(String? key, Duration elapsed, {required bool success}) {
    final effectiveKey = key ?? 'default';

    logger?.debug(
      '[Network][debug] key=$effectiveKey '
      'elapsedMs=${elapsed.inMilliseconds} success=$success',
    );

    if (elapsed > const Duration(seconds: 5)) {
      logger?.warn(
        '[Network] action=observe_latency result=degraded '
        'code=slow_request context=key=$effectiveKey '
        'elapsedMs=${elapsed.inMilliseconds} success=$success',
      );
    }
  }

  void _failInflightEntries(Object error, StackTrace stackTrace) {
    for (final entry in _inflight.values) {
      entry.completeError(error, stackTrace);
    }
    _inflight.clear();
  }
}

class LimiterStats {
  LimiterStats({
    required this.capacity,
    required this.targetCapacity,
    required this.p95,
    required this.errorRate,
    required this.windowCount,
  });

  final int capacity;
  final int targetCapacity;
  final Duration p95;
  final double errorRate;
  final int windowCount;

  @override
  String toString() =>
      'cap=$capacity target=$targetCapacity '
      'p95=${p95.inMilliseconds}ms '
      'err=${(errorRate * 100).toStringAsFixed(1)}% '
      'n=$windowCount';
}

class _Limiter {
  _Limiter(int initialTargetCapacity)
    : assert(initialTargetCapacity > 0),
      _targetCapacity = initialTargetCapacity,
      _currentCapacity = initialTargetCapacity,
      _latencies = Queue<Duration>();

  int _targetCapacity;
  int _currentCapacity;
  int _permitsInUse = 0;
  bool _isDisposed = false;

  final Queue<_Waiter> _waiters = Queue<_Waiter>();
  final Queue<Duration> _latencies;

  final Completer<void> _disposeSignal = Completer<void>();

  DateTime? _cooldownUntil;
  int _errors = 0;
  DateTime _windowStart = DateTime.now();
  static const Duration _window = Duration(seconds: 3);

  DateTime _lastAdjust = DateTime.fromMillisecondsSinceEpoch(0);

  set targetCapacity(int value) {
    assert(value > 0);

    _targetCapacity = value;
    if (_currentCapacity > _targetCapacity) {
      _currentCapacity = _targetCapacity;
    } else if (_currentCapacity <= 0) {
      _currentCapacity = 1;
    }

    _drain();
  }

  LimiterStats get stats {
    final latencies = _latencies.toList()..sort((a, b) => a.compareTo(b));
    final count = latencies.length;
    final p95 = count == 0
        ? Duration.zero
        : latencies[(0.95 * (count - 1)).round()];

    final total = count + _errors;
    final errorRate = total == 0 ? 0.0 : _errors / total;

    return LimiterStats(
      capacity: _currentCapacity,
      targetCapacity: _targetCapacity,
      p95: p95,
      errorRate: errorRate,
      windowCount: total,
    );
  }

  Future<void> acquire({
    required Duration timeout,
    Future<DioException>? cancelSignal,
  }) async {
    _throwIfDisposed();

    await _waitForCooldown(cancelSignal);
    _throwIfDisposed();

    if (_permitsInUse < _currentCapacity) {
      _permitsInUse++;
      return;
    }

    final waiter = _Waiter();
    _waiters.addLast(waiter);

    try {
      final pending = <Future<void>>[
        waiter.completer.future,
        _disposeSignal.future.then<void>((_) {
          throw const _LimiterDisposed('Limiter has been disposed');
        }),
      ];

      if (cancelSignal != null) {
        pending.add(
          cancelSignal.then<void>((_) {
            throw const _LimiterAcquireCancelled(
              'Request cancelled while waiting for limiter slot',
            );
          }),
        );
      }

      await Future.any<void>(pending).timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            'Limiter acquire timeout after ${timeout.inSeconds}s',
            timeout,
          );
        },
      );
    } catch (_) {
      _removeWaiter(waiter);
      rethrow;
    }
  }

  void release() {
    if (_isDisposed) return;

    while (_waiters.isNotEmpty) {
      final waiter = _waiters.removeFirst();
      if (waiter.completer.isCompleted) {
        continue;
      }

      waiter.completer.complete();
      return;
    }

    if (_permitsInUse > 0) {
      _permitsInUse--;
    }
  }

  void cooldown(Duration duration) {
    final candidate = DateTime.now().add(duration);
    if (_cooldownUntil == null || candidate.isAfter(_cooldownUntil!)) {
      _cooldownUntil = candidate;
    }
  }

  void recordSuccess(Duration latency) {
    _pushLatency(latency);
    _maybeAdapt();
  }

  void recordFailure(Duration latency, {int? statusCode}) {
    _pushLatency(latency);
    _errors++;

    if (statusCode == 429) {
      cooldown(const Duration(seconds: 2));
    }

    _maybeAdapt();
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    if (!_disposeSignal.isCompleted) {
      _disposeSignal.complete();
    }

    while (_waiters.isNotEmpty) {
      final waiter = _waiters.removeFirst();
      if (!waiter.completer.isCompleted) {
        waiter.completer.completeError(
          const _LimiterDisposed('Limiter has been disposed'),
        );
      }
    }
  }

  Future<void> _waitForCooldown(Future<DioException>? cancelSignal) async {
    final now = DateTime.now();
    final cooldownUntil = _cooldownUntil;

    if (cooldownUntil == null || !now.isBefore(cooldownUntil)) {
      return;
    }

    final waitDuration = cooldownUntil.difference(now);

    final pending = <Future<void>>[
      Future<void>.delayed(waitDuration),
      _disposeSignal.future.then<void>((_) {
        throw const _LimiterDisposed('Limiter has been disposed');
      }),
    ];

    if (cancelSignal != null) {
      pending.add(
        cancelSignal.then<void>((_) {
          throw const _LimiterAcquireCancelled(
            'Request cancelled during limiter cooldown',
          );
        }),
      );
    }

    await Future.any<void>(pending);
  }

  void _pushLatency(Duration latency) {
    final now = DateTime.now();

    if (now.difference(_windowStart) > _window) {
      _latencies.clear();
      _errors = 0;
      _windowStart = now;
    }

    _latencies.addLast(latency);

    if (_latencies.length > 512) {
      _latencies.removeFirst();
    }
  }

  void _maybeAdapt() {
    final now = DateTime.now();
    if (now.difference(_lastAdjust) < _window) return;

    final currentStats = stats;

    if (currentStats.windowCount >= 10) {
      final shouldDecrease =
          currentStats.p95 > const Duration(milliseconds: 2500) ||
          currentStats.errorRate >= 0.12;

      final shouldIncrease =
          currentStats.p95 < const Duration(milliseconds: 800) &&
          currentStats.errorRate <= 0.02;

      if (shouldDecrease) {
        _currentCapacity = max(1, _currentCapacity - 1);
      } else if (shouldIncrease) {
        _currentCapacity = min(_targetCapacity, _currentCapacity + 1);
      }

      _drain();
    }

    _lastAdjust = now;
  }

  void _drain() {
    if (_isDisposed) return;

    while (_waiters.isNotEmpty && _permitsInUse < _currentCapacity) {
      final waiter = _waiters.removeFirst();

      if (waiter.completer.isCompleted) {
        continue;
      }

      _permitsInUse++;
      waiter.completer.complete();
    }
  }

  void _removeWaiter(_Waiter waiter) {
    _waiters.remove(waiter);
  }

  void _throwIfDisposed() {
    if (_isDisposed) {
      throw const _LimiterDisposed('Limiter has been disposed');
    }
  }
}

class _Waiter {
  final Completer<void> completer = Completer<void>();
}

class _InflightEntry {
  _InflightEntry() : _completer = Completer<Response<dynamic>>();

  final Completer<Response<dynamic>> _completer;

  Future<Response<dynamic>> get future => _completer.future;

  void complete(Response<dynamic> response) {
    if (_completer.isCompleted) return;
    _completer.complete(response);
  }

  void completeError(Object error, StackTrace stackTrace) {
    if (_completer.isCompleted) return;
    _completer.completeError(error, stackTrace);
  }
}

class _InflightRegistration {
  _InflightRegistration.owner({required this.key, required this.entry})
    : isOwner = true;

  _InflightRegistration.joiner({required this.key, required this.entry})
    : isOwner = false;

  final String key;
  final _InflightEntry entry;
  final bool isOwner;

  void complete(Response<dynamic> response) {
    if (!isOwner) return;
    entry.complete(response);
  }

  void completeError(Object error, StackTrace stackTrace) {
    if (!isOwner) return;
    entry.completeError(error, stackTrace);
  }
}

class _LimiterAcquireTimeout implements Exception {
  const _LimiterAcquireTimeout(this.message);

  final String message;
}

class _LimiterAcquireCancelled implements Exception {
  const _LimiterAcquireCancelled(this.message);

  final String message;
}

class _LimiterDisposed implements Exception {
  const _LimiterDisposed(this.message);

  final String message;
}

/// LRU cache avec TTL par entrée.
class _LruCache<K, V> {
  _LruCache({required this.capacity}) : assert(capacity > 0);

  final int capacity;
  final Map<K, _Entry<V>> _map = <K, _Entry<V>>{};

  V? getIfFresh(K key, {required DateTime now}) {
    final entry = _map.remove(key);
    if (entry == null) return null;

    if (entry.expiresAt.isBefore(now)) {
      return null;
    }

    _map[key] = entry;
    return entry.value;
  }

  void put(K key, V value, {required Duration ttl, required DateTime now}) {
    final expiresAt = now.add(ttl);

    _map.remove(key);
    _map[key] = _Entry(value, expiresAt);

    while (_map.length > capacity) {
      _map.remove(_map.keys.first);
    }
  }

  void clear() => _map.clear();
}

class _Entry<V> {
  _Entry(this.value, this.expiresAt);

  final V value;
  final DateTime expiresAt;
}

class _CachedPayload {
  _CachedPayload({
    required this.data,
    required this.statusCode,
    required this.headers,
    required this.extra,
    required this.queryParameters,
    required this.requestHeaders,
    required this.method,
    required this.path,
    required this.baseUrl,
  });

  final dynamic data;
  final int? statusCode;
  final Map<String, List<String>> headers;
  final Map<String, dynamic> extra;
  final Map<String, dynamic> queryParameters;
  final Map<String, dynamic> requestHeaders;
  final String method;
  final String path;
  final String baseUrl;

  factory _CachedPayload.fromResponse(Response response) {
    return _CachedPayload(
      data: response.data,
      statusCode: response.statusCode,
      headers: _cloneHeaders(response.headers),
      extra: Map<String, dynamic>.from(response.extra),
      queryParameters: Map<String, dynamic>.from(
        response.requestOptions.queryParameters,
      ),
      requestHeaders: Map<String, dynamic>.from(
        response.requestOptions.headers,
      ),
      method: response.requestOptions.method,
      path: response.requestOptions.path,
      baseUrl: response.requestOptions.baseUrl,
    );
  }

  Response<T>? tryAsResponse<T>() {
    try {
      return asResponse<T>();
    } catch (_) {
      return null;
    }
  }

  Response<T> asResponse<T>() {
    return Response<T>(
      data: data as T,
      statusCode: statusCode,
      headers: Headers.fromMap(headers),
      requestOptions: RequestOptions(
        path: path,
        method: method,
        baseUrl: baseUrl,
        queryParameters: Map<String, dynamic>.from(queryParameters),
        headers: Map<String, dynamic>.from(requestHeaders),
      ),
      extra: Map<String, dynamic>.from(extra),
    );
  }

  static Map<String, List<String>> _cloneHeaders(Headers headers) {
    final map = <String, List<String>>{};
    for (final entry in headers.map.entries) {
      map[entry.key] = List<String>.from(entry.value);
    }
    return map;
  }
}
