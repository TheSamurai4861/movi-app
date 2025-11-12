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
    } catch (_) {
      return 'search_history_default';
    }
  }

  Future<void> add(String query) async {
    final now = DateTime.now().toUtc();
    final item = {'q': query, 't': now.toIso8601String()};
    final key = await _userScopedKey();
    final existing = await _cache.get(key);
    final list = List<Map<String, dynamic>>.from(
      (existing?['items'] as List?) ?? const <Map<String, dynamic>>[],
    );
    // Remove duplicates
    list.removeWhere((e) => e['q'] == query);
    list.insert(0, item);
    // Keep max 20
    while (list.length > 20) {
      list.removeLast();
    }
    await _cache.put(key: key, type: _type, payload: {'items': list});
  }

  Future<List<SearchHistoryItem>> list() async {
    final key = await _userScopedKey();
    final map = await _cache.get(key);
    if (map == null) return [];
    final list = ((map['items'] as List?) ?? const <Map<String, dynamic>>[])
        .cast<Map<String, dynamic>>();
    return list
        .map(
          (e) => SearchHistoryItem(
            query: (e['q'] as String?) ?? '',
            savedAt:
                DateTime.tryParse((e['t'] as String?) ?? '')?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          ),
        )
        .where((i) => i.query.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> remove(String query) async {
    final key = await _userScopedKey();
    final existing = await _cache.get(key);
    if (existing == null) return;
    final list = List<Map<String, dynamic>>.from(
      (existing['items'] as List?) ?? const <Map<String, dynamic>>[],
    );
    list.removeWhere((e) => e['q'] == query);
    await _cache.put(key: key, type: _type, payload: {'items': list});
  }
}
