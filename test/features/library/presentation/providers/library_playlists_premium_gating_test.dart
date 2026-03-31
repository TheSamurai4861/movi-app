import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/subscription/application/usecases/can_access_premium_feature.dart';
import 'package:movi/src/core/subscription/domain/entities/billing_availability.dart';
import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_entitlement.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_snapshot.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_status.dart';
import 'package:movi/src/core/subscription/domain/entities/subscription_offer.dart';
import 'package:movi/src/core/subscription/domain/repositories/subscription_repository.dart';
import 'package:movi/src/core/subscription/presentation/providers/subscription_providers.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/features/library/domain/repositories/library_repository.dart';
import 'package:movi/src/features/library/library_constants.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/features/playlist/playlist.dart';
import 'package:flutter/material.dart' show Locale;

void main() {
  test('hides in_progress and watch_history when not premium', () async {
    final container = ProviderContainer(
      overrides: [
        currentLocaleProvider.overrideWithValue(const Locale('fr')),
        currentUserIdProvider.overrideWithValue('test-user'),
        libraryRepositoryProvider.overrideWithValue(_FakeLibraryRepository()),
        playlistRepositoryProvider.overrideWithValue(_FakePlaylistRepository()),
        canAccessPremiumFeatureUseCaseProvider.overrideWithValue(
          CanAccessPremiumFeature(
            _FakeSubscriptionRepository(
              snapshot: SubscriptionSnapshot(
                status: SubscriptionStatus.inactive,
                billingAvailability: BillingAvailability.available,
                entitlements: const [
                  SubscriptionEntitlement(
                    feature: PremiumFeature.localContinueWatching,
                    isActive: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final playlists = await container.read(libraryPlaylistsProvider.future);

    expect(
      playlists.any((p) => p.id == LibraryConstants.inProgressPlaylistId),
      isFalse,
    );
    expect(
      playlists.any((p) => p.id == LibraryConstants.watchHistoryPlaylistId),
      isFalse,
    );
  });

  test('shows in_progress and watch_history when premium', () async {
    final container = ProviderContainer(
      overrides: [
        currentLocaleProvider.overrideWithValue(const Locale('fr')),
        currentUserIdProvider.overrideWithValue('test-user'),
        libraryRepositoryProvider.overrideWithValue(_FakeLibraryRepository()),
        playlistRepositoryProvider.overrideWithValue(_FakePlaylistRepository()),
        canAccessPremiumFeatureUseCaseProvider.overrideWithValue(
          CanAccessPremiumFeature(
            _FakeSubscriptionRepository(
              snapshot: SubscriptionSnapshot(
                status: SubscriptionStatus.active,
                billingAvailability: BillingAvailability.available,
                entitlements: const [
                  SubscriptionEntitlement(
                    feature: PremiumFeature.localContinueWatching,
                    isActive: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final playlists = await container.read(libraryPlaylistsProvider.future);

    expect(
      playlists.any((p) => p.id == LibraryConstants.inProgressPlaylistId),
      isTrue,
    );
    expect(
      playlists.any((p) => p.id == LibraryConstants.watchHistoryPlaylistId),
      isTrue,
    );
  });
}

class _FakeLibraryRepository implements LibraryRepository {
  @override
  Future<List<MovieSummary>> getLikedMovies() async => const [];

  @override
  Future<List<TvShowSummary>> getLikedShows() async => const [];

  @override
  Future<List<SagaSummary>> getLikedSagas() async => const [];

  @override
  Future<List<PersonSummary>> getLikedPersons() async => const [];

  @override
  Future<List<ContentReference>> getHistoryCompleted() async {
    return [
      ContentReference(
        id: 'm1',
        type: ContentType.movie,
        title: MediaTitle('m1'),
      ),
    ];
  }

  @override
  Future<List<ContentReference>> getHistoryInProgress() async {
    return [
      ContentReference(
        id: 'm2',
        type: ContentType.movie,
        title: MediaTitle('m2'),
      ),
    ];
  }

  @override
  Future<List<PlaylistSummary>> getUserPlaylists(String userId) async => const [];
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  _FakeSubscriptionRepository({required this.snapshot});

  final SubscriptionSnapshot snapshot;

  @override
  Future<SubscriptionSnapshot> getCurrentSubscription() async => snapshot;

  @override
  Future<List<SubscriptionOffer>> loadAvailableOffers() {
    throw UnimplementedError();
  }

  @override
  Future<SubscriptionSnapshot> purchaseSubscription({required String offerId}) {
    throw UnimplementedError();
  }

  @override
  Future<SubscriptionSnapshot> refreshSubscription() {
    throw UnimplementedError();
  }

  @override
  Future<SubscriptionSnapshot> restoreSubscription() {
    throw UnimplementedError();
  }
}

class _FakePlaylistRepository implements PlaylistRepository {
  @override
  Future<void> addItem({required PlaylistId playlistId, required PlaylistItem item}) {
    throw UnimplementedError();
  }

  @override
  Future<void> createPlaylist({
    required PlaylistId id,
    required MediaTitle title,
    String? description,
    Uri? cover,
    required String owner,
    bool isPublic = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deletePlaylist(PlaylistId id) {
    throw UnimplementedError();
  }

  @override
  Future<List<PlaylistSummary>> getFeaturedPlaylists() async => const [];

  @override
  Future<Playlist> getPlaylist(PlaylistId id) {
    throw UnimplementedError();
  }

  @override
  Future<List<PlaylistSummary>> getUserPlaylists(String userId) async => const [];

  @override
  Future<void> normalizePositions(PlaylistId id) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeItem({required PlaylistId playlistId, required PlaylistItem item}) {
    throw UnimplementedError();
  }

  @override
  Future<void> renamePlaylist({required PlaylistId id, required MediaTitle title}) {
    throw UnimplementedError();
  }

  @override
  Future<void> reorderItem({
    required PlaylistId playlistId,
    required int fromPosition,
    required int toPosition,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<PlaylistSummary>> searchPlaylists(String query) async => const [];

  @override
  Future<void> setOwner({required PlaylistId id, required String owner}) {
    throw UnimplementedError();
  }

  @override
  Future<void> setPinned({required PlaylistId id, required bool isPinned}) {
    throw UnimplementedError();
  }
}

