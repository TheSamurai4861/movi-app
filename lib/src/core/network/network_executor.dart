// lib/src/core/network/network_executor.dart
import 'package:dio/dio.dart';
import 'package:movi/src/core/network/network_failures.dart';
import 'package:movi/src/core/network/dio_failure_mapper.dart';

import '../utils/logger.dart';

typedef NetworkCall<T> = Future<Response<T>> Function(Dio client);

class NetworkExecutor {
  NetworkExecutor(this._client, {this.logger});

  final Dio _client;
  final AppLogger? logger;

  Future<R> run<T, R>({
    required NetworkCall<T> request,
    required R Function(T data) mapper,
  }) async {
    try {
      final Response<T> response = await request(_client);
      final T? data = response.data;

      if (data == null) {
        throw const EmptyResponseFailure();
      }
      return mapper(data);
    } on DioException catch (e, st) {
      logger?.error('Network call failed', e, st);
      throw mapDioToFailure(e);
    } catch (e, st) {
      logger?.error('Unexpected network error', e, st);
      throw UnknownFailure(e.toString());
    }
  }
}
