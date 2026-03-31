import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/parental/application/services/child_profile_rating_preload_service.dart';
import 'package:movi/src/core/parental/domain/entities/parental_content_candidate.dart';
import 'package:movi/src/core/parental/domain/repositories/parental_content_candidate_repository.dart';
import 'package:movi/src/core/parental/domain/services/content_rating_warmup_gateway.dart';
import 'package:movi/src/core/parental/domain/services/movie_metadata_resolver.dart';
import 'package:movi/src/core/parental/domain/services/series_metadata_resolver.dart';

void main() {
  group('ChildProfileRatingPreloadService', () {
    test('résout les ids manquants puis préchauffe les ratings', () async {
      final candidateRepository = _FakeCandidateRepository(
        <ParentalContentCandidate>[
          const ParentalContentCandidate(
            kind: ParentalContentCandidateKind.movie,
            title: 'The Matrix',
            normalizedTitle: 'the matrix',
          ),
          const ParentalContentCandidate(
            kind: ParentalContentCandidateKind.series,
            title: 'Breaking Bad',
            normalizedTitle: 'breaking bad',
          ),
        ],
      );

      final warmupGateway = _FakeRatingWarmupGateway();
      final service = ChildProfileRatingPreloadService(
        candidateRepository: candidateRepository,
        movieMetadataResolver: _FakeMovieMetadataResolver(
          <String, int>{'the matrix': 603},
        ),
        seriesMetadataResolver: _FakeSeriesMetadataResolver(
          <String, int>{'breaking bad': 1396},
        ),
        ratingWarmupGateway: warmupGateway,
        maxConcurrentResolutions: 1,
        maxConcurrentWarmups: 1,
      );

      final progresses = await service.preloadRatings().toList();

      expect(warmupGateway.warmedMovieIds, <int>[603]);
      expect(warmupGateway.warmedSeriesIds, <int>[1396]);
      expect(progresses.last.phase, PreloadPhase.completed);
      expect(progresses.last.moviesProcessed, 1);
      expect(progresses.last.seriesProcessed, 1);
    });

    test('déduplique les candidats par tmdb id ou titre normalisé', () async {
      final candidateRepository = _FakeCandidateRepository(
        <ParentalContentCandidate>[
          const ParentalContentCandidate(
            kind: ParentalContentCandidateKind.movie,
            title: 'Alien',
            normalizedTitle: 'alien',
            tmdbId: 348,
          ),
          const ParentalContentCandidate(
            kind: ParentalContentCandidateKind.movie,
            title: 'Alien 1979',
            normalizedTitle: 'alien',
            tmdbId: 348,
          ),
          const ParentalContentCandidate(
            kind: ParentalContentCandidateKind.series,
            title: 'Dark',
            normalizedTitle: 'dark',
          ),
          const ParentalContentCandidate(
            kind: ParentalContentCandidateKind.series,
            title: 'Dark [MULTI]',
            normalizedTitle: 'dark',
          ),
        ],
      );

      final warmupGateway = _FakeRatingWarmupGateway();
      final service = ChildProfileRatingPreloadService(
        candidateRepository: candidateRepository,
        movieMetadataResolver: _FakeMovieMetadataResolver(const <String, int>{}),
        seriesMetadataResolver: _FakeSeriesMetadataResolver(
          <String, int>{'dark': 70523},
        ),
        ratingWarmupGateway: warmupGateway,
        maxConcurrentResolutions: 1,
        maxConcurrentWarmups: 1,
      );

      await service.preload();

      expect(warmupGateway.warmedMovieIds, <int>[348]);
      expect(warmupGateway.warmedSeriesIds, <int>[70523]);
    });
  });
}

class _FakeCandidateRepository implements ParentalContentCandidateRepository {
  const _FakeCandidateRepository(this._candidates);

  final List<ParentalContentCandidate> _candidates;

  @override
  Future<List<ParentalContentCandidate>> listCandidates() async => _candidates;
}

class _FakeMovieMetadataResolver implements MovieMetadataResolver {
  const _FakeMovieMetadataResolver(this._byTitle);

  final Map<String, int> _byTitle;

  @override
  Future<MovieMetadataResolution?> resolveByTitle(String normalizedTitle) async {
    final tmdbId = _byTitle[normalizedTitle];
    if (tmdbId == null) {
      return null;
    }
    return MovieMetadataResolution(tmdbId: tmdbId);
  }
}

class _FakeSeriesMetadataResolver implements SeriesMetadataResolver {
  const _FakeSeriesMetadataResolver(this._byTitle);

  final Map<String, int> _byTitle;

  @override
  Future<SeriesMetadataResolution?> resolveByTitle(
    String normalizedTitle,
  ) async {
    final tmdbId = _byTitle[normalizedTitle];
    if (tmdbId == null) {
      return null;
    }
    return SeriesMetadataResolution(tmdbId: tmdbId);
  }
}

class _FakeRatingWarmupGateway implements ContentRatingWarmupGateway {
  final List<int> warmedMovieIds = <int>[];
  final List<int> warmedSeriesIds = <int>[];

  @override
  Future<void> warmupMovieRating(int tmdbId) async {
    warmedMovieIds.add(tmdbId);
  }

  @override
  Future<void> warmupSeriesRating(int tmdbId) async {
    warmedSeriesIds.add(tmdbId);
  }
}