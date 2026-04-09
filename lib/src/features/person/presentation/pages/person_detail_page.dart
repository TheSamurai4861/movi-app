import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/focus/movi_focus_restore_policy.dart';
import 'package:movi/src/core/focus/movi_route_focus_boundary.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/person/presentation/providers/person_detail_providers.dart';
import 'package:movi/src/features/person/presentation/models/person_detail_view_model.dart';
import 'package:movi/src/features/person/presentation/widgets/person_detail_hero_section.dart';
import 'package:movi/src/features/person/presentation/widgets/person_detail_actions_row.dart';
import 'package:movi/src/features/person/presentation/widgets/person_biography_section.dart';
import 'package:movi/src/features/person/presentation/widgets/person_filmography_section.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';

class PersonDetailPage extends ConsumerStatefulWidget {
  const PersonDetailPage({super.key, this.personSummary, this.personId});

  final PersonSummary? personSummary;
  final String? personId;

  @override
  ConsumerState<PersonDetailPage> createState() => _PersonDetailPageState();
}

class _PersonDetailPageState extends ConsumerState<PersonDetailPage> {
  String? _resolvePersonId(BuildContext context) {
    if (widget.personSummary != null) return widget.personSummary!.id.value;
    if (widget.personId != null && widget.personId!.trim().isNotEmpty) {
      return widget.personId!.trim();
    }
    final extra = GoRouterState.of(context).extra;
    if (extra is PersonSummary) return extra.id.value;
    if (extra is String) return extra.trim().isEmpty ? null : extra.trim();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final personId = _resolvePersonId(context);
    if (personId == null) {
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Text(
            l10n.personNoData,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final vmAsync = ref.watch(personDetailControllerProvider(personId));

    return vmAsync.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: OverlaySplash(
          message: AppLocalizations.of(context)!.overlayPreparingMetadata,
        ),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.personGenericError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              MoviPrimaryButton(
                label: AppLocalizations.of(context)!.actionRetry,
                onPressed: () {
                  final personId = _resolvePersonId(context);
                  if (personId == null) return;
                  ref.invalidate(personDetailControllerProvider(personId));
                },
              ),
            ],
          ),
        ),
      ),
      data: (vm) => _PersonDetailContent(vm: vm, personId: personId),
    );
  }
}

class _PersonDetailContent extends StatefulWidget {
  const _PersonDetailContent({required this.vm, required this.personId});

  final PersonDetailViewModel vm;
  final String personId;

  @override
  State<_PersonDetailContent> createState() => _PersonDetailContentState();
}

class _PersonDetailContentState extends State<_PersonDetailContent> {
  bool _isTransitioningFromLoading = true;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _backFocusNode = FocusNode(debugLabel: 'PersonDetailBack');
  final FocusNode _primaryActionFocusNode = FocusNode(debugLabel: 'PersonDetailPrimaryAction');
  final FocusNode _favoriteActionFocusNode = FocusNode(
    debugLabel: 'PersonDetailFavoriteAction',
  );
  final FocusNode _biographyExpandFocusNode = FocusNode(
    debugLabel: 'PersonDetailBiographyExpand',
  );
  final FocusNode _firstMovieFocusNode = FocusNode(
    debugLabel: 'PersonDetailFirstMovie',
  );
  final FocusNode _firstShowFocusNode = FocusNode(
    debugLabel: 'PersonDetailFirstShow',
  );

  ScreenType _screenTypeFor(BuildContext context) {
    final mq = MediaQuery.of(context);
    return ScreenTypeResolver.instance.resolve(
      mq.size.width,
      mq.size.height == 0 ? 1 : mq.size.height,
    );
  }

  bool _useDesktopLayout(BuildContext context) {
    final screenType = _screenTypeFor(context);
    return screenType == ScreenType.desktop || screenType == ScreenType.tv;
  }

  double _horizontalPadding(BuildContext context) {
    return _useDesktopLayout(context) ? 36 : 20;
  }

  bool _requestFocusIfPossible(FocusNode node) {
    if (node.context == null || !node.canRequestFocus) {
      return false;
    }
    node.requestFocus();
    return true;
  }

  void _focusPrimaryActionAndScrollTop() {
    _requestFocusIfPossible(_primaryActionFocusNode);
    if (!_scrollController.hasClients || _scrollController.offset <= 0) {
      return;
    }
    unawaited(
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _focusBackAndScrollTop() {
    _requestFocusIfPossible(_backFocusNode);
    if (!_scrollController.hasClients || _scrollController.offset <= 0) {
      return;
    }
    unawaited(
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  KeyEventResult _handlePrimaryActionKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _focusBackAndScrollTop();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _requestFocusIfPossible(_favoriteActionFocusNode);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_requestFocusIfPossible(_biographyExpandFocusNode)) {
        return KeyEventResult.handled;
      }
      _requestFocusIfPossible(_firstMovieFocusNode);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleFavoriteActionKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _requestFocusIfPossible(_primaryActionFocusNode);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleBiographyExpandKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _focusPrimaryActionAndScrollTop();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _requestFocusIfPossible(_firstMovieFocusNode);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleFirstMovieKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_requestFocusIfPossible(_biographyExpandFocusNode)) {
        return KeyEventResult.handled;
      }
      _requestFocusIfPossible(_primaryActionFocusNode);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _requestFocusIfPossible(_firstShowFocusNode);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleFirstShowKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _requestFocusIfPossible(_firstMovieFocusNode);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _backFocusNode.dispose();
    _primaryActionFocusNode.dispose();
    _favoriteActionFocusNode.dispose();
    _biographyExpandFocusNode.dispose();
    _firstMovieFocusNode.dispose();
    _firstShowFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isTransitioningFromLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            setState(() {
              _isTransitioningFromLoading = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const heroHeight = 500.0;
    final cs = Theme.of(context).colorScheme;
    final isWideLayout = _useDesktopLayout(context);
    final horizontalPadding = _horizontalPadding(context);
    final movies = widget.vm.movies
        .map(
          (m) => MoviMedia(
            id: m.id.value,
            title: m.title.display,
            poster: m.poster,
            year: m.releaseYear,
            type: MoviMediaType.movie,
          ),
        )
        .toList(growable: false);
    final shows = widget.vm.shows
        .map(
          (s) => MoviMedia(
            id: s.id.value,
            title: s.title.display,
            poster: s.poster,
            type: MoviMediaType.series,
          ),
        )
        .toList(growable: false);

    return SwipeBackWrapper(
      child: MoviRouteFocusBoundary(
        restorePolicy: MoviFocusRestorePolicy(
          initialFocusNode: _primaryActionFocusNode,
          fallbackFocusNode: _backFocusNode,
        ),
        requestInitialFocusOnMount: true,
        onUnhandledBack: () {
          if (!mounted || !context.mounted) return false;
          context.pop();
          return true;
        },
        debugLabel: 'PersonDetailRouteFocus',
        child: Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          top: true,
          bottom: true,
          child: AnimatedOpacity(
            opacity: _isTransitioningFromLoading ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isWideLayout)
                          _buildDesktopHeader(
                            context,
                            horizontalPadding: horizontalPadding,
                            movies: movies,
                            shows: shows,
                          )
                        else
                          PersonDetailHeroSection(
                            photo: widget.vm.photo,
                            name: widget.vm.name,
                            moviesCount: widget.vm.moviesCount,
                            showsCount: widget.vm.showsCount,
                            backFocusNode: _backFocusNode,
                            height: heroHeight,
                          ),
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: horizontalPadding,
                            end: horizontalPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 16),
                              if (!isWideLayout) ...[
                                PersonDetailActionsRow(
                                  personId: widget.personId,
                                  movies: movies,
                                  shows: shows,
                                  primaryActionFocusNode: _primaryActionFocusNode,
                                  favoriteActionFocusNode: _favoriteActionFocusNode,
                                  onPrimaryActionKeyEvent: _handlePrimaryActionKey,
                                  onFavoriteActionKeyEvent:
                                      _handleFavoriteActionKey,
                                ),
                                const SizedBox(height: 32),
                              ],
                              if (widget.vm.biography != null &&
                                  widget.vm.biography!.isNotEmpty) ...[
                                PersonBiographySection(
                                  biography: widget.vm.biography!,
                                  expandFocusNode: _biographyExpandFocusNode,
                                  onExpandKeyEvent: _handleBiographyExpandKey,
                                ),
                                const SizedBox(height: 32),
                              ],
                              PersonFilmographySection(
                                movies: movies,
                                shows: shows,
                                firstMovieFocusNode: _firstMovieFocusNode,
                                firstShowFocusNode: _firstShowFocusNode,
                                onFirstMovieKeyEvent: _handleFirstMovieKey,
                                onFirstShowKeyEvent: _handleFirstShowKey,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      )
    );
  }

  Widget _buildDesktopHeader(
    BuildContext context, {
    required double horizontalPadding,
    required List<MoviMedia> movies,
    required List<MoviMedia> shows,
  }) {
    final cs = Theme.of(context).colorScheme;
    final photo = widget.vm.photo;
    final countLabel = AppLocalizations.of(
      context,
    )!.personMoviesCount(widget.vm.moviesCount, widget.vm.showsCount);

    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.only(
        start: horizontalPadding,
        end: horizontalPadding,
        top: 20,
        bottom: 28,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerHighest.withValues(alpha: 0.9),
            cs.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 47,
              height: 47,
              child: MoviFocusableAction(
                focusNode: _backFocusNode,
                onPressed: () => context.pop(),
                semanticLabel: AppLocalizations.of(context)!.semanticsBack,
                builder: (context, state) {
                  return MoviFocusFrame(
                    scale: state.focused ? 1.04 : 1,
                    padding: const EdgeInsets.all(6),
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: state.focused
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.transparent,
                    child: const SizedBox(
                      width: 35,
                      height: 35,
                      child: MoviAssetIcon(
                        AppAssets.iconBack,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildDesktopPhoto(photo),
              const SizedBox(width: 32),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.vm.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                              height: 1.05,
                            ) ??
                            TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                              height: 1.05,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          MoviPill(
                            countLabel,
                            large: true,
                            color: cs.surfaceContainer,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 376,
                        child: PersonDetailActionsRow(
                          personId: widget.personId,
                          movies: movies,
                          shows: shows,
                          primaryActionFocusNode: _primaryActionFocusNode,
                          favoriteActionFocusNode: _favoriteActionFocusNode,
                          onPrimaryActionKeyEvent: _handlePrimaryActionKey,
                          onFavoriteActionKeyEvent: _handleFavoriteActionKey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopPhoto(Uri? photo) {
    const size = 220.0;

    Widget child;
    if (photo == null) {
      child = const MoviPlaceholderCard(
        type: PlaceholderType.person,
        fit: BoxFit.cover,
        alignment: Alignment(0.0, 0.1),
        borderRadius: BorderRadius.zero,
      );
    } else {
      child = Image.network(
        photo.toString(),
        fit: BoxFit.cover,
        cacheWidth: 880,
        filterQuality: FilterQuality.high,
        alignment: const Alignment(0.0, 0.1),
        errorBuilder: (_, __, ___) => const MoviPlaceholderCard(
          type: PlaceholderType.person,
          fit: BoxFit.cover,
          alignment: Alignment(0.0, 0.1),
          borderRadius: BorderRadius.zero,
        ),
      );
    }

    return ClipOval(
      child: SizedBox(width: size, height: size, child: child),
    );
  }

  // Biography and hero image are now handled by dedicated widgets:
  // - PersonDetailHeroSection
  // - PersonBiographySection
}
