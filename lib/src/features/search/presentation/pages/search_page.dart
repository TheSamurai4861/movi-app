import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/features/search/presentation/providers/search_history_providers.dart';
import '../../../../core/widgets/movi_items_list.dart';
import '../../../../core/widgets/movi_media_card.dart';
import '../../../../core/models/movi_media.dart';
import '../../../search/presentation/providers/search_providers.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _textCtrl = TextEditingController();

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    final ctrl = ref.read(searchControllerProvider.notifier);
    final hasQuery = state.query.trim().length >= 3;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Recherche',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textCtrl,
                onChanged: (value) {
                  ctrl.setQuery(value);
                  if (value.trim().length < 3) {
                    // Rafraîchir l'historique dès que l'input passe sous 3 caractères
                    ref
                        .read(searchHistoryControllerProvider.notifier)
                        .refresh();
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Tapez votre recherche',
                  // Icône de recherche à gauche du placeholder
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Image.asset(
                      'assets/icons/search.png',
                      width: 25,
                      height: 25,
                    ),
                  ),
                  // Bouton suppression à droite uniquement si texte présent
                  suffixIcon: state.query.isNotEmpty
                      ? IconButton(
                          icon: Image.asset(
                            'assets/icons/supprimer.png',
                            width: 25,
                            height: 25,
                          ),
                          onPressed: () {
                            _textCtrl.clear();
                            ctrl.setQuery('');
                            // Assurer l’actualisation immédiate de l’historique après effacement
                            ref
                                .read(searchHistoryControllerProvider.notifier)
                                .refresh();
                          },
                          tooltip: 'Effacer',
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (!hasQuery) ...[
                _SearchHistoryList(
                  onSelect: (q) {
                    _textCtrl.text = q;
                    ctrl.setQuery(q);
                  },
                ),
                const Expanded(child: SizedBox.shrink()),
              ] else if (state.isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.error != null)
                Expanded(
                  child: Center(
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: [
                      if (state.movies.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        MoviItemsList(
                          title: 'Films',
                          subtitle: '(${state.movies.length} résultats)',
                          estimatedItemWidth: 150,
                          estimatedItemHeight: 300,
                          titlePadding: 0,
                          horizontalPadding: const EdgeInsetsDirectional.only(
                            start: 0,
                            end: 20,
                          ),
                          items: state.movies
                              .take(10)
                              .map(
                                (m) => MoviMediaCard(
                                  media: MoviMedia(
                                    id: m.id.value,
                                    title: m.title.display,
                                    poster: m.poster.toString(),
                                    year: (m.releaseYear?.toString() ?? '—'),
                                    rating: '—',
                                    type: MoviMediaType.movie,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                      if (state.shows.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        MoviItemsList(
                          title: 'Séries',
                          subtitle: '(${state.shows.length} résultats)',
                          estimatedItemWidth: 150,
                          estimatedItemHeight: 300,
                          titlePadding: 0,
                          horizontalPadding: const EdgeInsetsDirectional.only(
                            start: 0,
                            end: 20,
                          ),
                          items: state.shows
                              .take(10)
                              .map(
                                (s) => MoviMediaCard(
                                  media: MoviMedia(
                                    id: s.id.value,
                                    title: s.title.display,
                                    poster: s.poster.toString(),
                                    year: '—',
                                    rating: '—',
                                    type: MoviMediaType.series,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                      if (state.movies.isEmpty && state.shows.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Pas de résultats',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchHistoryList extends ConsumerWidget {
  const _SearchHistoryList({required this.onSelect});

  final void Function(String query) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(searchHistoryControllerProvider);
    return history.when(
      data: (items) {
        // Tri par plus récent
        final sorted = [...items]
          ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historique',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (sorted.isEmpty)
              const Text(
                'Aucune recherche récente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF737373),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFF737373),
                ),
                itemBuilder: (context, index) {
                  final h = sorted[index];
                  return SizedBox(
                    height: 55,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => onSelect(h.query),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                h.query,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Image.asset(
                            'assets/icons/supprimer.png',
                            width: 25,
                            height: 25,
                          ),
                          onPressed: () => ref
                              .read(searchHistoryControllerProvider.notifier)
                              .remove(h.query),
                          tooltip: 'Supprimer',
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
