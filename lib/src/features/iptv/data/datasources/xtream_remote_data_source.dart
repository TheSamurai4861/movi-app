import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/features/iptv/data/dtos/xtream_auth_dto.dart';
import 'package:movi/src/features/iptv/data/dtos/xtream_category_dto.dart';
import 'package:movi/src/features/iptv/data/dtos/xtream_stream_dto.dart';
import 'package:movi/src/features/iptv/domain/failures/iptv_failures.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';

class XtreamRemoteDataSource {
  XtreamRemoteDataSource(this._executor, {AppLogger? logger, String? userAgent})
    : _logger = logger,
      _userAgent = userAgent;

  final NetworkExecutor _executor;
  final AppLogger? _logger;
  final String? _userAgent;

  static const String _overrideUserAgent = String.fromEnvironment(
    'MOVI_XTREAM_USER_AGENT',
  );

  Future<XtreamAuthDto> authenticate({
    required XtreamEndpoint endpoint,
    required String username,
    required String password,
  }) {
    return _executor.run<dynamic, XtreamAuthDto>(
      request: (client, cancelToken) => client.getUri<dynamic>(
        endpoint.buildUri({'username': username, 'password': password}),
        options: _buildOptions(action: 'authenticate'),
        cancelToken: cancelToken,
      ),
      mapper: (response) => _parseAuthResponse(response, endpoint: endpoint),
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

  Future<Map<String, dynamic>> getSeriesInfo(
    XtreamAccountRequest request, {
    required int seriesId,
  }) {
    return _executor.run<dynamic, Map<String, dynamic>>(
      request: (client, cancelToken) => client.getUri<dynamic>(
        request.endpoint.buildUri({
          'username': request.username,
          'password': request.password,
          'action': 'get_series_info',
          'series_id': seriesId.toString(),
        }),
        options: _buildOptions(action: 'get_series_info'),
        cancelToken: cancelToken,
      ),
      mapper: (response) =>
          _parseSeriesInfoResponse(response, endpoint: request.endpoint),
    );
  }

  Future<List<XtreamCategoryDto>> _getCategories(
    XtreamAccountRequest request, {
    required String action,
  }) {
    return _executor.run<dynamic, List<XtreamCategoryDto>>(
      request: (client, cancelToken) => client.getUri<dynamic>(
        request.endpoint.buildUri({
          'username': request.username,
          'password': request.password,
          'action': action,
        }),
        options: _buildOptions(action: action),
        cancelToken: cancelToken,
      ),
      mapper: (response) => _parseCategoriesResponse(
        response,
        endpoint: request.endpoint,
        action: action,
      ),
    );
  }

  Future<List<XtreamStreamDto>> _getStreams(
    XtreamAccountRequest request, {
    required String action,
    String? categoryId,
  }) {
    final query = <String, String>{
      'username': request.username,
      'password': request.password,
      'action': action,
    };
    if (categoryId != null) {
      query['category_id'] = categoryId;
    }

    return _executor.run<dynamic, List<XtreamStreamDto>>(
      request: (client, cancelToken) => client.getUri<dynamic>(
        request.endpoint.buildUri(query),
        options: _buildOptions(action: action),
        cancelToken: cancelToken,
      ),
      mapper: (response) => _parseStreamsResponse(
        response,
        endpoint: request.endpoint,
        action: action,
      ),
    );
  }

  Options _buildOptions({required String action}) {
    return Options(
      responseType: ResponseType.plain,
      headers: <String, Object?>{
        'Accept': 'application/json, text/plain, */*',
        ..._buildXtreamHeaders(),
      },
    );
  }

  Map<String, String> _buildXtreamHeaders() {
    final headers = <String, String>{};
    final userAgent = _effectiveUserAgent;
    if (userAgent != null && userAgent.isNotEmpty) {
      headers['User-Agent'] = userAgent;
    }
    return headers;
  }

  String? get _effectiveUserAgent {
    final override = _overrideUserAgent.trim();
    if (override.isNotEmpty) {
      return override;
    }
    final configured = _userAgent?.trim();
    if (configured == null || configured.isEmpty) {
      return null;
    }
    return configured;
  }

  XtreamAuthDto _parseAuthResponse(
    Response<dynamic> response, {
    required XtreamEndpoint endpoint,
  }) {
    final payload = _decodePayload(
      response,
      endpoint: endpoint,
      action: 'authenticate',
    );
    if (payload is! Map<String, dynamic>) {
      throw XtreamInvalidResponseFailure(
        'Xtream auth response must be an object',
        context: _buildFailureContext(
          endpoint: endpoint,
          action: 'authenticate',
          response: response,
          payload: payload,
        ),
      );
    }
    if (!payload.containsKey('user_info') &&
        !payload.containsKey('auth') &&
        !payload.containsKey('status')) {
      throw XtreamInvalidResponseFailure(
        'Xtream auth response is missing authentication fields',
        context: _buildFailureContext(
          endpoint: endpoint,
          action: 'authenticate',
          response: response,
          payload: payload,
        ),
      );
    }
    _logXtreamSuccess(
      endpoint: endpoint,
      action: 'authenticate',
      response: response,
      payload: payload,
    );
    return XtreamAuthDto.fromJson(payload);
  }

  Map<String, dynamic> _parseSeriesInfoResponse(
    Response<dynamic> response, {
    required XtreamEndpoint endpoint,
  }) {
    final payload = _decodePayload(
      response,
      endpoint: endpoint,
      action: 'get_series_info',
    );
    if (payload is! Map<String, dynamic>) {
      throw XtreamInvalidResponseFailure(
        'Xtream series info response must be an object',
        context: _buildFailureContext(
          endpoint: endpoint,
          action: 'get_series_info',
          response: response,
          payload: payload,
        ),
      );
    }
    _logXtreamSuccess(
      endpoint: endpoint,
      action: 'get_series_info',
      response: response,
      payload: payload,
    );
    return payload;
  }

  List<XtreamCategoryDto> _parseCategoriesResponse(
    Response<dynamic> response, {
    required XtreamEndpoint endpoint,
    required String action,
  }) {
    final payload = _decodePayload(
      response,
      endpoint: endpoint,
      action: action,
    );
    final list = _extractListPayload(
      payload,
      fallbackKeys: const <String>['categories', 'data', 'results'],
      endpoint: endpoint,
      response: response,
      action: action,
    );
    _logXtreamSuccess(
      endpoint: endpoint,
      action: action,
      response: response,
      payload: payload,
      itemCount: list.length,
    );
    return list
        .whereType<Map<String, dynamic>>()
        .map(XtreamCategoryDto.fromJson)
        .toList(growable: false);
  }

  List<XtreamStreamDto> _parseStreamsResponse(
    Response<dynamic> response, {
    required XtreamEndpoint endpoint,
    required String action,
  }) {
    final payload = _decodePayload(
      response,
      endpoint: endpoint,
      action: action,
    );
    final list = _extractListPayload(
      payload,
      fallbackKeys: const <String>['results', 'streams', 'data'],
      endpoint: endpoint,
      response: response,
      action: action,
    );
    _logXtreamSuccess(
      endpoint: endpoint,
      action: action,
      response: response,
      payload: payload,
      itemCount: list.length,
    );
    return list
        .whereType<Map<String, dynamic>>()
        .map(XtreamStreamDto.fromJson)
        .toList(growable: false);
  }

  dynamic _decodePayload(
    Response<dynamic> response, {
    required XtreamEndpoint endpoint,
    required String action,
  }) {
    final data = response.data;
    if (data is List || data is Map<String, dynamic>) {
      return data;
    }

    if (data is! String) {
      throw XtreamInvalidResponseFailure(
        'Xtream response type is unsupported: ${data.runtimeType}',
        context: _buildFailureContext(
          endpoint: endpoint,
          action: action,
          response: response,
          payload: data,
        ),
      );
    }

    final contentType = _normalizeContentType(response);
    final body = data.trim();
    if (body.isEmpty) {
      throw XtreamInvalidResponseFailure(
        'Xtream response body is empty',
        context: _buildFailureContext(
          endpoint: endpoint,
          action: action,
          response: response,
          payload: body,
        ),
      );
    }

    if (_looksLikeHtml(body) || contentType.contains('text/html')) {
      throw XtreamBlockedResponseFailure(
        'Xtream endpoint returned HTML instead of JSON',
        context: _buildFailureContext(
          endpoint: endpoint,
          action: action,
          response: response,
          payload: body,
        ),
      );
    }

    if (body.startsWith('{') || body.startsWith('[')) {
      try {
        return jsonDecode(body);
      } on FormatException catch (error, stackTrace) {
        throw XtreamInvalidResponseFailure(
          'Xtream JSON decode failed: ${error.message}',
          cause: error,
          stackTrace: stackTrace,
          context: _buildFailureContext(
            endpoint: endpoint,
            action: action,
            response: response,
            payload: body,
          ),
        );
      }
    }

    throw XtreamBlockedResponseFailure(
      'Xtream endpoint returned non-JSON text',
      context: _buildFailureContext(
        endpoint: endpoint,
        action: action,
        response: response,
        payload: body,
      ),
    );
  }

  List<dynamic> _extractListPayload(
    dynamic payload, {
    required List<String> fallbackKeys,
    required XtreamEndpoint endpoint,
    required Response<dynamic> response,
    required String action,
  }) {
    if (payload is List) {
      return payload;
    }
    if (payload is Map<String, dynamic>) {
      for (final key in fallbackKeys) {
        final value = payload[key];
        if (value is List) {
          return value;
        }
      }
      throw XtreamInvalidResponseFailure(
        'Xtream list response has no supported list key',
        context: _buildFailureContext(
          endpoint: endpoint,
          action: action,
          response: response,
          payload: payload,
        ),
      );
    }
    throw XtreamInvalidResponseFailure(
      'Xtream list response has unexpected shape',
      context: _buildFailureContext(
        endpoint: endpoint,
        action: action,
        response: response,
        payload: payload,
      ),
    );
  }

  Map<String, Object?> _buildFailureContext({
    required XtreamEndpoint endpoint,
    required String action,
    required Response<dynamic> response,
    required dynamic payload,
  }) {
    final context = <String, Object?>{
      'host': endpoint.host,
      'action': action,
      'statusCode': response.statusCode,
      'contentType': _normalizeContentType(response),
      'payloadKind': _payloadKind(payload),
      'effectiveUserAgent': _effectiveUserAgent ?? 'default',
    };
    if (payload is String) {
      context['bodyLength'] = payload.length;
    } else if (payload is List) {
      context['itemCount'] = payload.length;
    } else if (payload is Map<String, dynamic>) {
      context['keys'] = payload.keys.take(8).join(',');
    }
    return context;
  }

  void _logXtreamSuccess({
    required XtreamEndpoint endpoint,
    required String action,
    required Response<dynamic> response,
    required dynamic payload,
    int? itemCount,
  }) {
    final contentType = _normalizeContentType(response);
    final suffix = itemCount == null ? '' : ' itemCount=$itemCount';
    _logger?.debug(
      '[Xtream] host=${endpoint.host} action=$action '
      'status=${response.statusCode ?? 0} contentType=$contentType '
      'payload=${_payloadKind(payload)}$suffix '
      'ua=${_effectiveUserAgent ?? 'default'}',
      category: 'IPTV',
    );
  }

  String _normalizeContentType(Response<dynamic> response) {
    final value =
        response.headers.value(Headers.contentTypeHeader) ?? 'unknown';
    final idx = value.indexOf(';');
    if (idx < 0) {
      return value.toLowerCase();
    }
    return value.substring(0, idx).trim().toLowerCase();
  }

  String _payloadKind(dynamic payload) {
    if (payload is List) return 'list';
    if (payload is Map<String, dynamic>) return 'map';
    if (payload is String) {
      return _looksLikeHtml(payload.trim()) ? 'html' : 'text';
    }
    return payload.runtimeType.toString();
  }

  bool _looksLikeHtml(String value) {
    final lower = value.trimLeft().toLowerCase();
    return lower.startsWith('<!doctype html') ||
        lower.startsWith('<html') ||
        lower.startsWith('<head') ||
        lower.startsWith('<body');
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
