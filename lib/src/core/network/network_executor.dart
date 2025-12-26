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

/// Exécuteur générique et résilient pour les appels réseau (Dio).
/// - Concurrence plafonnée par clé (ex.: "tmdb") avec adaptation dynamique.
/// - Déduplication "in-flight" par requête pour éviter les doublons simultanés.
/// - Mini cache mémoire (LRU + TTL) pour réponses chaudes (30–60s).
/// - Backoff exponentiel + jitter, circuit-breaker 429.
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
  }) : assert(defaultMaxConcurrent > 0, 'defaultMaxConcurrent must be > 0'),
       assert(memoryCacheMaxEntries > 0, 'memoryCacheMaxEntries must be > 0'),
       _limiters = <String, _Limiter>{},
       _inflight = <String, Future<Response<dynamic>>>{},
       _memoryCache = _LruCache<String, _CachedPayload>(
         capacity: memoryCacheMaxEntries,
       );

  final Dio _client;
  final AppLogger? logger;

  /// Clé de concurrence appliquée si `concurrencyKey` n’est pas fournie à `run`.
  final String? defaultConcurrencyKey;

  /// Plafond par défaut utilisé lors de la création d’un nouveau limiteur.
  final int defaultMaxConcurrent;

  /// Paramètres du mini cache mémoire.
  final int memoryCacheMaxEntries;
  final Duration memoryCacheDefaultTtl;

  /// Garde-fous anti-blocage.
  Duration inflightJoinTimeout;
  Duration limiterAcquireTimeout;

  /// Limiteurs partagés par clé (ex.: "tmdb") pour lisser l’ensemble des appels.
  final Map<String, _Limiter> _limiters;

  /// Déduplication "in-flight": clé → Future en cours.
  final Map<String, Future<Response<dynamic>>> _inflight;

  /// Mini cache mémoire partagé (LRU + TTL).
  final _LruCache<String, _CachedPayload> _memoryCache;

  String? _typedDedupKey<T>(String? dedupKey) {
    if (dedupKey == null) return null;
    return '$dedupKey|T=${T.toString()}';
  }

  /// Configure/ajuste dynamiquement la concurrence max pour une [key].
  void configureConcurrency(String key, int maxConcurrent) {
    assert(maxConcurrent > 0, 'maxConcurrent must be > 0');
    final existing = _limiters[key];
    if (existing == null) {
      _limiters[key] = _Limiter(maxConcurrent);
    } else {
      existing.capacity = maxConcurrent;
    }
  }

  void configureLimiterAcquireTimeout(Duration timeout) {
    limiterAcquireTimeout = timeout;
  }

  void configureInflightJoinTimeout(Duration timeout) {
    inflightJoinTimeout = timeout;
  }

  /// Récupère quelques stats (utile en debug/telemetry).
  LimiterStats? getLimiterStats(String key) => _limiters[key]?.stats;

  /// Efface tous les limiteurs/in-flight/cache (utile en tests).
  void resetLimiters() {
    _limiters.clear();
    _inflight.clear();
    _memoryCache.clear();
  }

  /// Exécute [request] puis mappe la réponse via [mapper].
  ///
  /// [dedupKey] — clé logique (ex.: "GET|/3/tv/123?lang=fr&append=images").
  /// Si fournie, déduplique les requêtes simultanées **et** permet la lecture/écriture
  /// du mini cache mémoire. Si omise, la dédup/caching ne s’appliquera pas.
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

    // Annulation & hooks
    CancelToken? cancelToken,
    AttemptHook? onAttemptStart,
    AttemptHook? onAttemptEnd,
  }) async {
    final key = concurrencyKey ?? defaultConcurrencyKey;
    final typedDedupKey = _typedDedupKey<T>(dedupKey);
    _Limiter? limiter;

    if (key != null) {
      limiter = _limiters.putIfAbsent(
        key,
        () => _Limiter(maxConcurrent ?? defaultMaxConcurrent),
      );
      if (maxConcurrent != null && maxConcurrent > 0) {
        limiter.capacity = maxConcurrent;
      }
    }

    // 1) Cache mémoire (hit possible avant tout réseau).
    if (typedDedupKey != null) {
      final cached = _memoryCache.getIfFresh(
        typedDedupKey,
        now: DateTime.now(),
      );
      if (cached != null) {
        try {
          return mapper(cached.asResponse<T>());
        } catch (_) {
          // En cas d’incompatibilité de type, on ignore le cache.
        }
      }
    }

    // 2) Déduplication "in-flight": si une requête identique est en cours, on attend le même Future.
    // Mais avec un timeout pour éviter les blocages infinis si la requête précédente est bloquée.
    if (typedDedupKey != null) {
      final inflight = _inflight[typedDedupKey];
      if (inflight != null) {
        logger?.debug(
          'Reusing in-flight request for dedupKey=$dedupKey',
        );
        try {
          // Ajouter un timeout pour éviter d'attendre indéfiniment une requête bloquée
          final resp = await (inflight as Future<Response<T>>).timeout(
            inflightJoinTimeout,
            onTimeout: () {
              logger?.warn(
                'In-flight request timeout for dedupKey=$dedupKey, removing from cache',
              );
              // Retirer de la map pour permettre une nouvelle tentative
              _inflight.remove(typedDedupKey);
              throw TimeoutException(
                'In-flight request timeout after ${inflightJoinTimeout.inSeconds}s',
                inflightJoinTimeout,
              );
            },
          );
          return mapper(resp);
        } on TimeoutException {
          // Si timeout, on continue avec une nouvelle requête
          logger?.warn(
            'In-flight request timed out for dedupKey=$dedupKey, will retry',
          );
        } on DioException catch (e) {
          throw mapDioToFailure(e);
        } catch (e) {
          throw UnknownFailure(e.toString());
        }
      }
    }

    for (int attempt = 0; ; attempt++) {
      var registeredInflight = false;
      // Circuit-breaker/cooldown sur la clé de concurrence (ex.: 429).
      if (limiter != null) {
        // Vérifier si le token est annulé avant d'acquérir une slot
        if (cancelToken != null && cancelToken.isCancelled) {
          throw DioException(
            requestOptions: RequestOptions(path: _client.options.baseUrl),
            type: DioExceptionType.cancel,
            error: 'Request cancelled before acquiring limiter slot',
          );
        }
        // Ajouter un timeout sur acquire() pour éviter les blocages infinis
        // Avec retry automatique pour les timeouts (max 2 tentatives avec backoff)
        final limiterInstance = limiter;
        int limiterRetryAttempt = 0;
        const maxLimiterRetries = 2;
        while (limiterRetryAttempt <= maxLimiterRetries) {
          try {
            await limiterInstance.acquire().timeout(
              limiterAcquireTimeout,
              onTimeout: () {
                final stats = limiterInstance.stats;
                logger?.warn(
                  'Limiter acquire timeout after ${limiterAcquireTimeout.inSeconds}s for concurrencyKey=$key '
                  '(attempt ${limiterRetryAttempt + 1}/${maxLimiterRetries + 1}, stats: $stats)',
                );
                throw TimeoutException(
                  'Limiter acquire timeout after ${limiterAcquireTimeout.inSeconds}s',
                  limiterAcquireTimeout,
                );
              },
            );
            // Succès, sortir de la boucle de retry
            break;
          } on TimeoutException {
            // Si acquire timeout, vérifier à nouveau le cancelToken
            if (cancelToken != null && cancelToken.isCancelled) {
              throw DioException(
                requestOptions: RequestOptions(path: _client.options.baseUrl),
                type: DioExceptionType.cancel,
                error: 'Request cancelled during limiter acquire',
              );
            }
            // Si on a atteint le max de retries, propager l'erreur
            if (limiterRetryAttempt >= maxLimiterRetries) {
              final stats = limiterInstance.stats;
              logger?.error(
                'Limiter acquire failed after ${maxLimiterRetries + 1} attempts for concurrencyKey=$key (stats: $stats)',
              );
              rethrow;
            }
            // Backoff exponentiel : 300ms, 600ms
            final backoffDelay = Duration(milliseconds: 300 * (1 << limiterRetryAttempt));
            logger?.debug(
              'Retrying limiter acquire after ${backoffDelay.inMilliseconds}ms (attempt ${limiterRetryAttempt + 1}/$maxLimiterRetries)',
            );
            await Future.delayed(backoffDelay);
            limiterRetryAttempt++;
          }
        }
      }

      DioException? dioErr;
      onAttemptStart?.call(attempt, null);
      final sw = Stopwatch()..start();

      try {
        // Crée (ou réutilise) la Future à partager pour la dédup "in-flight".
        Future<Response<T>> future;
        if (typedDedupKey != null) {
          final existing = _inflight[typedDedupKey];
          if (existing != null) {
            future = existing as Future<Response<T>>;
          } else {
            future = request(_client, cancelToken);
            _inflight[typedDedupKey] = future as Future<Response<dynamic>>;
            registeredInflight = true;
          }
        } else {
          future = request(_client, cancelToken);
        }

        // Gère un timeout de secours si non configuré côté Dio.
        final Response<T> response = await future.timeout(
          timeout ?? _timeoutFromDio(),
          onTimeout: () {
            throw DioException(
              requestOptions: RequestOptions(path: _client.options.baseUrl),
              type: DioExceptionType.receiveTimeout,
            );
          },
        );

        if (cancelToken?.isCancelled == true) {
          throw DioException(
            requestOptions: response.requestOptions,
            type: DioExceptionType.cancel,
            error: 'Canceled by caller',
          );
        }

        if (response.data == null) {
          throw const EmptyResponseFailure();
        }

        // Enregistre métriques (latence OK).
        sw.stop();
        limiter?.recordSuccess(sw.elapsed);

        // Log de performance
        _logPerformance(key, sw.elapsed, true);

        // 3) Écrit dans le cache mémoire (LRU + TTL).
        if (typedDedupKey != null) {
          final ttl = cacheTtl ?? memoryCacheDefaultTtl;
          _memoryCache.put(
            typedDedupKey,
            _CachedPayload.fromResponse(response),
            ttl: ttl,
            now: DateTime.now(),
          );
        }

        try {
          final out = mapper(response);
          onAttemptEnd?.call(attempt, null);
          return out;
        } finally {
          if (typedDedupKey != null && registeredInflight) {
            _inflight.remove(typedDedupKey);
          }
        }
      } on DioException catch (e, st) {
        sw.stop();
        dioErr = e;

        final status = e.response?.statusCode;

        // Ne pas logger les 404 comme des erreurs - c'est un cas normal (ressource inexistante)
        // Les 404 sont fréquents pour les ratings de contenu TMDB qui n'existent pas
        if (status == 404) {
          logger?.debug('Resource not found (404)', category: 'network');
        } else {
          logger?.error('Network call failed', e, st);
        }

        // Enregistre métriques (échec).
        limiter?.recordFailure(sw.elapsed, statusCode: status);

        // Circuit-breaker 429: courte pause pour la clé (ex.: 2s).
        if (status == 429) {
          limiter?.cooldown(const Duration(seconds: 2));
        }

        final shouldRetry =
            attempt < retries && _shouldRetry(e, attempt, retryIf);
        if (shouldRetry) {
          final delay = _computeBackoff(
            attempt: attempt,
            base: baseDelay,
            max: maxDelay,
            jitter: jitter,
          );
          onAttemptEnd?.call(attempt, e);
          await Future.delayed(delay);
          continue;
        }

        onAttemptEnd?.call(attempt, e);

        if (typedDedupKey != null && registeredInflight) {
          _inflight.remove(typedDedupKey);
        }
        throw mapDioToFailure(e);
      } catch (e, st) {
        sw.stop();
        logger?.error('Unexpected network error', e, st);
        onAttemptEnd?.call(attempt, dioErr);

        if (typedDedupKey != null && registeredInflight) {
          _inflight.remove(typedDedupKey);
        }
        throw UnknownFailure(e.toString());
      } finally {
        limiter?.release();
      }
    }
  }

  void dispose() {
    _limiters.clear();
    _inflight.clear();
    _memoryCache.clear();
  }

  Duration _timeoutFromDio() {
    final receive = _client.options.receiveTimeout;
    if (receive != null && receive > Duration.zero) return receive;
    final connect = _client.options.connectTimeout;
    if (connect != null && connect > Duration.zero) return connect;
    return const Duration(seconds: 15); // Réduit de 30s à 15s pour TMDB/Supabase
  }

  bool _shouldRetry(
    DioException error,
    int attempt,
    NetworkRetryEvaluator? customEvaluator,
  ) {
    if (customEvaluator != null) return customEvaluator(error, attempt);

    const retryableStatus = <int>{408, 425, 429, 500, 502, 503, 504};
    final status = error.response?.statusCode;
    if (status != null && retryableStatus.contains(status)) return true;

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
    // Backoff exponentiel "full jitter".
    final factor = 1 << attempt; // 2^attempt
    final ms = base.inMilliseconds * factor;
    final clamped = min(ms, max.inMilliseconds);
    if (!jitter) return Duration(milliseconds: clamped);
    final rnd = Random();
    return Duration(milliseconds: rnd.nextInt(clamped + 1));
  }

  /// Log de performance pour chaque requête
  void _logPerformance(String? key, Duration elapsed, bool success) {
    final keyStr = key ?? 'default';
    logger?.debug(
      '[Network] key=$keyStr elapsed=${elapsed.inMilliseconds}ms success=$success',
    );
    
    // Log warning si lent (>5s)
    if (elapsed > const Duration(seconds: 5)) {
      logger?.warn(
        '[Network] SLOW REQUEST: key=$keyStr elapsed=${elapsed.inMilliseconds}ms success=$success',
      );
    }
  }
}

/// Stats exposées par le limiteur (à logger/observer).
class LimiterStats {
  LimiterStats({
    required this.capacity,
    required this.p95,
    required this.errorRate,
    required this.windowCount,
  });

  final int capacity;
  final Duration p95;
  final double errorRate; // 0..1
  final int windowCount;

  @override
  String toString() =>
      'cap=$capacity p95=${p95.inMilliseconds}ms err=${(errorRate * 100).toStringAsFixed(1)}% n=$windowCount';
}

/// Sémaphore + métriques + adaptation de capacité.
class _Limiter {
  _Limiter(this._capacity)
    : assert(_capacity > 0),
      _latencies = Queue<Duration>();

  // Sémaphore FIFO
  int _capacity;
  int _permitsInUse = 0;
  final Queue<Completer<void>> _waiters = Queue<Completer<void>>();

  // Cooldown après 429
  DateTime? _cooldownUntil;

  // Métriques latence/erreurs (fenêtre glissante ~3s)
  final Queue<Duration> _latencies;
  int _errors = 0;
  DateTime _windowStart = DateTime.now();
  static const _window = Duration(seconds: 3);

  // Dernière adaptation effectuée
  DateTime _lastAdjust = DateTime.fromMillisecondsSinceEpoch(0);

  set capacity(int value) {
    assert(value > 0);
    _capacity = value;
    _drain();
  }

  LimiterStats get stats {
    final lat = _latencies.toList()..sort((a, b) => a.compareTo(b));
    final n = lat.length;
    final p95 = n == 0 ? Duration.zero : lat[(0.95 * (n - 1)).round()];
    final total = n + _errors;
    final errRate = total == 0 ? 0.0 : _errors / total;
    return LimiterStats(
      capacity: _capacity,
      p95: p95,
      errorRate: errRate,
      windowCount: total,
    );
  }

  Future<void> acquire() async {
    // Respecte un éventuel cooldown (ex.: suite à 429).
    final now = DateTime.now();
    final until = _cooldownUntil;
    if (until != null && now.isBefore(until)) {
      final wait = until.difference(now);
      await Future.delayed(wait);
    }

    if (_permitsInUse < _capacity) {
      _permitsInUse++;
      return;
    }
    final c = Completer<void>();
    _waiters.addLast(c);
    return c.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      // Transfert direct du slot libéré au prochain waiter (permits inchangés).
      _waiters.removeFirst().complete();
      return;
    }
    if (_permitsInUse > 0) _permitsInUse--;
  }

  void cooldown(Duration d) {
    final candidate = DateTime.now().add(d);
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

  void _pushLatency(Duration d) {
    final now = DateTime.now();
    // Purge fenêtre glissante
    if (now.difference(_windowStart) > _window) {
      _latencies.clear();
      _errors = 0;
      _windowStart = now;
    }
    _latencies.addLast(d);
    // Bound pour éviter une croissance illimitée
    if (_latencies.length > 512) {
      _latencies.removeFirst();
    }
  }

  void _maybeAdapt() {
    final now = DateTime.now();
    if (now.difference(_lastAdjust) < _window) return;

    final s = stats;
    // Règles simples :
    // - Si p95 > 2500ms ou erreur élevée → on réduit la capacité (min 2).
    // - Si p95 < 800ms et erreurs basses → on augmente (max 8).
    if (s.windowCount >= 10) {
      if (s.p95 > const Duration(milliseconds: 2500) || s.errorRate >= 0.12) {
        _capacity = max(2, _capacity - 1);
      } else if (s.p95 < const Duration(milliseconds: 800) &&
          s.errorRate <= 0.02) {
        _capacity = min(8, _capacity + 1);
      }
      _drain();
    }
    _lastAdjust = now;
  }

  void _drain() {
    while (_waiters.isNotEmpty && _permitsInUse < _capacity) {
      _permitsInUse++;
      _waiters.removeFirst().complete();
    }
  }
}

/// LRU cache avec TTL par entrée.
class _LruCache<K, V> {
  _LruCache({required this.capacity}) : assert(capacity > 0);

  final int capacity;

  final Map<K, _Entry<V>> _map = <K, _Entry<V>>{};

  V? getIfFresh(K key, {required DateTime now}) {
    final e = _map.remove(key);
    if (e == null) return null;
    if (e.expiresAt.isBefore(now)) {
      return null; // expiré
    }
    // Réinsère pour marquer l'accès récent.
    _map[key] = e;
    return e.value;
  }

  void put(K key, V value, {required Duration ttl, required DateTime now}) {
    final expires = now.add(ttl);
    _map.remove(key); // évite duplicat
    _map[key] = _Entry(value, expires);

    // Évite la croissance non bornée.
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
      requestHeaders: Map<String, dynamic>.from(response.requestOptions.headers),
      method: response.requestOptions.method,
      path: response.requestOptions.path,
      baseUrl: response.requestOptions.baseUrl,
    );
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
