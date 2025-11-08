import 'package:dio/dio.dart';

import '../utils/logger.dart';
import 'network_exceptions.dart';

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
      final response = await request(_client);
      final data = response.data;
      if (data == null) {
        throw const NetworkFailure.emptyResponse();
      }
      return mapper(data as T);
    } on DioException catch (error, stackTrace) {
      logger?.error('Network call failed', error, stackTrace);
      throw NetworkFailure.fromDioException(error);
    } catch (error, stackTrace) {
      logger?.error('Unexpected network error', error, stackTrace);
      throw NetworkFailure.unknown(error);
    }
  }
}
