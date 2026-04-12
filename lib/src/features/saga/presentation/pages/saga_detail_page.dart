import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/directional_edge.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/domain/focus_region_exit_map.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';

import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/saga/presentation/providers/saga_detail_providers.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';

class SagaDetailPage extends ConsumerStatefulWidget {
  const SagaDetailPage({super.key, required this.sagaId});

  final String sagaId;

  @override
  ConsumerState<SagaDetailPage> createState() => _SagaDetailPageState();
}

class _SagaDetailPageState extends ConsumerState<SagaDetailPage> {
  static const Color _iconActionFocusedBackground = Color(0x807A7A7A);
  static const double _heroFocusVerticalAlignment = 0.0;
  final FocusNode _primaryActionFocusNode = FocusNode(
    debugLabel: 'SagaDetailPrimaryAction',
  );
  final FocusNode _favoriteActionFocusNode = FocusNode(
    debugLabel: 'SagaDetailFavoriteAction',
  );
  final FocusNode _backFocusNode = FocusNode(debugLabel: 'SagaDetailBack');
  final List<FocusNode> _movieFocusNodes = <FocusNode>[];
  int? _lastFocusedMovieIndex;
  bool _didRequestEntryPrimaryFocus = false;

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    }
    return '${minutes}m';
  }

  Future<void> _playMovie(
    BuildContext context,
    WidgetRef ref,
    String movieId,
  ) async {
    navigateToMovieDetail(context, ref, ContentRouteArgs.movie(movieId));
  }

  Future<void> _startSaga(BuildContext context, WidgetRef ref) async {
    final startTarget = await ref.read(
      sagaStartTargetProvider(widget.sagaId).future,
    );
    if (!context.mounted) return;

    final movieId = startTarget.movieId;
    if (movieId != null && context.mounted) {
      await _playMovie(context, ref, movieId);
    }
  }

  ScreenType _screenTypeFor(BuildContext context) {
    final mq = MediaQuery.of(context);
    return ScreenTypeResolver.instance.resolve(
      mq.size.width,
      mq.size.height == 0 ? 1 : mq.size.height,
    );
  }

  bool _useDesktopDetailLayout(BuildContext context) {
    final screenType = _screenTypeFor(context);
    return screenType == ScreenType.desktop || screenType == ScreenType.tv;
  }

  double _sectionHorizontalPadding(BuildContext context) {
    return _useDesktopDetailLayout(context) ? 36 : 20;
  }

  @override
  void dispose() {
    _primaryActionFocusNode.dispose();
    _favoriteActionFocusNode.dispose();
    _backFocusNode.dispose();
    for (final node in _movieFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncMovieFocusNodes(int count) {
    while (_movieFocusNodes.length < count) {
      _movieFocusNodes.add(
        FocusNode(debugLabel: 'SagaMovie-${_movieFocusNodes.length}'),
      );
    }
    while (_movieFocusNodes.length > count) {
      _movieFocusNodes.removeLast().dispose();
    }
  }

  bool _requestMovieFocusAt(int index) {
    if (index < 0 || index >= _movieFocusNodes.length) return false;
    final node = _movieFocusNodes[index];
    if (node.context == null || !node.canRequestFocus) return false;
    node.requestFocus();
    return true;
  }

  void _requestPrimaryEntryFocusIfNeeded() {
    if (_didRequestEntryPrimaryFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_primaryActionFocusNode.context == null ||
          !_primaryActionFocusNode.canRequestFocus) {
        return;
      }
      _didRequestEntryPrimaryFocus = true;
      _primaryActionFocusNode.requestFocus();
    });
  }

  KeyEventResult _handlePrimaryActionKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _backFocusNode.requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final index = _lastFocusedMovieIndex ?? 0;
      _requestMovieFocusAt(index);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_favoriteActionFocusNode.context != null &&
          _favoriteActionFocusNode.canRequestFocus) {
        _favoriteActionFocusNode.requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleFavoriteActionKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _backFocusNode.requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _requestMovieFocusAt(0);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _primaryActionFocusNode.requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleMovieItemKey(
    int index,
    int totalCount,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_primaryActionFocusNode.context != null &&
          _primaryActionFocusNode.canRequestFocus) {
        _primaryActionFocusNode.requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (index == 0) {
        return KeyEventResult.handled;
      }
      _requestMovieFocusAt(index - 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      final next = index + 1;
      if (next >= totalCount) {
        return KeyEventResult.handled;
      }
      _requestMovieFocusAt(next);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleRouteBackKey(KeyEvent event, BuildContext context) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (!mounted || !context.mounted) return KeyEventResult.ignored;
      context.pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final sagaDetailAsync = ref.watch(sagaDetailProvider(widget.sagaId));
    final sagaStartTargetAsync = ref.watch(
      sagaStartTargetProvider(widget.sagaId),
    );
    final isFavoriteAsync = ref.watch(sagaIsFavoriteProvider(widget.sagaId));

    return SwipeBackWrapper(
      child: FocusRegionScope(
        regionId: AppFocusRegionId.sagaDetailPrimary,
        binding: FocusRegionBinding(
          resolvePrimaryEntryNode: () => _primaryActionFocusNode,
          resolveFallbackEntryNode: () => _backFocusNode,
        ),
        exitMap: FocusRegionExitMap({
          DirectionalEdge.left: AppFocusRegionId.shellSidebar,
        }),
        requestFocusOnMount: true,
        debugLabel: 'SagaDetailRegion',
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: (_, event) => _handleRouteBackKey(event, context),
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: SafeArea(
              top: true,
              bottom: true,
              child: sagaDetailAsync.when(
                loading: () => OverlaySplash(
                  message: AppLocalizations.of(
                    context,
                  )!.overlayPreparingMetadata,
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.errorWithMessage(error.toString()),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () =>
                            ref.refresh(sagaDetailProvider(widget.sagaId)),
                        child: Text(AppLocalizations.of(context)!.actionRetry),
                      ),
                    ],
                  ),
                ),
                data: (viewModel) {
                  _requestPrimaryEntryFocusIfNeeded();
                  final movies = viewModel.saga.timeline
                      .where(
                        (entry) => entry.reference.type == ContentType.movie,
                      )
                      .map((entry) {
                        final ref = entry.reference;
                        return MoviMedia(
                          id: ref.id,
                          title: ref.title.display,
                          poster: ref.poster,
                          year: entry.timelineYear,
                          type: MoviMediaType.movie,
                        );
                      })
                      .toList();

                  // Trier par année
                  movies.sort((a, b) {
                    final yearA = a.year ?? 0;
                    final yearB = b.year ?? 0;
                    return yearA.compareTo(yearB);
                  });
                  _syncMovieFocusNodes(movies.length);

                  final isWideLayout = _useDesktopDetailLayout(context);
                  final horizontalPadding = _sectionHorizontalPadding(context);
                  final synopsisText = viewModel.saga.synopsis?.value ?? '';
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (heroContext) =>
                              MoviVerticalEnsureVisibleTarget(
                                targetContext: heroContext,
                                child: MoviDetailHeroScene(
                                  isWideLayout: isWideLayout,
                                  background: _buildHeroImage(
                                    context,
                                    poster: viewModel.poster,
                                    backdrop: viewModel.backdrop,
                                  ),
                                  children: [
                                    if (isWideLayout)
                                      _buildDesktopHeroOverlay(
                                        context,
                                        ref,
                                        viewModel,
                                        sagaStartTargetAsync,
                                        isFavoriteAsync,
                                        synopsisText: synopsisText,
                                      ),
                                    _buildHeroTopBar(
                                      context,
                                      isWideLayout: isWideLayout,
                                      horizontalPadding: horizontalPadding,
                                    ),
                                  ],
                                ),
                              ),
                        ),
                        if (!isWideLayout)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 20,
                              end: 20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 16),
                                Text(
                                  viewModel.saga.title.display,
                                  style:
                                      Theme.of(
                                        context,
                                      ).textTheme.headlineMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ) ??
                                      const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${AppLocalizations.of(context)!.sagaMovieCount(viewModel.movieCount)} - ${_formatDuration(viewModel.totalDuration)}',
                                  style:
                                      Theme.of(context).textTheme.bodyLarge
                                          ?.copyWith(color: Colors.white70) ??
                                      const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: sagaStartTargetAsync.when(
                                        data: (startTarget) {
                                          return Focus(
                                            canRequestFocus: false,
                                            onKeyEvent: (_, event) =>
                                                _handlePrimaryActionKey(event),
                                            child: MoviPrimaryButton(
                                              focusNode:
                                                  _primaryActionFocusNode,
                                              label: startTarget.hasInProgress
                                                  ? AppLocalizations.of(
                                                      context,
                                                    )!.sagaContinue
                                                  : AppLocalizations.of(
                                                      context,
                                                    )!.sagaStartNow,
                                              assetIcon: AppAssets.iconPlay,
                                              onPressed: () =>
                                                  _startSaga(context, ref),
                                            ),
                                          );
                                        },
                                        loading: () => MoviPrimaryButton(
                                          label: AppLocalizations.of(
                                            context,
                                          )!.sagaStartNow,
                                          assetIcon: AppAssets.iconPlay,
                                          onPressed: () {},
                                        ),
                                        error: (_, __) => MoviPrimaryButton(
                                          label: AppLocalizations.of(
                                            context,
                                          )!.sagaStartNow,
                                          assetIcon: AppAssets.iconPlay,
                                          onPressed: () =>
                                              _startSaga(context, ref),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: isFavoriteAsync.when(
                                        data: (isFavorite) => Focus(
                                          canRequestFocus: false,
                                          onKeyEvent: (_, event) =>
                                              _handleFavoriteActionKey(event),
                                          child: MoviFavoriteButton(
                                            focusNode: _favoriteActionFocusNode,
                                            isFavorite: isFavorite,
                                            size: 44,
                                            iconSize: 28,
                                            focusPadding: const EdgeInsets.all(
                                              5,
                                            ),
                                            focusedBackgroundColor:
                                                _iconActionFocusedBackground,
                                            focusedBorderColor: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            borderWidth: 2,
                                            onPressed: () async {
                                              await ref
                                                  .read(
                                                    sagaToggleFavoriteProvider
                                                        .notifier,
                                                  )
                                                  .toggle(
                                                    widget.sagaId,
                                                    SagaSummary(
                                                      id: viewModel.saga.id,
                                                      tmdbId:
                                                          viewModel.saga.tmdbId,
                                                      title:
                                                          viewModel.saga.title,
                                                      cover: viewModel.poster,
                                                    ),
                                                  );
                                            },
                                          ),
                                        ),
                                        loading: () => MoviFavoriteButton(
                                          isFavorite: true,
                                          size: 44,
                                          iconSize: 28,
                                          focusPadding: const EdgeInsets.all(5),
                                          focusedBackgroundColor:
                                              _iconActionFocusedBackground,
                                          focusedBorderColor: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          borderWidth: 2,
                                          onPressed: () {},
                                        ),
                                        error: (_, __) => MoviFavoriteButton(
                                          isFavorite: true,
                                          size: 44,
                                          iconSize: 28,
                                          focusPadding: const EdgeInsets.all(5),
                                          focusedBackgroundColor:
                                              _iconActionFocusedBackground,
                                          focusedBorderColor: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          borderWidth: 2,
                                          onPressed: () {},
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 32),
                        // Liste des films
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: horizontalPadding,
                            end: horizontalPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.sagaMoviesList,
                                style:
                                    Theme.of(context).textTheme.titleLarge
                                        ?.copyWith(color: Colors.white) ??
                                    const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              // Liste horizontale des films
                              Consumer(
                                builder: (context, ref, _) {
                                  final availabilityAsync = ref.watch(
                                    sagaMoviesAvailabilityProvider(
                                      widget.sagaId,
                                    ),
                                  );
                                  return availabilityAsync.when(
                                    data: (availability) {
                                      return SizedBox(
                                        height: MoviMediaCard.listHeight,
                                        child: Builder(
                                          builder: (listContext) =>
                                              MoviVerticalEnsureVisibleTarget(
                                                targetContext: listContext,
                                                child: ListView.separated(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  clipBehavior: Clip.none,
                                                  padding: EdgeInsets.zero,
                                                  itemCount: movies.length,
                                                  separatorBuilder: (_, __) =>
                                                      const SizedBox(width: 16),
                                                  itemBuilder: (context, index) {
                                                    final movie = movies[index];
                                                    final movieId =
                                                        int.tryParse(movie.id);
                                                    final isAvailable =
                                                        movieId != null &&
                                                        (availability[movieId] ??
                                                            false);
                                                    return MoviEnsureVisibleOnFocus(
                                                      horizontalAlignment: 0.18,
                                                      verticalAlignment: 0.34,
                                                      child: _SagaMovieCard(
                                                        media: movie,
                                                        isAvailable:
                                                            isAvailable,
                                                        focusNode:
                                                            _movieFocusNodes[index],
                                                        onKeyEvent: (event) =>
                                                            _handleMovieItemKey(
                                                              index,
                                                              movies.length,
                                                              event,
                                                            ),
                                                        onFocusChange: (hasFocus) {
                                                          if (hasFocus) {
                                                            _lastFocusedMovieIndex =
                                                                index;
                                                          }
                                                        },
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                        ),
                                      );
                                    },
                                    loading: () => const SizedBox(
                                      height: MoviMediaCard.listHeight,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    error: (_, __) => SizedBox(
                                      height: MoviMediaCard.listHeight,
                                      child: Builder(
                                        builder: (listContext) =>
                                            MoviVerticalEnsureVisibleTarget(
                                              targetContext: listContext,
                                              child: ListView.separated(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                clipBehavior: Clip.none,
                                                padding: EdgeInsets.zero,
                                                itemCount: movies.length,
                                                separatorBuilder: (_, __) =>
                                                    const SizedBox(width: 16),
                                                itemBuilder: (context, index) {
                                                  final movie = movies[index];
                                                  return MoviEnsureVisibleOnFocus(
                                                    horizontalAlignment: 0.18,
                                                    verticalAlignment: 0.34,
                                                    child: _SagaMovieCard(
                                                      media: movie,
                                                      isAvailable: true,
                                                      focusNode:
                                                          _movieFocusNodes[index],
                                                      onKeyEvent: (event) =>
                                                          _handleMovieItemKey(
                                                            index,
                                                            movies.length,
                                                            event,
                                                          ),
                                                      onFocusChange: (hasFocus) {
                                                        if (hasFocus) {
                                                          _lastFocusedMovieIndex =
                                                              index;
                                                        }
                                                      },
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(
    BuildContext context, {
    required Uri? poster,
    required Uri? backdrop,
  }) {
    return MoviHeroBackground(
      posterBackground: poster?.toString(),
      poster: poster?.toString(),
      backdrop: backdrop?.toString(),
      placeholderType: PlaceholderType.movie,
      imageStrategy: MoviHeroImageStrategy.backdropFirst,
    );
  }

  Widget _buildHeroTopBar(
    BuildContext context, {
    required bool isWideLayout,
    required double horizontalPadding,
  }) {
    return MoviDetailHeroTopBar(
      isWideLayout: isWideLayout,
      horizontalPadding: horizontalPadding,
      leading: MoviEnsureVisibleOnFocus(
        verticalAlignment: _heroFocusVerticalAlignment,
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: (_, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              if (_primaryActionFocusNode.context != null &&
                  _primaryActionFocusNode.canRequestFocus) {
                _primaryActionFocusNode.requestFocus();
              }
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: MoviDetailHeroActionButton(
            focusNode: _backFocusNode,
            iconAsset: AppAssets.iconBack,
            semanticLabel: 'Retour',
            onPressed: () => context.pop(),
            isWideLayout: isWideLayout,
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeroOverlay(
    BuildContext context,
    WidgetRef ref,
    SagaDetailViewModel viewModel,
    AsyncValue<SagaStartTarget> sagaStartTargetAsync,
    AsyncValue<bool> isFavoriteAsync, {
    required String synopsisText,
  }) {
    return MoviDetailHeroDesktopOverlay(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            viewModel.saga.title.display,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ) ??
                const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.05,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MoviPill(
                AppLocalizations.of(
                  context,
                )!.sagaMovieCount(viewModel.movieCount),
                large: true,
              ),
              MoviPill(_formatDuration(viewModel.totalDuration), large: true),
            ],
          ),
          if (synopsisText.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 72,
              child: Text(
                synopsisText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style:
                    Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ) ??
                    const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 320,
                child: sagaStartTargetAsync.when(
                  data: (startTarget) {
                    return MoviEnsureVisibleOnFocus(
                      verticalAlignment: _heroFocusVerticalAlignment,
                      child: Focus(
                        canRequestFocus: false,
                        onKeyEvent: (_, event) =>
                            _handlePrimaryActionKey(event),
                        child: MoviPrimaryButton(
                          focusNode: _primaryActionFocusNode,
                          label: startTarget.hasInProgress
                              ? AppLocalizations.of(context)!.sagaContinue
                              : AppLocalizations.of(context)!.sagaStartNow,
                          assetIcon: AppAssets.iconPlay,
                          onPressed: () => _startSaga(context, ref),
                        ),
                      ),
                    );
                  },
                  loading: () => MoviPrimaryButton(
                    label: AppLocalizations.of(context)!.sagaStartNow,
                    assetIcon: AppAssets.iconPlay,
                    onPressed: () {},
                  ),
                  error: (_, __) => MoviPrimaryButton(
                    label: AppLocalizations.of(context)!.sagaStartNow,
                    assetIcon: AppAssets.iconPlay,
                    onPressed: () => _startSaga(context, ref),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 44,
                height: 44,
                child: isFavoriteAsync.when(
                  data: (isFavorite) => MoviEnsureVisibleOnFocus(
                    verticalAlignment: _heroFocusVerticalAlignment,
                    child: Focus(
                      canRequestFocus: false,
                      onKeyEvent: (_, event) => _handleFavoriteActionKey(event),
                      child: MoviFavoriteButton(
                        focusNode: _favoriteActionFocusNode,
                        isFavorite: isFavorite,
                        size: 44,
                        iconSize: 28,
                        focusPadding: const EdgeInsets.all(5),
                        focusedBackgroundColor: _iconActionFocusedBackground,
                        focusedBorderColor: Theme.of(
                          context,
                        ).colorScheme.primary,
                        borderWidth: 2,
                        onPressed: () async {
                          await ref
                              .read(sagaToggleFavoriteProvider.notifier)
                              .toggle(
                                widget.sagaId,
                                SagaSummary(
                                  id: viewModel.saga.id,
                                  tmdbId: viewModel.saga.tmdbId,
                                  title: viewModel.saga.title,
                                  cover: viewModel.poster,
                                ),
                              );
                        },
                      ),
                    ),
                  ),
                  loading: () => MoviFavoriteButton(
                    isFavorite: true,
                    size: 44,
                    iconSize: 28,
                    focusPadding: const EdgeInsets.all(5),
                    focusedBackgroundColor: _iconActionFocusedBackground,
                    focusedBorderColor: Theme.of(context).colorScheme.primary,
                    borderWidth: 2,
                    onPressed: () {},
                  ),
                  error: (_, __) => MoviFavoriteButton(
                    isFavorite: true,
                    size: 44,
                    iconSize: 28,
                    focusPadding: const EdgeInsets.all(5),
                    focusedBackgroundColor: _iconActionFocusedBackground,
                    focusedBorderColor: Theme.of(context).colorScheme.primary,
                    borderWidth: 2,
                    onPressed: () {},
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SagaMovieCard extends ConsumerWidget {
  const _SagaMovieCard({
    required this.media,
    required this.isAvailable,
    this.focusNode,
    this.onKeyEvent,
    this.onFocusChange,
  });

  final MoviMedia media;
  final bool isAvailable;
  final FocusNode? focusNode;
  final KeyEventResult Function(KeyEvent event)? onKeyEvent;
  final ValueChanged<bool>? onFocusChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Opacity(
      opacity: isAvailable ? 1.0 : 0.5,
      child: ColorFiltered(
        colorFilter: isAvailable
            ? const ColorFilter.mode(Colors.transparent, BlendMode.color)
            : const ColorFilter.matrix([
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
              ]),
        child: Focus(
          onKeyEvent: (_, event) =>
              onKeyEvent?.call(event) ?? KeyEventResult.ignored,
          onFocusChange: onFocusChange,
          child: MoviMediaCard(
            media: media,
            focusNode: focusNode,
            heroTag: 'saga_movie_${media.id}',
            onTap: isAvailable
                ? (mm) => navigateToMovieDetail(
                    context,
                    ref,
                    ContentRouteArgs.movie(mm.id),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
