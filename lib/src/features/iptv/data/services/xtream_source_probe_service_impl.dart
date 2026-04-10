import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/features/iptv/data/services/public_ip_echo_service.dart';
import 'package:movi/src/features/iptv/data/services/xtream_route_execution_service.dart';
import 'package:movi/src/features/iptv/domain/entities/source_connection_models.dart';
import 'package:movi/src/features/iptv/domain/entities/source_probe_models.dart';
import 'package:movi/src/features/iptv/domain/failures/iptv_failures.dart';
import 'package:movi/src/features/iptv/domain/repositories/source_probe_service.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';

class XtreamSourceProbeServiceImpl implements SourceProbeService {
  XtreamSourceProbeServiceImpl(
    this._execution,
    this._publicIpEchoService,
    this._logger,
  );

  final XtreamRouteExecutionService _execution;
  final PublicIpEchoService _publicIpEchoService;
  final AppLogger _logger;

  @override
  Future<SourceProbeResult> probeXtream({
    required String serverUrl,
    required String username,
    required String password,
    String preferredRouteProfileId = RouteProfile.defaultId,
    List<String> fallbackRouteProfileIds = const <String>[],
    String? accountId,
    bool includePublicIp = true,
  }) async {
    final endpoint = XtreamEndpoint.parse(serverUrl);
    final profiles = await _execution.resolveProfiles(
      accountId: accountId,
      preferredRouteProfileId: preferredRouteProfileId,
      fallbackRouteProfileIds: fallbackRouteProfileIds,
      useStoredPolicy: false,
    );

    final attempts = <ProbeAttemptResult>[];
    for (final profile in profiles) {
      final publicIp = includePublicIp
          ? await _resolvePublicIp(profile)
          : 'unavailable';

      final dnsAttempt = await _probeDns(profile, endpoint, publicIp: publicIp);
      attempts.add(dnsAttempt);
      if (dnsAttempt.status == ProbeAttemptStatus.failed) {
        if (profile.kind == RouteProfileKind.defaultRoute) {
          return SourceProbeResult(
            sourceKind: SourceKind.xtream,
            routeProfileId: profile.id,
            routeProfileKind: profile.kind,
            isValid: false,
            attempts: attempts,
            errorKind: dnsAttempt.errorKind,
            errorMessage: dnsAttempt.errorMessage,
            publicIp: publicIp,
          );
        }
        continue;
      }

      final tcpAttempt = await _probeTcp(profile, endpoint, publicIp: publicIp);
      attempts.add(tcpAttempt);
      if (tcpAttempt.status == ProbeAttemptStatus.failed) {
        continue;
      }

      final httpSimpleAttempt = await _probeHttpSimple(
        profile,
        endpoint,
        publicIp: publicIp,
      );
      attempts.add(httpSimpleAttempt);
      if (httpSimpleAttempt.status == ProbeAttemptStatus.failed) {
        continue;
      }

      final authAttempt = await _probeAuth(
        profile,
        endpoint,
        username: username,
        password: password,
        publicIp: publicIp,
      );
      attempts.add(authAttempt);
      if (authAttempt.status == ProbeAttemptStatus.failed) {
        if (_shouldTryNext(authAttempt.errorKind)) {
          continue;
        }
        return SourceProbeResult(
          sourceKind: SourceKind.xtream,
          routeProfileId: profile.id,
          routeProfileKind: profile.kind,
          isValid: false,
          attempts: attempts,
          errorKind: authAttempt.errorKind,
          errorMessage: authAttempt.errorMessage,
          publicIp: publicIp,
        );
      }

      attempts.add(
        ProbeAttemptResult(
          routeProfileId: profile.id,
          routeProfileKind: profile.kind,
          stage: ProbeStage.validation,
          status: ProbeAttemptStatus.success,
          latencyMs: 0,
          publicIp: publicIp,
        ),
      );

      return SourceProbeResult(
        sourceKind: SourceKind.xtream,
        routeProfileId: profile.id,
        routeProfileKind: profile.kind,
        isValid: true,
        attempts: attempts,
        publicIp: publicIp,
      );
    }

    final last = attempts.isEmpty ? null : attempts.last;
    return SourceProbeResult(
      sourceKind: SourceKind.xtream,
      routeProfileId: profiles.isEmpty ? RouteProfile.defaultId : profiles.last.id,
      routeProfileKind: profiles.isEmpty
          ? RouteProfileKind.defaultRoute
          : profiles.last.kind,
      isValid: false,
      attempts: attempts,
      errorKind: last?.errorKind ?? SourceProbeErrorKind.unknown,
      errorMessage: last?.errorMessage ?? 'Source Xtream invalide ou inaccessible.',
      publicIp: last?.publicIp,
    );
  }

  Future<String?> _resolvePublicIp(RouteProfile profile) async {
    final dio = await _execution.buildDioForProfile(profile);
    final publicIp = await _publicIpEchoService.resolvePublicIp(dio);
    return publicIp ?? 'unavailable';
  }

  Future<ProbeAttemptResult> _probeDns(
    RouteProfile profile,
    XtreamEndpoint endpoint, {
    String? publicIp,
  }) async {
    final sw = Stopwatch()..start();
    try {
      if (profile.kind == RouteProfileKind.proxy) {
        final host = profile.proxyHost?.trim();
        if (host == null || host.isEmpty) {
          return ProbeAttemptResult(
            routeProfileId: profile.id,
            routeProfileKind: profile.kind,
            stage: ProbeStage.dns,
            status: ProbeAttemptStatus.failed,
            latencyMs: sw.elapsedMilliseconds,
            publicIp: publicIp,
            errorKind: SourceProbeErrorKind.dnsNotFound,
            errorMessage: 'Proxy host missing.',
          );
        }
        await InternetAddress.lookup(host).timeout(const Duration(seconds: 5));
        return ProbeAttemptResult(
          routeProfileId: profile.id,
          routeProfileKind: profile.kind,
          stage: ProbeStage.dns,
          status: ProbeAttemptStatus.success,
          latencyMs: sw.elapsedMilliseconds,
          publicIp: publicIp,
          proxyLabel: '${profile.proxyHost}:${profile.proxyPort}',
        );
      }

      await InternetAddress.lookup(endpoint.host).timeout(
        const Duration(seconds: 5),
      );
      return ProbeAttemptResult(
        routeProfileId: profile.id,
        routeProfileKind: profile.kind,
        stage: ProbeStage.dns,
        status: ProbeAttemptStatus.success,
        latencyMs: sw.elapsedMilliseconds,
        publicIp: publicIp,
      );
    } on SocketException catch (error) {
      return ProbeAttemptResult(
        routeProfileId: profile.id,
        routeProfileKind: profile.kind,
        stage: ProbeStage.dns,
        status: ProbeAttemptStatus.failed,
        latencyMs: sw.elapsedMilliseconds,
        publicIp: publicIp,
        errorKind: SourceProbeErrorKind.dnsNotFound,
        errorMessage: error.message,
        errorDetails: error.osError?.message,
      );
    } on TimeoutException {
      return ProbeAttemptResult(
        routeProfileId: profile.id,
        routeProfileKind: profile.kind,
        stage: ProbeStage.dns,
        status: ProbeAttemptStatus.failed,
        latencyMs: sw.elapsedMilliseconds,
        publicIp: publicIp,
        errorKind: SourceProbeErrorKind.dnsTimeout,
        errorMessage: 'DNS timeout',
      );
    }
  }

  Future<ProbeAttemptResult> _probeTcp(
    RouteProfile profile,
    XtreamEndpoint endpoint, {
    String? publicIp,
  }) async {
    final sw = Stopwatch()..start();
    final host = profile.kind == RouteProfileKind.proxy
        ? profile.proxyHost?.trim()
        : endpoint.host;
    final port = profile.kind == RouteProfileKind.proxy
        ? profile.proxyPort
        : (endpoint.uri.hasPort ? endpoint.uri.port : _defaultPort(endpoint.uri.scheme));
    if (host == null || host.isEmpty || port == null || port <= 0) {
      return ProbeAttemptResult(
        routeProfileId: profile.id,
        routeProfileKind: profile.kind,
        stage: ProbeStage.tcp,
        status: ProbeAttemptStatus.failed,
        latencyMs: sw.elapsedMilliseconds,
        publicIp: publicIp,
        errorKind: SourceProbeErrorKind.tcpRefused,
        errorMessage: 'Missing TCP target.',
      );
    }

    Socket? socket;
    try {
      socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      return ProbeAttemptResult(
        routeProfileId: profile.id,
        routeProfileKind: profile.kind,
        stage: ProbeStage.tcp,
        status: ProbeAttemptStatus.success,
        latencyMs: sw.elapsedMilliseconds,
        publicIp: publicIp,
        proxyLabel: profile.kind == RouteProfileKind.proxy ? '$host:$port' : null,
      );
    } on SocketException catch (error) {
      return ProbeAttemptResult(
        routeProfileId: profile.id,
        routeProfileKind: profile.kind,
        stage: ProbeStage.tcp,
        status: ProbeAttemptStatus.failed,
        latencyMs: sw.elapsedMilliseconds,
        publicIp: publicIp,
        errorKind: error.osError?.message.toLowerCase().contains('refused') == true
            ? SourceProbeErrorKind.tcpRefused
            : SourceProbeErrorKind.routeBlocked,
        errorMessage: error.message,
        errorDetails: error.osError?.message,
      );
    } on TimeoutException {
      return ProbeAttemptResult(
        routeProfileId: profile.id,
        routeProfileKind: profile.kind,
        stage: ProbeStage.tcp,
        status: ProbeAttemptStatus.failed,
        latencyMs: sw.elapsedMilliseconds,
        publicIp: publicIp,
        errorKind: SourceProbeErrorKind.tcpTimeout,
        errorMessage: 'TCP timeout',
      );
    } finally {
      await socket?.close();
    }
  }

  Future<ProbeAttemptResult> _probeHttpSimple(
    RouteProfile profile,
    XtreamEndpoint endpoint, {
    String? publicIp,
  }) async {
    final sw = Stopwatch()..start();
    final dio = await _execution.buildDioForProfile(profile);
    try {
      final response = await dio.getUri<String>(
        endpoint.buildUri(const <String, String>{}),
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (_) => true,
        ),
      );
      final snippet = _sanitizeSnippet(response.data, username: null, password: null);
      final status = response.statusCode ?? 0;
      if (status >= 400) {
        return ProbeAttemptResult(
          routeProfileId: profile.id,
          routeProfileKind: profile.kind,
          stage: ProbeStage.httpSimple,
          status: ProbeAttemptStatus.failed,
          latencyMs: sw.elapsedMilliseconds,
          publicIp: publicIp,
          httpStatusCode: status,
          contentType: response.headers.value(Headers.contentTypeHeader),
          responseSnippet: snippet,
          errorKind: (status == 403 || status == 429)
              ? SourceProbeErrorKind.providerIpBlocked
              : SourceProbeErrorKind.httpDenied,
          errorMessage: 'HTTP $status',
        );
      }
      return ProbeAttemptResult(
        routeProfileId: profile.id,
        routeProfileKind: profile.kind,
        stage: ProbeStage.httpSimple,
        status: ProbeAttemptStatus.success,
        latencyMs: sw.elapsedMilliseconds,
        publicIp: publicIp,
        httpStatusCode: status,
        contentType: response.headers.value(Headers.contentTypeHeader),
        responseSnippet: snippet,
        proxyLabel: profile.kind == RouteProfileKind.proxy
            ? '${profile.proxyHost}:${profile.proxyPort}'
            : null,
      );
    } on DioException catch (error) {
      return ProbeAttemptResult(
        routeProfileId: profile.id,
        routeProfileKind: profile.kind,
        stage: ProbeStage.httpSimple,
        status: ProbeAttemptStatus.failed,
        latencyMs: sw.elapsedMilliseconds,
        publicIp: publicIp,
        errorKind: error.type == DioExceptionType.receiveTimeout
            ? SourceProbeErrorKind.httpTimeout
            : SourceProbeErrorKind.routeBlocked,
        errorMessage: error.message,
        proxyLabel: profile.kind == RouteProfileKind.proxy
            ? '${profile.proxyHost}:${profile.proxyPort}'
            : null,
      );
    }
  }

  Future<ProbeAttemptResult> _probeAuth(
    RouteProfile profile,
    XtreamEndpoint endpoint, {
    required String username,
    required String password,
    String? publicIp,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final result = await _execution.execute(
        endpoint: endpoint,
        username: username,
        password: password,
        action: 'probe_auth',
        preferredRouteProfileId: profile.id,
        fallbackRouteProfileIds: const <String>[],
        overrideStoredPolicy: true,
        operation: (remote, request) => remote.authenticate(
          endpoint: request.endpoint,
          username: request.username,
          password: request.password,
        ),
        isTerminalFailureResult: (auth) => !auth.isAuthorized,
        terminalFailureFactory: (_, matchedProfile) => XtreamRouteExecutionFailure(
          'Identifiants Xtream invalides.',
          errorKind: SourceProbeErrorKind.authInvalidCredentials,
          code: 'xtream_auth_invalid_credentials',
          context: <String, Object?>{
            'routeProfileId': matchedProfile.id,
            'routeProfileKind': matchedProfile.kind.name,
            'host': endpoint.host,
          },
        ),
      );
      return ProbeAttemptResult(
        routeProfileId: result.routeProfile.id,
        routeProfileKind: result.routeProfile.kind,
        stage: ProbeStage.auth,
        status: ProbeAttemptStatus.success,
        latencyMs: sw.elapsedMilliseconds,
        publicIp: publicIp,
        proxyLabel: result.routeProfile.kind == RouteProfileKind.proxy
            ? '${result.routeProfile.proxyHost}:${result.routeProfile.proxyPort}'
            : null,
      );
    } on XtreamRouteExecutionFailure catch (failure) {
      _logger.warn(
        '[XtreamProbe] host=${endpoint.host} profile=${profile.id} '
        'stage=auth errorKind=${failure.errorKind.name} '
        'message=${failure.message}',
        category: 'IPTV',
      );
      return ProbeAttemptResult(
        routeProfileId: profile.id,
        routeProfileKind: profile.kind,
        stage: ProbeStage.auth,
        status: ProbeAttemptStatus.failed,
        latencyMs: sw.elapsedMilliseconds,
        publicIp: publicIp,
        errorKind: failure.errorKind,
        errorMessage: failure.message,
        errorDetails: failure.context?.toString(),
        proxyLabel: profile.kind == RouteProfileKind.proxy
            ? '${profile.proxyHost}:${profile.proxyPort}'
            : null,
      );
    }
  }

  bool _shouldTryNext(SourceProbeErrorKind? errorKind) {
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

  int _defaultPort(String scheme) {
    return scheme.toLowerCase() == 'https' ? 443 : 80;
  }

  String? _sanitizeSnippet(
    String? raw, {
    required String? username,
    required String? password,
  }) {
    if (raw == null) return null;
    var next = raw;
    if (username != null && username.isNotEmpty) {
      next = next.replaceAll(username, '***');
    }
    if (password != null && password.isNotEmpty) {
      next = next.replaceAll(password, '***');
    }
    if (next.length > 4096) {
      next = '${next.substring(0, 4096)}...';
    }
    return next;
  }
}
