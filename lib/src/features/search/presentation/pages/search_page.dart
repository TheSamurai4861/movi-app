// lib/src/features/search/presentation/pages/search_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
// ignore: unused_import
import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/features/search/presentation/providers/search_history_providers.dart';
import 'package:movi/src/features/search/presentation/providers/search_providers.dart';
import 'package:movi/src/features/search/presentation/widgets/genres_grid.dart';
import 'package:movi/src/features/search/presentation/widgets/watch_providers_grid.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';

/// SearchPage (version "content-only" pour être hostée par le Shell).
///
/// ✅ Changements clés vs l'ancienne version:
/// - Pas de Scaffold/SafeArea ici (le Shell s’en charge).
/// - Pas de padding global fixe (le ShellContentHost doit gérer le padding).
/// - Ne reset pas la query au initState -> compatible retention (Home+Search).
/// - UI rebuild propre via listeners (text/focus) sans setState manuel lourd.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();

  bool _syncedFromState = false;

  bool get _hasQuery => _textCtrl.text.trim().length >= 3;

  @override
  void initState() {
    super.initState();

    // Charger l’historique une fois.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(searchHistoryControllerProvider.notifier).refresh());
    });

    // Rebuild quand focus/text change (utile pour basculer "history/results").
    _textCtrl.addListener(_onTextChangedLocal);
    _focusNode.addListener(_onFocusChangedLocal);
  }

  void _onTextChangedLocal() {
    if (!mounted) return;
    setState(() {});
  }

  void _onFocusChangedLocal() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _textCtrl.removeListener(_onTextChangedLocal);
    _focusNode.removeListener(_onFocusChangedLocal);
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final state = ref.watch(searchControllerProvider);
    final ctrl = ref.read(searchControllerProvider.notifier);

    // Retention-friendly: si on revient sur la page et que le controller a déjà
    // une query, on sync le TextField une seule fois.
    if (!_syncedFromState) {
      final existing = state.query.trim();
      if (existing.isNotEmpty && _textCtrl.text.trim() != existing) {
        _textCtrl.text = existing;
        _textCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _textCtrl.text.length),
        );
      }
      _syncedFromState = true;
    }

    // On ne met pas de Scaffold ici: le Shell fournit l’enveloppe.
    // On ajoute juste Material pour garantir Ink/Tooltip/Theme ok si besoin.
    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre (le ShellContentHost gère le padding global)
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                l10n.searchTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 16),

            // Champ de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SearchField(
                controller: _textCtrl,
                focusNode: _focusNode,
                hintText: l10n.searchHint,
                clearTooltip: l10n.clear,
                onChanged: (value) {
                // Toujours synchroniser la query du contrôleur
                ctrl.setQuery(value);

                // Quand on repasse sous 3 caractères -> on re-charge l’historique
                if (value.trim().length < 3) {
                  unawaited(
                    ref.read(searchHistoryControllerProvider.notifier).refresh(),
                  );
                }
              },
              onClear: () {
                _textCtrl.clear();
                ctrl.setQuery('');
                unawaited(
                  ref.read(searchHistoryControllerProvider.notifier).refresh(),
                );
                // Garder le focus pour enchaîner directement
                _focusNode.requestFocus();
              },
              onSubmitted: (value) {
                // "Search" clavier -> déclencher explicitement
                ctrl.setQuery(value);
                FocusScope.of(context).unfocus();
              },
              ),
            ),

            const SizedBox(height: 32),

            // ======= HISTORIQUE OU RÉSULTATS =======
            if (!_hasQuery && _focusNode.hasFocus) ...[
              _SearchHistoryList(
                onSelect: (q) {
                  _textCtrl.text = q;
                  _textCtrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: _textCtrl.text.length),
                  );

                  // Déclenche la recherche sans effacer immédiatement l’UI
                  ctrl.setQuery(q);

                  // Sur TV/desktop: on peut retirer le focus pour voir la liste
                  FocusScope.of(context).unfocus();
                },
              ),
              const Expanded(child: SizedBox.shrink()),
            ] else if (!_hasQuery) ...[
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: const [
                    WatchProvidersGrid(),
                    SizedBox(height: 32),
                    GenresGrid(),
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ] else if (state.isLoading) ...[
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ] else if (state.error != null) ...[
              Expanded(
                child: Center(
                  child: Text(
                    state.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    final q = _textCtrl.text.trim();
                    if (q.length < 3) {
                      await ref
                          .read(searchHistoryControllerProvider.notifier)
                          .refresh();
                      return;
                    }
                    ctrl.setQuery(q);
                  },
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (state.movies.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        MoviItemsList(
                          title: l10n.moviesTitle,
                          subtitle: l10n.resultsCount(state.movies.length),
                          estimatedItemWidth: 150,
                          estimatedItemHeight: 300,
                          titlePadding: 0,
                          horizontalPadding: EdgeInsets.zero,
                          items: state.movies
                              .take(10)
                              .toList()
                              .asMap()
                              .entries
                              .map(
                                (entry) => _AnimatedMovieCard(
                                  media: MoviMedia(
                                    id: entry.value.id.value,
                                    title: entry.value.title.display,
                                    poster: entry.value.poster,
                                    year: entry.value.releaseYear,
                                    type: MoviMediaType.movie,
                                  ),
                                  onTap: (mm) => navigateToMovieDetail(
                                    context,
                                    ref,
                                    ContentRouteArgs.movie(mm.id),
                                  ),
                                  delay: Duration(milliseconds: entry.key * 100),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                      if (state.shows.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        MoviItemsList(
                          title: l10n.seriesTitle,
                          subtitle: l10n.resultsCount(state.shows.length),
                          estimatedItemWidth: 150,
                          estimatedItemHeight: 300,
                          titlePadding: 0,
                          horizontalPadding: EdgeInsets.zero,
                          items: state.shows
                              .take(10)
                              .toList()
                              .asMap()
                              .entries
                              .map(
                                (entry) => _AnimatedMovieCard(
                                  media: MoviMedia(
                                    id: entry.value.id.value,
                                    title: entry.value.title.display,
                                    poster: entry.value.poster,
                                    type: MoviMediaType.series,
                                  ),
                                  onTap: (mm) => navigateToTvDetail(
                                    context,
                                    ref,
                                    ContentRouteArgs.series(mm.id),
                                  ),
                                  delay: Duration(milliseconds: entry.key * 100),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                      if (state.people.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        MoviItemsList(
                          title: l10n.searchPeopleTitle,
                          subtitle: l10n.resultsCount(state.people.length),
                          estimatedItemWidth: 150,
                          estimatedItemHeight: 300,
                          titlePadding: 0,
                          horizontalPadding: EdgeInsets.zero,
                          items: state.people
                              .take(10)
                              .toList()
                              .asMap()
                              .entries
                              .map(
                                (entry) => _AnimatedPersonCard(
                                  person: MoviPerson(
                                    id: entry.value.id.value,
                                    name: entry.value.name,
                                    poster: entry.value.photo,
                                    role: l10n.personRoleActor,
                                  ),
                                  onTap: (p) => context.push(
                                    AppRouteNames.person,
                                    extra: entry.value,
                                  ),
                                  delay: Duration(milliseconds: entry.key * 100),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                      if (state.sagas.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, _) {
                            final filteredSagasAsync =
                                ref.watch(filteredSagasProvider(state.sagas));
                            return filteredSagasAsync.when(
                              data: (filteredSagas) {
                                if (filteredSagas.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return MoviItemsList(
                                  title: l10n.searchSagasTitle,
                                  subtitle: l10n.resultsCount(filteredSagas.length),
                                  estimatedItemWidth: 150,
                                  estimatedItemHeight: 300,
                                  titlePadding: 0,
                                  horizontalPadding: EdgeInsets.zero,
                                  items: filteredSagas
                                      .take(10)
                                      .toList()
                                      .asMap()
                                      .entries
                                      .map(
                                        (entry) => _AnimatedSagaCard(
                                          saga: entry.value,
                                          delay: Duration(
                                            milliseconds: entry.key * 100,
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          },
                        ),
                      ],
                      if (state.movies.isEmpty &&
                          state.shows.isEmpty &&
                          state.people.isEmpty &&
                          state.sagas.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              l10n.noResults,
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.clearTooltip,
    required this.onChanged,
    required this.onClear,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final String clearTooltip;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Image.asset(
            'assets/icons/search.png',
            width: 25,
            height: 25,
          ),
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Image.asset(
                  'assets/icons/supprimer.png',
                  width: 25,
                  height: 25,
                ),
                onPressed: onClear,
                tooltip: clearTooltip,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      ),
    );
  }
}

class _AnimatedPersonCard extends StatefulWidget {
  const _AnimatedPersonCard({
    required this.person,
    required this.onTap,
    required this.delay,
  });

  final MoviPerson person;
  final void Function(MoviPerson) onTap;
  final Duration delay;

  @override
  State<_AnimatedPersonCard> createState() => _AnimatedPersonCardState();
}

class _AnimatedPersonCardState extends State<_AnimatedPersonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _translateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _translateAnimation = Tween<double>(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _translateAnimation.value),
            child: MoviPersonCard(person: widget.person, onTap: widget.onTap),
          ),
        );
      },
    );
  }
}

class _AnimatedMovieCard extends StatefulWidget {
  const _AnimatedMovieCard({
    required this.media,
    required this.onTap,
    required this.delay,
  });

  final MoviMedia media;
  final void Function(MoviMedia) onTap;
  final Duration delay;

  @override
  State<_AnimatedMovieCard> createState() => _AnimatedMovieCardState();
}

class _AnimatedMovieCardState extends State<_AnimatedMovieCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _translateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _translateAnimation = Tween<double>(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _translateAnimation.value),
            child: MoviMediaCard(media: widget.media, onTap: widget.onTap),
          ),
        );
      },
    );
  }
}

class _SearchHistoryList extends ConsumerWidget {
  const _SearchHistoryList({required this.onSelect});

  final void Function(String query) onSelect;

  Widget _buildHistorySection(
    BuildContext context,
    WidgetRef ref,
    Widget child, {
    required bool hasItems,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.historyTitle, style: theme.textTheme.titleLarge),
            if (hasItems)
              TextButton(
                onPressed: () {
                  ref.read(searchHistoryControllerProvider.notifier).clearAll();
                },
                child: Text(l10n.actionClearHistory),
              ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final history = ref.watch(searchHistoryControllerProvider);

    return history.when(
      data: (items) {
        final sorted = [...items]..sort((a, b) => b.savedAt.compareTo(a.savedAt));

        return _buildHistorySection(
          context,
          ref,
          sorted.isEmpty
              ? Text(
                  l10n.historyEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  itemBuilder: (context, index) {
                    final h = sorted[index];
                    return SizedBox(
                      height: 55,
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => onSelect(h.query),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  h.query,
                                  style: theme.textTheme.bodyLarge,
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
                            tooltip: l10n.delete,
                          ),
                        ],
                      ),
                    );
                  },
                ),
          hasItems: sorted.isNotEmpty,
        );
      },
      loading: () => _buildHistorySection(
        context,
        ref,
        const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
        hasItems: false,
      ),
      error: (_, __) => _buildHistorySection(
        context,
        ref,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.errorUnknown,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => ref
                  .read(searchHistoryControllerProvider.notifier)
                  .refresh(),
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(l10n.actionRetry),
            ),
          ],
        ),
        hasItems: false,
      ),
    );
  }
}

class _AnimatedSagaCard extends StatefulWidget {
  const _AnimatedSagaCard({required this.saga, required this.delay});

  final SagaSummary saga;
  final Duration delay;

  @override
  State<_AnimatedSagaCard> createState() => _AnimatedSagaCardState();
}

class _AnimatedSagaCardState extends State<_AnimatedSagaCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _translateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _translateAnimation = Tween<double>(begin: 15.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _translateAnimation.value),
            child: _SagaCard(saga: widget.saga),
          ),
        );
      },
    );
  }
}

class _SagaCard extends StatelessWidget {
  const _SagaCard({required this.saga});

  final SagaSummary saga;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textStyle = theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    return GestureDetector(
      onTap: () => context.push(AppRouteNames.sagaDetail, extra: saga.id.value),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildPosterImage(saga.cover, 150, 225),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 150,
              child: Text(
                saga.title.display,
                style: textStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterImage(Uri? poster, double width, double height) {
    if (poster == null) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFF222222),
        child: const Center(
          child: Icon(Icons.broken_image, size: 32, color: Colors.white54),
        ),
      );
    }

    final source = poster.toString().trim();
    if (source.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFF222222),
        child: const Center(
          child: Icon(Icons.broken_image, size: 32, color: Colors.white54),
        ),
      );
    }

    final scheme = poster.scheme.toLowerCase();
    if (scheme == 'http' || scheme == 'https') {
      return Image.network(
        poster.toString(),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: const Color(0xFF222222),
          child: const Center(
            child: Icon(Icons.broken_image, size: 32, color: Colors.white54),
          ),
        ),
        gaplessPlayback: true,
        filterQuality: FilterQuality.low,
        cacheWidth: (width * 2).toInt(),
        cacheHeight: (height * 2).toInt(),
      );
    }

    final assetPath = scheme == 'asset' ? poster.path : source;
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: const Color(0xFF222222),
        child: const Center(
          child: Icon(Icons.broken_image, size: 32, color: Colors.white54),
        ),
      ),
      cacheWidth: (width * 2).toInt(),
      cacheHeight: (height * 2).toInt(),
    );
  }
}
