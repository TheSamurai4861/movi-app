import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:movi/src/core/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/core/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/core/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/core/iptv/domain/value_objects/xtream_endpoint.dart';

import '../../storage/database/sqlite_database.dart';

/// Repository local pour la persistance des comptes et playlists IPTV.
/// Implémentation basée sur `sqflite` avec conversions typées et garde-fous.
class IptvLocalRepository {
  static const String _tblAccounts = 'iptv_accounts';
  static const String _tblPlaylists = 'iptv_playlists';

  Future<Database> get _db => LocalDatabase.instance();

  /// Enregistre ou met à jour un [XtreamAccount].
  Future<void> saveAccount(XtreamAccount account) async {
    final db = await _db;
    await db.insert(
      _tblAccounts,
      <String, Object?>{
        'account_id': account.id,
        'alias': account.alias,
        'endpoint': account.endpoint.toRawUrl(),
        'username': account.username,
        'password': account.password,
        'status': account.status.name,
        'expiration': account.expirationDate?.millisecondsSinceEpoch,
        'created_at': account.createdAt.millisecondsSinceEpoch,
        'last_error': account.lastError,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère tous les comptes IPTV persistés.
  Future<List<XtreamAccount>> getAccounts() async {
    final db = await _db;
    final rows = await db.query(_tblAccounts);
    return rows.map(_parseAccountRow).toList(growable: false);
  }

  /// Supprime un compte et ses playlists associées.
  Future<void> removeAccount(String id) async {
    final db = await _db;
    await db.delete(
      _tblAccounts,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
    );
    await db.delete(
      _tblPlaylists,
      where: 'account_id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Sauvegarde les playlists d'un compte sous forme de payload JSON.
  Future<void> savePlaylists(
    String accountId,
    List<XtreamPlaylist> playlists,
  ) async {
    final db = await _db;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final playlist in playlists) {
      final payload = <String, Object?>{
        'title': playlist.title,
        'type': playlist.type.name,
        'categoryId': playlist.id,
        'items': playlist.items
            .map(
              (XtreamPlaylistItem item) => <String, Object?>{
                'streamId': item.streamId,
                'title': item.title,
                'poster': item.posterUrl,
                'categoryName': item.categoryName,
                'tmdbId': item.tmdbId,
                'type': item.type.name,
              },
            )
            .toList(growable: false),
      };

      batch.insert(
        _tblPlaylists,
        <String, Object?>{
          'account_id': accountId,
          'category_id': playlist.id,
          'payload': jsonEncode(payload),
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Récupère les playlists d'un compte (décodage défensif + normalisation).
  Future<List<XtreamPlaylist>> getPlaylists(String accountId) async {
    final db = await _db;
    final rows = await db.query(
      _tblPlaylists,
      where: 'account_id = ?',
      whereArgs: <Object?>[accountId],
    );

    final result = <XtreamPlaylist>[];
    for (final row in rows) {
      final payload = _decodeMap(row['payload']);
      if (payload == null) continue;

      final String title = _asString(payload['title']) ?? '';
      final String categoryId = _asString(payload['categoryId']) ?? '';
      final XtreamPlaylistType playlistType =
          _normalizePlaylistType(_asString(payload['type']));

      final List<dynamic> itemsList = _asList(payload['items']);

      final items = <XtreamPlaylistItem>[];
      for (final dynamic item in itemsList) {
        if (item is! Map<String, dynamic>) continue;

        final String categoryName = _asString(item['categoryName']) ?? '';
        final int? streamId = _asNum(item['streamId'])?.toInt();
        final String itemTitle = _asString(item['title']) ?? '';
        final String? posterUrl = _asString(item['poster']);
        final int? tmdbId = _asNum(item['tmdbId'])?.toInt();

        final String rawType = (_asString(item['type']) ?? '').toLowerCase().trim();
        final XtreamPlaylistItemType itemType =
            _normalizeItemType(rawType, playlistType);

        if (streamId == null) continue;

        items.add(
          XtreamPlaylistItem(
            accountId: accountId,
            categoryId: categoryId,
            categoryName: categoryName,
            streamId: streamId,
            title: itemTitle,
            type: itemType,
            tmdbId: tmdbId,
            posterUrl: posterUrl,
          ),
        );
      }

      result.add(
        XtreamPlaylist(
          id: categoryId,
          accountId: accountId,
          title: title,
          type: playlistType,
          items: items,
        ),
      );
    }

    return result;
  }

  /// Construit l'ensemble des TMDB IDs disponibles localement.
  Future<Set<int>> getAvailableTmdbIds({XtreamPlaylistItemType? type}) async {
    final accounts = await getAccounts();
    final ids = <int>{};

    for (final account in accounts) {
      final playlists = await getPlaylists(account.id);
      for (final playlist in playlists) {
        for (final item in playlist.items) {
          final int? tmdbId = item.tmdbId;
          if (tmdbId == null) continue;
          if (type != null && item.type != type) continue;
          ids.add(tmdbId);
        }
      }
    }

    return ids;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  XtreamAccount _parseAccountRow(Map<String, Object?> row) {
    final String id = (row['account_id'] as String?) ?? '';
    final String alias = (row['alias'] as String?) ?? '';
    final String endpointRaw = (row['endpoint'] as String?) ?? '';
    final String username = (row['username'] as String?) ?? '';
    final String password = (row['password'] as String?) ?? '';
    final String statusStr =
        (row['status'] as String?) ?? XtreamAccountStatus.pending.name;
    final int createdAtMs = (row['created_at'] as int?) ?? 0;
    final int? expirationMs = row['expiration'] as int?;
    final String? lastError = row['last_error'] as String?;

    final XtreamAccountStatus status = XtreamAccountStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => XtreamAccountStatus.pending,
    );

    return XtreamAccount(
      id: id,
      alias: alias,
      endpoint: XtreamEndpoint.parse(endpointRaw),
      username: username,
      password: password,
      status: status,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      expirationDate:
          expirationMs != null ? DateTime.fromMillisecondsSinceEpoch(expirationMs) : null,
      lastError: lastError,
    );
  }

  Map<String, dynamic>? _decodeMap(Object? raw) {
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        return null;
      }
      return null;
    }
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }

  List<dynamic> _asList(Object? v) {
    if (v is List) return List<dynamic>.from(v);
    return const <dynamic>[];
  }

  String? _asString(Object? v) => v?.toString();

  num? _asNum(Object? v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  XtreamPlaylistType _normalizePlaylistType(String? raw) {
    final r = (raw ?? '').toLowerCase().trim();
    for (final t in XtreamPlaylistType.values) {
      if (t.name == r) return t;
    }
    // Tentatives de normalisation simples
    const moviesTokens = <String>{'movie', 'movies', 'vod', 'films'};
    const seriesTokens = <String>{
      'tv',
      'tvshow',
      'tvshows',
      'show',
      'shows',
      'serie',
      'series',
      'tv_series',
      'series_tv',
      'série',
      'séries',
    };
    if (seriesTokens.contains(r)) return XtreamPlaylistType.series;
    if (moviesTokens.contains(r)) return XtreamPlaylistType.movies;
    return XtreamPlaylistType.movies;
  }

  XtreamPlaylistItemType _normalizeItemType(
    String raw,
    XtreamPlaylistType playlistType,
  ) {
    if (raw.isEmpty || raw == 'null') {
      return playlistType == XtreamPlaylistType.series
          ? XtreamPlaylistItemType.series
          : XtreamPlaylistItemType.movie;
    }

    final r = raw.replaceAll('-', '_');

    for (final t in XtreamPlaylistItemType.values) {
      if (t.name == r) return t;
    }

    const seriesTokens = <String>{
      'tv',
      'tvshow',
      'tvshows',
      'show',
      'shows',
      'serie',
      'series',
      'tv_series',
      'series_tv',
      'série',
      'séries',
      'epg_series',
    };

    if (seriesTokens.contains(r)) return XtreamPlaylistItemType.series;

    return playlistType == XtreamPlaylistType.series
        ? XtreamPlaylistItemType.series
        : XtreamPlaylistItemType.movie;
  }
}
