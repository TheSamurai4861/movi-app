import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';

/// Service pour construire les URLs de streaming Xtream
class XtreamStreamUrlBuilder {
  XtreamStreamUrlBuilder({
    required IptvLocalRepository iptvLocal,
    required CredentialsVault vault,
    NetworkExecutor? networkExecutor,
  }) : _iptvLocal = iptvLocal,
       _vault = vault,
       _networkExecutor = networkExecutor;

  final IptvLocalRepository _iptvLocal;
  final CredentialsVault _vault;
  final NetworkExecutor? _networkExecutor;

  /// Construit l'URL de streaming pour un film
  /// Format: host:port/movie/username/password/movie_id ou host:port/movie/username/password/movie_id.mkv
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

    // Format Xtream direct : /movie/{username}/{password}/{streamId}
    // On peut aussi essayer avec .mkv : /movie/{username}/{password}/{streamId}.mkv
    // Pour l'instant, on utilise le format sans extension
    return '$baseUrl$port/movie/${Uri.encodeComponent(account.username)}/${Uri.encodeComponent(password)}/$streamId';
  }

  /// Construit l'URL de streaming pour un épisode de série en utilisant l'ID unique de l'épisode
  ///
  /// Format utilisé (méthode 1 - recommandée) : host:port/series/username/password/episode_id[.extension]
  ///
  /// Si container_extension est fourni dans la playlist, il sera ajouté à l'URL.
  /// Cette méthode est la plus simple et la plus courante dans les panels Xtream récents.
  ///
  /// Exemple : http://monserveur.com:8000/series/user123/pass123/789.mp4
  Future<String?> buildEpisodeStreamUrl({
    required int episodeId,
    required String accountId,
    String? extension,
    int? seriesId, // Paramètre conservé pour compatibilité mais non utilisé
  }) async {
    final account = await _getAccount(accountId);
    if (account == null) return null;

    final password = await _getPassword(account);
    if (password == null) return null;

    final endpoint = account.endpoint.uri;
    final baseUrl = '${endpoint.scheme}://${endpoint.host}';
    final port = endpoint.hasPort ? ':${endpoint.port}' : '';

    // Méthode 1 (recommandée et la plus courante) : seulement episode_id
    // Format: /series/{username}/{password}/{episodeId}[.extension]
    // Si container_extension est fourni, l'ajouter à l'URL
    final extensionSuffix = extension != null && extension.isNotEmpty
        ? (extension.startsWith('.') ? extension : '.$extension')
        : '';
    return '$baseUrl$port/series/${Uri.encodeComponent(account.username)}/${Uri.encodeComponent(password)}/$episodeId$extensionSuffix';
  }

  /// Construit l'URL de streaming depuis un XtreamPlaylistItem (film)
  Future<String?> buildStreamUrlFromMovieItem(XtreamPlaylistItem item) async {
    if (item.type != XtreamPlaylistItemType.movie) {
      return null;
    }
    return buildMovieStreamUrl(
      streamId: item.streamId,
      accountId: item.accountId,
    );
  }

  /// Construit l'URL de streaming depuis un XtreamPlaylistItem (série) et numéros d'épisode
  /// Essaie d'abord de récupérer l'ID réel de l'épisode depuis l'API Xtream
  Future<String?> buildStreamUrlFromSeriesItem({
    required XtreamPlaylistItem item,
    required int seasonNumber,
    required int episodeNumber,
  }) async {
    if (item.type != XtreamPlaylistItemType.series) {
      return null;
    }

    // Vérifier que le streamId est valide
    if (item.streamId == 0) {
      // Si le streamId est invalide, on ne peut pas construire l'URL
      return null;
    }

    // Essayer d'abord de récupérer les données de l'épisode depuis le stockage local
    final episodeData = await _iptvLocal.getEpisodeData(
      accountId: item.accountId,
      seriesId: item.streamId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );

    if (episodeData != null && episodeData.episodeId > 0) {
      // Utiliser l'ID réel de l'épisode depuis le stockage local avec l'extension si disponible
      return buildEpisodeStreamUrl(
        episodeId: episodeData.episodeId,
        accountId: item.accountId,
        extension: episodeData.extension,
      );
    }

    // Fallback : essayer de récupérer depuis l'API Xtream et le mettre en cache
    final apiEpisodeData = await _getEpisodeDataFromApi(
      seriesId: item.streamId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      accountId: item.accountId,
    );

    if (apiEpisodeData != null && apiEpisodeData.episodeId > 0) {
      // Sauvegarder l'épisode avec son extension pour les prochaines fois
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

      // Utiliser l'ID réel de l'épisode avec l'extension si disponible
      return buildEpisodeStreamUrl(
        episodeId: apiEpisodeData.episodeId,
        accountId: item.accountId,
        extension: apiEpisodeData.extension,
      );
    }

    // Fallback : utiliser seulement l'ID de l'épisode calculé (sans seriesId)
    // Format: /series/{username}/{password}/{calculatedEpisodeId}
    // Cette méthode peut fonctionner si l'ID de l'épisode est unique
    final account = await _getAccount(item.accountId);
    if (account == null) return null;

    final password = await _getPassword(account);
    if (password == null) return null;

    final endpoint = account.endpoint.uri;
    final baseUrl = '${endpoint.scheme}://${endpoint.host}';
    final port = endpoint.hasPort ? ':${endpoint.port}' : '';

    // Calcul approximatif de l'ID de l'épisode basé sur seriesId, season et episode
    // Format: /series/{username}/{password}/{calculatedEpisodeId}
    // On essaie d'abord sans seriesId (méthode 1 recommandée par l'utilisateur)
    final calculatedEpisodeId =
        item.streamId * 10000 + seasonNumber * 100 + episodeNumber;
    return '$baseUrl$port/series/${Uri.encodeComponent(account.username)}/${Uri.encodeComponent(password)}/$calculatedEpisodeId';
  }

  /// Récupère les données réelles de l'épisode depuis l'API Xtream
  /// Utilise l'API get_series_info pour récupérer les épisodes de la série
  /// Retourne l'ID de l'épisode et son extension (container_extension) si disponible
  Future<({int episodeId, String? extension})?> _getEpisodeDataFromApi({
    required int seriesId,
    required int seasonNumber,
    required int episodeNumber,
    required String accountId,
  }) async {
    if (_networkExecutor == null) return null;

    try {
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

      final response = await _networkExecutor
          .run<dynamic, Map<String, dynamic>>(
            request: (client, cancelToken) => client.getUri<dynamic>(
              uri,
              options: Options(responseType: ResponseType.json),
              cancelToken: cancelToken,
            ),
            mapper: (response) {
              final data = response.data;
              if (data is Map<String, dynamic>) {
                return data;
              } else if (data is String) {
                final s = data.trim();
                if (s.isEmpty) {
                  return <String, dynamic>{};
                }
                try {
                  final decoded = jsonDecode(s);
                  if (decoded is Map<String, dynamic>) {
                    return decoded;
                  }
                } catch (_) {
                  // JSON invalide, retourner un map vide
                  return <String, dynamic>{};
                }
              }
              return <String, dynamic>{};
            },
          );

      // Parser la réponse pour trouver l'épisode
      // La structure typique est : { "episodes": { "1": [{ "id": 123, "episode_num": 1, ... }] } }
      final episodes = response['episodes'];
      if (episodes is Map<String, dynamic>) {
        final seasonKey = seasonNumber.toString();
        final seasonEpisodes = episodes[seasonKey];
        if (seasonEpisodes is List) {
          for (final episodeData in seasonEpisodes) {
            if (episodeData is Map<String, dynamic>) {
              final epNum = episodeData['episode_num'];
              final episodeId = episodeData['id'] ?? episodeData['stream_id'];
              final extension =
                  episodeData['container_extension']?.toString() ??
                  episodeData['extension']?.toString();

              // Vérifier si c'est le bon épisode
              if (epNum != null &&
                  epNum == episodeNumber &&
                  episodeId != null) {
                final id = episodeId is int
                    ? episodeId
                    : int.tryParse(episodeId.toString());
                if (id != null && id > 0) {
                  return (episodeId: id, extension: extension);
                }
              }
            }
          }
        }
      }

      return null;
    } catch (e) {
      // En cas d'erreur (réponse vide, JSON invalide, etc.), retourner null pour utiliser le fallback
      // Le fallback calculera l'ID d'épisode basé sur la formule: seriesId * 10000 + seasonNumber * 100 + episodeNumber
      return null;
    }
  }

  Future<XtreamAccount?> _getAccount(String accountId) async {
    final accounts = await _iptvLocal.getAccounts();
    if (accounts.isEmpty) return null;

    try {
      return accounts.firstWhere((a) => a.id == accountId);
    } catch (_) {
      // Si le compte spécifique n'est pas trouvé, retourner le premier disponible
      return accounts.first;
    }
  }

  Future<String?> _getPassword(XtreamAccount account) async {
    // Essayer plusieurs clés possibles pour le mot de passe
    String? password = await _vault.readPassword(account.id);
    if (password != null && password.isNotEmpty) return password;

    final hostKey = '${account.endpoint.host}_${account.username}'
        .toLowerCase();
    if (hostKey != account.id) {
      password = await _vault.readPassword(hostKey);
      if (password != null && password.isNotEmpty) return password;
    }

    final rawUrlKey = '${account.endpoint.toRawUrl()}_${account.username}'
        .toLowerCase();
    if (rawUrlKey != account.id && rawUrlKey != hostKey) {
      password = await _vault.readPassword(rawUrlKey);
      if (password != null && password.isNotEmpty) return password;
    }

    return null;
  }
}
