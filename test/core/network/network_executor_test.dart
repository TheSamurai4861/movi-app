import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/core/network/network_exceptions.dart';
import 'package:movi/src/core/utils/logger.dart';

void main() {
  group('NetworkExecutor', () {
    late Dio dio;
    late NetworkExecutor executor;

    setUp(() {
      dio = Dio();
      dio.interceptors.clear();
      executor = NetworkExecutor(dio, logger: AppLogger());
    });

    test('returns mapped data when request succeeds', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                data: const {'value': 42},
                statusCode: 200,
              ),
            );
          },
        ),
      );

      final result = await executor.run<Map<String, dynamic>, int>(
        request: (client) => client.get<Map<String, dynamic>>('https://example.com/test'),
        mapper: (json) => json['value'] as int,
      );

      expect(result, 42);
    });

    test('throws NetworkFailure on DioException', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionTimeout,
              ),
            );
          },
        ),
      );

      expect(
        () => executor.run<Map<String, dynamic>, int>(
          request: (client) => client.get<Map<String, dynamic>>('https://example.com/test'),
          mapper: (json) => json['value'] as int,
        ),
        throwsA(isA<TimeoutFailure>()),
      );
    });
  });
}
