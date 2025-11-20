import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/search/data/dtos/tmdb_watch_provider_dto.dart';

class SearchLocalDataSource {
  SearchLocalDataSource(this._cache);

  final ContentCacheRepository _cache;

  static const String _watchProvidersKeyPrefix = 'watch_providers_';
  static const Duration _watchProvidersTtl = Duration(days: 1);

  Future<List<TmdbWatchProviderDto>?> getWatchProviders(String region) async {
    final key = '$_watchProvidersKeyPrefix$region';
    final data = await _cache.get(key);
    
    if (data == null) return null;
    
    final timestampStr = data['timestamp'] as String?;
    if (timestampStr == null) return null;
    
    final timestamp = DateTime.tryParse(timestampStr);
    if (timestamp == null) return null;
    
    if (DateTime.now().difference(timestamp) > _watchProvidersTtl) {
      await _cache.remove(key);
      return null;
    }

    final list = data['providers'] as List<dynamic>?;
    if (list == null) return null;

    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => TmdbWatchProviderDto.fromJson(json))
        .toList();
  }

  Future<void> cacheWatchProviders(String region, List<TmdbWatchProviderDto> providers) async {
    final key = '$_watchProvidersKeyPrefix$region';
    final jsonList = providers.map((dto) => dto.toJson()).toList();
    
    await _cache.put(
      key: key,
      type: 'watch_providers',
      payload: {
        'timestamp': DateTime.now().toIso8601String(),
        'providers': jsonList,
      },
    );
  }
}
