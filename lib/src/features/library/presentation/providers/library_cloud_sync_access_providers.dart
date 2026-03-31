
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/presentation/providers/subscription_providers.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/features/library/application/services/cloud_sync_access_policy.dart';
import 'package:movi/src/features/library/application/services/cloud_sync_preferences.dart';

final cloudSyncAccessPolicyProvider = Provider<CloudSyncAccessPolicy>((ref) {
  return const CloudSyncAccessPolicy();
});

final cloudSyncPreferencesProvider = FutureProvider<CloudSyncPreferences>((
  ref,
) async {
  final locator = ref.watch(slProvider);
  final preferences = await CloudSyncPreferences.create(
    storage: locator<SecureStorageRepository>(),
  );

  ref.onDispose(() {
    unawaited(preferences.dispose());
  });

  return preferences;
});

final cloudSyncUserPreferenceProvider = StreamProvider<bool>((ref) async* {
  final preferences = await ref.watch(cloudSyncPreferencesProvider.future);
  yield* preferences.userWantsAutoSyncStreamWithInitial;
});

final cloudSyncAuthSnapshotProvider = StreamProvider<AuthSnapshot>((
  ref,
) async* {
  final repository = ref.watch(authRepositoryProvider);
  final currentSession = repository.currentSession;

  if (currentSession == null) {
    yield AuthSnapshot.unauthenticated;
  } else {
    yield AuthSnapshot(
      status: AuthStatus.authenticated,
      session: currentSession,
    );
  }

  yield* repository.onAuthStateChange;
});

final cloudLibrarySyncEntitlementProvider = Provider<bool>((ref) {
  return ref
      .watch(canAccessPremiumFeatureProvider(PremiumFeature.cloudLibrarySync))
      .maybeWhen(data: (value) => value, orElse: () => false);
});

final cloudSyncAccessStateProvider = Provider<CloudSyncAccessState>((ref) {
  final policy = ref.watch(cloudSyncAccessPolicyProvider);
  final userWantsAutoSync = ref
      .watch(cloudSyncUserPreferenceProvider)
      .maybeWhen(data: (value) => value, orElse: () => false);
  final authSnapshot = ref
      .watch(cloudSyncAuthSnapshotProvider)
      .maybeWhen(data: (value) => value, orElse: () => AuthSnapshot.unknown);
  final hasPremiumEntitlement = ref.watch(cloudLibrarySyncEntitlementProvider);

  return policy.resolve(
    userWantsAutoSync: userWantsAutoSync,
    isAuthenticated: authSnapshot.isAuthenticated,
    hasPremiumEntitlement: hasPremiumEntitlement,
  );
});

final effectiveCloudSyncEnabledProvider = Provider<bool>((ref) {
  return ref.watch(cloudSyncAccessStateProvider).effectiveCloudSyncEnabled;
});

final shouldBootstrapLibraryCloudSyncProvider = Provider<bool>((ref) {
  return ref.watch(effectiveCloudSyncEnabledProvider);
});
