import 'package:flutter/foundation.dart';
import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/features/iptv/data/datasources/stalker_remote_data_source.dart';
import 'package:movi/src/features/iptv/domain/value_objects/stalker_endpoint.dart';

/// Service pour construire les URLs de stream Stalker Portal
class StalkerStreamUrlBuilder {
  StalkerStreamUrlBuilder({NetworkExecutor? networkExecutor})
    : _networkExecutor = networkExecutor;

  final NetworkExecutor? _networkExecutor;
  StalkerRemoteDataSource? _remote;
  String? _lastDetail;

  String? get lastDetail => _lastDetail;

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[StalkerStreamUrlBuilder] $message');
    }
  }

  /// Construit l'URL de stream pour un contenu VOD
  /// Utilise l'action `get_url` ou `create_link` selon le serveur
  Future<String?> buildVodStreamUrl({
    required StalkerEndpoint endpoint,
    required String token,
    required String contentId,
    String? macAddress,
  }) async {
    final resolved = await _resolveVodStreamUrl(
      endpoint: endpoint,
      token: token,
      contentId: contentId,
      macAddress: macAddress,
    );
    if (resolved != null) return resolved;
    return null;
  }

  /// Construit l'URL de stream pour une série
  /// Utilise l'action `get_url` avec l'ID de la série
  Future<String?> buildSeriesStreamUrl({
    required StalkerEndpoint endpoint,
    required String token,
    required String seriesId,
    int? seasonNumber,
    int? episodeNumber,
    String? macAddress,
  }) async {
    final resolved = await _resolveSeriesStreamUrl(
      endpoint: endpoint,
      token: token,
      seriesId: seriesId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      macAddress: macAddress,
    );
    if (resolved != null) return resolved;
    return null;
  }

  /// Construit l'URL de stream pour une chaîne live TV
  /// Utilise l'action `create_link` avec la commande
  Future<String> buildLiveTvStreamUrl({
    required StalkerEndpoint endpoint,
    required String token,
    required String cmd,
    String? macAddress,
  }) async {
    final params = {
      'type': 'itv',
      'action': 'create_link',
      'token': token,
      'cmd': cmd,
    };

    final uri = endpoint.buildUri(params);
    return uri.toString();
  }

  StalkerRemoteDataSource? _buildRemote() {
    if (_networkExecutor == null) return null;
    _remote ??= StalkerRemoteDataSource(_networkExecutor);
    return _remote;
  }

  Future<String?> _resolveVodStreamUrl({
    required StalkerEndpoint endpoint,
    required String token,
    required String contentId,
    String? macAddress,
  }) async {
    _lastDetail = null;
    final remote = _buildRemote();
    if (remote == null) return null;

    final createData = await remote.createVodStreamLink(
      endpoint: endpoint,
      token: token,
      contentId: contentId,
      macAddress: macAddress,
    );
    _debugLog(
      'Stalker VOD create_link response: ${_summarizeResponse(createData)}',
    );
    final createUrl = _extractStreamUrl(createData, endpoint);
    if (createUrl != null) return createUrl;

    final getData = await remote.getVodStreamLink(
      endpoint: endpoint,
      token: token,
      contentId: contentId,
      macAddress: macAddress,
    );
    _debugLog('Stalker VOD get_url response: ${_summarizeResponse(getData)}');
    final getUrl = _extractStreamUrl(getData, endpoint);
    if (getUrl != null) return getUrl;

    final detail = _extractDetail(createData) ?? _extractDetail(getData);
    if (detail != null) {
      _lastDetail = detail;
      _debugLog('Stalker VOD link detail: ${_maskSensitive(detail)}');
    }

    final refreshedToken = await _refreshTokenIfNeeded(
      endpoint: endpoint,
      macAddress: macAddress,
      currentToken: token,
      detail: detail,
    );
    if (refreshedToken == null || refreshedToken == token) {
      return null;
    }

    final retryCreate = await remote.createVodStreamLink(
      endpoint: endpoint,
      token: refreshedToken,
      contentId: contentId,
      macAddress: macAddress,
    );
    _debugLog(
      'Stalker VOD create_link retry response: ${_summarizeResponse(retryCreate)}',
    );
    final retryCreateUrl = _extractStreamUrl(retryCreate, endpoint);
    if (retryCreateUrl != null) return retryCreateUrl;

    final retryGet = await remote.getVodStreamLink(
      endpoint: endpoint,
      token: refreshedToken,
      contentId: contentId,
      macAddress: macAddress,
    );
    _debugLog(
      'Stalker VOD get_url retry response: ${_summarizeResponse(retryGet)}',
    );
    final retryUrl = _extractStreamUrl(retryGet, endpoint);
    if (retryUrl != null) return retryUrl;
    final retryDetail = _extractDetail(retryCreate) ?? _extractDetail(retryGet);
    if (retryDetail != null) {
      _lastDetail = retryDetail;
      _debugLog('Stalker VOD retry detail: ${_maskSensitive(retryDetail)}');
    }
    return null;
  }

  Future<String?> _resolveSeriesStreamUrl({
    required StalkerEndpoint endpoint,
    required String token,
    required String seriesId,
    int? seasonNumber,
    int? episodeNumber,
    String? macAddress,
  }) async {
    _lastDetail = null;
    final remote = _buildRemote();
    if (remote == null) return null;

    final createData = await remote.createSeriesStreamLink(
      endpoint: endpoint,
      token: token,
      seriesId: seriesId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      macAddress: macAddress,
    );
    _debugLog(
      'Stalker series create_link response: ${_summarizeResponse(createData)}',
    );
    final createUrl = _extractStreamUrl(createData, endpoint);
    if (createUrl != null) return createUrl;

    final getData = await remote.getSeriesStreamLink(
      endpoint: endpoint,
      token: token,
      seriesId: seriesId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      macAddress: macAddress,
    );
    _debugLog(
      'Stalker series get_url response: ${_summarizeResponse(getData)}',
    );
    final getUrl = _extractStreamUrl(getData, endpoint);
    if (getUrl != null) return getUrl;

    final detail = _extractDetail(createData) ?? _extractDetail(getData);
    if (detail != null) {
      _lastDetail = detail;
      _debugLog('Stalker series link detail: ${_maskSensitive(detail)}');
    }

    final refreshedToken = await _refreshTokenIfNeeded(
      endpoint: endpoint,
      macAddress: macAddress,
      currentToken: token,
      detail: detail,
    );
    if (refreshedToken == null || refreshedToken == token) {
      return null;
    }

    final retryCreate = await remote.createSeriesStreamLink(
      endpoint: endpoint,
      token: refreshedToken,
      seriesId: seriesId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      macAddress: macAddress,
    );
    _debugLog(
      'Stalker series create_link retry response: ${_summarizeResponse(retryCreate)}',
    );
    final retryCreateUrl = _extractStreamUrl(retryCreate, endpoint);
    if (retryCreateUrl != null) return retryCreateUrl;

    final retryGet = await remote.getSeriesStreamLink(
      endpoint: endpoint,
      token: refreshedToken,
      seriesId: seriesId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      macAddress: macAddress,
    );
    _debugLog(
      'Stalker series get_url retry response: ${_summarizeResponse(retryGet)}',
    );
    final retryUrl = _extractStreamUrl(retryGet, endpoint);
    if (retryUrl != null) return retryUrl;
    final retryDetail = _extractDetail(retryCreate) ?? _extractDetail(retryGet);
    if (retryDetail != null) {
      _lastDetail = retryDetail;
      _debugLog('Stalker series retry detail: ${_maskSensitive(retryDetail)}');
    }
    return null;
  }

  String? _extractStreamUrl(dynamic data, StalkerEndpoint endpoint) {
    final resolved = _extractFromValue(data, endpoint);
    if (resolved != null) {
      _debugLog('Stalker resolved stream URL: ${_maskSensitive(resolved)}');
    } else {
      _debugLog('Stalker stream URL not found in response.');
    }
    return resolved;
  }

  String? _extractFromValue(dynamic value, StalkerEndpoint endpoint) {
    if (value == null) return null;
    if (value is String) return _normalizeCommand(value, endpoint);
    if (value is Map<String, dynamic>) {
      final candidate =
          value['cmd'] ??
          value['url'] ??
          value['stream'] ??
          value['link'] ??
          value['path'] ??
          value['src'] ??
          value['file'];
      final playToken = value['play_token'] ?? value['playToken'];
      final parsed = _normalizeCommand(
        candidate?.toString(),
        endpoint,
        playToken: playToken?.toString(),
      );
      if (parsed != null) return parsed;

      final nested = value['data'] ?? value['js'];
      final nestedParsed = _extractFromValue(nested, endpoint);
      if (nestedParsed != null) return nestedParsed;
    }
    if (value is List) {
      for (final entry in value) {
        final parsed = _extractFromValue(entry, endpoint);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  String? _normalizeCommand(
    String? raw,
    StalkerEndpoint endpoint, {
    String? playToken,
  }) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final match = RegExp(r'((?:https?|rtsp|udp)://\S+)').firstMatch(trimmed);
    final direct = match?.group(1);
    if (direct != null) {
      return _appendPlayToken(
        direct.replaceAll('"', '').replaceAll("'", '').trim(),
        playToken,
      );
    }

    var candidate = trimmed;
    if (candidate.startsWith('ffmpeg ')) {
      candidate = candidate.substring(7).trim();
    } else if (candidate.startsWith('auto ')) {
      candidate = candidate.substring(5).trim();
    }

    if (candidate.startsWith('/')) {
      final uri = endpoint.uri;
      final port = uri.hasPort ? ':${uri.port}' : '';
      return _appendPlayToken(
        '${uri.scheme}://${uri.host}$port$candidate'
            .replaceAll('"', '')
            .replaceAll("'", '')
            .trim(),
        playToken,
      );
    }

    return _appendPlayToken(
      candidate.replaceAll('"', '').replaceAll("'", '').trim(),
      playToken,
    );
  }

  String _summarizeResponse(dynamic data) {
    if (data == null) return 'null';
    if (data is Map<String, dynamic>) {
      final keys = data.keys.toList(growable: false);
      final candidate =
          data['cmd'] ??
          data['url'] ??
          data['stream'] ??
          data['link'] ??
          data['path'] ??
          data['src'] ??
          data['file'];
      final nested = data['data'] ?? data['js'];
      final detail =
          data['detail'] ?? data['error'] ?? data['message'] ?? data['status'];
      final sample = candidate?.toString() ?? nested?.toString();
      return 'map keys=$keys sample=${_maskSensitive(sample)} detail=${_maskSensitive(detail?.toString())}';
    }
    if (data is List) {
      return 'list length=${data.length} sample=${_maskSensitive(data.isNotEmpty ? data.first?.toString() : null)}';
    }
    return 'value=${_maskSensitive(data.toString())}';
  }

  String _maskSensitive(String? raw) {
    if (raw == null) return 'null';
    var value = raw;
    value = value.replaceAll(
      RegExp(r'([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}'),
      '**:**:**:**:**:**',
    );
    value = value.replaceAll(
      RegExp(r'(?<=token=)[^&\\s]+'),
      '***',
    );
    value = value.replaceAll(
      RegExp(r'(?<=play_token=)[^&\\s]+'),
      '***',
    );
    value = value.replaceAll(
      RegExp(r'(/movie/|/series/)([^/]+)/([^/]+)'),
      r'$1***/***',
    );
    return value;
  }

  String? _extractDetail(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is Map<String, dynamic>) {
      final detail =
          value['detail'] ?? value['error'] ?? value['message'] ?? value['status'];
      final parsed = _extractDetail(detail);
      if (parsed != null) return parsed;
      final nested = value['data'] ?? value['js'];
      return _extractDetail(nested);
    }
    if (value is List) {
      for (final entry in value) {
        final parsed = _extractDetail(entry);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  Future<String?> _refreshTokenIfNeeded({
    required StalkerEndpoint endpoint,
    required String? macAddress,
    required String currentToken,
    required String? detail,
  }) async {
    final mac = macAddress ?? '';
    if (mac.isEmpty) return null;
    final shouldRefresh = detail == null
        ? true
        : detail.toLowerCase().contains('token') ||
            detail.toLowerCase().contains('expire') ||
            detail.toLowerCase().contains('auth') ||
            detail.toLowerCase().contains('access') ||
            detail.toLowerCase().contains('mac');
    if (!shouldRefresh) return null;

    final remote = _buildRemote();
    if (remote == null) return null;

    final refreshed = await remote.handshake(
      endpoint: endpoint,
      macAddress: mac,
    );
    final token = refreshed.token;
    if (token.isNotEmpty && token != currentToken) {
      _debugLog('Stalker token refreshed for playback.');
      return token;
    }
    return null;
  }

  String _appendPlayToken(String url, String? playToken) {
    if (playToken == null || playToken.isEmpty) return url;
    if (url.contains('play_token=')) return url;
    final sep = url.contains('?') ? '&' : '?';
    return '$url${sep}play_token=$playToken';
  }
}
