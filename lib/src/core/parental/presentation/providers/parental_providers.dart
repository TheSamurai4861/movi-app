import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/parental/application/services/child_profile_rating_preload_service.dart';
import 'package:movi/src/core/parental/domain/repositories/content_rating_repository.dart';
import 'package:movi/src/core/parental/domain/services/age_policy.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/shared/domain/services/similarity_service.dart';
import 'package:movi/src/core/state/app_state_provider.dart';

final contentRatingRepositoryProvider = Provider<ContentRatingRepository>((ref) {
  return ref.watch(slProvider)<ContentRatingRepository>();
});

final agePolicyProvider = Provider<AgePolicy>((ref) {
  return ref.watch(slProvider)<AgePolicy>();
});

final childProfileRatingPreloadServiceProvider =
    Provider<ChildProfileRatingPreloadService>((ref) {
  final sl = ref.watch(slProvider);
  final ratingRepo = ref.watch(contentRatingRepositoryProvider);
  final iptvLocal = sl<IptvLocalRepository>();
  final movieRemote = sl<TmdbMovieRemoteDataSource>();
  final tvRemote = sl<TmdbTvRemoteDataSource>();
  final similarity = sl<SimilarityService>();
  final cache = sl<ContentCacheRepository>();
  final languageCode = ref.watch(currentLanguageCodeProvider);
  final language = '$languageCode-$languageCode'.toUpperCase();

  return ChildProfileRatingPreloadService(
    iptvLocal,
    ratingRepo,
    movieRemote,
    tvRemote,
    similarity,
    cache,
    language,
  );
});

