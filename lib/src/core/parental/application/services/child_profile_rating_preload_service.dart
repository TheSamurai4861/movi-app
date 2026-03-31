import 'dart:async';
import 'dart:collection';

import 'package:movi/src/core/parental/domain/entities/parental_content_candidate.dart';
import 'package:movi/src/core/parental/domain/repositories/parental_content_candidate_repository.dart';
import 'package:movi/src/core/parental/domain/services/content_rating_warmup_gateway.dart';
import 'package:movi/src/core/parental/domain/services/movie_metadata_resolver.dart';
import 'package:movi/src/core/parental/domain/services/series_metadata_resolver.dart';

/// État de progression du préchargement.
class PreloadProgress {
  const PreloadProgress({
    required this.phase,
    required this.moviesProcessed,
    required this.moviesTotal,
    required this.seriesProcessed,
    required this.seriesTotal,
    required this.elapsedSeconds,
    required this.estimatedSecondsRemaining,
  });

  final PreloadPhase phase;
  final int moviesProcessed;
  final int moviesTotal;
  final int seriesProcessed;
  final int seriesTotal;
  final int elapsedSeconds;
  final int? estimatedSecondsRemaining;

  double get moviesProgress =>
      moviesTotal > 0 ? moviesProcessed / moviesTotal : 0.0;

  double get seriesProgress =>
      seriesTotal > 0 ? seriesProcessed / seriesTotal : 0.0;

  double get overallProgress {
    final total = moviesTotal + seriesTotal;
    if (total == 0) {
      return 0.0;
    }
    return (moviesProcessed + seriesProcessed) / total;
  }
}

enum PreloadPhase { resolvingIds, fetchingRatings, completed }

class _Semaphore {
  _Semaphore(this._max) : _available = _max;

  final int _max;
  int _available;
  final Queue<Completer<void>> _waiters = Queue<Completer<void>>();

  Future<void> acquire() {
    if (_available > 0) {
      _available -= 1;
      return Future<void>.value();
    }

    final completer = Completer<void>();
    _waiters.addLast(completer);
    return completer.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete();
      return;
    }

    _available += 1;
    if (_available > _max) {
      _available = _max;
    }
  }
}

class _ResolvedCandidate {
  const _ResolvedCandidate({
    required this.kind,
    required this.title,
    required this.tmdbId,
  });

  final ParentalContentCandidateKind kind;
  final String title;
  final int tmdbId;
}

/// Service applicatif responsable de l'orchestration du préchargement parental.
///
/// Responsabilités :
/// - charger des candidats neutres
/// - résoudre les TMDB IDs manquants via ports
/// - déclencher le warmup des ratings via un gateway
///
/// Ne dépend d'aucun détail concret IPTV / TMDB.
class ChildProfileRatingPreloadService {
  ChildProfileRatingPreloadService({
    required ParentalContentCandidateRepository candidateRepository,
    required MovieMetadataResolver movieMetadataResolver,
    required SeriesMetadataResolver seriesMetadataResolver,
    required ContentRatingWarmupGateway ratingWarmupGateway,
    this.maxConcurrentResolutions = 4,
    this.maxConcurrentWarmups = 6,
  }) : _candidateRepository = candidateRepository,
       _movieMetadataResolver = movieMetadataResolver,
       _seriesMetadataResolver = seriesMetadataResolver,
       _ratingWarmupGateway = ratingWarmupGateway;

  final ParentalContentCandidateRepository _candidateRepository;
  final MovieMetadataResolver _movieMetadataResolver;
  final SeriesMetadataResolver _seriesMetadataResolver;
  final ContentRatingWarmupGateway _ratingWarmupGateway;

  final int maxConcurrentResolutions;
  final int maxConcurrentWarmups;

  /// Alias de compatibilité.
  Stream<PreloadProgress> preloadForChildProfile() => preloadRatings();

  /// Lance le préchargement et émet les étapes de progression.
  Stream<PreloadProgress> preloadRatings() async* {
    final stopwatch = Stopwatch()..start();

    final candidates = await _candidateRepository.listCandidates();
    final groupedCandidates = _groupCandidates(candidates);

    var moviesProcessed = 0;
    var seriesProcessed = 0;

    yield _buildProgress(
      phase: PreloadPhase.resolvingIds,
      moviesProcessed: moviesProcessed,
      moviesTotal: groupedCandidates.movies.length,
      seriesProcessed: seriesProcessed,
      seriesTotal: groupedCandidates.series.length,
      stopwatch: stopwatch,
    );

    final resolvedMovies = await _resolveMovieCandidates(
      groupedCandidates.movies,
      onItemResolved: () {
        moviesProcessed += 1;
      },
    );

    yield _buildProgress(
      phase: PreloadPhase.resolvingIds,
      moviesProcessed: moviesProcessed,
      moviesTotal: groupedCandidates.movies.length,
      seriesProcessed: seriesProcessed,
      seriesTotal: groupedCandidates.series.length,
      stopwatch: stopwatch,
    );

    final resolvedSeries = await _resolveSeriesCandidates(
      groupedCandidates.series,
      onItemResolved: () {
        seriesProcessed += 1;
      },
    );

    yield _buildProgress(
      phase: PreloadPhase.resolvingIds,
      moviesProcessed: moviesProcessed,
      moviesTotal: groupedCandidates.movies.length,
      seriesProcessed: seriesProcessed,
      seriesTotal: groupedCandidates.series.length,
      stopwatch: stopwatch,
    );

    moviesProcessed = 0;
    seriesProcessed = 0;

    yield _buildProgress(
      phase: PreloadPhase.fetchingRatings,
      moviesProcessed: moviesProcessed,
      moviesTotal: resolvedMovies.length,
      seriesProcessed: seriesProcessed,
      seriesTotal: resolvedSeries.length,
      stopwatch: stopwatch,
    );

    await _warmupMovies(
      resolvedMovies,
      onItemWarmed: () {
        moviesProcessed += 1;
      },
    );

    yield _buildProgress(
      phase: PreloadPhase.fetchingRatings,
      moviesProcessed: moviesProcessed,
      moviesTotal: resolvedMovies.length,
      seriesProcessed: seriesProcessed,
      seriesTotal: resolvedSeries.length,
      stopwatch: stopwatch,
    );

    await _warmupSeries(
      resolvedSeries,
      onItemWarmed: () {
        seriesProcessed += 1;
      },
    );

    yield _buildProgress(
      phase: PreloadPhase.completed,
      moviesProcessed: moviesProcessed,
      moviesTotal: resolvedMovies.length,
      seriesProcessed: seriesProcessed,
      seriesTotal: resolvedSeries.length,
      stopwatch: stopwatch,
      estimatedSecondsRemaining: 0,
    );

    stopwatch.stop();
  }

  /// Variante pratique quand l'appelant préfère un callback à un stream.
  Future<void> preload({
    void Function(PreloadProgress progress)? onProgress,
  }) async {
    await for (final progress in preloadRatings()) {
      onProgress?.call(progress);
    }
  }

  _GroupedCandidates _groupCandidates(
    List<ParentalContentCandidate> candidates,
  ) {
    final movies = <ParentalContentCandidate>[];
    final series = <ParentalContentCandidate>[];

    for (final candidate in candidates) {
      switch (candidate.kind) {
        case ParentalContentCandidateKind.movie:
          movies.add(candidate);
          break;
        case ParentalContentCandidateKind.series:
          series.add(candidate);
          break;
      }
    }

    return _GroupedCandidates(
      movies: _deduplicateCandidates(movies),
      series: _deduplicateCandidates(series),
    );
  }

  List<ParentalContentCandidate> _deduplicateCandidates(
    List<ParentalContentCandidate> candidates,
  ) {
    final uniqueByKey = <String, ParentalContentCandidate>{};

    for (final candidate in candidates) {
      final key = candidate.hasTmdbId
          ? 'tmdb:${candidate.tmdbId}'
          : 'title:${candidate.normalizedTitle}';

      uniqueByKey.putIfAbsent(key, () => candidate);
    }

    return uniqueByKey.values.toList(growable: false);
  }

  Future<List<_ResolvedCandidate>> _resolveMovieCandidates(
    List<ParentalContentCandidate> candidates, {
    required void Function() onItemResolved,
  }) async {
    final semaphore = _Semaphore(maxConcurrentResolutions);
    final resolved = <_ResolvedCandidate>[];

    await Future.wait(
      candidates.map((candidate) async {
        await semaphore.acquire();
        try {
          final tmdbId = await _resolveMovieTmdbId(candidate);
          if (tmdbId != null && tmdbId > 0) {
            resolved.add(
              _ResolvedCandidate(
                kind: ParentalContentCandidateKind.movie,
                title: candidate.title,
                tmdbId: tmdbId,
              ),
            );
          }
        } finally {
          onItemResolved();
          semaphore.release();
        }
      }),
    );

    return _deduplicateResolvedCandidates(resolved);
  }

  Future<List<_ResolvedCandidate>> _resolveSeriesCandidates(
    List<ParentalContentCandidate> candidates, {
    required void Function() onItemResolved,
  }) async {
    final semaphore = _Semaphore(maxConcurrentResolutions);
    final resolved = <_ResolvedCandidate>[];

    await Future.wait(
      candidates.map((candidate) async {
        await semaphore.acquire();
        try {
          final tmdbId = await _resolveSeriesTmdbId(candidate);
          if (tmdbId != null && tmdbId > 0) {
            resolved.add(
              _ResolvedCandidate(
                kind: ParentalContentCandidateKind.series,
                title: candidate.title,
                tmdbId: tmdbId,
              ),
            );
          }
        } finally {
          onItemResolved();
          semaphore.release();
        }
      }),
    );

    return _deduplicateResolvedCandidates(resolved);
  }

  Future<int?> _resolveMovieTmdbId(ParentalContentCandidate candidate) async {
    if (candidate.hasTmdbId) {
      return candidate.tmdbId;
    }

    final resolution = await _movieMetadataResolver.resolveByTitle(
      candidate.normalizedTitle,
    );
    return resolution?.tmdbId;
  }

  Future<int?> _resolveSeriesTmdbId(ParentalContentCandidate candidate) async {
    if (candidate.hasTmdbId) {
      return candidate.tmdbId;
    }

    final resolution = await _seriesMetadataResolver.resolveByTitle(
      candidate.normalizedTitle,
    );
    return resolution?.tmdbId;
  }

  List<_ResolvedCandidate> _deduplicateResolvedCandidates(
    List<_ResolvedCandidate> candidates,
  ) {
    final unique = <int, _ResolvedCandidate>{};

    for (final candidate in candidates) {
      unique.putIfAbsent(candidate.tmdbId, () => candidate);
    }

    return unique.values.toList(growable: false);
  }

  Future<void> _warmupMovies(
    List<_ResolvedCandidate> candidates, {
    required void Function() onItemWarmed,
  }) async {
    final semaphore = _Semaphore(maxConcurrentWarmups);

    await Future.wait(
      candidates.map((candidate) async {
        await semaphore.acquire();
        try {
          await _ratingWarmupGateway.warmupMovieRating(candidate.tmdbId);
        } catch (_) {
          // Best-effort: un échec unitaire ne doit pas bloquer tout le warmup.
        } finally {
          onItemWarmed();
          semaphore.release();
        }
      }),
    );
  }

  Future<void> _warmupSeries(
    List<_ResolvedCandidate> candidates, {
    required void Function() onItemWarmed,
  }) async {
    final semaphore = _Semaphore(maxConcurrentWarmups);

    await Future.wait(
      candidates.map((candidate) async {
        await semaphore.acquire();
        try {
          await _ratingWarmupGateway.warmupSeriesRating(candidate.tmdbId);
        } catch (_) {
          // Best-effort: un échec unitaire ne doit pas bloquer tout le warmup.
        } finally {
          onItemWarmed();
          semaphore.release();
        }
      }),
    );
  }

  PreloadProgress _buildProgress({
    required PreloadPhase phase,
    required int moviesProcessed,
    required int moviesTotal,
    required int seriesProcessed,
    required int seriesTotal,
    required Stopwatch stopwatch,
    int? estimatedSecondsRemaining,
  }) {
    return PreloadProgress(
      phase: phase,
      moviesProcessed: moviesProcessed,
      moviesTotal: moviesTotal,
      seriesProcessed: seriesProcessed,
      seriesTotal: seriesTotal,
      elapsedSeconds: stopwatch.elapsed.inSeconds,
      estimatedSecondsRemaining:
          estimatedSecondsRemaining ??
          _estimateSecondsRemaining(
            processed: moviesProcessed + seriesProcessed,
            total: moviesTotal + seriesTotal,
            elapsed: stopwatch.elapsed,
          ),
    );
  }

  int? _estimateSecondsRemaining({
    required int processed,
    required int total,
    required Duration elapsed,
  }) {
    if (processed <= 0 || total <= 0 || processed >= total) {
      return processed >= total ? 0 : null;
    }

    final averageMsPerItem = elapsed.inMilliseconds / processed;
    final remainingItems = total - processed;
    final remainingMs = averageMsPerItem * remainingItems;

    return Duration(milliseconds: remainingMs.round()).inSeconds;
  }
}

class _GroupedCandidates {
  const _GroupedCandidates({required this.movies, required this.series});

  final List<ParentalContentCandidate> movies;
  final List<ParentalContentCandidate> series;
}
