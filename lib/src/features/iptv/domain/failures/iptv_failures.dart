import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/features/iptv/domain/entities/source_probe_models.dart';

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class AccountNotFoundFailure extends Failure {
  const AccountNotFoundFailure(super.message);
}

class MissingCredentialsFailure extends Failure {
  const MissingCredentialsFailure(super.message);
}

/// URL de serveur Xtream invalide ou mal formée.
class InvalidEndpointFailure extends Failure {
  const InvalidEndpointFailure(
    super.message, {
    String? code,
    super.stackTrace,
    super.cause,
    super.context,
  }) : super(code: code ?? 'iptv_invalid_endpoint');
}

class XtreamInvalidResponseFailure extends Failure {
  const XtreamInvalidResponseFailure(
    super.message, {
    String? code,
    super.stackTrace,
    super.cause,
    super.context,
  }) : super(code: code ?? 'xtream_invalid_response');
}

class XtreamBlockedResponseFailure extends Failure {
  const XtreamBlockedResponseFailure(
    super.message, {
    String? code,
    super.stackTrace,
    super.cause,
    super.context,
  }) : super(code: code ?? 'xtream_blocked_response');
}

class XtreamRouteExecutionFailure extends Failure {
  const XtreamRouteExecutionFailure(
    super.message, {
    required this.errorKind,
    String? code,
    super.stackTrace,
    super.cause,
    super.context,
  }) : super(code: code ?? 'xtream_route_execution');

  final SourceProbeErrorKind errorKind;
}
