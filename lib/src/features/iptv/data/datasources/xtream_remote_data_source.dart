import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:movi/src/features/iptv/data/dtos/xtream_auth_dto.dart';
import 'package:movi/src/features/iptv/data/dtos/xtream_category_dto.dart';
import 'package:movi/src/features/iptv/data/dtos/xtream_stream_dto.dart';

class XtreamRemoteDataSource {
  XtreamRemoteDataSource(this._executor);

  final NetworkExecutor _executor;

  Future<XtreamAuthDto> authenticate({
    required XtreamEndpoint endpoint,
    required String username,
    required String password,
  }) {
    return _executor.run<dynamic, XtreamAuthDto>(
      request: (client) => client.getUri<dynamic>(
        endpoint.buildUri({'username': username, 'password': password}),
        options: Options(responseType: ResponseType.json),
      ),
      mapper: (response) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return XtreamAuthDto.fromJson(data);
        }
        if (data is String) {
          final s = data.trim();
          if (s.startsWith('{') || s.startsWith('[')) {
            final decoded = jsonDecode(s);
            if (decoded is Map<String, dynamic>) {
              return XtreamAuthDto.fromJson(decoded);
            }
          }
          return XtreamAuthDto(
            status: 'error',
            message: 'Réponse non-JSON du serveur Xtream',
            expiration: null,
          );
        }
        return XtreamAuthDto(
          status: 'error',
          message: 'Réponse invalide du serveur Xtream',
          expiration: null,
        );
      },
    );
  }

  Future<List<XtreamCategoryDto>> getVodCategories(
    XtreamAccountRequest request,
  ) {
    return _getCategories(request, action: 'get_vod_categories');
  }

  Future<List<XtreamCategoryDto>> getSeriesCategories(
    XtreamAccountRequest request,
  ) {
    return _getCategories(request, action: 'get_series_categories');
  }

  Future<List<XtreamStreamDto>> getVodStreams(
    XtreamAccountRequest request, {
    String? categoryId,
  }) {
    return _getStreams(
      request,
      action: 'get_vod_streams',
      categoryId: categoryId,
    );
  }

  Future<List<XtreamStreamDto>> getSeries(
    XtreamAccountRequest request, {
    String? categoryId,
  }) {
    return _getStreams(request, action: 'get_series', categoryId: categoryId);
  }

  Future<List<XtreamCategoryDto>> _getCategories(
    XtreamAccountRequest request, {
    required String action,
  }) {
    return _executor.run<dynamic, List<XtreamCategoryDto>>(
      request: (client) => client.getUri<dynamic>(
        request.endpoint.buildUri({
          'username': request.username,
          'password': request.password,
          'action': action,
        }),
        options: Options(responseType: ResponseType.json),
      ),
      mapper: (response) {
        final data = response.data;
        List<dynamic> list;
        if (data is List) {
          list = data;
        } else if (data is String) {
          final s = data.trim();
          if (s.startsWith('[')) {
            final decoded = jsonDecode(s);
            list = decoded is List ? decoded : const [];
          } else {
            list = const [];
          }
        } else if (data is Map<String, dynamic>) {
          final v = data['categories'];
          list = v is List ? v : const [];
        } else {
          list = const [];
        }
        return list
            .whereType<Map<String, dynamic>>()
            .map(XtreamCategoryDto.fromJson)
            .toList(growable: false);
      },
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

    return _executor.run<dynamic, List<XtreamStreamDto>>(
      request: (client) => client.getUri<dynamic>(
        request.endpoint.buildUri(query),
        options: Options(responseType: ResponseType.json),
      ),
      mapper: (response) {
        final data = response.data;
        List<dynamic> list;
        if (data is List) {
          list = data;
        } else if (data is String) {
          final s = data.trim();
          if (s.startsWith('[')) {
            final decoded = jsonDecode(s);
            list = decoded is List ? decoded : const [];
          } else {
            list = const [];
          }
        } else if (data is Map<String, dynamic>) {
          final v = data['results'] ?? data['streams'] ?? data['data'];
          list = v is List ? v : const [];
        } else {
          list = const [];
        }
        return list
            .whereType<Map<String, dynamic>>()
            .map(XtreamStreamDto.fromJson)
            .toList(growable: false);
      },
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
