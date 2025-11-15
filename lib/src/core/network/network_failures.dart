// lib/src/core/network/network_failures.dart
import 'package:movi/src/core/shared/failure.dart';

/// Modèle d’échecs réseau neutre (domaine) à mapper côté UI.
abstract class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {this.statusCode});
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

class TimeoutFailure extends NetworkFailure {
  const TimeoutFailure() : super('Request timed out');
}

class ConnectionFailure extends NetworkFailure {
  const ConnectionFailure() : super('Connection error');
}

class UnauthorizedFailure extends NetworkFailure {
  const UnauthorizedFailure() : super('Unauthorized', statusCode: 401);
}

class ForbiddenFailure extends NetworkFailure {
  const ForbiddenFailure() : super('Forbidden', statusCode: 403);
}

class NotFoundFailure extends NetworkFailure {
  const NotFoundFailure() : super('Not found', statusCode: 404);
}

class RateLimitedFailure extends NetworkFailure {
  const RateLimitedFailure() : super('Rate limited', statusCode: 429);
}

class BadCertificateFailure extends NetworkFailure {
  const BadCertificateFailure()
    : super('Certificate validation failed', statusCode: 495);
}

class ServerFailure extends NetworkFailure {
  const ServerFailure(super.message, {super.statusCode});
}

class EmptyResponseFailure extends NetworkFailure {
  const EmptyResponseFailure() : super('Empty response');
}

class UnknownFailure extends NetworkFailure {
  const UnknownFailure([super.message = 'Unknown error']);
}

class CancelledFailure extends NetworkFailure {
  const CancelledFailure() : super('Request cancelled');
}
