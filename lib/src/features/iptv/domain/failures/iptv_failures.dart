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
    String message, {
    String? code,
    StackTrace? stackTrace,
    Object? cause,
    Map<String, Object?>? context,
  }) : super(
         message,
         code: code ?? 'iptv_invalid_endpoint',
         stackTrace: stackTrace,
         cause: cause,
         context: context,
       );
}
