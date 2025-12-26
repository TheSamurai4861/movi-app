// lib/src/core/network/dio_failure_mapper.dart
import 'package:dio/dio.dart';
import 'package:movi/src/core/network/network_failures.dart';

NetworkFailure mapDioToFailure(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const TimeoutFailure();

    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      final message = e.response?.statusMessage ?? 'Server error';
      if (status == 401) return const UnauthorizedFailure();
      if (status == 403) return const ForbiddenFailure();
      if (status == 404) return const NotFoundFailure();
      if (status == 429) return const RateLimitedFailure();
      return ServerFailure(message, statusCode: status);

    case DioExceptionType.badCertificate:
      return const BadCertificateFailure();

    case DioExceptionType.connectionError:
      return const ConnectionFailure();

    case DioExceptionType.cancel:
      return const CancelledFailure();

    case DioExceptionType.unknown:
      final msg = (e.error?.toString() ?? e.message) ?? 'Unknown error';
      return UnknownFailure(msg);
  }
}
