import 'package:movi/src/core/shared/failure.dart';

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
