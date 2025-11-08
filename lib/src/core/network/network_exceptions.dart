import 'package:dio/dio.dart';

sealed class NetworkFailure implements Exception {
  const NetworkFailure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  static NetworkFailure fromDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure.timeout();
      case DioExceptionType.badResponse:
        final status = exception.response?.statusCode ?? 0;
        if (status == 401) return const NetworkFailure.unauthorized();
        if (status == 403) return const NetworkFailure.forbidden();
        if (status == 404) return const NetworkFailure.notFound();
        if (status == 429) return const NetworkFailure.rateLimited();
        return NetworkFailure.server('Server error', statusCode: status);
      case DioExceptionType.badCertificate:
      case DioExceptionType.connectionError:
        return const NetworkFailure.connection();
      case DioExceptionType.cancel:
        return const NetworkFailure.cancelled();
      case DioExceptionType.unknown:
        return NetworkFailure.unknown(exception.error);
    }
  }

  const factory NetworkFailure.timeout() = TimeoutFailure;
  const factory NetworkFailure.connection() = ConnectionFailure;
  const factory NetworkFailure.unauthorized() = UnauthorizedFailure;
  const factory NetworkFailure.forbidden() = ForbiddenFailure;
  const factory NetworkFailure.notFound() = NotFoundFailure;
  const factory NetworkFailure.rateLimited() = RateLimitedFailure;
  const factory NetworkFailure.server(String message, {int? statusCode}) = ServerFailure;
  const factory NetworkFailure.emptyResponse() = EmptyResponseFailure;
  factory NetworkFailure.unknown(Object? error) => UnknownFailure(error?.toString() ?? 'Unknown error');
  const factory NetworkFailure.cancelled() = CancelledFailure;
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

class ServerFailure extends NetworkFailure {
  const ServerFailure(super.message, {super.statusCode});
}

class EmptyResponseFailure extends NetworkFailure {
  const EmptyResponseFailure() : super('Empty response');
}

class UnknownFailure extends NetworkFailure {
  const UnknownFailure(super.message);
}

class CancelledFailure extends NetworkFailure {
  const CancelledFailure() : super('Request cancelled');
}
