import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/iptv/data/services/route_profile_credentials_store.dart';
import 'package:movi/src/features/iptv/domain/entities/source_connection_models.dart';
import 'package:movi/src/features/iptv/domain/entities/source_probe_models.dart';
import 'package:movi/src/features/iptv/domain/repositories/route_profile_repository.dart';
import 'package:movi/src/features/iptv/domain/repositories/source_connection_policy_repository.dart';
import 'package:movi/src/features/iptv/domain/repositories/source_probe_service.dart';

final routeProfileRepositoryProvider = Provider<RouteProfileRepository>((ref) {
  return ref.watch(slProvider)<RouteProfileRepository>();
});

final routeProfileCredentialsStoreProvider =
    Provider<RouteProfileCredentialsStore>((ref) {
      return ref.watch(slProvider)<RouteProfileCredentialsStore>();
    });

final sourceConnectionPolicyRepositoryProvider =
    Provider<SourceConnectionPolicyRepository>((ref) {
      return ref.watch(slProvider)<SourceConnectionPolicyRepository>();
    });

final sourceProbeServiceProvider = Provider<SourceProbeService>((ref) {
  return ref.watch(slProvider)<SourceProbeService>();
});

final routeProfilesProvider = FutureProvider<List<RouteProfile>>((ref) async {
  return ref.watch(routeProfileRepositoryProvider).listProfiles();
});

final routeProfileCredentialsProvider =
    FutureProvider.family<RouteProfileCredentials?, String>((ref, profileId) {
      return ref
          .watch(routeProfileCredentialsStoreProvider)
          .read(profileId.trim());
    });

final sourceConnectionPolicyProvider =
    FutureProvider.family<SourceConnectionPolicy, String>((ref, accountId) async {
      final repository = ref.watch(sourceConnectionPolicyRepositoryProvider);
      final normalizedAccountId = accountId.trim();
      final policy = await repository.getPolicy(
        accountId: normalizedAccountId,
        sourceKind: SourceKind.xtream,
      );
      return policy ??
          SourceConnectionPolicy.defaults(
            ownerId: 'device_local',
            accountId: normalizedAccountId,
            sourceKind: SourceKind.xtream,
          );
    });

class NetworkProfileEditState {
  const NetworkProfileEditState({
    this.isLoading = false,
    this.error,
  });

  final bool isLoading;
  final String? error;

  NetworkProfileEditState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return NetworkProfileEditState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NetworkProfileEditController extends Notifier<NetworkProfileEditState> {
  late final RouteProfileRepository _profiles;
  late final RouteProfileCredentialsStore _credentials;
  late final SourceConnectionPolicyRepository _policies;

  @override
  NetworkProfileEditState build() {
    _profiles = ref.watch(routeProfileRepositoryProvider);
    _credentials = ref.watch(routeProfileCredentialsStoreProvider);
    _policies = ref.watch(sourceConnectionPolicyRepositoryProvider);
    return const NetworkProfileEditState();
  }

  Future<RouteProfile?> saveProxyProfile({
    String? id,
    required String name,
    required String scheme,
    required String host,
    required int port,
    required bool enabled,
    String? proxyUsername,
    String? proxyPassword,
  }) async {
    state = const NetworkProfileEditState(isLoading: true);
    try {
      final now = DateTime.now();
      final profileId = (id == null || id.trim().isEmpty)
          ? 'proxy_${now.microsecondsSinceEpoch}'
          : id.trim();
      final existing = await _profiles.getProfileById(profileId);
      final profile = RouteProfile(
        id: profileId,
        ownerId: existing?.ownerId ?? 'device_local',
        name: name.trim(),
        kind: RouteProfileKind.proxy,
        proxyScheme: scheme.trim().isEmpty ? 'http' : scheme.trim(),
        proxyHost: host.trim(),
        proxyPort: port,
        enabled: enabled,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      final saved = await _profiles.saveProfile(profile);
      final username = proxyUsername?.trim() ?? '';
      final password = proxyPassword ?? '';
      if (username.isNotEmpty || password.isNotEmpty) {
        await _credentials.save(
          saved.id,
          RouteProfileCredentials(username: username, password: password),
        );
      } else {
        await _credentials.remove(saved.id);
      }
      ref.invalidate(routeProfilesProvider);
      ref.invalidate(routeProfileCredentialsProvider(saved.id));
      state = const NetworkProfileEditState();
      return saved;
    } catch (error) {
      state = NetworkProfileEditState(
        isLoading: false,
        error: error.toString(),
      );
      return null;
    }
  }

  Future<void> deleteProfile(String id) async {
    state = const NetworkProfileEditState(isLoading: true);
    try {
      await _profiles.deleteProfile(id);
      await _credentials.remove(id);
      ref.invalidate(routeProfilesProvider);
      ref.invalidate(routeProfileCredentialsProvider(id));
      state = const NetworkProfileEditState();
    } catch (error) {
      state = NetworkProfileEditState(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  Future<void> saveSourcePolicy({
    required String accountId,
    required String preferredRouteProfileId,
    required List<String> fallbackRouteProfileIds,
    String? lastWorkingRouteProfileId,
  }) async {
    state = const NetworkProfileEditState(isLoading: true);
    try {
      final current = await _policies.getPolicy(
        accountId: accountId.trim(),
        sourceKind: SourceKind.xtream,
      );
      final next =
          current ??
          SourceConnectionPolicy.defaults(
            ownerId: 'device_local',
            accountId: accountId.trim(),
            sourceKind: SourceKind.xtream,
          );
      await _policies.savePolicy(
        next.copyWith(
          preferredRouteProfileId: preferredRouteProfileId,
          fallbackRouteProfileIds: fallbackRouteProfileIds,
          lastWorkingRouteProfileId: lastWorkingRouteProfileId,
          updatedAt: DateTime.now(),
        ),
      );
      ref.invalidate(sourceConnectionPolicyProvider(accountId));
      state = const NetworkProfileEditState();
    } catch (error) {
      state = NetworkProfileEditState(
        isLoading: false,
        error: error.toString(),
      );
    }
  }
}

final networkProfileEditControllerProvider =
    NotifierProvider<NetworkProfileEditController, NetworkProfileEditState>(
      NetworkProfileEditController.new,
    );

class XtreamSourceProbeState {
  const XtreamSourceProbeState({
    this.isLoading = false,
    this.error,
    this.result,
  });

  final bool isLoading;
  final String? error;
  final SourceProbeResult? result;

  XtreamSourceProbeState copyWith({
    bool? isLoading,
    String? error,
    SourceProbeResult? result,
    bool clearError = false,
  }) {
    return XtreamSourceProbeState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      result: result ?? this.result,
    );
  }
}

class XtreamSourceProbeController extends Notifier<XtreamSourceProbeState> {
  late final SourceProbeService _probeService;

  @override
  XtreamSourceProbeState build() {
    _probeService = ref.watch(sourceProbeServiceProvider);
    return const XtreamSourceProbeState();
  }

  Future<SourceProbeResult?> probeXtream({
    required String serverUrl,
    required String username,
    required String password,
    String preferredRouteProfileId = RouteProfile.defaultId,
    List<String> fallbackRouteProfileIds = const <String>[],
    String? accountId,
    bool includePublicIp = true,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _probeService.probeXtream(
        serverUrl: serverUrl,
        username: username,
        password: password,
        preferredRouteProfileId: preferredRouteProfileId,
        fallbackRouteProfileIds: fallbackRouteProfileIds,
        accountId: accountId,
        includePublicIp: includePublicIp,
      );
      state = XtreamSourceProbeState(result: result);
      return result;
    } catch (error) {
      state = XtreamSourceProbeState(
        error: error.toString(),
      );
      return null;
    }
  }

  void reset() {
    state = const XtreamSourceProbeState();
  }
}

final xtreamSourceProbeControllerProvider =
    NotifierProvider<XtreamSourceProbeController, XtreamSourceProbeState>(
      XtreamSourceProbeController.new,
    );
