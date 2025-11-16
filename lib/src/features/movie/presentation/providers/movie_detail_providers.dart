import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/features/movie/presentation/models/movie_detail_view_model.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/features/movie/domain/usecases/filter_recommendations_by_iptv.dart';

final movieDetailControllerProvider =
    FutureProvider.family<MovieDetailViewModel, String>((ref, movieId) async {
      final lang = ref.watch(currentLanguageCodeProvider);
      final locator = ref.watch(slProvider);
      final logger = locator<AppLogger>();
      final repo = locator<MovieRepository>();
      final id = MovieId(movieId);
      final t0 = DateTime.now();
      final detail = await repo.getMovie(id);
      final t1 = DateTime.now();
      final people = await repo.getCredits(id);
      final t2 = DateTime.now();
      final reco = await repo.getRecommendations(id);
      final t3 = DateTime.now();
      final filterReco = locator<FilterRecommendationsByIptvAvailability>();
      final filtered = await filterReco(reco);
      logger.debug(
        'movie_detail fetch id=$movieId lang=$lang durations: detail=${t1.difference(t0).inMilliseconds}ms, credits=${t2.difference(t1).inMilliseconds}ms, reco=${t3.difference(t2).inMilliseconds}ms',
        category: 'movie_detail',
      );
      return MovieDetailViewModel.fromDomain(
        detail: detail,
        credits: people,
        recommendations: filtered,
        language: lang,
      );
    });
