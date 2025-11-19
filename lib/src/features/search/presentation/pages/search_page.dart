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
import 'package:movi/src/features/search/presentation/widgets/watch_providers_grid.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();

  bool get _hasQuery => _textCtrl.text.trim().length >= 3;

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    // Écouter les changements de focus pour mettre à jour l'UI
    _focusNode.addListener(_onFocusChange);
    // Charger une première fois l'historique + forcer une query vide.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(searchHistoryControllerProvider.notifier).refresh());
      ref.read(searchControllerProvider.notifier).setQuery('');
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _textCtrl.dispose();
    _focusNode.dispose();
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
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Builder(
                  builder: (context) {
                    final colorScheme = Theme.of(context).colorScheme;
                    return TextField(
                      controller: _textCtrl,
                      focusNode: _focusNode,
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
                          padding: const EdgeInsets.only(left: 12, right: 8),
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
                                          searchHistoryControllerProvider
                                              .notifier,
                                        )
                                        .refresh(),
                                  );
                                },
                                tooltip: AppLocalizations.of(context)!.clear,
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // ======= HISTORIQUE OU RÉSULTATS =======
              if (!_hasQuery && _focusNode.hasFocus) ...[
                _SearchHistoryList(
                  onSelect: (q) {
                    _textCtrl.text = q;
                    ctrl.setQueryImmediate(q);
                  },
                ),
                const Expanded(child: SizedBox.shrink()),
              ] else if (!_hasQuery) ...[
                const WatchProvidersGrid(),
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
                                  onTap: (mm) => context.push(
                                    AppRouteNames.movie,
                                    extra: mm,
                                  ),
                                  delay: Duration(
                                    milliseconds: entry.key * 100,
                                  ),
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
                                  onTap: (mm) =>
                                      context.push(AppRouteNames.tv, extra: mm),
                                  delay: Duration(
                                    milliseconds: entry.key * 100,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                      if (state.people.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        MoviItemsList(
                          title: AppLocalizations.of(context)!.searchPeopleTitle,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.resultsCount(state.people.length),
                          estimatedItemWidth: 150,
                          estimatedItemHeight: 300,
                          titlePadding: 20,
                          horizontalPadding: const EdgeInsetsDirectional.only(
                            start: 20,
                            end: 20,
                          ),
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
                                    role: AppLocalizations.of(context)!.personRoleActor,
                                  ),
                                  onTap: (p) => context.push(
                                    AppRouteNames.person,
                                    extra: entry.value,
                                  ),
                                  delay: Duration(
                                    milliseconds: entry.key * 100,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                      if (state.sagas.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, _) {
                            final filteredSagasAsync = ref.watch(
                              filteredSagasProvider(state.sagas),
                            );
                            return filteredSagasAsync.when(
                              data: (filteredSagas) {
                                if (filteredSagas.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return MoviItemsList(
                                  title: AppLocalizations.of(context)!.searchSagasTitle,
                                  subtitle: AppLocalizations.of(
                                    context,
                                  )!.resultsCount(filteredSagas.length),
                                  estimatedItemWidth: 150,
                                  estimatedItemHeight: 300,
                                  titlePadding: 20,
                                  horizontalPadding:
                                      const EdgeInsetsDirectional.only(
                                        start: 20,
                                        end: 20,
                                      ),
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

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _translateAnimation = Tween<double>(
      begin: 15.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
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

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _translateAnimation = Tween<double>(
      begin: 15.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.historyTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              if (hasItems)
                TextButton(
                  onPressed: () {
                    ref
                        .read(searchHistoryControllerProvider.notifier)
                        .clearAll();
                  },
                  child: Text(
                    AppLocalizations.of(context)!.actionClearHistory,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ),
            ],
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
          ref,
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
          hasItems: sorted.isNotEmpty,
        );
      },
      loading: () => _buildHistorySection(
        context,
        ref,
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        hasItems: false,
      ),
      error: (_, __) => _buildHistorySection(
        context,
        ref,
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

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _translateAnimation = Tween<double>(
      begin: 15.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
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
    final textStyle =
        theme.textTheme.titleSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        );

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
