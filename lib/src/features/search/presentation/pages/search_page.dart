// lib/src/features/search/presentation/pages/search_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/directional_edge.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/domain/focus_region_exit_map.dart';
import 'package:movi/src/core/focus/presentation/focus_directional_navigation.dart';
import 'package:movi/src/core/focus/presentation/focus_orchestrator_provider.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/subscription/subscription.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/features/search/presentation/providers/search_history_providers.dart';
import 'package:movi/src/features/search/presentation/providers/search_providers.dart';
import 'package:movi/src/features/search/presentation/widgets/genres_grid.dart';
import 'package:movi/src/features/search/presentation/widgets/watch_providers_grid.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';

const int _searchQueryMinLength = 3;

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
  static void _noop() {}
  static const double _focusVerticalAlignment = 0.22;
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _clearFocusNode = FocusNode(debugLabel: 'SearchClearButton');
  final _firstHistoryItemFocusNode = FocusNode(
    debugLabel: 'SearchFirstHistoryItem',
  );
  final _firstProviderFocusNode = FocusNode(debugLabel: 'SearchFirstProvider');
  final _firstGenreFocusNode = FocusNode(debugLabel: 'SearchFirstGenre');
  final _firstMovieResultFocusNode = FocusNode(
    debugLabel: 'SearchFirstMovieResult',
  );
  final _firstShowResultFocusNode = FocusNode(
    debugLabel: 'SearchFirstShowResult',
  );
  final _firstPersonResultFocusNode = FocusNode(
    debugLabel: 'SearchFirstPersonResult',
  );
  final _firstSagaResultFocusNode = FocusNode(
    debugLabel: 'SearchFirstSagaResult',
  );

  String _lastTextValue = '';
  String? _programmaticTextReason;
  DateTime? _lastUserTypingAt;
  bool _allowExpectedInputUnfocus = false;
  bool _syncedFromState = false;
  bool _historyVisibilityLock = false;
  bool _historySectionHasFocus = false;
  bool _searchInputActivated = false;
  String? _pendingAutoFocusResultsQuery;
  Timer? _historyHideTimer;

  void _debugSearchFocus(String message) {
    assert(() {
      debugPrint('[DEBUG][SearchFocus] $message');
      return true;
    }());
  }

  int _providerFocusRequestId = 0;
  int? _providerFocusRequestColumn;
  int _genreFocusRequestId = 0;
  int? _genreFocusRequestColumn;

  bool get _hasQuery => _textCtrl.text.trim().length >= _searchQueryMinLength;

  ScreenType _screenTypeFor(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ScreenTypeResolver.instance.resolve(size.width, size.height);
  }

  bool _useDesktopSearchLayout(BuildContext context) {
    final screenType = _screenTypeFor(context);
    return screenType == ScreenType.desktop || screenType == ScreenType.tv;
  }

  double _pageHorizontalPadding(BuildContext context) {
    return switch (_screenTypeFor(context)) {
      ScreenType.mobile => 20,
      ScreenType.tablet => 24,
      ScreenType.desktop => 32,
      ScreenType.tv => 40,
    };
  }

  double _contentMaxWidth(BuildContext context) {
    return switch (_screenTypeFor(context)) {
      ScreenType.mobile => double.infinity,
      ScreenType.tablet => 960,
      ScreenType.desktop => 1180,
      ScreenType.tv => 1320,
    };
  }

  double _searchFieldMaxWidth(BuildContext context) {
    return switch (_screenTypeFor(context)) {
      ScreenType.mobile => double.infinity,
      ScreenType.tablet => 560,
      ScreenType.desktop => 620,
      ScreenType.tv => 680,
    };
  }

  double _historyMaxWidth(BuildContext context) {
    return switch (_screenTypeFor(context)) {
      ScreenType.mobile => double.infinity,
      ScreenType.tablet => 680,
      ScreenType.desktop => 760,
      ScreenType.tv => 820,
    };
  }

  double _topSpacing(BuildContext context) {
    return switch (_screenTypeFor(context)) {
      ScreenType.mobile => 20,
      ScreenType.tablet => 20,
      ScreenType.desktop => 30,
      ScreenType.tv => 30,
    };
  }

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
    _clearFocusNode.addListener(_onClearFocusChangedLocal);
    HardwareKeyboard.instance.addHandler(_handleSearchKeyboard);
  }

  void _markProgrammaticTextChange(String reason) {
    _programmaticTextReason = reason;
  }

  void _onTextChangedLocal() {
    if (!mounted) return;
    final current = _textCtrl.text;
    final reason = _programmaticTextReason;
    if (reason == null || reason == 'user_or_unknown') {
      _lastUserTypingAt = DateTime.now();
    }
    _programmaticTextReason = null;
    _debugSearchFocus(
      'textChanged value="$current" prev="$_lastTextValue" len=${current.trim().length} hasFocus=${_focusNode.hasFocus} clearHasFocus=${_clearFocusNode.hasFocus} reason=${reason ?? 'user_or_unknown'}',
    );
    _lastTextValue = current;
    setState(() {});
  }

  void _onClearFocusChangedLocal() {
    if (!mounted) return;
    _debugSearchFocus(
      'clearFocusChanged clearHasFocus=${_clearFocusNode.hasFocus} inputHasFocus=${_focusNode.hasFocus}',
    );
  }

  void _onFocusChangedLocal() {
    if (!mounted) return;
    final primary = FocusManager.instance.primaryFocus;
    _debugSearchFocus(
      'focusChanged inputHasFocus=${_focusNode.hasFocus} primary=${primary?.debugLabel ?? 'null'} text="${_textCtrl.text}"',
    );
    _historyHideTimer?.cancel();
    if (_focusNode.hasFocus) {
      if (_historyVisibilityLock) {
        _historyVisibilityLock = false;
      }
      setState(() {});
      return;
    }
    final recentlyTyped =
        _lastUserTypingAt != null &&
        DateTime.now().difference(_lastUserTypingAt!) <
            const Duration(milliseconds: 450);
    final shouldRestoreUnexpectedDrop =
        !_allowExpectedInputUnfocus &&
        _searchInputActivated &&
        recentlyTyped &&
        !_clearFocusNode.hasFocus;
    if (shouldRestoreUnexpectedDrop) {
      _debugSearchFocus(
        'unexpected focus drop detected -> restoring input focus (primary=${primary?.debugLabel ?? 'null'})',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        FocusDirectionalNavigation.requestFocus(_focusNode);
      });
      return;
    }
    _searchInputActivated = false;
    if (!_hasQuery) {
      _historyVisibilityLock = true;
      _historyHideTimer = Timer(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        setState(() {
          _historyVisibilityLock = false;
        });
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleSearchKeyboard);
    _historyHideTimer?.cancel();
    _textCtrl.removeListener(_onTextChangedLocal);
    _focusNode.removeListener(_onFocusChangedLocal);
    _clearFocusNode.removeListener(_onClearFocusChangedLocal);
    _textCtrl.dispose();
    _focusNode.dispose();
    _clearFocusNode.dispose();
    _firstHistoryItemFocusNode.dispose();
    _firstProviderFocusNode.dispose();
    _firstGenreFocusNode.dispose();
    _firstMovieResultFocusNode.dispose();
    _firstShowResultFocusNode.dispose();
    _firstPersonResultFocusNode.dispose();
    _firstSagaResultFocusNode.dispose();
    super.dispose();
  }

  bool _enterRegion(
    AppFocusRegionId regionId, {
    bool restoreLastFocused = true,
  }) {
    return ref
        .read(focusOrchestratorProvider)
        .enterRegion(regionId, restoreLastFocused: restoreLastFocused);
  }

  bool _resolveExitFromRegion(AppFocusRegionId regionId) {
    return ref
        .read(focusOrchestratorProvider)
        .resolveExit(regionId, DirectionalEdge.left);
  }

  void _setSearchInputActivated(bool activated) {
    if (_searchInputActivated == activated) return;
    if (!mounted) {
      _searchInputActivated = activated;
      return;
    }
    setState(() {
      _searchInputActivated = activated;
    });
  }

  void _scheduleResultsAutoFocus(String query) {
    final trimmed = query.trim();
    _pendingAutoFocusResultsQuery = trimmed.length >= _searchQueryMinLength
        ? trimmed
        : null;
  }

  void _runWithExpectedInputUnfocus(VoidCallback action) {
    _allowExpectedInputUnfocus = true;
    action();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _allowExpectedInputUnfocus = false;
    });
  }

  void _focusNearestProviderFromGenres(int column) {
    if (!mounted) return;
    setState(() {
      _providerFocusRequestId++;
      _providerFocusRequestColumn = column;
    });
  }

  void _focusNearestGenreFromProviders(int column) {
    if (!mounted) return;
    setState(() {
      _genreFocusRequestId++;
      _genreFocusRequestColumn = column;
    });
  }

  AppFocusRegionId? _firstAvailableResultsRegion() {
    final state = ref.read(searchControllerProvider);
    if (state.movies.isNotEmpty) {
      return AppFocusRegionId.searchResultsMovies;
    }
    if (state.shows.isNotEmpty) {
      return AppFocusRegionId.searchResultsSeries;
    }
    if (state.people.isNotEmpty) {
      return AppFocusRegionId.searchResultsPeople;
    }
    if (state.sagas.isNotEmpty) {
      return AppFocusRegionId.searchResultsSagas;
    }
    return null;
  }

  bool _hasHistoryItems() {
    return ref
        .read(searchHistoryControllerProvider)
        .maybeWhen(data: (items) => items.isNotEmpty, orElse: () => false);
  }

  bool _focusFirstSearchResult({bool restoreLastFocused = false}) {
    final regionId = _firstAvailableResultsRegion();
    if (regionId == null) {
      _debugSearchFocus('focusFirstSearchResult skipped (no region)');
      return false;
    }
    _debugSearchFocus(
      'focusFirstSearchResult enter region=$regionId restore=$restoreLastFocused',
    );
    return _enterRegion(regionId, restoreLastFocused: restoreLastFocused);
  }

  bool _enterFirstAvailableRegionBelow({bool preferHistory = false}) {
    final hasHistoryItems = _hasHistoryItems();
    final showHistory =
        !_hasQuery &&
        hasHistoryItems &&
        ((_focusNode.hasFocus && hasHistoryItems) ||
            _historySectionHasFocus ||
            _historyVisibilityLock);
    final showWatchProviders = ref
        .read(
          canAccessPremiumFeatureProvider(
            PremiumFeature.extendedDiscoveryDetails,
          ),
        )
        .maybeWhen(data: (value) => value, orElse: () => false);

    final candidates = <AppFocusRegionId>[
      if (!_hasQuery && preferHistory && showHistory)
        AppFocusRegionId.searchHistory,
      if (!_hasQuery && showWatchProviders) AppFocusRegionId.searchProviders,
      if (!_hasQuery) AppFocusRegionId.searchGenres,
      if (!_hasQuery && !preferHistory && showHistory)
        AppFocusRegionId.searchHistory,
      if (_hasQuery && _firstAvailableResultsRegion() != null)
        _firstAvailableResultsRegion()!,
    ];

    for (final regionId in candidates) {
      if (_enterRegion(regionId, restoreLastFocused: false)) {
        return true;
      }
    }
    return false;
  }

  void _focusSearchContentBelow({bool preferHistory = false}) {
    if (_enterFirstAvailableRegionBelow(preferHistory: preferHistory)) {
      return;
    }
    FocusScope.of(context).nextFocus();
  }

  bool _handleSearchKeyboard(KeyEvent event) {
    if (_focusNode.hasFocus) {
      return FocusDirectionalNavigation.handleDirectionalTransition(
            event,
            onLeft: () => _resolveExitFromRegion(AppFocusRegionId.searchInput),
            onRight: _textCtrl.text.isEmpty
                ? null
                : () =>
                      FocusDirectionalNavigation.requestFocus(_clearFocusNode),
            onUp: () => true,
            onDown: () {
              _focusSearchContentBelow(preferHistory: _hasHistoryItems());
              return true;
            },
          ) ==
          KeyEventResult.handled;
    }

    if (_clearFocusNode.hasFocus) {
      return FocusDirectionalNavigation.handleDirectionalTransition(
            event,
            onLeft: () => FocusDirectionalNavigation.requestFocus(_focusNode),
            onUp: () => true,
            onDown: () {
              _focusSearchContentBelow();
              return true;
            },
            onRight: () => true,
          ) ==
          KeyEventResult.handled;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final horizontalPadding = _pageHorizontalPadding(context);
    final useDesktopLayout = _useDesktopSearchLayout(context);
    final contentMaxWidth = _contentMaxWidth(context);
    final gridMaxWidth = useDesktopLayout ? double.infinity : contentMaxWidth;
    final searchFieldMaxWidth = _searchFieldMaxWidth(context);
    final topSpacing = _topSpacing(context);
    final historyMaxWidth = useDesktopLayout
        ? double.infinity
        : _historyMaxWidth(context);
    final hasHistoryItems = ref
        .watch(searchHistoryControllerProvider)
        .maybeWhen(data: (items) => items.isNotEmpty, orElse: () => false);
    final showHistory =
        !_hasQuery &&
        ((_focusNode.hasFocus && hasHistoryItems) ||
            _historySectionHasFocus ||
            _historyVisibilityLock);
    final showWatchProviders = ref
        .watch(
          canAccessPremiumFeatureProvider(
            PremiumFeature.extendedDiscoveryDetails,
          ),
        )
        .maybeWhen(data: (value) => value, orElse: () => false);
    final resultsListPadding = EdgeInsets.symmetric(
      horizontal: horizontalPadding,
    );

    final state = ref.watch(searchControllerProvider);
    final ctrl = ref.read(searchControllerProvider.notifier);
    final hasAnyResults =
        state.movies.isNotEmpty ||
        state.shows.isNotEmpty ||
        state.people.isNotEmpty ||
        state.sagas.isNotEmpty;

    if (_pendingAutoFocusResultsQuery != null &&
        !state.isLoading &&
        state.query == _pendingAutoFocusResultsQuery) {
      if (_focusNode.hasFocus || _searchInputActivated) {
        _debugSearchFocus(
          'pendingAutoFocus cleared (input active) query="${_pendingAutoFocusResultsQuery!}"',
        );
        _pendingAutoFocusResultsQuery = null;
      } else {
        _debugSearchFocus(
          'pendingAutoFocus applying query="${_pendingAutoFocusResultsQuery!}"',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (hasAnyResults) {
            _focusFirstSearchResult();
          }
        });
        _pendingAutoFocusResultsQuery = null;
      }
    }

    if (!_syncedFromState) {
      final existing = state.query.trim();
      if (existing.isNotEmpty && _textCtrl.text.trim() != existing) {
        _markProgrammaticTextChange('initial_sync_from_state');
        _debugSearchFocus('initialSync setText="$existing"');
        _textCtrl.text = existing;
        _textCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _textCtrl.text.length),
        );
      }
      _syncedFromState = true;
    }

    final searchHeaderChildren = <Widget>[
      SizedBox(height: topSpacing),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: Text(
              l10n.searchTitle,
              style:
                  Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ) ??
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: searchFieldMaxWidth),
            child: _SearchField(
              controller: _textCtrl,
              focusNode: _focusNode,
              clearFocusNode: _clearFocusNode,
              hintText: l10n.searchHint,
              clearTooltip: l10n.clear,
              onArrowLeft: () {
                _runWithExpectedInputUnfocus(() {
                  _resolveExitFromRegion(AppFocusRegionId.searchInput);
                });
              },
              onArrowUp: _noop,
              onArrowDown: () => _runWithExpectedInputUnfocus(
                () => _focusSearchContentBelow(preferHistory: hasHistoryItems),
              ),
              onArrowRight: () {
                if (_textCtrl.text.isEmpty) return;
                _runWithExpectedInputUnfocus(() {
                  FocusDirectionalNavigation.requestFocus(_clearFocusNode);
                });
              },
              onClearArrowLeft: () {
                FocusDirectionalNavigation.requestFocus(_focusNode);
              },
              onClearArrowUp: _noop,
              onClearArrowDown: () => _focusSearchContentBelow(),
              onActivate: () => _setSearchInputActivated(true),
              onChanged: (value) {
                _setSearchInputActivated(true);
                _pendingAutoFocusResultsQuery = null;
                _debugSearchFocus(
                  'onChanged value="$value" len=${value.trim().length} pendingAutoFocusCleared=true',
                );
                ctrl.setQuery(value);

                if (value.trim().length < _searchQueryMinLength) {
                  unawaited(
                    ref
                        .read(searchHistoryControllerProvider.notifier)
                        .refresh(),
                  );
                }
              },
              onClear: () {
                _debugSearchFocus(
                  'onClear pressed textBefore="${_textCtrl.text}"',
                );
                _markProgrammaticTextChange('on_clear_pressed');
                _textCtrl.clear();
                ctrl.setQuery('');
                _pendingAutoFocusResultsQuery = null;
                unawaited(
                  ref.read(searchHistoryControllerProvider.notifier).refresh(),
                );
                FocusDirectionalNavigation.requestFocus(_focusNode);
              },
              onSubmitted: (value) {
                _setSearchInputActivated(true);
                _scheduleResultsAutoFocus(value);
                _debugSearchFocus(
                  'onSubmitted value="$value" pendingAutoFocus="${_pendingAutoFocusResultsQuery ?? ''}"',
                );
                ctrl.setQueryImmediate(value);
                _runWithExpectedInputUnfocus(() {
                  FocusScope.of(context).unfocus();
                });
              },
            ),
          ),
        ),
      ),
      const SizedBox(height: 32),
    ];

    Widget buildResultsList() {
      Widget section(Widget child) {
        return Builder(
          builder: (sectionContext) => MoviVerticalEnsureVisibleTarget(
            targetContext: sectionContext,
            child: child,
          ),
        );
      }

      return ListView(
        padding: EdgeInsets.zero,
        children: [
          ...searchHeaderChildren,
          if (state.movies.isNotEmpty) ...[
            const SizedBox(height: 16),
            FocusRegionScope(
              regionId: AppFocusRegionId.searchResultsMovies,
              binding: FocusRegionBinding(
                resolvePrimaryEntryNode: () => _firstMovieResultFocusNode,
              ),
              exitMap: FocusRegionExitMap({
                DirectionalEdge.left: AppFocusRegionId.shellSidebar,
                DirectionalEdge.back: AppFocusRegionId.shellSidebar,
              }),
              debugLabel: 'SearchMoviesRegion',
              child: section(
                MoviItemsList(
                  title: l10n.moviesTitle,
                  subtitle: l10n.resultsCount(state.movies.length),
                  estimatedItemWidth: 150,
                  estimatedItemHeight: 300,
                  verticalFocusAlignment: _focusVerticalAlignment,
                  titlePadding: horizontalPadding,
                  horizontalPadding: resultsListPadding,
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
                            originRegionId:
                                AppFocusRegionId.searchResultsMovies,
                            fallbackRegionId:
                                AppFocusRegionId.searchResultsMovies,
                          ),
                          focusNode: entry.key == 0
                              ? _firstMovieResultFocusNode
                              : null,
                          onFirstLeft: entry.key == 0
                              ? () => _resolveExitFromRegion(
                                  AppFocusRegionId.searchResultsMovies,
                                )
                              : null,
                          delay: Duration(milliseconds: entry.key * 100),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
          ],
          if (state.shows.isNotEmpty) ...[
            const SizedBox(height: 16),
            FocusRegionScope(
              regionId: AppFocusRegionId.searchResultsSeries,
              binding: FocusRegionBinding(
                resolvePrimaryEntryNode: () => _firstShowResultFocusNode,
              ),
              exitMap: FocusRegionExitMap({
                DirectionalEdge.left: AppFocusRegionId.shellSidebar,
                DirectionalEdge.back: AppFocusRegionId.shellSidebar,
              }),
              debugLabel: 'SearchSeriesRegion',
              child: section(
                MoviItemsList(
                  title: l10n.seriesTitle,
                  subtitle: l10n.resultsCount(state.shows.length),
                  estimatedItemWidth: 150,
                  estimatedItemHeight: 300,
                  verticalFocusAlignment: _focusVerticalAlignment,
                  titlePadding: horizontalPadding,
                  horizontalPadding: resultsListPadding,
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
                            originRegionId:
                                AppFocusRegionId.searchResultsSeries,
                            fallbackRegionId:
                                AppFocusRegionId.searchResultsSeries,
                          ),
                          focusNode: entry.key == 0
                              ? _firstShowResultFocusNode
                              : null,
                          onFirstLeft: entry.key == 0
                              ? () => _resolveExitFromRegion(
                                  AppFocusRegionId.searchResultsSeries,
                                )
                              : null,
                          delay: Duration(milliseconds: entry.key * 100),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
          ],
          if (state.people.isNotEmpty) ...[
            const SizedBox(height: 16),
            FocusRegionScope(
              regionId: AppFocusRegionId.searchResultsPeople,
              binding: FocusRegionBinding(
                resolvePrimaryEntryNode: () => _firstPersonResultFocusNode,
              ),
              exitMap: FocusRegionExitMap({
                DirectionalEdge.left: AppFocusRegionId.shellSidebar,
                DirectionalEdge.back: AppFocusRegionId.shellSidebar,
              }),
              debugLabel: 'SearchPeopleRegion',
              child: section(
                MoviItemsList(
                  title: l10n.searchPeopleTitle,
                  subtitle: l10n.resultsCount(state.people.length),
                  estimatedItemWidth: 150,
                  estimatedItemHeight: 300,
                  verticalFocusAlignment: _focusVerticalAlignment,
                  titlePadding: horizontalPadding,
                  horizontalPadding: resultsListPadding,
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
                          focusNode: entry.key == 0
                              ? _firstPersonResultFocusNode
                              : null,
                          onFirstLeft: entry.key == 0
                              ? () => _resolveExitFromRegion(
                                  AppFocusRegionId.searchResultsPeople,
                                )
                              : null,
                          delay: Duration(milliseconds: entry.key * 100),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
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
                    return FocusRegionScope(
                      regionId: AppFocusRegionId.searchResultsSagas,
                      binding: FocusRegionBinding(
                        resolvePrimaryEntryNode: () =>
                            _firstSagaResultFocusNode,
                      ),
                      exitMap: FocusRegionExitMap({
                        DirectionalEdge.left: AppFocusRegionId.shellSidebar,
                        DirectionalEdge.back: AppFocusRegionId.shellSidebar,
                      }),
                      debugLabel: 'SearchSagasRegion',
                      child: section(
                        MoviItemsList(
                          title: l10n.searchSagasTitle,
                          subtitle: l10n.resultsCount(filteredSagas.length),
                          estimatedItemWidth: 150,
                          estimatedItemHeight: 300,
                          verticalFocusAlignment: _focusVerticalAlignment,
                          titlePadding: horizontalPadding,
                          horizontalPadding: resultsListPadding,
                          items: filteredSagas
                              .take(10)
                              .toList()
                              .asMap()
                              .entries
                              .map(
                                (entry) => _AnimatedSagaCard(
                                  saga: entry.value,
                                  focusNode: entry.key == 0
                                      ? _firstSagaResultFocusNode
                                      : null,
                                  onFirstLeft: entry.key == 0
                                      ? () => _resolveExitFromRegion(
                                          AppFocusRegionId.searchResultsSagas,
                                        )
                                      : null,
                                  delay: Duration(
                                    milliseconds: entry.key * 100,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
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
      );
    }

    return FocusRegionScope(
      regionId: AppFocusRegionId.searchInput,
      binding: FocusRegionBinding(
        resolvePrimaryEntryNode: () => _focusNode,
        resolveFallbackEntryNode: () => _clearFocusNode,
      ),
      exitMap: FocusRegionExitMap({
        DirectionalEdge.left: AppFocusRegionId.shellSidebar,
        DirectionalEdge.back: AppFocusRegionId.shellSidebar,
      }),
      debugLabel: 'SearchPageRegion',
      child: Material(
        color: Colors.transparent,
        child: SizedBox.expand(
          child: !_hasQuery
              ? ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ...searchHeaderChildren,
                    AnimatedSize(
                      duration: const Duration(milliseconds: 340),
                      curve: Curves.easeInOutCubic,
                      alignment: Alignment.topCenter,
                      child: showHistory
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 32),
                              child: FocusRegionScope(
                                regionId: AppFocusRegionId.searchHistory,
                                binding: FocusRegionBinding(
                                  resolvePrimaryEntryNode: () =>
                                      _firstHistoryItemFocusNode,
                                ),
                                exitMap: FocusRegionExitMap({
                                  DirectionalEdge.left:
                                      AppFocusRegionId.shellSidebar,
                                  DirectionalEdge.back:
                                      AppFocusRegionId.shellSidebar,
                                }),
                                debugLabel: 'SearchHistoryRegion',
                                child: Builder(
                                  builder: (sectionContext) =>
                                      MoviVerticalEnsureVisibleTarget(
                                        targetContext: sectionContext,
                                        child: _SearchHistoryList(
                                          horizontalPadding: horizontalPadding,
                                          maxContentWidth: historyMaxWidth,
                                          useWideLayout: useDesktopLayout,
                                          firstItemFocusNode:
                                              _firstHistoryItemFocusNode,
                                          focusVerticalAlignment:
                                              _focusVerticalAlignment,
                                          onFocusChange: (hasFocus) {
                                            if (_historySectionHasFocus ==
                                                hasFocus) {
                                              return;
                                            }
                                            setState(() {
                                              _historySectionHasFocus =
                                                  hasFocus;
                                            });
                                          },
                                          onSelect: (q) {
                                            _debugSearchFocus(
                                              'historySelect query="$q"',
                                            );
                                            _markProgrammaticTextChange(
                                              'history_select',
                                            );
                                            _textCtrl.text = q;
                                            _textCtrl.selection =
                                                TextSelection.fromPosition(
                                                  TextPosition(
                                                    offset:
                                                        _textCtrl.text.length,
                                                  ),
                                                );
                                            _scheduleResultsAutoFocus(q);
                                            ctrl.setQueryImmediate(q);
                                            _runWithExpectedInputUnfocus(() {
                                              FocusScope.of(context).unfocus();
                                            });
                                          },
                                        ),
                                      ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (showWatchProviders)
                      FocusRegionScope(
                        regionId: AppFocusRegionId.searchProviders,
                        binding: FocusRegionBinding(
                          resolvePrimaryEntryNode: () =>
                              _firstProviderFocusNode,
                        ),
                        exitMap: FocusRegionExitMap({
                          DirectionalEdge.left: AppFocusRegionId.shellSidebar,
                          DirectionalEdge.back: AppFocusRegionId.shellSidebar,
                        }),
                        debugLabel: 'SearchProvidersRegion',
                        child: Builder(
                          builder: (sectionContext) =>
                              MoviVerticalEnsureVisibleTarget(
                                targetContext: sectionContext,
                                child: WatchProvidersGrid(
                                  horizontalPadding: horizontalPadding,
                                  maxContentWidth: gridMaxWidth,
                                  firstItemFocusNode: _firstProviderFocusNode,
                                  onFirstItemLeft: () => _resolveExitFromRegion(
                                    AppFocusRegionId.searchProviders,
                                  ),
                                  onLastRowDown:
                                      _focusNearestGenreFromProviders,
                                  focusVerticalAlignment:
                                      _focusVerticalAlignment,
                                  focusRequestId: _providerFocusRequestId,
                                  focusRequestColumn:
                                      _providerFocusRequestColumn,
                                ),
                              ),
                        ),
                      ),
                    if (showWatchProviders) const SizedBox(height: 32),
                    FocusRegionScope(
                      regionId: AppFocusRegionId.searchGenres,
                      binding: FocusRegionBinding(
                        resolvePrimaryEntryNode: () => _firstGenreFocusNode,
                      ),
                      exitMap: FocusRegionExitMap({
                        DirectionalEdge.left: AppFocusRegionId.shellSidebar,
                        DirectionalEdge.back: AppFocusRegionId.shellSidebar,
                      }),
                      debugLabel: 'SearchGenresRegion',
                      child: Builder(
                        builder: (sectionContext) =>
                            MoviVerticalEnsureVisibleTarget(
                              targetContext: sectionContext,
                              child: GenresGrid(
                                horizontalPadding: horizontalPadding,
                                maxContentWidth: gridMaxWidth,
                                firstItemFocusNode: _firstGenreFocusNode,
                                onFirstItemLeft: () => _resolveExitFromRegion(
                                  AppFocusRegionId.searchGenres,
                                ),
                                onFirstRowUp: showWatchProviders
                                    ? _focusNearestProviderFromGenres
                                    : null,
                                focusRequestId: _genreFocusRequestId,
                                focusRequestColumn: _genreFocusRequestColumn,
                                focusVerticalAlignment: _focusVerticalAlignment,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 125),
                  ],
                )
              : state.isLoading
              ? ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ...searchHeaderChildren,
                    const SizedBox(height: 120),
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 100),
                  ],
                )
              : state.error != null
              ? ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ...searchHeaderChildren,
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Text(
                        state.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    final q = _textCtrl.text.trim();
                    if (q.length < _searchQueryMinLength) {
                      await ref
                          .read(searchHistoryControllerProvider.notifier)
                          .refresh();
                      return;
                    }
                    ctrl.setQuery(q);
                  },
                  child: buildResultsList(),
                ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.clearFocusNode,
    required this.hintText,
    required this.clearTooltip,
    required this.onActivate,
    required this.onArrowLeft,
    required this.onArrowUp,
    required this.onArrowDown,
    required this.onArrowRight,
    required this.onClearArrowLeft,
    required this.onClearArrowUp,
    required this.onClearArrowDown,
    required this.onChanged,
    required this.onClear,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode clearFocusNode;
  final String hintText;
  final String clearTooltip;
  final VoidCallback onActivate;
  final VoidCallback onArrowLeft;
  final VoidCallback onArrowUp;
  final VoidCallback onArrowDown;
  final VoidCallback onArrowRight;
  final VoidCallback onClearArrowLeft;
  final VoidCallback onClearArrowUp;
  final VoidCallback onClearArrowDown;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft): onArrowLeft,
        const SingleActivator(LogicalKeyboardKey.arrowUp): onArrowUp,
        const SingleActivator(LogicalKeyboardKey.arrowDown): onArrowDown,
        const SingleActivator(LogicalKeyboardKey.arrowRight): onArrowRight,
      },
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        onTap: onActivate,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: const MoviAssetIcon(
              AppAssets.iconSearch,
              width: 25,
              height: 25,
              color: Colors.white70,
            ),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? CallbackShortcuts(
                  bindings: <ShortcutActivator, VoidCallback>{
                    const SingleActivator(LogicalKeyboardKey.arrowLeft):
                        onClearArrowLeft,
                    const SingleActivator(LogicalKeyboardKey.arrowUp):
                        onClearArrowUp,
                    const SingleActivator(LogicalKeyboardKey.arrowDown):
                        onClearArrowDown,
                  },
                  child: IconButton(
                    focusNode: clearFocusNode,
                    icon: const MoviAssetIcon(
                      AppAssets.iconDelete,
                      width: 25,
                      height: 25,
                      color: Colors.white,
                    ),
                    onPressed: onClear,
                    tooltip: clearTooltip,
                  ),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 16,
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
    this.focusNode,
    this.onFirstLeft,
  });

  final MoviPerson person;
  final void Function(MoviPerson) onTap;
  final Duration delay;
  final FocusNode? focusNode;
  final VoidCallback? onFirstLeft;

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
            child: Focus(
              canRequestFocus: false,
              onKeyEvent: (_, event) =>
                  FocusDirectionalNavigation.handleDirectionalTransition(
                    event,
                    onLeft: widget.onFirstLeft == null
                        ? null
                        : () {
                            widget.onFirstLeft!();
                            return true;
                          },
                    blockLeft: false,
                    blockRight: false,
                    blockUp: false,
                    blockDown: false,
                  ),
              child: MoviPersonCard(
                person: widget.person,
                onTap: widget.onTap,
                focusNode: widget.focusNode,
              ),
            ),
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
    this.focusNode,
    this.onFirstLeft,
  });

  final MoviMedia media;
  final void Function(MoviMedia) onTap;
  final Duration delay;
  final FocusNode? focusNode;
  final VoidCallback? onFirstLeft;

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
            child: Focus(
              canRequestFocus: false,
              onKeyEvent: (_, event) =>
                  FocusDirectionalNavigation.handleDirectionalTransition(
                    event,
                    onLeft: widget.onFirstLeft == null
                        ? null
                        : () {
                            widget.onFirstLeft!();
                            return true;
                          },
                    blockLeft: false,
                    blockRight: false,
                    blockUp: false,
                    blockDown: false,
                  ),
              child: MoviMediaCard(
                media: widget.media,
                onTap: widget.onTap,
                focusNode: widget.focusNode,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SearchHistoryList extends ConsumerWidget {
  const _SearchHistoryList({
    required this.onSelect,
    this.horizontalPadding = 20,
    this.maxContentWidth = double.infinity,
    this.useWideLayout = false,
    this.firstItemFocusNode,
    this.focusVerticalAlignment = 0.22,
    this.onFocusChange,
  });

  final void Function(String query) onSelect;
  final double horizontalPadding;
  final double maxContentWidth;
  final bool useWideLayout;
  final FocusNode? firstItemFocusNode;
  final double focusVerticalAlignment;
  final ValueChanged<bool>? onFocusChange;

  Widget _buildHistorySection(
    BuildContext context,
    WidgetRef ref,
    Widget child, {
    required bool hasItems,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: onFocusChange,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.historyTitle,
                          style: theme.textTheme.titleLarge,
                        ),
                        if (hasItems)
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(
                                    searchHistoryControllerProvider.notifier,
                                  )
                                  .clearAll();
                            },
                            child: Text(l10n.actionClearHistory),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final history = ref.watch(searchHistoryControllerProvider);

    return history.when(
      data: (items) {
        final sorted = [...items]
          ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
        final recent = sorted.take(6).toList(growable: false);

        return _buildHistorySection(
          context,
          ref,
          recent.isEmpty
              ? Text(
                  l10n.historyEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : useWideLayout
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final spacing = 24.0;
                    final availableWidth = constraints.maxWidth;
                    final itemWidth = availableWidth > spacing
                        ? (availableWidth - spacing) / 2
                        : availableWidth;
                    final itemHeight = 62.0;
                    final aspectRatio = itemWidth > 0
                        ? itemWidth / itemHeight
                        : 1.0;

                    return GridView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recent.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: 0,
                        childAspectRatio: aspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final h = recent[index];
                        return _SearchHistoryItem(
                          query: h.query,
                          focusNode: index == 0 ? firstItemFocusNode : null,
                          focusVerticalAlignment: focusVerticalAlignment,
                          onTap: () => onSelect(h.query),
                          onRemove: () => ref
                              .read(searchHistoryControllerProvider.notifier)
                              .remove(h.query),
                        );
                      },
                    );
                  },
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recent.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.45,
                    ),
                  ),
                  itemBuilder: (context, index) {
                    final h = recent[index];
                    return _SearchHistoryItem(
                      query: h.query,
                      focusNode: index == 0 ? firstItemFocusNode : null,
                      focusVerticalAlignment: focusVerticalAlignment,
                      onTap: () => onSelect(h.query),
                      onRemove: () => ref
                          .read(searchHistoryControllerProvider.notifier)
                          .remove(h.query),
                    );
                  },
                ),
          hasItems: recent.isNotEmpty,
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
              onPressed: () =>
                  ref.read(searchHistoryControllerProvider.notifier).refresh(),
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

class _SearchHistoryItem extends StatelessWidget {
  const _SearchHistoryItem({
    required this.query,
    required this.onTap,
    required this.onRemove,
    this.focusNode,
    this.focusVerticalAlignment = 0.22,
  });

  final String query;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final FocusNode? focusNode;
  final double focusVerticalAlignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MoviEnsureVisibleOnFocus(
      verticalAlignment: focusVerticalAlignment,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            focusNode: focusNode,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      query,
                      style: theme.textTheme.bodyLarge,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const MoviAssetIcon(
                      AppAssets.iconDelete,
                      width: 25,
                      height: 25,
                      color: Colors.white,
                    ),
                    onPressed: onRemove,
                    tooltip: AppLocalizations.of(context)!.delete,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedSagaCard extends StatefulWidget {
  const _AnimatedSagaCard({
    required this.saga,
    required this.delay,
    this.focusNode,
    this.onFirstLeft,
  });

  final SagaSummary saga;
  final Duration delay;
  final FocusNode? focusNode;
  final VoidCallback? onFirstLeft;

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
            child: Focus(
              canRequestFocus: false,
              onKeyEvent: (_, event) =>
                  FocusDirectionalNavigation.handleDirectionalTransition(
                    event,
                    onLeft: widget.onFirstLeft == null
                        ? null
                        : () {
                            widget.onFirstLeft!();
                            return true;
                          },
                    blockLeft: false,
                    blockRight: false,
                    blockUp: false,
                    blockDown: false,
                  ),
              child: _SagaCard(saga: widget.saga, focusNode: widget.focusNode),
            ),
          ),
        );
      },
    );
  }
}

class _SagaCard extends ConsumerWidget {
  const _SagaCard({required this.saga, this.focusNode});

  final SagaSummary saga;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final textStyle =
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    return MoviFocusableAction(
      focusNode: focusNode,
      onPressed: () => navigateToSagaDetail(
        context,
        ref,
        sagaId: saga.id.value,
        originRegionId: AppFocusRegionId.searchResultsSagas,
        fallbackRegionId: AppFocusRegionId.searchResultsSagas,
      ),
      semanticLabel: saga.title.display,
      builder: (context, state) {
        return MoviFocusFrame(
          scale: state.focused ? 1.035 : 1,
          child: SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: state.focused
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: state.focused
                        ? [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.18),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildPosterImage(saga.cover, 150, 225),
                  ),
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
      },
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
      return MoviNetworkImage(
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
