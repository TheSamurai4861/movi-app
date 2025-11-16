// lib/src/features/search/presentation/pages/search_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/models/models.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/features/search/presentation/providers/search_history_providers.dart';
import 'package:movi/src/features/search/presentation/providers/search_providers.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _textCtrl = TextEditingController();

  bool get _hasQuery => _textCtrl.text.trim().length >= 3;

  @override
  void initState() {
    super.initState();
    // Charger une première fois l’historique + forcer une query vide.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref.read(searchHistoryControllerProvider.notifier).refresh(),
      );
      ref.read(searchControllerProvider.notifier).setQuery('');
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    final ctrl = ref.read(searchControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                child: Text(
                  AppLocalizations.of(context)!.searchTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: TextField(
                  controller: _textCtrl,
                  onChanged: (value) {
                    // Toujours synchroniser la query du contrôleur
                    ctrl.setQuery(value);

                    // Quand on repasse sous 3 caractères → on revient en mode historique
                    if (value.trim().length < 3) {
                      unawaited(
                        ref
                            .read(searchHistoryControllerProvider.notifier)
                            .refresh(),
                      );
                    }
                  },
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchHint,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Image.asset(
                        'assets/icons/search.png',
                        width: 25,
                        height: 25,
                      ),
                    ),
                    suffixIcon: _textCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: Image.asset(
                              'assets/icons/supprimer.png',
                              width: 25,
                              height: 25,
                            ),
                            onPressed: () {
                              _textCtrl.clear();
                              ctrl.setQuery('');
                              unawaited(
                                ref
                                    .read(
                                      searchHistoryControllerProvider.notifier,
                                    )
                                    .refresh(),
                              );
                            },
                            tooltip: AppLocalizations.of(context)!.clear,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ======= HISTORIQUE OU RÉSULTATS =======
              if (!_hasQuery) ...[
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
                          title: AppLocalizations.of(context)!.moviesTitle,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.resultsCount(state.movies.length),
                          estimatedItemWidth: 150,
                          estimatedItemHeight: 300,
                          titlePadding: 20,
                          horizontalPadding: const EdgeInsetsDirectional.only(
                            start: 20,
                            end: 20,
                          ),
                          items: state.movies
                              .take(10)
                              .map(
                                (m) => MoviMediaCard(
                                  media: MoviMedia(
                                    id: m.id.value,
                                    title: m.title.display,
                                    poster: m.poster,
                                    year: m.releaseYear,
                                    type: MoviMediaType.movie,
                                  ),
                                  onTap: (mm) =>
                                      context.push(AppRouteNames.movie, extra: mm),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                      if (state.shows.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        MoviItemsList(
                          title: AppLocalizations.of(context)!.seriesTitle,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.resultsCount(state.shows.length),
                          estimatedItemWidth: 150,
                          estimatedItemHeight: 300,
                          titlePadding: 20,
                          horizontalPadding: const EdgeInsetsDirectional.only(
                            start: 20,
                            end: 20,
                          ),
                          items: state.shows
                              .take(10)
                              .map(
                                (s) => MoviMediaCard(
                                  media: MoviMedia(
                                    id: s.id.value,
                                    title: s.title.display,
                                    poster: s.poster,
                                    type: MoviMediaType.series,
                                  ),
                                  onTap: (mm) =>
                                      context.push(AppRouteNames.tv, extra: mm),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                      if (state.movies.isEmpty && state.shows.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              AppLocalizations.of(context)!.noResults,
                              style: const TextStyle(
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

  Widget _buildHistorySection(BuildContext context, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
          child: Text(
            AppLocalizations.of(context)!.historyTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(searchHistoryControllerProvider);

    return history.when(
      data: (items) {
        final sorted = [...items]
          ..sort((a, b) => b.savedAt.compareTo(a.savedAt));

        return _buildHistorySection(
          context,
          sorted.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                  child: Text(
                    AppLocalizations.of(context)!.historyEmpty,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF737373),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(left: 20, right: 20),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
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
                            tooltip: AppLocalizations.of(context)!.delete,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
      loading: () => _buildHistorySection(
        context,
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
      error: (_, __) => _buildHistorySection(
        context,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.errorUnknown,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => ref
                    .read(searchHistoryControllerProvider.notifier)
                    .refresh(),
                icon: const Icon(Icons.refresh, size: 20),
                label: Text(AppLocalizations.of(context)!.actionRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
