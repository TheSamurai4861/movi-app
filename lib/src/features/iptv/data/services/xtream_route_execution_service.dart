import 'package:dio/dio.dart';
import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/network/http_client_factory.dart';
import 'package:movi/src/core/network/network_failures.dart';
import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/core/network/proxy/proxy_configuration.dart';
import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/features/iptv/data/datasources/xtream_remote_data_source.dart';
import 'package:movi/src/features/iptv/data/services/route_profile_credentials_store.dart';
import 'package:movi/src/features/iptv/domain/entities/source_connection_models.dart';
import 'package:movi/src/features/iptv/domain/entities/source_probe_models.dart';
import 'package:movi/src/features/iptv/domain/failures/iptv_failures.dart';
import 'package:movi/src/features/iptv/domain/repositories/route_profile_repository.dart';
import 'package:movi/src/features/iptv/domain/repositories/source_connection_policy_repository.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';

class XtreamRouteExecutionResult<T> {
  const XtreamRouteExecutionResult({
    required this.value,
    required this.routeProfile,
  });

  final T value;
  final RouteProfile routeProfile;
}

class XtreamRouteExecutionService {
  XtreamRouteExecutionService(
    this._config,
    this._logger,
    this._routeProfiles,
    this._policies,
    this._credentialsStore,
  );

  final AppConfig _config;
  final AppLogger _logger;
  final RouteProfileRepository _routeProfiles;
  final SourceConnectionPolicyRepository _policies;
  final RouteProfileCredentialsStore _credentialsStore;

  Future<List<RouteProfile>> resolveProfiles({
    String? accountId,
    String preferredRouteProfileId = RouteProfile.defaultId,
    List<String> fallbackRouteProfileIds = const <String>[],
    bool useStoredPolicy = true,
  }) async {
    String preferred = preferredRouteProfileId;
    List<String> fallbacks = fallbackRouteProfileIds;
    String? lastWorking;

    if (useStoredPolicy && accountId != null && accountId.trim().isNotEmpty) {
      final policy = await _policies.getPolicy(
        accountId: accountId.trim(),
        sourceKind: SourceKind.xtream,
      );
      if (policy != null) {
        preferred = policy.preferredRouteProfileId;
        fallbacks = policy.fallbackRouteProfileIds;
        lastWorking = policy.lastWorkingRouteProfileId;
      }
    }

    final orderedIds = <String>[
      preferred.trim().isEmpty ? RouteProfile.defaultId : preferred.trim(),
      if (lastWorking != null && lastWorking.trim().isNotEmpty)
        lastWorking.trim(),
      ...fallbacks.map((id) => id.trim()).where((id) => id.isNotEmpty),
    ];

    final seen = <String>{};
    final profiles = <RouteProfile>[];
    for (final id in orderedIds) {
      if (!seen.add(id)) continue;
      final profile = await _routeProfiles.getProfileById(id);
      if (profile == null) continue;
      if (!profile.enabled) continue;
      profiles.add(profile);
    }
    if (profiles.isEmpty) {
      profiles.add(RouteProfile.defaultProfile());
    }
    return profiles;
  }

  Future<XtreamRouteExecutionResult<T>> execute<T>({
    required XtreamEndpoint endpoint,
    required String username,
    required String password,
    required String action,
    required Future<T> Function(
      XtreamRemoteDataSource remote,
      XtreamAccountRequest request,
    )
    operation,
    String? accountId,
    String preferredRouteProfileId = RouteProfile.defaultId,
    List<String> fallbackRouteProfileIds = const <String>[],
    bool Function(T result)? isTerminalFailureResult,
    XtreamRouteExecutionFailure Function(T result, RouteProfile profile)?
    terminalFailureFactory,
    bool overrideStoredPolicy = false,
    bool useStoredPolicy = true,
  }) async {
    final profiles = await resolveProfiles(
      accountId: accountId,
      preferredRouteProfileId: preferredRouteProfileId,
      fallbackRouteProfileIds: fallbackRouteProfileIds,
      useStoredPolicy: useStoredPolicy,
    );
    XtreamRouteExecutionFailure? lastFailure;

    for (final profile in profiles) {
      final remote = await _buildRemoteForProfile(profile);
      final request = XtreamAccountRequest(
        endpoint: endpoint,
        username: username,
        password: password,
      );
      try {
        final result = await operation(remote, request);
        if (isTerminalFailureResult != null &&
            isTerminalFailureResult(result)) {
          final failure =
              terminalFailureFactory?.call(result, profile) ??
              XtreamRouteExecutionFailure(
                'Xtream terminal failure on ${profile.id}',
                errorKind: SourceProbeErrorKind.authInvalidCredentials,
                code: 'xtream_terminal_failure',
                context: _failureContext(
                  action: action,
                  profile: profile,
                  endpoint: endpoint,
                ),
              );
          _logFailure(
            action: action,
            endpoint: endpoint,
            profile: profile,
            failure: failure,
          );
          throw failure;
        }

        if (accountId != null && accountId.trim().isNotEmpty) {
          await rememberWorkingProfile(
            accountId: accountId.trim(),
            preferredRouteProfileId: preferredRouteProfileId,
            fallbackRouteProfileIds: fallbackRouteProfileIds,
            routeProfileId: profile.id,
            overrideStoredPolicy: overrideStoredPolicy,
          );
        }
        _logger.info(
          '[XtreamRoute] action=$action host=${endpoint.host} '
          'profile=${profile.id} kind=${profile.kind.name} result=success',
          category: 'IPTV',
        );
        return XtreamRouteExecutionResult<T>(
          value: result,
          routeProfile: profile,
        );
      } on XtreamRouteExecutionFailure catch (failure) {
        lastFailure = failure;
        _logFailure(
          action: action,
          endpoint: endpoint,
          profile: profile,
          failure: failure,
        );
        if (!_shouldTryNext(failure.errorKind)) {
          rethrow;
        }
      } on Failure catch (failure) {
        final mapped = _mapFailure(
          failure,
          profile: profile,
          endpoint: endpoint,
          action: action,
        );
        lastFailure = mapped;
        _logFailure(
          action: action,
          endpoint: endpoint,
          profile: profile,
          failure: mapped,
        );
        if (!_shouldTryNext(mapped.errorKind)) {
          throw mapped;
        }
      } catch (error, stackTrace) {
        final failure = XtreamRouteExecutionFailure(
          'Unexpected Xtream route failure: $error',
          errorKind: SourceProbeErrorKind.unknown,
          cause: error,
          stackTrace: stackTrace,
          context: _failureContext(
            action: action,
            profile: profile,
            endpoint: endpoint,
          ),
        );
        lastFailure = failure;
        _logFailure(
          action: action,
          endpoint: endpoint,
          profile: profile,
          failure: failure,
        );
      }
    }

    throw lastFailure ??
        XtreamRouteExecutionFailure(
          'Xtream route execution exhausted without result',
          errorKind: SourceProbeErrorKind.unknown,
          context: <String, Object?>{'action': action, 'host': endpoint.host},
        );
  }

  Future<void> rememberWorkingProfile({
    required String accountId,
    required String preferredRouteProfileId,
    required List<String> fallbackRouteProfileIds,
    required String routeProfileId,
    bool overrideStoredPolicy = false,
  }) async {
    final existing = await _policies.getPolicy(
      accountId: accountId,
      sourceKind: SourceKind.xtream,
    );
    final next =
        existing ??
        SourceConnectionPolicy.defaults(
          ownerId: 'device_local',
          accountId: accountId,
          sourceKind: SourceKind.xtream,
        );
    final effectivePreferred = overrideStoredPolicy || existing == null
        ? preferredRouteProfileId
        : existing.preferredRouteProfileId;
    final effectiveFallbacks = overrideStoredPolicy || existing == null
        ? fallbackRouteProfileIds
        : existing.fallbackRouteProfileIds;
    await _policies.savePolicy(
      next.copyWith(
        preferredRouteProfileId: effectivePreferred,
        fallbackRouteProfileIds: effectiveFallbacks,
        lastWorkingRouteProfileId: routeProfileId,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<XtreamRemoteDataSource> _buildRemoteForProfile(
    RouteProfile profile,
  ) async {
    final factory = HttpClientFactory(
      config: _config,
      logger: _logger,
      useEnvironmentProxy: false,
      proxyConfiguration: await _proxyConfigurationForProfile(profile),
    );
    final dio = factory.create();
    final executor = NetworkExecutor(
      dio,
      logger: _logger,
      defaultMaxConcurrent: 4,
    );
    return XtreamRemoteDataSource(
      executor,
      logger: _logger,
      userAgent: 'MOVI/${_config.metadata.version} XtreamCatalog',
    );
  }

  Future<Dio> buildDioForProfile(RouteProfile profile) async {
    final factory = HttpClientFactory(
      config: _config,
      logger: _logger,
      useEnvironmentProxy: false,
      proxyConfiguration: await _proxyConfigurationForProfile(profile),
    );
    return factory.create();
  }

  Future<DioProxyConfiguration?> _proxyConfigurationForProfile(
    RouteProfile profile,
  ) async {
    if (profile.kind != RouteProfileKind.proxy) {
      return null;
    }
    final host = profile.proxyHost?.trim();
    final port = profile.proxyPort;
    final scheme = (profile.proxyScheme ?? 'http').trim();
    if (host == null || host.isEmpty || port == null || port <= 0) {
      return null;
    }

    final creds = await _credentialsStore.read(profile.id);
    final proxyUri = creds == null
        ? Uri(scheme: scheme, host: host, port: port)
        : Uri(
            scheme: scheme,
            host: host,
            port: port,
            userInfo: '${creds.username}:${creds.password}',
          );
    return DioProxyConfiguration(httpProxy: proxyUri, httpsProxy: proxyUri);
  }

  XtreamRouteExecutionFailure _mapFailure(
    Failure failure, {
    required RouteProfile profile,
    required XtreamEndpoint endpoint,
    required String action,
  }) {
    final kind = switch (failure) {
      TimeoutFailure() => SourceProbeErrorKind.httpTimeout,
      ConnectionFailure() => SourceProbeErrorKind.routeBlocked,
      BadCertificateFailure() => SourceProbeErrorKind.tlsError,
      ForbiddenFailure() => SourceProbeErrorKind.providerIpBlocked,
      RateLimitedFailure() => SourceProbeErrorKind.providerIpBlocked,
      UnauthorizedFailure() => SourceProbeErrorKind.httpDenied,
      NotFoundFailure() => SourceProbeErrorKind.sourceTypeMismatch,
      ServerFailure(statusCode: final statusCode)
          when statusCode == 403 || statusCode == 429 =>
        SourceProbeErrorKind.providerIpBlocked,
      ServerFailure() => SourceProbeErrorKind.httpDenied,
      XtreamBlockedResponseFailure() => SourceProbeErrorKind.providerIpBlocked,
      XtreamInvalidResponseFailure() =>
        SourceProbeErrorKind.invalidResponseFormat,
      AuthFailure() => SourceProbeErrorKind.authInvalidCredentials,
      XtreamRouteExecutionFailure(errorKind: final errorKind) => errorKind,
      _ => SourceProbeErrorKind.unknown,
    };

    return XtreamRouteExecutionFailure(
      failure.message,
      errorKind: kind,
      code: failure.code,
      cause: failure.cause ?? failure,
      stackTrace: failure.stackTrace,
      context: <String, Object?>{
        ...?failure.context,
        ..._failureContext(
          action: action,
          profile: profile,
          endpoint: endpoint,
        ),
      },
    );
  }

  bool _shouldTryNext(SourceProbeErrorKind errorKind) {
    return switch (errorKind) {
      SourceProbeErrorKind.routeBlocked => true,
      SourceProbeErrorKind.httpDenied => true,
      SourceProbeErrorKind.httpTimeout => true,
      SourceProbeErrorKind.tcpRefused => true,
      SourceProbeErrorKind.tcpTimeout => true,
      SourceProbeErrorKind.tlsError => true,
      SourceProbeErrorKind.providerIpBlocked => true,
      SourceProbeErrorKind.invalidResponseFormat => true,
      _ => false,
    };
  }

  void _logFailure({
    required String action,
    required XtreamEndpoint endpoint,
    required RouteProfile profile,
    required XtreamRouteExecutionFailure failure,
  }) {
    _logger.warn(
      '[XtreamRoute] action=$action host=${endpoint.host} '
      'profile=${profile.id} kind=${profile.kind.name} '
      'errorKind=${failure.errorKind.name} message=${failure.message}',
      category: 'IPTV',
    );
  }

  Map<String, Object?> _failureContext({
    required String action,
    required RouteProfile profile,
    required XtreamEndpoint endpoint,
  }) {
    return <String, Object?>{
      'action': action,
      'routeProfileId': profile.id,
      'routeProfileKind': profile.kind.name,
      'host': endpoint.host,
      if (profile.kind == RouteProfileKind.proxy &&
          profile.proxyHost != null &&
          profile.proxyPort != null)
        'proxy': '${profile.proxyHost}:${profile.proxyPort}',
    };
  }
}
