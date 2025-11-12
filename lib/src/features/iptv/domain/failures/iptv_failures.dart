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
