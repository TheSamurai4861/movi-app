// lib/src/features/category_browser/data/datasources/category_local_data_source.dart

import 'package:movi/src/features/iptv/application/iptv_catalog_reader.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/category_browser/domain/value_objects/category_key.dart';
import 'package:movi/src/features/category_browser/domain/value_objects/paginated_result.dart';

/// DataSource local pour les catégories IPTV.
///
/// Responsable de :
/// - déléguer à `IptvCatalogReader` la récupération des éléments,
/// - mettre en cache les résultats pour éviter des rechargements complets
///   répétés sur les mêmes catégories.
class CategoryLocalDataSource {
  CategoryLocalDataSource(this._catalogReader);

  final IptvCatalogReader _catalogReader;

  /// Cache avec timestamp pour invalidation TTL.
  /// Structure: clé de catégorie -> (liste d'items, timestamp de création).
  final Map<CategoryKey, _CachedItems> _cache = <CategoryKey, _CachedItems>{};

  /// Durée de vie du cache en millisecondes (30 minutes par défaut).
  static const int _cacheTtlMs = 30 * 60 * 1000;

  /// Nombre maximum d'entrées dans le cache (50 par défaut).
  /// Si le cache dépasse cette limite, les entrées les plus anciennes sont supprimées.
  static const int _maxCacheEntries = 50;

  /// Récupère toutes les références de contenu pour une catégorie donnée.
  ///
  /// Utilise un cache en mémoire avec TTL pour limiter les appels répétés.
  /// Le cache est invalidé automatiquement après [ _cacheTtlMs] millisecondes.
  Future<List<ContentReference>> listItems(CategoryKey key) async {
    final cached = _cache[key];
    final now = DateTime.now().millisecondsSinceEpoch;

    // Vérifier si le cache est valide (existe et n'est pas expiré)
    if (cached != null &&
        (now - cached.timestamp) < _cacheTtlMs &&
        cached.items.isNotEmpty) {
      return cached.items;
    }

    // Charger depuis le catalogue
    final items = await _catalogReader.listCategory(key);

    // Nettoyer le cache si nécessaire (limite de taille)
    _cleanCacheIfNeeded();

    // Mettre à jour le cache
    _cache[key] = _CachedItems(items, now);

    return items;
  }

  /// Récupère une page d'items pour une catégorie donnée.
  ///
  /// La pagination est appliquée sur les données présentes dans le cache
  /// (ou fraîchement chargées), afin de ne pas remonter toute la liste
  /// jusqu'à la couche présentation.
  Future<PaginatedResult<ContentReference>> listItemsPage(
    CategoryKey key, {
    required int page,
    required int pageSize,
  }) async {
    if (page < 1) page = 1;
    if (pageSize <= 0) {
      return const PaginatedResult<ContentReference>(
        items: <ContentReference>[],
        page: 1,
        hasMore: false,
        totalCount: 0,
      );
    }

    final cached = _cache[key];
    final now = DateTime.now().millisecondsSinceEpoch;

    List<ContentReference> items;

    if (cached != null &&
        (now - cached.timestamp) < _cacheTtlMs &&
        cached.items.isNotEmpty) {
      items = cached.items;
    } else {
      // Charger depuis le catalogue et mettre en cache.
      final loaded = await _catalogReader.listCategory(key);

      _cleanCacheIfNeeded();
      _cache[key] = _CachedItems(loaded, now);
      items = loaded;
    }

    final total = items.length;
    if (total == 0) {
      return PaginatedResult<ContentReference>(
        items: const <ContentReference>[],
        page: page,
        hasMore: false,
        totalCount: 0,
      );
    }

    final startIndex = (page - 1) * pageSize;
    if (startIndex >= total) {
      return PaginatedResult<ContentReference>(
        items: const <ContentReference>[],
        page: page,
        hasMore: false,
        totalCount: total,
      );
    }

    final endIndex = (startIndex + pageSize) > total
        ? total
        : (startIndex + pageSize);
    final slice = items.sublist(startIndex, endIndex);
    final hasMore = endIndex < total;

    return PaginatedResult<ContentReference>(
      items: slice,
      page: page,
      hasMore: hasMore,
      totalCount: total,
    );
  }

  /// Nettoie le cache si le nombre d'entrées dépasse [_maxCacheEntries].
  /// Supprime les entrées les plus anciennes en premier (FIFO simple).
  void _cleanCacheIfNeeded() {
    if (_cache.length < _maxCacheEntries) return;

    // Trouver la clé avec le timestamp le plus ancien
    CategoryKey? oldestKey;
    int oldestTimestamp = DateTime.now().millisecondsSinceEpoch;

    for (final entry in _cache.entries) {
      if (entry.value.timestamp < oldestTimestamp) {
        oldestTimestamp = entry.value.timestamp;
        oldestKey = entry.key;
      }
    }

    // Supprimer l'entrée la plus ancienne
    if (oldestKey != null) {
      _cache.remove(oldestKey);
    }
  }

  /// Vide complètement le cache.
  /// Utile pour forcer un rechargement complet lors d'un refresh global.
  void clearCache() {
    _cache.clear();
  }
}

/// Entrée de cache avec timestamp.
class _CachedItems {
  _CachedItems(this.items, this.timestamp);

  final List<ContentReference> items;
  final int timestamp;
}
