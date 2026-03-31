import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/parental/application/services/child_profile_rating_preload_service.dart';
import 'package:movi/src/core/parental/data/repositories/iptv_parental_content_candidate_repository.dart';
import 'package:movi/src/core/parental/data/services/content_rating_repository_warmup_gateway.dart';
import 'package:movi/src/core/parental/data/services/noop_content_metadata_resolvers.dart';
import 'package:movi/src/core/parental/domain/repositories/content_rating_repository.dart';
import 'package:movi/src/core/parental/domain/repositories/parental_content_candidate_repository.dart';
import 'package:movi/src/core/parental/domain/services/age_policy.dart';
import 'package:movi/src/core/parental/domain/services/content_rating_warmup_gateway.dart';
import 'package:movi/src/core/parental/domain/services/movie_metadata_resolver.dart';
import 'package:movi/src/core/parental/domain/services/series_metadata_resolver.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/storage/storage.dart';

final contentRatingRepositoryProvider = Provider<ContentRatingRepository>((
  ref,
) {
  return ref.watch(slProvider)<ContentRatingRepository>();
});

final agePolicyProvider = Provider<AgePolicy>((ref) {
  return ref.watch(slProvider)<AgePolicy>();
});

final childProfileRatingPreloadServiceProvider =
    Provider<ChildProfileRatingPreloadService>((ref) {
      final sl = ref.watch(slProvider);
      final ratingRepository = ref.watch(contentRatingRepositoryProvider);

      final candidateRepository =
          sl.isRegistered<ParentalContentCandidateRepository>()
          ? sl<ParentalContentCandidateRepository>()
          : IptvParentalContentCandidateRepository(sl<IptvLocalRepository>());

      final movieMetadataResolver = sl.isRegistered<MovieMetadataResolver>()
          ? sl<MovieMetadataResolver>()
          : const NoopMovieMetadataResolver();

      final seriesMetadataResolver = sl.isRegistered<SeriesMetadataResolver>()
          ? sl<SeriesMetadataResolver>()
          : const NoopSeriesMetadataResolver();

      final languageCode = ref.watch(currentLanguageCodeProvider);
      final preferredRegions = _preferredRegionsForLanguage(languageCode);

      final ratingWarmupGateway = sl.isRegistered<ContentRatingWarmupGateway>()
          ? sl<ContentRatingWarmupGateway>()
          : ContentRatingRepositoryWarmupGateway(
              ratingRepository,
              preferredRegions: preferredRegions,
            );

      return ChildProfileRatingPreloadService(
        candidateRepository: candidateRepository,
        movieMetadataResolver: movieMetadataResolver,
        seriesMetadataResolver: seriesMetadataResolver,
        ratingWarmupGateway: ratingWarmupGateway,
      );
    });

List<String> _preferredRegionsForLanguage(String languageCode) {
  final normalized = languageCode.trim().toLowerCase();

  switch (normalized) {
    case 'nl':
    case 'nl-be':
    case 'nl-nl':
      return const <String>['BE', 'NL', 'US'];
    case 'fr':
    case 'fr-be':
    case 'fr-fr':
      return const <String>['BE', 'FR', 'US'];
    default:
      return const <String>['BE', 'FR', 'US'];
  }
}
