import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';

/// Service pour construire les URLs de streaming Xtream
class XtreamStreamUrlBuilder {
  XtreamStreamUrlBuilder({
    required IptvLocalRepository iptvLocal,
    required CredentialsVault vault,
  }) : _iptvLocal = iptvLocal,
       _vault = vault;

  final IptvLocalRepository _iptvLocal;
  final CredentialsVault _vault;

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

  /// Construit l'URL de streaming pour un épisode de série
  /// Format: host:port/series/username/password/series_id/season/episode ou host:port/series/username/password/series_id/season/episode.mkv
  Future<String?> buildEpisodeStreamUrl({
    required int seriesId,
    required int seasonNumber,
    required int episodeNumber,
    required String accountId,
  }) async {
    final account = await _getAccount(accountId);
    if (account == null) return null;

    final password = await _getPassword(account);
    if (password == null) return null;

    final endpoint = account.endpoint.uri;
    final baseUrl = '${endpoint.scheme}://${endpoint.host}';
    final port = endpoint.hasPort ? ':${endpoint.port}' : '';

    // Format Xtream direct : /series/{username}/{password}/{seriesId}/{season}/{episode}
    // On peut aussi essayer avec .mkv : /series/{username}/{password}/{seriesId}/{season}/{episode}.mkv
    // Pour l'instant, on utilise le format sans extension
    return '$baseUrl$port/series/${Uri.encodeComponent(account.username)}/${Uri.encodeComponent(password)}/$seriesId/$seasonNumber/$episodeNumber';
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
  Future<String?> buildStreamUrlFromSeriesItem({
    required XtreamPlaylistItem item,
    required int seasonNumber,
    required int episodeNumber,
  }) async {
    if (item.type != XtreamPlaylistItemType.series) {
      return null;
    }
    return buildEpisodeStreamUrl(
      seriesId: item.streamId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      accountId: item.accountId,
    );
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
