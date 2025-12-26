// lib/src/features/search/data/datasources/search_history_local_data_source.dart
import 'dart:developer' as dev;

import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/search/domain/entities/search_history_item.dart';

class SearchHistoryLocalDataSource {
  SearchHistoryLocalDataSource(this._cache);

  final ContentCacheRepository _cache;

  static const String _type = 'search';

  // Clé d'historique scoped par utilisateur (fallback sur 'default').
  Future<String> _userScopedKey() async {
    try {
      final profile = await _cache.get('user_profile');
      final name = (profile?['firstName'] as String?)?.trim().toLowerCase();
      final suffix = (name != null && name.isNotEmpty) ? name : 'default';
      return 'search_history_$suffix';
    } catch (e, st) {
      dev.log(
        '[SearchHistoryLocalDataSource] _userScopedKey: fallback default (error: $e)',
        stackTrace: st,
      );
      return 'search_history_default';
    }
  }

  Future<void> add(String query) async {
    try {
      final now = DateTime.now().toUtc();
      final item = {'q': query, 't': now.toIso8601String()};
      final key = await _userScopedKey();

      final existing = await _safeGet(key);
      final list = _decodeItems(existing);

      // Remove duplicates
      list.removeWhere((e) => e['q'] == query);
      list.insert(0, item);

      // Keep max 20
      while (list.length > 20) {
        list.removeLast();
      }

      await _cache.put(key: key, type: _type, payload: {'items': list});
    } catch (e, st) {
      dev.log(
        '[SearchHistoryLocalDataSource] add("$query") failed: $e',
        stackTrace: st,
      );
      // On n'échoue pas vers l’UI : on ignore l’erreur.
    }
  }

  Future<List<SearchHistoryItem>> list() async {
    try {
      final key = await _userScopedKey();
      final map = await _safeGet(key);
      if (map == null) return const [];

      final rawItems = _decodeItems(map);

      return rawItems
          .map(
            (e) => SearchHistoryItem(
              query: (e['q'] as String?)?.trim() ?? '',
              savedAt: _parseDate(e['t']),
            ),
          )
          .where((i) => i.query.isNotEmpty)
          .toList(growable: false);
    } catch (e, st) {
      dev.log(
        '[SearchHistoryLocalDataSource] list() failed, returning []. Error: $e',
        stackTrace: st,
      );
      return const [];
    }
  }

  Future<void> remove(String query) async {
    try {
      final key = await _userScopedKey();
      final existing = await _safeGet(key);
      if (existing == null) return;

      final list = _decodeItems(existing);
      list.removeWhere((e) => e['q'] == query);

      await _cache.put(key: key, type: _type, payload: {'items': list});
    } catch (e, st) {
      dev.log(
        '[SearchHistoryLocalDataSource] remove("$query") failed: $e',
        stackTrace: st,
      );
      // Là aussi, on ne remonte pas l'erreur à l'UI.
    }
  }

  Future<void> clear() async {
    try {
      final key = await _userScopedKey();
      await _cache.put(key: key, type: _type, payload: {'items': []});
    } catch (e, st) {
      dev.log(
        '[SearchHistoryLocalDataSource] clear() failed: $e',
        stackTrace: st,
      );
    }
  }

  // --- Helpers privés -------------------------------------------------------

  Future<Map<String, dynamic>?> _safeGet(String key) async {
    try {
      final value = await _cache.get(key);
      if (value == null) return null;
      return value;
    } catch (e, st) {
      dev.log(
        '[SearchHistoryLocalDataSource] _safeGet("$key") failed: $e',
        stackTrace: st,
      );
      return null;
    }
  }

  /// Transforme `map['items']` en `List<Map<String, dynamic>>` safe.
  List<Map<String, dynamic>> _decodeItems(Map<String, dynamic>? map) {
    final result = <Map<String, dynamic>>[];

    if (map == null) return result;

    final raw = map['items'];
    if (raw is! List) return result;

    for (final item in raw) {
      if (item is Map) {
        try {
          result.add(item.cast<String, dynamic>());
        } catch (e, st) {
          dev.log(
            '[SearchHistoryLocalDataSource] _decodeItems: cast error for $item: $e',
            stackTrace: st,
          );
        }
      }
    }

    return result;
  }

  DateTime _parseDate(dynamic input) {
    final s = input as String?;
    if (s == null || s.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.tryParse(s)?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
