import 'package:equatable/equatable.dart';

import 'package:movi/src/features/iptv/domain/entities/source_connection_models.dart';

enum ProbeStage { dns, tcp, httpSimple, auth, validation }

enum ProbeAttemptStatus { success, failed, skipped, notApplicable }

enum SourceProbeErrorKind {
  dnsNotFound,
  dnsTimeout,
  tcpRefused,
  tcpTimeout,
  tlsError,
  httpTimeout,
  httpDenied,
  providerIpBlocked,
  authInvalidCredentials,
  sourceTypeMismatch,
  invalidResponseFormat,
  routeBlocked,
  unknown,
}

class ProbeAttemptResult extends Equatable {
  const ProbeAttemptResult({
    required this.routeProfileId,
    required this.routeProfileKind,
    required this.stage,
    required this.status,
    required this.latencyMs,
    this.publicIp,
    this.httpStatusCode,
    this.contentType,
    this.responseSnippet,
    this.errorKind,
    this.errorMessage,
    this.errorDetails,
    this.proxyLabel,
  });

  final String routeProfileId;
  final RouteProfileKind routeProfileKind;
  final ProbeStage stage;
  final ProbeAttemptStatus status;
  final int latencyMs;
  final String? publicIp;
  final int? httpStatusCode;
  final String? contentType;
  final String? responseSnippet;
  final SourceProbeErrorKind? errorKind;
  final String? errorMessage;
  final String? errorDetails;
  final String? proxyLabel;

  @override
  List<Object?> get props => <Object?>[
    routeProfileId,
    routeProfileKind,
    stage,
    status,
    latencyMs,
    publicIp,
    httpStatusCode,
    contentType,
    responseSnippet,
    errorKind,
    errorMessage,
    errorDetails,
    proxyLabel,
  ];
}

class SourceProbeResult extends Equatable {
  const SourceProbeResult({
    required this.sourceKind,
    required this.routeProfileId,
    required this.routeProfileKind,
    required this.isValid,
    required this.attempts,
    this.errorKind,
    this.errorMessage,
    this.publicIp,
  });

  final SourceKind sourceKind;
  final String routeProfileId;
  final RouteProfileKind routeProfileKind;
  final bool isValid;
  final List<ProbeAttemptResult> attempts;
  final SourceProbeErrorKind? errorKind;
  final String? errorMessage;
  final String? publicIp;

  @override
  List<Object?> get props => <Object?>[
    sourceKind,
    routeProfileId,
    routeProfileKind,
    isValid,
    attempts,
    errorKind,
    errorMessage,
    publicIp,
  ];
}
