import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/notifications/local_notification_gateway.dart';
import 'package:movi/src/core/notifications/local_notification_gateway_provider.dart';
import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/presentation/providers/subscription_providers.dart';
import 'package:movi/src/core/storage/repositories/series_tracking_local_repository.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

final seriesTrackingRepositoryProvider = Provider<SeriesTrackingLocalRepository>(
  (ref) => SeriesTrackingLocalRepository(),
);

final class SeriesTrackingState {
  const SeriesTrackingState({
    required this.isTracked,
    required this.hasNewEpisode,
  });

  final bool isTracked;
  final bool hasNewEpisode;
}

final seriesTrackingStateProvider =
    FutureProvider.family<SeriesTrackingState, String>((ref, seriesId) async {
      final hasPremium = await ref.watch(
        canAccessPremiumFeatureProvider(PremiumFeature.seriesEpisodeTracking).future,
      );
      if (!hasPremium) {
        return const SeriesTrackingState(
          isTracked: false,
          hasNewEpisode: false,
        );
      }

      final repo = ref.watch(seriesTrackingRepositoryProvider);
      final userId = ref.watch(currentUserIdProvider);
      final tracked = await repo.getTrackedSeries(seriesId, userId: userId);
      return SeriesTrackingState(
        isTracked: tracked != null,
        hasNewEpisode: tracked?.hasNewEpisode ?? false,
      );
    });

final seriesIsTrackedProvider = FutureProvider.family<bool, String>(
  (ref, seriesId) async {
    final state = await ref.watch(seriesTrackingStateProvider(seriesId).future);
    return state.isTracked;
  },
);

final seriesHasNewEpisodeProvider = FutureProvider.family<bool, String>(
  (ref, seriesId) async {
    final state = await ref.watch(seriesTrackingStateProvider(seriesId).future);
    return state.hasNewEpisode;
  },
);

final seriesTrackingToggleProvider =
    NotifierProvider<SeriesTrackingToggleNotifier, void>(
      SeriesTrackingToggleNotifier.new,
    );

class SeriesTrackingToggleNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> toggle({
    required String seriesId,
    required String title,
    Uri? poster,
  }) async {
    final hasPremium = await ref.read(
      canAccessPremiumFeatureProvider(PremiumFeature.seriesEpisodeTracking).future,
    );
    if (!hasPremium) return;

    final repo = ref.read(seriesTrackingRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    final isTracked = await repo.isTracked(seriesId, userId: userId);

    if (isTracked) {
      await repo.untrackSeries(seriesId, userId: userId);
    } else {
      final latest = await _resolveLatestEpisodeSnapshot(seriesId);
      await repo.trackSeries(
        seriesId: seriesId,
        userId: userId,
        title: title,
        poster: poster,
        latestEpisode: latest,
      );
      await ref
          .read(localNotificationGatewayProvider)
          .requestSeriesNotificationsPermissionIfNeeded();
    }

    _invalidateSeries(seriesId);
  }

  Future<void> markSeen(String seriesId) async {
    final repo = ref.read(seriesTrackingRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    await repo.markNewEpisodeSeen(seriesId, userId: userId);
    _invalidateSeries(seriesId);
  }

  Future<void> refreshTrackedSeriesStatus(String seriesId) async {
    final hasPremium = await ref.read(
      canAccessPremiumFeatureProvider(PremiumFeature.seriesEpisodeTracking).future,
    );
    if (!hasPremium) return;

    final repo = ref.read(seriesTrackingRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    final tracked = await repo.getTrackedSeries(seriesId, userId: userId);
    if (tracked == null) return;
    final latest = await _resolveLatestEpisodeSnapshot(seriesId);
    if (latest == null) return;

    final outcome = await repo.updateLatestEpisodeSnapshot(
      seriesId: seriesId,
      userId: userId,
      latestEpisode: latest,
    );

    if (outcome?.shouldNotify == true) {
      await _notifyAboutNewEpisode(
        request: NewEpisodeNotificationRequest(
          seriesId: tracked.seriesId,
          seriesTitle: tracked.title,
          seasonNumber: latest.seasonNumber,
          episodeNumber: latest.episodeNumber,
          posterUri: tracked.poster,
        ),
      );
    }

    _invalidateSeries(seriesId);
  }

  Future<void> refreshFavoriteSeriesStatuses() async {
    final hasPremium = await ref.read(
      canAccessPremiumFeatureProvider(PremiumFeature.seriesEpisodeTracking).future,
    );
    if (!hasPremium) return;

    final libraryRepository = ref.read(libraryRepositoryProvider);
    final favorites = await libraryRepository.getLikedShows();
    for (final show in favorites) {
      await refreshTrackedSeriesStatus(show.id.value);
    }
  }

  Future<void> refreshAllTrackedSeriesStatuses() async {
    final hasPremium = await ref.read(
      canAccessPremiumFeatureProvider(PremiumFeature.seriesEpisodeTracking).future,
    );
    if (!hasPremium) return;

    final repo = ref.read(seriesTrackingRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    final trackedSeries = await repo.readAllTrackedSeries(userId: userId);
    for (final tracked in trackedSeries) {
      await refreshTrackedSeriesStatus(tracked.seriesId);
    }
  }

  Future<LatestEpisodeSnapshot?> _resolveLatestEpisodeSnapshot(
    String seriesId,
  ) async {
    final tvRepository = ref.read(tvRepositoryProvider);
    final seasons = await tvRepository.getSeasons(SeriesId(seriesId));
    return _pickLatestReleasedEpisode(seasons);
  }

  Future<void> _notifyAboutNewEpisode({
    required NewEpisodeNotificationRequest request,
  }) async {
    final gateway = ref.read(localNotificationGatewayProvider);
    await gateway.showNewEpisodeNotification(request);
  }

  void _invalidateSeries(String seriesId) {
    ref.invalidate(seriesTrackingStateProvider(seriesId));
    ref.invalidate(seriesIsTrackedProvider(seriesId));
    ref.invalidate(seriesHasNewEpisodeProvider(seriesId));
  }
}

LatestEpisodeSnapshot? _pickLatestReleasedEpisode(List<Season> seasons) {
  LatestEpisodeSnapshot? latest;
  final now = DateTime.now();
  for (final season in seasons) {
    for (final episode in season.episodes) {
      final airDate = episode.airDate;
      if (airDate != null && airDate.isAfter(now)) {
        continue;
      }
      final candidate = LatestEpisodeSnapshot(
        seasonNumber: season.seasonNumber,
        episodeNumber: episode.episodeNumber,
        airDate: airDate,
      );
      if (latest == null) {
        latest = candidate;
        continue;
      }
      final latestKey = latest.seasonNumber * 10000 + latest.episodeNumber;
      final candidateKey =
          candidate.seasonNumber * 10000 + candidate.episodeNumber;
      if (candidateKey > latestKey) {
        latest = candidate;
      }
    }
  }
  return latest;
}
