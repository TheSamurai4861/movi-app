import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';
import 'package:movi/src/features/iptv/data/services/stalker_stream_url_builder.dart';

class XtreamStreamUrlBuilderImpl implements XtreamStreamUrlBuilder {
  XtreamStreamUrlBuilderImpl({
    required IptvLocalRepository iptvLocal,
    required CredentialsVault vault,
    NetworkExecutor? networkExecutor,
  }) : _iptvLocal = iptvLocal,
       _vault = vault,
       _networkExecutor = networkExecutor;

  final IptvLocalRepository _iptvLocal;
  final CredentialsVault _vault;
  final NetworkExecutor? _networkExecutor;

  @override
  Future<String?> buildMovieStreamUrl({
    required int streamId,
    required String accountId,
  }) async {
    final account = await _getAccount(accountId);
    if (account == null) return null;
    final password = await _getPassword(account);
    if (password == null) return null;
    final endpoint = account.endpoint.uri;
    final baseUrl = '${endpoint.scheme}://${endpoint.host}';
    final port = endpoint.hasPort ? ':${endpoint.port}' : '';
    final basePath = _streamBasePath(endpoint);
    return '$baseUrl$port$basePath/movie/${Uri.encodeComponent(account.username)}/${Uri.encodeComponent(password)}/$streamId';
  }

  @override
  Future<String?> buildEpisodeStreamUrl({
    required int episodeId,
    required String accountId,
    String? extension,
    int? seriesId,
  }) async {
    final account = await _getAccount(accountId);
    if (account == null) return null;
    final password = await _getPassword(account);
    if (password == null) return null;
    final endpoint = account.endpoint.uri;
    final baseUrl = '${endpoint.scheme}://${endpoint.host}';
    final port = endpoint.hasPort ? ':${endpoint.port}' : '';
    final basePath = _streamBasePath(endpoint);
    final ext = extension != null && extension.isNotEmpty
        ? (extension.startsWith('.') ? extension : '.$extension')
        : '';
    final url =
        '$baseUrl$port$basePath/series/${Uri.encodeComponent(account.username)}/${Uri.encodeComponent(password)}/$episodeId$ext';
    _debugLog('Episode stream URL: ${_maskStreamUrl(url)}');
    return url;
  }

  @override
  Future<String?> buildStreamUrlFromMovieItem(XtreamPlaylistItem item) async {
    if (item.type != XtreamPlaylistItemType.movie) return null;
    
    // Vérifier si c'est un compte Xtream
    final account = await _getAccount(item.accountId);
    if (account != null) {
      // Compte Xtream
      final base = await buildMovieStreamUrl(
        streamId: item.streamId,
        accountId: item.accountId,
      );
      if (base == null) return null;

      final ext = _normalizeExtension(item.containerExtension);
      final url = ext == null ? base : '$base.$ext';
      _debugLog('Movie stream URL (Xtream): ${_maskStreamUrl(url)}');
      return url;
    }
    
    // Essayer Stalker
    final stalkerAccount = await _iptvLocal.getStalkerAccount(item.accountId);
    if (stalkerAccount != null) {
      final url = await _buildStalkerMovieUrl(stalkerAccount, item);
      if (url != null) {
        _debugLog('Movie stream URL (Stalker): ${_maskStreamUrl(url)}');
      }
      return url;
    }
    
    return null;
  }

  @override
  Future<String?> buildStreamUrlFromSeriesItem({
    required XtreamPlaylistItem item,
    required int seasonNumber,
    required int episodeNumber,
  }) async {
    if (item.type != XtreamPlaylistItemType.series) return null;
    if (item.streamId == 0) return null;

    // Vérifier d'abord si c'est un compte Stalker
    final stalkerAccount = await _iptvLocal.getStalkerAccount(item.accountId);
    if (stalkerAccount != null) {
      final url = await _buildStalkerSeriesUrl(
        stalkerAccount,
        item,
        seasonNumber,
        episodeNumber,
      );
      if (url != null) {
        _debugLog('Episode stream URL (Stalker): ${_maskStreamUrl(url)}');
      }
      return url;
    }

    // Logique Xtream normale
    final episodeData = await _iptvLocal.getEpisodeData(
      accountId: item.accountId,
      seriesId: item.streamId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
    if (episodeData != null && episodeData.episodeId > 0) {
      return buildEpisodeStreamUrl(
        episodeId: episodeData.episodeId,
        accountId: item.accountId,
        extension: episodeData.extension,
      );
    }

    if (_networkExecutor != null) {
      final apiEpisodeData = await _getEpisodeDataFromApi(
        seriesId: item.streamId,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        accountId: item.accountId,
      );
      if (apiEpisodeData != null && apiEpisodeData.episodeId > 0) {
        await _iptvLocal.saveEpisodes(
          accountId: item.accountId,
          seriesId: item.streamId,
          episodes: {
            seasonNumber: {
              episodeNumber: EpisodeData(
                episodeId: apiEpisodeData.episodeId,
                extension: apiEpisodeData.extension,
              ),
            },
          },
        );
        return buildEpisodeStreamUrl(
          episodeId: apiEpisodeData.episodeId,
          accountId: item.accountId,
          extension: apiEpisodeData.extension,
        );
      }
    }

    final account = await _getAccount(item.accountId);
    if (account == null) return null;
    final password = await _getPassword(account);
    if (password == null) return null;
    final endpoint = account.endpoint.uri;
    final baseUrl = '${endpoint.scheme}://${endpoint.host}';
    final port = endpoint.hasPort ? ':${endpoint.port}' : '';
    final basePath = _streamBasePath(endpoint);
    final calculatedEpisodeId = item.streamId * 10000 + seasonNumber * 100 + episodeNumber;
    final url =
        '$baseUrl$port$basePath/series/${Uri.encodeComponent(account.username)}/${Uri.encodeComponent(password)}/$calculatedEpisodeId';
    _debugLog('Episode stream URL (Xtream fallback): ${_maskStreamUrl(url)}');
    return url;
  }

  /// Certains panels Xtream ne sont pas à la racine du host (ex: `/xtream/`).
  ///
  /// Dans ce cas, les URLs de streaming sont aussi sous ce préfixe :
  /// `http(s)://host[:port]/xtream/movie/...` et `.../xtream/series/...`.
  String _streamBasePath(Uri endpoint) {
    final raw = endpoint.path;
    if (raw.isEmpty || raw == '/') return '';

    final lower = raw.toLowerCase();
    final int idxPlayer = lower.lastIndexOf('player_api.php');
    final int idxGet = lower.lastIndexOf('get.php');

    String base;
    if (idxPlayer >= 0) {
      base = raw.substring(0, idxPlayer);
    } else if (idxGet >= 0) {
      base = raw.substring(0, idxGet);
    } else {
      base = raw;
    }

    // Normaliser: pas de trailing slash, et '' si on retombe sur '/'
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    if (base == '/') return '';
    if (base.isEmpty) return '';
    return base.startsWith('/') ? base : '/$base';
  }

  Future<({int episodeId, String? extension})?> _getEpisodeDataFromApi({
    required int seriesId,
    required int seasonNumber,
    required int episodeNumber,
    required String accountId,
  }) async {
    if (_networkExecutor == null) return null;
    final account = await _getAccount(accountId);
    if (account == null) return null;
    final password = await _getPassword(account);
    if (password == null) return null;
    final endpoint = account.endpoint;
    final uri = endpoint.buildUri({
      'username': account.username,
      'password': password,
      'action': 'get_series_info',
      'series_id': seriesId.toString(),
    });
    final response = await _networkExecutor.run<dynamic, Map<String, dynamic>>(
      request: (client, cancelToken) => client.getUri<dynamic>(
        uri,
        options: Options(responseType: ResponseType.json),
        cancelToken: cancelToken,
      ),
      mapper: (resp) {
        final data = resp.data;
        if (data is Map<String, dynamic>) return data;
        if (data is String) {
          final s = data.trim();
          if (s.isEmpty) return <String, dynamic>{};
          try {
            final decoded = jsonDecode(s);
            if (decoded is Map<String, dynamic>) return decoded;
          } catch (_) {
            return <String, dynamic>{};
          }
        }
        return <String, dynamic>{};
      },
    );
    final episodes = response['episodes'];

    final result = _findEpisodeData(
      episodes: episodes,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
    if (result != null) {
      _debugLog(
        'Episode found: S${seasonNumber.toString().padLeft(2, '0')}'
        'E${episodeNumber.toString().padLeft(2, '0')}'
        ' -> id=${result.episodeId}, ext=${result.extension ?? '<none>'}',
      );
    } else {
      _debugLog(
        'Episode not found in get_series_info: '
        'seriesId=$seriesId season=$seasonNumber episode=$episodeNumber',
      );
    }
    return result;
  }

  ({int episodeId, String? extension})? _findEpisodeData({
    required dynamic episodes,
    required int seasonNumber,
    required int episodeNumber,
  }) {
    // 1) Structure la plus courante: Map<String season, List episodes>
    if (episodes is Map<String, dynamic>) {
      final seasonKey = seasonNumber.toString();
      final seasonEpisodes = episodes[seasonKey];
      if (seasonEpisodes is List) {
        return _findEpisodeDataInList(
          seasonEpisodes,
          seasonNumber: seasonNumber,
          episodeNumber: episodeNumber,
        );
      }
      return null;
    }

    // 2) Certains panels renvoient `episodes` sous forme de liste (par saison ou flat).
    if (episodes is List) {
      // 2a) Liste de listes (chaque sous-liste = saison)
      if (episodes.isNotEmpty && episodes.first is List) {
        for (final seasonList in episodes) {
          if (seasonList is! List) continue;
          final found = _findEpisodeDataInList(
            seasonList,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
          );
          if (found != null) return found;
        }
        return null;
      }

      // 2b) Liste "flat" d'épisodes, chaque item contient season + episode_num.
      return _findEpisodeDataInList(
        episodes,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
      );
    }

    return null;
  }

  ({int episodeId, String? extension})? _findEpisodeDataInList(
    List<dynamic> list, {
    required int seasonNumber,
    required int episodeNumber,
  }) {
    for (final ep in list) {
      final Map<String, dynamic> map;
      if (ep is Map<String, dynamic>) {
        map = ep;
      } else if (ep is Map) {
        final tmp = <String, dynamic>{};
        for (final entry in ep.entries) {
          final k = entry.key;
          if (k is String) {
            tmp[k] = entry.value;
          }
        }
        map = tmp;
      } else {
        continue;
      }

      final int? sNum = _toInt(
        map['season'] ?? map['season_num'] ?? map['season_number'],
      );
      if (sNum != null && sNum != seasonNumber) {
        continue;
      }

      final int? epNum = _toInt(
        map['episode_num'] ?? map['episode'] ?? map['episode_number'],
      );
      if (epNum == null || epNum != episodeNumber) continue;

      final dynamic rawId = map['id'] ?? map['stream_id'] ?? map['episode_id'];
      final int? id = _toInt(rawId);
      if (id == null || id <= 0) {
        _debugLog(
          'Episode id missing/invalid for season=$seasonNumber episode=$episodeNumber; raw=$rawId',
        );
        return null;
      }

      final ext = _normalizeExtension(
        map['container_extension']?.toString() ?? map['extension']?.toString(),
      );
      return (episodeId: id, extension: ext);
    }
    return null;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  String? _normalizeExtension(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    return s.startsWith('.') ? s.substring(1) : s;
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[XtreamStreamUrlBuilder] $message');
    }
  }

  String _maskStreamUrl(String url) {
    // Masquage best-effort: on cache les segments username/password (2 segments après /movie/ ou /series/).
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    final segments = uri.pathSegments.toList(growable: true);
    final int movieIdx = segments.indexOf('movie');
    final int seriesIdx = segments.indexOf('series');
    final int idx = movieIdx >= 0 ? movieIdx : seriesIdx;
    if (idx >= 0) {
      if (segments.length > idx + 1) segments[idx + 1] = '***';
      if (segments.length > idx + 2) segments[idx + 2] = '***';
    }

    return uri.replace(pathSegments: segments).toString();
  }

  Future<XtreamAccount?> _getAccount(String accountId) async {
    final accounts = await _iptvLocal.getAccounts();
    if (accounts.isEmpty) return null;
    try {
      return accounts.firstWhere((a) => a.id == accountId);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getPassword(XtreamAccount account) async {
    String? password = await _vault.readPassword(account.id);
    if (password != null && password.isNotEmpty) return password;
    final hostKey = '${account.endpoint.host}_${account.username}'.toLowerCase();
    if (hostKey != account.id) {
      password = await _vault.readPassword(hostKey);
      if (password != null && password.isNotEmpty) return password;
    }
    final rawUrlKey = '${account.endpoint.toRawUrl()}_${account.username}'.toLowerCase();
    if (rawUrlKey != account.id && rawUrlKey != hostKey) {
      password = await _vault.readPassword(rawUrlKey);
      if (password != null && password.isNotEmpty) return password;
    }
    return null;
  }

  Future<String?> _buildStalkerMovieUrl(
    StalkerAccount account,
    XtreamPlaylistItem item,
  ) async {
    final builder = StalkerStreamUrlBuilder(
      networkExecutor: _networkExecutor,
    );
    final token = account.token ?? '';
    if (token.isEmpty) return null;

    final url = await builder.buildVodStreamUrl(
      endpoint: account.endpoint,
      token: token,
      contentId: item.streamId.toString(),
      macAddress: account.macAddress,
    );
    if (url == null && builder.lastDetail != null) {
      throw StalkerStreamFailure(_formatStalkerDetail(builder.lastDetail!));
    }
    return url;
  }

  Future<String?> _buildStalkerSeriesUrl(
    StalkerAccount account,
    XtreamPlaylistItem item,
    int seasonNumber,
    int episodeNumber,
  ) async {
    final builder = StalkerStreamUrlBuilder(
      networkExecutor: _networkExecutor,
    );
    final token = account.token ?? '';
    if (token.isEmpty) return null;

    final url = await builder.buildSeriesStreamUrl(
      endpoint: account.endpoint,
      token: token,
      seriesId: item.streamId.toString(),
      macAddress: account.macAddress,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
    if (url == null && builder.lastDetail != null) {
      throw StalkerStreamFailure(_formatStalkerDetail(builder.lastDetail!));
    }
    return url;
  }

  String _formatStalkerDetail(String detail) {
    final raw = detail.trim();
    final cleaned = raw.replaceAll('{', '').replaceAll('}', '').trim();
    if (cleaned.isEmpty) return 'Stalker portal refused the stream link.';
    if (cleaned.toLowerCase().contains('dehors')) {
      return 'Stalker portal refused the stream link (dehors).';
    }
    return 'Stalker portal refused the stream link: $cleaned';
  }
}

class StalkerStreamFailure implements Exception {
  StalkerStreamFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
