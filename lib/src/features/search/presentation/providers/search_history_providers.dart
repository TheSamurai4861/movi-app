import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/search/domain/entities/search_history_item.dart';
import 'package:movi/src/features/search/domain/repositories/search_history_repository.dart';
import 'package:movi/src/features/search/domain/usecases/add_search_query_to_history.dart';
import 'package:movi/src/features/search/domain/usecases/list_search_history.dart';
import 'package:movi/src/features/search/domain/usecases/remove_search_history_item.dart';

/// Repository résolu via le service locator.
final searchHistoryRepositoryProvider = Provider<SearchHistoryRepository>((
  ref,
) {
  final locator = ref.watch(slProvider);
  return locator<SearchHistoryRepository>();
});

/// Contrôleur d’historique basé sur AsyncNotifier.
/// Ne met JAMAIS l’état en AsyncError : en cas de souci, on renvoie
/// soit la liste précédente, soit [].
class SearchHistoryController extends AsyncNotifier<List<SearchHistoryItem>> {
  late final SearchHistoryRepository _repo;
  late final ListSearchHistory _listHistory;
  late final RemoveSearchHistoryItem _removeHistory;
  late final AddSearchQueryToHistory _addHistory;

  @override
  Future<List<SearchHistoryItem>> build() async {
    _repo = ref.watch(searchHistoryRepositoryProvider);
    _listHistory = ListSearchHistory(_repo);
    _removeHistory = RemoveSearchHistoryItem(_repo);
    _addHistory = AddSearchQueryToHistory(_repo);

    // Chargement initial avec protection.
    final items = await _safeLoad();
    return items;
  }

  /// Ajout d’une query à l’historique puis rechargement.
  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    try {
      await _addHistory(trimmed);
      await refresh();
    } catch (e, st) {
      dev.log(
        '[SearchHistoryController] add("$trimmed") failed: $e',
        stackTrace: st,
      );
      // On ne met pas l’état en erreur : l’UI garde l’ancien historique.
    }
  }

  /// Suppression d'une query de l'historique puis rechargement.
  Future<void> remove(String query) async {
    try {
      await _removeHistory(query);
      await refresh();
    } catch (e, st) {
      dev.log(
        '[SearchHistoryController] remove("$query") failed: $e',
        stackTrace: st,
      );
      // Là non plus, on ne touche pas à l'état en cas d'erreur.
    }
  }

  /// Suppression de tout l'historique puis rechargement.
  Future<void> clearAll() async {
    try {
      await _repo.clear();
      await refresh();
    } catch (e, st) {
      dev.log(
        '[SearchHistoryController] clearAll() failed: $e',
        stackTrace: st,
      );
    }
  }

  /// Recharge l’historique sans exposer AsyncError à l’UI.
  Future<void> refresh() async {
    final previous = state;

    // Optionnel : afficher un spinner; sinon tu peux commenter cette ligne.
    state = const AsyncValue.loading();

    final items = await _safeLoad(fallback: previous);
    state = AsyncValue.data(items);
  }

  // ---------------------------------------------------------------------------
  // Helpers privés
  // ---------------------------------------------------------------------------

  /// Charge la liste depuis le usecase, en gérant les exceptions.
  ///
  /// - En cas de succès: retourne la liste chargée.
  /// - En cas d’erreur: log + retourne soit la valeur précédente, soit [].
  Future<List<SearchHistoryItem>> _safeLoad({
    AsyncValue<List<SearchHistoryItem>>? fallback,
  }) async {
    try {
      final items = await _listHistory();
      return items;
    } catch (e, st) {
      dev.log(
        '[SearchHistoryController] _safeLoad() failed: $e',
        stackTrace: st,
      );

      if (fallback != null && fallback.hasValue) {
        return fallback.value!;
      }

      // Aucun état précédent valide → on repart sur une liste vide.
      return const <SearchHistoryItem>[];
    }
  }
}

/// Provider Riverpod exposé à l’UI.
final searchHistoryControllerProvider =
    AsyncNotifierProvider<SearchHistoryController, List<SearchHistoryItem>>(
      SearchHistoryController.new,
    );
