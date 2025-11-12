// lib/src/core/network/network_executor.dart
import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:dio/dio.dart';

import 'package:movi/src/core/network/dio_failure_mapper.dart';
import 'package:movi/src/core/network/network_failures.dart';
import 'package:movi/src/core/logging/logger.dart';

typedef NetworkCall<T> = Future<Response<T>> Function(Dio client);
typedef RetryEvaluator = bool Function(DioException error, int attempt);
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
  }) : assert(defaultMaxConcurrent > 0, 'defaultMaxConcurrent must be > 0') {
    _memoryCache ??= _LruCache<String, Response<dynamic>>(
      capacity: memoryCacheMaxEntries,
    );
  }

  final Dio _client;
  final AppLogger? logger;

  /// Clé de concurrence appliquée si `concurrencyKey` n’est pas fournie à `run`.
  final String? defaultConcurrencyKey;

  /// Plafond par défaut utilisé lors de la création d’un nouveau limiteur.
  final int defaultMaxConcurrent;

  /// Paramètres du mini cache mémoire.
  final int memoryCacheMaxEntries;
  final Duration memoryCacheDefaultTtl;

  /// Limiteurs partagés par clé (ex.: "tmdb") pour lisser l’ensemble des appels.
  static final Map<String, _Limiter> _limiters = <String, _Limiter>{};

  /// Déduplication "in-flight": clé → Future en cours.
  static final Map<String, Future<Response<dynamic>>> _inflight =
      <String, Future<Response<dynamic>>>{};

  /// Mini cache mémoire partagé (LRU + TTL).
  static _LruCache<String, Response<dynamic>>? _memoryCache;

  /// Configure/ajuste dynamiquement la concurrence max pour une [key].
  static void configureConcurrency(String key, int maxConcurrent) {
    assert(maxConcurrent > 0, 'maxConcurrent must be > 0');
    final existing = _limiters[key];
    if (existing == null) {
      _limiters[key] = _Limiter(maxConcurrent);
    } else {
      existing.capacity = maxConcurrent;
    }
  }

  /// Récupère quelques stats (utile en debug/telemetry).
  static LimiterStats? getLimiterStats(String key) => _limiters[key]?.stats;

  /// Efface tous les limiteurs/in-flight/cache (utile en tests).
  static void resetLimiters() {
    _limiters.clear();
    _inflight.clear();
    _memoryCache?.clear();
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

    // Résilience / retry
    int retries = 0,
    RetryEvaluator? retryIf,
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
    if (dedupKey != null) {
      final cached = _memoryCache?.getIfFresh(dedupKey, now: DateTime.now());
      if (cached != null) {
        try {
          final mapped = mapper(cached as Response<T>);
          return mapped;
        } catch (_) {
          // En cas d’incompatibilité de type, on ignore le cache.
        }
      }
    }

    // 2) Déduplication "in-flight": si une requête identique est en cours, on attend le même Future.
    if (dedupKey != null) {
      final inflight = _inflight[dedupKey];
      if (inflight != null) {
        try {
          final resp = await inflight as Response<T>;
          return mapper(resp);
        } on DioException catch (e) {
          throw mapDioToFailure(e);
        } catch (e) {
          throw UnknownFailure(e.toString());
        }
      }
    }

    for (int attempt = 0; ; attempt++) {
      // Circuit-breaker/cooldown sur la clé de concurrence (ex.: 429).
      if (limiter != null) {
        await limiter.acquire();
      }

      DioException? dioErr;
      onAttemptStart?.call(attempt, null);
      final sw = Stopwatch()..start();

      try {
        // Crée (ou réutilise) la Future à partager pour la dédup "in-flight".
        Future<Response<T>> future;
        if (dedupKey != null) {
          future =
              (_inflight[dedupKey] ??=
                      request(_client) as Future<Response<dynamic>>)
                  as Future<Response<T>>;
        } else {
          future = request(_client);
        }

        // Gère un timeout de secours si non configuré côté Dio.
        final Response<T> response = await future.timeout(
          _timeoutFromDio(),
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

        // 3) Écrit dans le cache mémoire (LRU + TTL).
        if (dedupKey != null) {
          final ttl = cacheTtl ?? memoryCacheDefaultTtl;
          _memoryCache?.put(
            dedupKey,
            response as Response<dynamic>,
            ttl: ttl,
            now: DateTime.now(),
          );
        }

        // 4) Retire la requête de l’in-flight (si présente).
        if (dedupKey != null) {
          _inflight.remove(dedupKey);
        }

        onAttemptEnd?.call(attempt, null);
        final out = mapper(response);
        return out;
      } on DioException catch (e, st) {
        sw.stop();
        dioErr = e;
        logger?.error('Network call failed', e, st);

        final status = e.response?.statusCode;

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

        // Nettoie l’in-flight si c’était la requête partagée qui a échoué.
        if (dedupKey != null) {
          _inflight.remove(dedupKey);
        }

        throw mapDioToFailure(e);
      } catch (e, st) {
        sw.stop();
        logger?.error('Unexpected network error', e, st);
        onAttemptEnd?.call(attempt, dioErr);

        // Nettoie l’in-flight si c’était la requête partagée qui a échoué.
        if (dedupKey != null) {
          _inflight.remove(dedupKey);
        }

        throw UnknownFailure(e.toString());
      } finally {
        limiter?.release();
      }
    }
  }

  Duration _timeoutFromDio() {
    final receive = _client.options.receiveTimeout;
    if (receive != null && receive > Duration.zero) return receive;
    final connect = _client.options.connectTimeout;
    if (connect != null && connect > Duration.zero) return connect;
    return const Duration(seconds: 30);
  }

  bool _shouldRetry(
    DioException error,
    int attempt,
    RetryEvaluator? customEvaluator,
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
    if (_waiters.isNotEmpty && _permitsInUse <= _capacity) {
      _permitsInUse++; // transfert direct
      _waiters.removeFirst().complete();
      return;
    }
    if (_permitsInUse > 0) {
      _permitsInUse--;
    }
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
