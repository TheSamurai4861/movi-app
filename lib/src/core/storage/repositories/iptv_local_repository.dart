import 'dart:convert';

import 'package:movi/src/core/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/core/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/core/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/core/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:sqflite/sqflite.dart';

import '../../storage/database/sqlite_database.dart';

class IptvLocalRepository {
  Future<Database> get _db => LocalDatabase.instance();

  Future<void> saveAccount(XtreamAccount account) async {
    final db = await _db;
    await db.insert('iptv_accounts', {
      'account_id': account.id,
      'alias': account.alias,
      'endpoint': account.endpoint.toRawUrl(),
      'username': account.username,
      'password': account.password,
      'status': account.status.name,
      'expiration': account.expirationDate?.millisecondsSinceEpoch,
      'created_at': account.createdAt.millisecondsSinceEpoch,
      'last_error': account.lastError,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<XtreamAccount>> getAccounts() async {
    final db = await _db;
    final rows = await db.query('iptv_accounts');
    return rows
        .map(
          (row) => XtreamAccount(
            id: row['account_id'] as String,
            alias: row['alias'] as String,
            endpoint: XtreamEndpoint.parse(row['endpoint'] as String),
            username: row['username'] as String,
            password: row['password'] as String,
            status: XtreamAccountStatus.values.firstWhere(
              (status) => status.name == row['status'],
              orElse: () => XtreamAccountStatus.pending,
            ),
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              row['created_at'] as int,
            ),
            expirationDate: (row['expiration'] as int?) != null
                ? DateTime.fromMillisecondsSinceEpoch(row['expiration'] as int)
                : null,
            lastError: row['last_error'] as String?,
          ),
        )
        .toList();
  }

  Future<void> removeAccount(String id) async {
    final db = await _db;
    await db.delete('iptv_accounts', where: 'account_id = ?', whereArgs: [id]);
    await db.delete('iptv_playlists', where: 'account_id = ?', whereArgs: [id]);
  }

  Future<void> savePlaylists(
    String accountId,
    List<XtreamPlaylist> playlists,
  ) async {
    final db = await _db;
    final batch = db.batch();
    for (final playlist in playlists) {
      batch.insert('iptv_playlists', {
        'account_id': accountId,
        'category_id': playlist.id,
        'payload': jsonEncode({
          'title': playlist.title,
          'type': playlist.type.name,
          'categoryId': playlist.id,
          'items': playlist.items
              .map(
                (item) => {
                  'streamId': item.streamId,
                  'title': item.title,
                  'poster': item.posterUrl,
                  'categoryName': item.categoryName,
                  'tmdbId': item.tmdbId,
                  'type': item.type.name,
                },
              )
              .toList(),
        }),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<XtreamPlaylist>> getPlaylists(String accountId) async {
    final db = await _db;
    final rows = await db.query(
      'iptv_playlists',
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
    return rows.map((row) {
      final payload =
          jsonDecode(row['payload'] as String) as Map<String, dynamic>;
      final items = (payload['items'] as List<dynamic>).map((item) {
        final type = XtreamPlaylistItemType.values.firstWhere(
          (t) => t.name == item['type'],
          orElse: () => XtreamPlaylistItemType.movie,
        );
        return XtreamPlaylistItem(
          accountId: accountId,
          categoryId: payload['categoryId']?.toString() ?? '',
          categoryName: item['categoryName']?.toString() ?? '',
          streamId: (item['streamId'] as num).toInt(),
          title: item['title']?.toString() ?? '',
          type: type,
          // >>> ajoute ces champs <<<
          tmdbId: (item['tmdbId'] as num?)?.toInt(),
          posterUrl: item['poster'] as String?,
          // si tu as aussi rating/releaseYear dans le payload, mappe-les ici :
          // rating: (item['rating'] as num?)?.toDouble(),
          // releaseYear: (item['releaseYear'] as num?)?.toInt(),
        );
      }).toList();

      return XtreamPlaylist(
        id: row['category_id'] as String,
        accountId: accountId,
        title: payload['title'] as String? ?? '',
        type: XtreamPlaylistType.values.firstWhere(
          (type) => type.name == payload['type'],
          orElse: () => XtreamPlaylistType.movies,
        ),
        items: items,
      );
    }).toList();
  }

  /// Build a set of available TMDB IDs across all accounts and playlists.
  /// Optionally filter by item [type] (movie or series).
  Future<Set<int>> getAvailableTmdbIds({XtreamPlaylistItemType? type}) async {
    final accounts = await getAccounts();
    final ids = <int>{};
    for (final account in accounts) {
      final playlists = await getPlaylists(account.id);
      for (final playlist in playlists) {
        for (final item in playlist.items) {
          if (item.tmdbId == null) continue;
          if (type != null && item.type != type) continue;
          ids.add(item.tmdbId!);
        }
      }
    }
    return ids;
  }
}
