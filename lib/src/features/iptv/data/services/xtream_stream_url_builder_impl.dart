import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';

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
    return '$baseUrl$port/movie/${Uri.encodeComponent(account.username)}/${Uri.encodeComponent(password)}/$streamId';
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
    final ext = extension != null && extension.isNotEmpty
        ? (extension.startsWith('.') ? extension : '.$extension')
        : '';
    return '$baseUrl$port/series/${Uri.encodeComponent(account.username)}/${Uri.encodeComponent(password)}/$episodeId$ext';
  }

  @override
  Future<String?> buildStreamUrlFromMovieItem(XtreamPlaylistItem item) async {
    if (item.type != XtreamPlaylistItemType.movie) return null;
    return buildMovieStreamUrl(streamId: item.streamId, accountId: item.accountId);
  }

  @override
  Future<String?> buildStreamUrlFromSeriesItem({
    required XtreamPlaylistItem item,
    required int seasonNumber,
    required int episodeNumber,
  }) async {
    if (item.type != XtreamPlaylistItemType.series) return null;
    if (item.streamId == 0) return null;

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
    final calculatedEpisodeId = item.streamId * 10000 + seasonNumber * 100 + episodeNumber;
    return '$baseUrl$port/series/${Uri.encodeComponent(account.username)}/${Uri.encodeComponent(password)}/$calculatedEpisodeId';
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
    if (episodes is Map<String, dynamic>) {
      final seasonKey = seasonNumber.toString();
      final seasonEpisodes = episodes[seasonKey];
      if (seasonEpisodes is List) {
        for (final ep in seasonEpisodes) {
          if (ep is Map<String, dynamic>) {
            final epNum = ep['episode_num'];
            final episodeId = ep['id'] ?? ep['stream_id'];
            final extension = ep['container_extension']?.toString() ?? ep['extension']?.toString();
            if (epNum != null && epNum == episodeNumber && episodeId != null) {
              final id = episodeId is int ? episodeId : int.tryParse(episodeId.toString());
              if (id != null && id > 0) {
                return (episodeId: id, extension: extension);
              }
            }
          }
        }
      }
    }
    return null;
  }

  Future<XtreamAccount?> _getAccount(String accountId) async {
    final accounts = await _iptvLocal.getAccounts();
    if (accounts.isEmpty) return null;
    try {
      return accounts.firstWhere((a) => a.id == accountId);
    } catch (_) {
      return accounts.first;
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
}