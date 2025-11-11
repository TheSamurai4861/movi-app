import '../../../network/network_executor.dart';
import '../../domain/value_objects/xtream_endpoint.dart';
import '../dtos/xtream_auth_dto.dart';
import '../dtos/xtream_category_dto.dart';
import '../dtos/xtream_stream_dto.dart';

class XtreamRemoteDataSource {
  XtreamRemoteDataSource(this._executor);

  final NetworkExecutor _executor;

  Future<XtreamAuthDto> authenticate({
    required XtreamEndpoint endpoint,
    required String username,
    required String password,
  }) {
    return _executor.run<Map<String, dynamic>, XtreamAuthDto>(
      request: (client) => client.getUri<Map<String, dynamic>>(
        endpoint.buildUri({
          'username': username,
          'password': password,
        }),
      ),
      mapper: (response) => XtreamAuthDto.fromJson(response.data!),
    );
  }

  Future<List<XtreamCategoryDto>> getVodCategories(XtreamAccountRequest request) {
    return _getCategories(request, action: 'get_vod_categories');
  }

  Future<List<XtreamCategoryDto>> getSeriesCategories(XtreamAccountRequest request) {
    return _getCategories(request, action: 'get_series_categories');
  }

  Future<List<XtreamStreamDto>> getVodStreams(XtreamAccountRequest request, {String? categoryId}) {
    return _getStreams(request, action: 'get_vod_streams', categoryId: categoryId);
  }

  Future<List<XtreamStreamDto>> getSeries(XtreamAccountRequest request, {String? categoryId}) {
    return _getStreams(request, action: 'get_series', categoryId: categoryId);
  }

  Future<List<XtreamCategoryDto>> _getCategories(
    XtreamAccountRequest request, {
    required String action,
  }) {
    return _executor.run<List<dynamic>, List<XtreamCategoryDto>>(
      request: (client) => client.getUri<List<dynamic>>(
        request.endpoint.buildUri({
          'username': request.username,
          'password': request.password,
          'action': action,
        }),
      ),
      mapper: (response) =>
          response.data!
              .map((item) => XtreamCategoryDto.fromJson(item as Map<String, dynamic>))
              .toList(growable: false),
    );
  }

  Future<List<XtreamStreamDto>> _getStreams(
    XtreamAccountRequest request, {
    required String action,
    String? categoryId,
  }) {
    final query = {
      'username': request.username,
      'password': request.password,
      'action': action,
    };
    if (categoryId != null) {
      query['category_id'] = categoryId;
    }

    return _executor.run<List<dynamic>, List<XtreamStreamDto>>(
      request: (client) => client.getUri<List<dynamic>>(
        request.endpoint.buildUri(query),
      ),
      mapper: (response) =>
          response.data!
              .map((item) => XtreamStreamDto.fromJson(item as Map<String, dynamic>))
              .toList(growable: false),
    );
  }
}

class XtreamAccountRequest {
  XtreamAccountRequest({
    required this.endpoint,
    required this.username,
    required this.password,
  });

  final XtreamEndpoint endpoint;
  final String username;
  final String password;
}
