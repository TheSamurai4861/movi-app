import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/directional_edge.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/domain/focus_region_exit_map.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/theme/app_colors.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_track_series_button.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart';
import 'package:movi/src/features/tv/presentation/models/tv_detail_view_model.dart';
import 'package:movi/src/features/tv/presentation/services/episode_playback_page_telemetry.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/performance/domain/performance_diagnostic_logger.dart';
import 'package:movi/src/shared/domain/constants/playback_progress_thresholds.dart';
import 'package:movi/src/shared/presentation/providers/playback_history_providers.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/player/domain/entities/playback_selection_decision.dart';
import 'package:movi/src/features/player/domain/entities/playback_launch_plan.dart';
import 'package:movi/src/features/player/domain/entities/playback_selection_preferences.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/player/domain/value_objects/preferred_playback_quality.dart';
import 'package:movi/src/core/network/network.dart';
import 'package:movi/src/features/welcome/presentation/utils/error_presenter.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/home/presentation/widgets/home_layout_constants.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/library/presentation/widgets/library_playlist_card.dart';
import 'package:movi/src/features/playlist/playlist.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/core/parental/presentation/utils/parental_reason_localizer.dart';
import 'package:movi/src/core/parental/presentation/widgets/restricted_content_sheet.dart';
import 'package:movi/src/core/reporting/presentation/widgets/report_problem_sheet.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/features/tv/domain/entities/episode_playback_season_snapshot.dart';
import 'package:movi/src/core/subscription/subscription.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/features/tv/presentation/widgets/episode_playback_variant_sheet.dart';
import 'package:movi/src/features/series_tracking/presentation/providers/series_tracking_providers.dart';

class TvDetailPage extends ConsumerStatefulWidget {
  const TvDetailPage({super.key, required this.seriesId});

  final String seriesId;

  @override
  ConsumerState<TvDetailPage> createState() => _TvDetailPageState();
}

enum EpisodeSortOrder { ascending, descending }

enum _TvHeroAction { primary, changeVersion, tracking, favorite }

@visibleForTesting
Widget buildTvDetailMobileHeroLogo({
  required String mediaTitle,
  required TextStyle titleStyle,
  required double maxWidth,
  Uri? logo,
}) {
  return Semantics(
    header: true,
    label: mediaTitle,
    child: logo == null
        ? Text(
            mediaTitle,
            style: titleStyle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          )
        : MoviResponsiveLogo(
            imageUrl: logo.toString(),
            semanticLabel: mediaTitle,
            alignment: Alignment.center,
            maxWidth: maxWidth,
            reservedHeight: 84,
            wideMaxHeight: 84,
            tallMaxHeight: 112,
            blockyMaxHeight: 132,
            blockyRatioThreshold: 1.45,
            overflowUpFactor: 1.0,
            extraUpOffset: 16,
            onErrorFallback: (_) => Text(
              mediaTitle,
              style: titleStyle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
  );
}

/// ClÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©s "saison:ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©pisode" considÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©rÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©es comme terminÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©es (>= 95%).
final _seriesSeenStateProvider =
    FutureProvider.family<SeriesSeenState?, String>((ref, seriesId) async {
      final locator = ref.watch(slProvider);
      if (!locator.isRegistered<SeriesSeenStateRepository>()) {
        return null;
      }
      final userId = ref.watch(currentUserIdProvider);
      return locator<SeriesSeenStateRepository>().getSeenState(
        seriesId,
        userId: userId,
      );
    });

final _watchedEpisodeKeysProvider = FutureProvider.family<Set<String>, String>((
  ref,
  seriesId,
) async {
  final historyRepo = ref.watch(slProvider)<HistoryLocalRepository>();
  final userId = ref.watch(currentUserIdProvider);
  final entries = await historyRepo.readAll(ContentType.series, userId: userId);
  final seenState = await ref.watch(_seriesSeenStateProvider(seriesId).future);

  final watched = <String>{};
  for (final e in entries) {
    if (e.contentId != seriesId) continue;
    final s = e.season;
    final ep = e.episode;
    if (s == null || ep == null) continue;
    final d = e.duration;
    if (d == null || d.inSeconds <= 0) continue;
    final pos = e.lastPosition?.inSeconds ?? 0;
    final progress = pos / d.inSeconds;
    if (progress >= PlaybackProgressThresholds.maxInProgress) {
      watched.add('$s:$ep');
    }
  }
  if (seenState?.seasonNumber != null && seenState?.episodeNumber != null) {
    watched.add('${seenState!.seasonNumber}:${seenState.episodeNumber}');
  }
  return watched;
});

class _TvDetailPageState extends ConsumerState<TvDetailPage>
    with TickerProviderStateMixin {
  static void _noop() {}
  static const double _heroFocusVerticalAlignment = 0.0;
  static const double _heroTopBarFocusVerticalAlignment = 0.0;
  bool _overviewExpanded = false;
  bool _isTransitioningFromLoading = true;
  late TabController _tabController;
  EpisodeSortOrder _episodeSortOrder = EpisodeSortOrder.ascending;
  String mediaTitle =
      'ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â';
  String yearText =
      'ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â';
  String seasonsCountText =
      'ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â';
  String ratingText =
      'ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â';
  String overviewText = '';
  List<MoviPerson> cast = const [];
  List<SeasonViewModel> seasons = const [];
  TvDetailViewModel? _lastVm;
  String? _lastHeroLogoDiagnosticSignature;
  bool _changeVersionFocused = false;
  Timer? _autoRefreshTimer;
  Timer? _seasonsCheckTimer;
  bool _reloadInFlight = false;
  DateTime? _lastReloadAt;
  int _retryCount = 0;
  bool _seasonTabListenerAttached = false;
  bool _seasonTabsFocused = false;
  bool _desktopEntryFocusApplied = false;
  bool _mobileEntryTopApplied = false;
  final Map<int, DateTime> _seasonLoadingStartTimes = {};
  final Map<String, FocusNode> _seasonEpisodeFocusNodes = {};
  final Map<int, int> _lastFocusedEpisodeIndexBySeason = {};
  final Map<int, FocusNode> _castFocusNodes = {};
  final ScrollController _pageScrollController = ScrollController(
    keepScrollOffset: false,
  );
  final FocusNode _primaryActionFocusNode = FocusNode(
    debugLabel: 'TvDetailPrimaryAction',
  );
  final FocusNode _changeVersionFocusNode = FocusNode(
    debugLabel: 'TvDetailChangeVersion',
  );
  final FocusNode _trackSeriesFocusNode = FocusNode(
    debugLabel: 'TvDetailTrackSeries',
  );
  final FocusNode _favoriteActionFocusNode = FocusNode(
    debugLabel: 'TvDetailFavorite',
  );
  final FocusNode _seasonTabsFocusNode = FocusNode(
    debugLabel: 'TvDetailSeasonTabs',
  );
  final FocusNode _backFocusNode = FocusNode(debugLabel: 'TvHeroBack');
  final FocusNode _moreFocusNode = FocusNode(debugLabel: 'TvHeroMore')
    ..canRequestFocus = false;
  _TvHeroAction _lastFocusedHeroAction = _TvHeroAction.primary;
  int? _lastFocusedCastIndex;
  int? _pendingEpisodeFocusSeasonNumber;
  int? _pendingEpisodeFocusVisibleIndex;
  static const int _maxRetries = 3;
  static const Duration _loadingTimeout = Duration(seconds: 15);
  static const Duration _seasonLoadingTimeout = Duration(seconds: 10);
  static const Duration _seasonsCheckInterval = Duration(seconds: 3);
  static const Duration _reloadCooldown = Duration(seconds: 2);

  static const String _spoilerModeStorageKey = 'prefs.tv_spoiler_mode_enabled';
  final FlutterSecureStorage _spoilerStorage = const FlutterSecureStorage();
  bool _spoilerModeEnabled = false;

  void _requestReload(String mediaId) {
    if (!mounted) return;
    if (_reloadInFlight) return;

    final now = DateTime.now();
    final last = _lastReloadAt;
    if (last != null && now.difference(last) < _reloadCooldown) return;

    final current = ref.read(tvDetailProgressiveControllerProvider(mediaId));
    if (current.isLoading) return;

    _reloadInFlight = true;
    _lastReloadAt = now;
    ref.invalidate(tvDetailProgressiveControllerProvider(mediaId));

    // LibÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¨re le verrou aprÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¨s un court dÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©lai pour ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©viter les rafales.
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _reloadInFlight = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _isTransitioningFromLoading = true;
    _mobileEntryTopApplied = false;
    _pendingEpisodeFocusSeasonNumber = null;
    _pendingEpisodeFocusVisibleIndex = null;
    _lastFocusedCastIndex = null;
    _lastFocusedEpisodeIndexBySeason.clear();
    _tabController = TabController(length: 1, vsync: this);
    _startAutoRefreshTimer();
    _startSeasonsCheckTimer();
    unawaited(_loadSpoilerMode());
    unawaited(_refreshSeriesTrackingState());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetScrollToTopForMobile();
      _ensureDesktopTopAndPrimaryFocus();
    });
  }

  @override
  void didUpdateWidget(covariant TvDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seriesId != widget.seriesId) {
      _desktopEntryFocusApplied = false;
      _mobileEntryTopApplied = false;
      _pendingEpisodeFocusSeasonNumber = null;
      _pendingEpisodeFocusVisibleIndex = null;
      _lastFocusedCastIndex = null;
      _lastFocusedEpisodeIndexBySeason.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resetScrollToTopForMobile();
        _ensureDesktopTopAndPrimaryFocus();
      });
    }
  }

  Future<void> _loadSpoilerMode() async {
    try {
      final raw = await _spoilerStorage.read(key: _spoilerModeStorageKey);
      final enabled = raw == '1' || raw == 'true';
      if (!mounted) return;
      setState(() => _spoilerModeEnabled = enabled);
    } catch (_) {
      // Best-effort: ignore storage errors.
    }
  }

  Future<void> _setSpoilerMode(bool enabled) async {
    if (_spoilerModeEnabled == enabled) return;
    if (mounted) setState(() => _spoilerModeEnabled = enabled);
    try {
      if (enabled) {
        await _spoilerStorage.write(key: _spoilerModeStorageKey, value: '1');
      } else {
        await _spoilerStorage.delete(key: _spoilerModeStorageKey);
      }
    } catch (_) {
      // Best-effort: ignore storage errors.
    }
  }

  Future<void> _refreshSeriesTrackingState() async {
    await ref
        .read(seriesTrackingToggleProvider.notifier)
        .refreshTrackedSeriesStatus(widget.seriesId);
    await ref
        .read(seriesTrackingToggleProvider.notifier)
        .markSeen(widget.seriesId);
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _seasonsCheckTimer?.cancel();
    if (_seasonTabListenerAttached) {
      _tabController.removeListener(_onSeasonTabChanged);
    }
    for (final node in _seasonEpisodeFocusNodes.values) {
      node.dispose();
    }
    for (final node in _castFocusNodes.values) {
      node.dispose();
    }
    _primaryActionFocusNode.dispose();
    _changeVersionFocusNode.dispose();
    _trackSeriesFocusNode.dispose();
    _favoriteActionFocusNode.dispose();
    _seasonTabsFocusNode.dispose();
    _backFocusNode.dispose();
    _moreFocusNode.dispose();
    _pageScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSeasonTabChanged() {
    if (!mounted) return;
    // Ignore intermediate animation ticks.
    if (_tabController.indexIsChanging) return;

    final vm = ref
        .read(tvDetailProgressiveControllerProvider(widget.seriesId))
        .value;
    if (vm == null) return;

    final seasonsList = vm.seasons;
    final index = _tabController.index;
    if (index < 0 || index >= seasonsList.length) return;

    final season = seasonsList[index];
    // Si la saison affichÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©e n'a pas encore d'ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©pisodes et n'est pas en chargement,
    // on la charge immÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©diatement (prioritÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â© UX).
    if (!season.isLoadingEpisodes && season.episodes.isEmpty) {
      unawaited(
        ref
            .read(
              tvDetailProgressiveControllerProvider(widget.seriesId).notifier,
            )
            .reloadSeasonEpisodes(season.seasonNumber),
      );
      return;
    }

    if (_pendingEpisodeFocusSeasonNumber == season.seasonNumber) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _tryFulfillPendingEpisodeFocus();
      });
    }
  }

  KeyEventResult _handleHeroBackKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_trackSeriesFocusNode.context != null &&
          _trackSeriesFocusNode.canRequestFocus) {
        _trackSeriesFocusNode.requestFocus();
      } else {
        _moreFocusNode.canRequestFocus = true;
        _moreFocusNode.requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _requestNearestHeroActionFocusFrom(_backFocusNode);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
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

  KeyEventResult _handleHeroTrackingTopBarKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _backFocusNode.requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _moreFocusNode.canRequestFocus = true;
      _moreFocusNode.requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _requestNearestHeroActionFocusFrom(_trackSeriesFocusNode);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleHeroMoreKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_trackSeriesFocusNode.context != null &&
          _trackSeriesFocusNode.canRequestFocus) {
        _trackSeriesFocusNode.requestFocus();
      } else {
        _backFocusNode.requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _requestNearestHeroActionFocusFrom(_moreFocusNode);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String _episodeFocusKey(int seasonNumber, int visibleIndex) {
    return '$seasonNumber:$visibleIndex';
  }

  FocusNode _episodeFocusNode(int seasonNumber, int visibleIndex) {
    final key = _episodeFocusKey(seasonNumber, visibleIndex);
    return _seasonEpisodeFocusNodes.putIfAbsent(
      key,
      () => FocusNode(
        debugLabel: 'TvSeason-$seasonNumber-EpisodeIndex-$visibleIndex',
      ),
    );
  }

  void _syncEpisodeFocusNodesForSeason(int seasonNumber, int count) {
    final keysToRemove = _seasonEpisodeFocusNodes.keys
        .where((key) {
          if (!key.startsWith('$seasonNumber:')) return false;
          final parts = key.split(':');
          if (parts.length != 2) return false;
          final visibleIndex = int.tryParse(parts[1]);
          if (visibleIndex == null) return false;
          return visibleIndex >= count;
        })
        .toList(growable: false);

    for (final key in keysToRemove) {
      _seasonEpisodeFocusNodes.remove(key)?.dispose();
    }
  }

  void _handleEpisodeFocusChanged(
    int seasonNumber,
    int visibleIndex,
    bool focused,
  ) {
    if (!focused) return;
    _lastFocusedEpisodeIndexBySeason[seasonNumber] = visibleIndex;
    if (_pendingEpisodeFocusSeasonNumber == seasonNumber &&
        _pendingEpisodeFocusVisibleIndex == visibleIndex) {
      _pendingEpisodeFocusSeasonNumber = null;
      _pendingEpisodeFocusVisibleIndex = null;
    }
  }

  void _scrollPageToEpisodeSection() {
    if (!_useDesktopDetailLayout(context)) return;
    if (!_pageScrollController.hasClients) return;
    final position = _pageScrollController.position;
    final targetOffset = position.maxScrollExtent;
    if ((targetOffset - position.pixels).abs() < 1) {
      return;
    }
    try {
      position.jumpTo(targetOffset);
    } catch (_) {
      // Best effort: focus can move while the page scrollable is detaching.
    }
  }

  void _resetScrollToTopForMobile() {
    if (!mounted) return;
    if (_useDesktopDetailLayout(context)) return;
    if (_mobileEntryTopApplied) return;
    if (!_pageScrollController.hasClients) return;
    final position = _pageScrollController.position;
    if (position.pixels <= 0) {
      _mobileEntryTopApplied = true;
      return;
    }
    try {
      position.jumpTo(0);
      _mobileEntryTopApplied = true;
    } catch (_) {
      // Best effort while the scrollable is attaching.
    }
  }

  void _ensureDesktopTopAndPrimaryFocus() {
    if (!mounted) return;
    if (!_useDesktopDetailLayout(context)) return;
    if (_desktopEntryFocusApplied) return;

    if (_pageScrollController.hasClients) {
      final position = _pageScrollController.position;
      if (position.pixels > 0) {
        try {
          position.jumpTo(0);
        } catch (_) {
          // Best effort while the scrollable is attaching.
        }
      }
    }

    if (_primaryActionFocusNode.context != null &&
        _primaryActionFocusNode.canRequestFocus) {
      _primaryActionFocusNode.requestFocus();
      _desktopEntryFocusApplied = true;
    }
  }

  int _resolveEpisodeFocusIndexForSeason(int seasonNumber, int itemCount) {
    if (itemCount <= 0) return 0;
    final lastFocused = _lastFocusedEpisodeIndexBySeason[seasonNumber];
    if (lastFocused == null) return 0;
    return lastFocused.clamp(0, itemCount - 1);
  }

  bool _requestSeasonEpisodeFocus({
    required int seasonNumber,
    required int visibleIndex,
    bool scheduleIfUnavailable = true,
  }) {
    final node = _episodeFocusNode(seasonNumber, visibleIndex);
    if (node.context != null && node.canRequestFocus) {
      node.requestFocus();
      _pendingEpisodeFocusSeasonNumber = null;
      _pendingEpisodeFocusVisibleIndex = null;
      return true;
    }

    if (!scheduleIfUnavailable) {
      return false;
    }

    _pendingEpisodeFocusSeasonNumber = seasonNumber;
    _pendingEpisodeFocusVisibleIndex = visibleIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tryFulfillPendingEpisodeFocus();
    });
    return true;
  }

  bool _tryFulfillPendingEpisodeFocus() {
    final seasonNumber = _pendingEpisodeFocusSeasonNumber;
    final visibleIndex = _pendingEpisodeFocusVisibleIndex;
    if (seasonNumber == null || visibleIndex == null) {
      return false;
    }
    return _requestSeasonEpisodeFocus(
      seasonNumber: seasonNumber,
      visibleIndex: visibleIndex,
      scheduleIfUnavailable: false,
    );
  }

  FocusNode _castFocusNode(int index) {
    return _castFocusNodes.putIfAbsent(
      index,
      () => FocusNode(debugLabel: 'TvCast-$index'),
    );
  }

  void _syncCastFocusNodes(int count) {
    final toRemove = _castFocusNodes.keys.where((key) => key >= count).toList();
    for (final key in toRemove) {
      _castFocusNodes.remove(key)?.dispose();
    }
  }

  void _markHeroActionFocused(_TvHeroAction action, bool focused) {
    if (!focused) return;
    _lastFocusedHeroAction = action;
  }

  bool _isFocusNodeActive(FocusNode node) {
    final context = node.context;
    if (context == null || !node.canRequestFocus) {
      return false;
    }
    if (context is Element && !context.mounted) {
      return false;
    }
    return true;
  }

  double? _focusNodeCenterX(FocusNode node) {
    final context = node.context;
    if (context == null) return null;
    if (context is Element && !context.mounted) {
      return null;
    }
    RenderObject? renderObject;
    try {
      renderObject = context.findRenderObject();
    } on FlutterError {
      return null;
    }
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }
    final origin = renderObject.localToGlobal(Offset.zero);
    return origin.dx + (renderObject.size.width / 2);
  }

  bool _requestClosestFocusFrom(
    FocusNode source,
    Iterable<FocusNode> candidates,
  ) {
    final available = candidates.where(_isFocusNodeActive).toList();
    if (available.isEmpty) return false;

    final sourceCenterX = _focusNodeCenterX(source);
    if (sourceCenterX == null) {
      available.first.requestFocus();
      return true;
    }

    available.sort((a, b) {
      final aDistance =
          ((_focusNodeCenterX(a) ?? sourceCenterX) - sourceCenterX).abs();
      final bDistance =
          ((_focusNodeCenterX(b) ?? sourceCenterX) - sourceCenterX).abs();
      return aDistance.compareTo(bDistance);
    });

    available.first.requestFocus();
    return true;
  }

  Iterable<FocusNode> _visibleHeroActionNodes() sync* {
    if (_primaryActionFocusNode.context != null &&
        _primaryActionFocusNode.canRequestFocus) {
      yield _primaryActionFocusNode;
    }
    if (_changeVersionFocusNode.context != null &&
        _changeVersionFocusNode.canRequestFocus) {
      yield _changeVersionFocusNode;
    }
    if (_trackSeriesFocusNode.context != null &&
        _trackSeriesFocusNode.canRequestFocus) {
      yield _trackSeriesFocusNode;
    }
    if (_favoriteActionFocusNode.context != null &&
        _favoriteActionFocusNode.canRequestFocus) {
      yield _favoriteActionFocusNode;
    }
  }

  FocusNode? _focusNodeForHeroAction(_TvHeroAction action) {
    switch (action) {
      case _TvHeroAction.primary:
        return _primaryActionFocusNode;
      case _TvHeroAction.changeVersion:
        return _changeVersionFocusNode;
      case _TvHeroAction.tracking:
        return _trackSeriesFocusNode;
      case _TvHeroAction.favorite:
        return _favoriteActionFocusNode;
    }
  }

  bool _requestNearestHeroActionFocusFrom(FocusNode source) {
    final fallback = _focusNodeForHeroAction(_lastFocusedHeroAction);
    if (_focusNodeCenterX(source) == null &&
        fallback != null &&
        fallback.context != null &&
        fallback.canRequestFocus) {
      fallback.requestFocus();
      return true;
    }
    return _requestClosestFocusFrom(source, _visibleHeroActionNodes());
  }

  bool _requestNearestTopBarFocusFrom(FocusNode source) {
    _moreFocusNode.canRequestFocus = true;
    return _requestClosestFocusFrom(source, [
      _backFocusNode,
      _trackSeriesFocusNode,
      _moreFocusNode,
    ]);
  }

  bool _requestNearestCastFocusFrom(FocusNode source) {
    final fallbackIndex = _lastFocusedCastIndex;
    if (_focusNodeCenterX(source) == null && fallbackIndex != null) {
      final fallbackNode = _castFocusNodes[fallbackIndex];
      if (fallbackNode != null &&
          fallbackNode.context != null &&
          fallbackNode.canRequestFocus) {
        fallbackNode.requestFocus();
        return true;
      }
    }
    final candidates = List<FocusNode>.generate(
      _castFocusNodes.length,
      (index) => _castFocusNode(index),
      growable: false,
    );
    return _requestClosestFocusFrom(source, candidates);
  }

  bool _requestSeasonTabsFocus() {
    if (_seasonTabsFocusNode.context == null ||
        !_seasonTabsFocusNode.canRequestFocus) {
      return false;
    }
    _seasonTabsFocusNode.requestFocus();
    return true;
  }

  bool _requestActiveSeasonEpisodeFocus({bool forcePageToBottom = false}) {
    if (seasons.isEmpty) return false;
    final index = _tabController.index;
    if (index < 0 || index >= seasons.length) return false;

    final season = seasons[index];
    final targetIndex = _resolveEpisodeFocusIndexForSeason(
      season.seasonNumber,
      season.episodes.length,
    );

    if (forcePageToBottom) {
      _scrollPageToEpisodeSection();
    }

    if (_tabController.indexIsChanging) {
      _pendingEpisodeFocusSeasonNumber = season.seasonNumber;
      _pendingEpisodeFocusVisibleIndex = targetIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Future<void>.delayed(const Duration(milliseconds: 180), () {
          if (!mounted) return;
          _tryFulfillPendingEpisodeFocus();
        });
      });
      return true;
    }

    if (season.isLoadingEpisodes || season.episodes.isEmpty) {
      _pendingEpisodeFocusSeasonNumber = season.seasonNumber;
      _pendingEpisodeFocusVisibleIndex = targetIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _tryFulfillPendingEpisodeFocus();
      });
      return true;
    }

    return _requestSeasonEpisodeFocus(
      seasonNumber: season.seasonNumber,
      visibleIndex: targetIndex,
    );
  }

  KeyEventResult _handleEpisodeItemKey(
    int seasonNumber,
    int visibleIndex,
    int itemCount,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _requestSeasonTabsFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (visibleIndex > 0) {
        _episodeFocusNode(seasonNumber, visibleIndex - 1).requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (visibleIndex < itemCount - 1) {
        _episodeFocusNode(seasonNumber, visibleIndex + 1).requestFocus();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  bool _requestHeroActionDownTarget(FocusNode source) {
    if (_requestNearestCastFocusFrom(source)) {
      return true;
    }
    if (_requestSeasonTabsFocus()) {
      return true;
    }
    return _requestActiveSeasonEpisodeFocus();
  }

  KeyEventResult _handleHeroActionKey(
    FocusNode source,
    KeyEvent event, {
    FocusNode? leftNode,
    FocusNode? rightNode,
  }) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _requestNearestTopBarFocusFrom(source);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _requestHeroActionDownTarget(source);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (leftNode != null &&
          leftNode.context != null &&
          leftNode.canRequestFocus) {
        leftNode.requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (rightNode != null &&
          rightNode.context != null &&
          rightNode.canRequestFocus) {
        rightNode.requestFocus();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleCastItemKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _requestNearestHeroActionFocusFrom(_castFocusNode(index));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (!_requestSeasonTabsFocus()) {
        _requestActiveSeasonEpisodeFocus();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (index > 0) {
        _castFocusNode(index - 1).requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_castFocusNodes.containsKey(index + 1)) {
        _castFocusNode(index + 1).requestFocus();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleSeasonTabsKey(
    List<SeasonViewModel> seasons,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (!_requestNearestCastFocusFrom(_seasonTabsFocusNode)) {
        _requestNearestHeroActionFocusFrom(_seasonTabsFocusNode);
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _requestActiveSeasonEpisodeFocus(forcePageToBottom: true);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (_tabController.index > 0) {
        _tabController.animateTo(_tabController.index - 1);
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (_tabController.index < seasons.length - 1) {
        _tabController.animateTo(_tabController.index + 1);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    final mediaId = widget.seriesId;

    _autoRefreshTimer = Timer(_loadingTimeout, () {
      // VÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©rifier mounted AVANT d'utiliser ref
      if (!mounted) return;
      if (_retryCount >= _maxRetries) return;

      try {
        final vmAsync = ref.read(
          tvDetailProgressiveControllerProvider(mediaId),
        );
        // Si toujours en chargement aprÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¨s le timeout, relancer
        if (vmAsync.isLoading && mounted) {
          _retryCount++;
          _requestReload(mediaId);
          if (mounted) {
            _startAutoRefreshTimer();
          }
        }
      } catch (e) {
        // Ignorer les erreurs si le widget est dÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©montÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©
        if (mounted) {
          rethrow;
        }
      }
    });
  }

  void _startSeasonsCheckTimer() {
    _seasonsCheckTimer?.cancel();

    _seasonsCheckTimer = Timer.periodic(_seasonsCheckInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final vmAsync = ref.read(
          tvDetailProgressiveControllerProvider(widget.seriesId),
        );
        final vm = vmAsync.value;
        if (vm == null) return;

        for (final season in vm.seasons) {
          final seasonKey = season.seasonNumber;

          if (season.isLoadingEpisodes) {
            if (!_seasonLoadingStartTimes.containsKey(seasonKey)) {
              _seasonLoadingStartTimes[seasonKey] = DateTime.now();
              continue;
            }

            final loadingStart = _seasonLoadingStartTimes[seasonKey]!;
            final loadingDuration = DateTime.now().difference(loadingStart);
            if (loadingDuration <= _seasonLoadingTimeout) {
              continue;
            }

            final logger = ref.read(slProvider)<AppLogger>();
            logger.debug(
              'Saison ${season.seasonNumber} en chargement depuis ${loadingDuration.inSeconds}s, relance ciblée',
              category: 'tv_detail',
            );

            _seasonLoadingStartTimes[seasonKey] = DateTime.now();
            unawaited(
              ref
                  .read(
                    tvDetailProgressiveControllerProvider(
                      widget.seriesId,
                    ).notifier,
                  )
                  .reloadSeasonEpisodes(season.seasonNumber),
            );
            continue;
          }

          _seasonLoadingStartTimes.remove(seasonKey);
        }
      } catch (e) {
        if (mounted) {
          rethrow;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaId = widget.seriesId;
    final profile = ref.watch(currentProfileProvider);
    final hasRestrictions =
        profile != null && (profile.isKid || profile.pegiLimit != null);

    if (hasRestrictions) {
      final content = ContentReference(
        id: mediaId,
        type: ContentType.series,
        title: MediaTitle(mediaId),
      );
      final decisionAsync = ref.watch(
        parental.contentAgeDecisionProvider(content),
      );
      return decisionAsync.when(
        loading: () => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: const OverlaySplash(),
        ),
        error: (_, __) => _buildAllowedDetail(context, mediaId),
        data: (decision) {
          if (decision.isAllowed) return _buildAllowedDetail(context, mediaId);

          final l10n = AppLocalizations.of(context)!;
          final localizedReason = getLocalizedParentalReason(
            context,
            decision.reason,
          );
          final displayMessage =
              localizedReason ?? l10n.parentalContentRestrictedDefault;

          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(title: Text(l10n.parentalContentRestricted)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 48),
                    const SizedBox(height: 12),
                    Text(displayMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final ok = await RestrictedContentSheet.show(
                          context,
                          ref,
                          profile: profile,
                          reason: decision.reason,
                          originRegionId: AppFocusRegionId.tvDetailPrimary,
                          fallbackRegionId: AppFocusRegionId.tvDetailPrimary,
                        );
                        if (!ok) return;
                        ref.invalidate(
                          parental.contentAgeDecisionProvider(content),
                        );
                        if (mounted) setState(() {});
                      },
                      child: Text('${l10n.parentalUnlockButton} (PIN)'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return _buildAllowedDetail(context, mediaId);
  }

  Widget _buildAllowedDetail(BuildContext context, String mediaId) {
    final vmAsync = ref.watch(tvDetailProgressiveControllerProvider(mediaId));

    // IMPORTANT: pas d'auto-retry. L'utilisateur relance via ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œRÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©essayerÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â.
    vmAsync.whenOrNull(
      error: (_, __) {
        if (mounted) {
          _autoRefreshTimer?.cancel();
        }
      },
      data: (_) {
        if (mounted) {
          _autoRefreshTimer?.cancel();
          _retryCount = 0;
        }
      },
    );

    return vmAsync.when(
      loading: () {
        final cached = _lastVm;
        if (cached == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: OverlaySplash(
              message: AppLocalizations.of(context)!.overlayPreparingMetadata,
            ),
          );
        }

        // ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â°vite le flicker "dÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©tails -> placeholder -> dÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©tails" quand le provider est invalidÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©
        // (ex: saisons longues ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â  charger). On garde l'ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©cran de dÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©tails affichÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©.
        final seasonsLength = cached.seasons.isEmpty
            ? 1
            : cached.seasons.length;
        if (_tabController.length != seasonsLength) {
          _tabController.dispose();
          _tabController = TabController(length: seasonsLength, vsync: this);
        }
        return _buildWithValues(
          mediaTitle: cached.title,
          yearText: cached.yearText,
          seasonsCountText: cached.seasonsCountText,
          ratingText: cached.ratingText,
          overviewText: cached.overviewText,
          cast: cached.cast,
          seasons: cached.seasons,
          isLoading: false,
          logo: cached.logo,
          poster: cached.poster,
          posterBackground: cached.posterBackground,
          backdrop: cached.backdrop,
        );
      },
      error: (e, st) => _buildErrorScaffold(e),
      data: (vm) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _resetScrollToTopForMobile();
          _ensureDesktopTopAndPrimaryFocus();
        });
        _lastVm = vm;
        // DÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©marrer la transition d'opacitÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â© aprÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¨s un court dÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©lai
        if (_isTransitioningFromLoading) {
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

        // VÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©rifier les saisons qui sont en chargement et les tracker
        for (final season in vm.seasons) {
          if (season.isLoadingEpisodes) {
            if (!_seasonLoadingStartTimes.containsKey(season.seasonNumber)) {
              _seasonLoadingStartTimes[season.seasonNumber] = DateTime.now();
            }
          } else {
            _seasonLoadingStartTimes.remove(season.seasonNumber);
          }
        }

        // Update tab controller synchronously when seasons are loaded
        final seasonsLength = vm.seasons.isEmpty ? 1 : vm.seasons.length;
        if (_tabController.length != seasonsLength) {
          _tabController.dispose();
          _tabController = TabController(length: seasonsLength, vsync: this);
        }
        return _buildWithValues(
          mediaTitle: vm.title,
          yearText: vm.yearText,
          seasonsCountText: vm.seasonsCountText,
          ratingText: vm.ratingText,
          overviewText: vm.overviewText,
          cast: vm.cast,
          seasons: vm.seasons,
          isLoading: _isTransitioningFromLoading,
          logo: vm.logo,
          poster: vm.poster,
          posterBackground: vm.posterBackground,
          backdrop: vm.backdrop,
        );
      },
    );
  }

  Widget _buildErrorScaffold(Object e) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isWideLayout = _useDesktopDetailLayout(context);

    final bool isNotFound = e is NotFoundFailure;
    final String title = isNotFound
        ? 'Infos de la sÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©rie indisponibles'
        : l10n.errorConnectionGeneric;
    final String message = e is NetworkFailure
        ? presentFailure(context, e)
        : l10n.errorUnknown;

    final maxContentWidth = isWideLayout ? 520.0 : double.infinity;
    final buttonWidth = isWideLayout ? 360.0 : double.infinity;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isNotFound
                                    ? Icons.info_outline
                                    : Icons.wifi_off_rounded,
                                color: cs.onSurface.withValues(alpha: 0.9),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isNotFound
                                ? 'Certaines informations (synopsis, casting, images) ne sont pas disponibles pour cette sÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©rie.'
                                : message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: SizedBox(
                      width: buttonWidth,
                      child: MoviPrimaryButton(
                        label: l10n.actionRetry,
                        height: 48,
                        expand: !isWideLayout,
                        onPressed: () {
                          ref.invalidate(
                            tvDetailProgressiveControllerProvider(
                              widget.seriesId,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: buttonWidth,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        child: Text(l10n.actionBack),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isNotFound)
                    Center(
                      child: SizedBox(
                        width: buttonWidth,
                        height: 48,
                        child: TextButton(
                          onPressed: () async {
                            final tmdbId = int.tryParse(widget.seriesId);
                            if (tmdbId == null) return;
                            await ReportProblemSheet.show(
                              context,
                              ref,
                              contentType: ContentType.series,
                              tmdbId: tmdbId,
                              contentTitle: mediaTitle,
                              originRegionId: AppFocusRegionId.tvDetailPrimary,
                              fallbackRegionId: AppFocusRegionId.tvDetailPrimary,
                            );
                          },
                          child: Text(l10n.actionReportProblem),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

  void _logHeroLogoDiagnostic(Uri? logo) {
    final url = logo?.toString();
    final path = Uri.tryParse(url ?? '')?.path.toLowerCase() ?? '';
    final bool isSvg = path.endsWith('.svg');
    final String extension = path.contains('.')
        ? path.split('.').last
        : (path.isEmpty ? 'none' : 'unknown');
    final signature = '$url|$isSvg|$extension';
    if (_lastHeroLogoDiagnosticSignature == signature) {
      return;
    }
    _lastHeroLogoDiagnosticSignature = signature;

    ref
        .read(slProvider)<AppLogger>()
        .debug(
          'tv_detail_hero_logo logoPresent=${logo != null} isSvg=$isSvg extension=$extension url=${url ?? 'none'}',
          category: 'tv_detail',
        );
  }

  Widget _buildWithValues({
    required String mediaTitle,
    required String yearText,
    required String seasonsCountText,
    required String ratingText,
    required String overviewText,
    required List<MoviPerson> cast,
    required List<SeasonViewModel> seasons,
    required bool isLoading,
    Uri? logo,
    Uri? poster,
    Uri? posterBackground,
    Uri? backdrop,
  }) {
    this.mediaTitle = mediaTitle;
    this.yearText = yearText;
    this.seasonsCountText = seasonsCountText;
    this.ratingText = ratingText;
    this.overviewText = overviewText;
    this.cast = cast;
    this.seasons = seasons;
    _logHeroLogoDiagnostic(logo);

    final cs = Theme.of(context).colorScheme;
    final isWideLayout = _useDesktopDetailLayout(context);
    final mobileHeroHeight =
        MediaQuery.of(context).size.height *
        HomeLayoutConstants.heroMobileStackHeightFactor;
    return SwipeBackWrapper(
      child: FocusRegionScope(
        regionId: AppFocusRegionId.tvDetailPrimary,
        binding: FocusRegionBinding(
          resolvePrimaryEntryNode: () => _primaryActionFocusNode,
          resolveFallbackEntryNode: () => _backFocusNode,
        ),
        exitMap: FocusRegionExitMap({
          DirectionalEdge.left: AppFocusRegionId.shellSidebar,
        }),
        requestFocusOnMount: isWideLayout,
        debugLabel: 'TvDetailRegion',
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: (_, event) => _handleRouteBackKey(event, context),
          child: Scaffold(
            backgroundColor: cs.surface,
            body: SafeArea(
              top: true,
              bottom: true,
              child: AnimatedOpacity(
                opacity: isLoading ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: Column(
                  children: [
                    Expanded(
                      child: SyncableRefreshIndicator(
                        onRefresh: () async {
                          // RafraÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â®chir aussi le contenu local aprÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¨s la sync
                          ref.invalidate(
                            tvDetailProgressiveControllerProvider(
                              widget.seriesId,
                            ),
                          );
                        },
                        child: SingleChildScrollView(
                          controller: _pageScrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Builder(
                                builder: (heroContext) =>
                                    MoviVerticalEnsureVisibleTarget(
                                      targetContext: heroContext,
                                      child: MoviDetailHeroScene(
                                        isWideLayout: isWideLayout,
                                        mobileHeight: mobileHeroHeight,
                                        overlaySpec: isWideLayout
                                            ? null
                                            : MoviHeroOverlaySpec.home(
                                                isWideLayout: false,
                                              ).copyWith(
                                                globalTintOpacity: 52 / 255,
                                                topOpacities: const <double>[
                                                  1.0,
                                                  0.96,
                                                  0.72,
                                                  0.28,
                                                  0.0,
                                                ],
                                                bottomOpacities: const <double>[
                                                  0.0,
                                                  0.28,
                                                  0.42,
                                                  0.60,
                                                  0.80,
                                                  1.0,
                                                ],
                                              ),
                                        background: _buildHeroImage(
                                          posterBackground,
                                          poster,
                                          backdrop,
                                        ),
                                        children: [
                                          _buildHeroTopBar(
                                            isWideLayout: isWideLayout,
                                          ),
                                          if (!isWideLayout)
                                            _buildMobileHeroOverlay(
                                              mediaTitle: mediaTitle,
                                              yearText: yearText,
                                              seasonsCountText:
                                                  seasonsCountText,
                                              ratingText: ratingText,
                                              logo: logo,
                                            ),
                                          if (isWideLayout)
                                            _buildDesktopHeroOverlay(
                                              mediaTitle: mediaTitle,
                                              yearText: yearText,
                                              seasonsCountText:
                                                  seasonsCountText,
                                              ratingText: ratingText,
                                              overviewText: overviewText,
                                              logo: logo,
                                            ),
                                        ],
                                      ),
                                    ),
                              ),
                              if (!isWideLayout)
                                _buildMobileDynamicPanel(
                                  mediaTitle: mediaTitle,
                                  overviewText: overviewText,
                                ),
                              const SizedBox(height: 32),
                              _buildDistribution(cast),
                              const SizedBox(height: 32),
                              if (seasons.isNotEmpty)
                                _buildSeasonsTabs(seasons),
                              const SizedBox(height: 70),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroTopBar({required bool isWideLayout}) {
    final l10n = AppLocalizations.of(context)!;
    return MoviDetailHeroTopBar(
      isWideLayout: isWideLayout,
      horizontalPadding: _sectionHorizontalPadding(context),
      leading: MoviEnsureVisibleOnFocus(
        verticalAlignment: _heroTopBarFocusVerticalAlignment,
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: (_, event) => _handleHeroBackKey(event),
          child: MoviDetailHeroActionButton(
            focusNode: _backFocusNode,
            iconAsset: AppAssets.iconBack,
            semanticLabel: l10n.semanticsBack,
            onPressed: () => context.pop(),
            isWideLayout: isWideLayout,
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Consumer(
            builder: (context, ref, _) {
              final hasPremiumAsync = ref.watch(
                canAccessPremiumFeatureProvider(
                  PremiumFeature.seriesEpisodeTracking,
                ),
              );
              return hasPremiumAsync.when(
                data: (hasPremium) {
                  if (!hasPremium) {
                    return const SizedBox.shrink();
                  }
                  final seriesId = widget.seriesId;
                  final isTrackedAsync = ref.watch(
                    seriesIsTrackedProvider(seriesId),
                  );
                  return Focus(
                    canRequestFocus: false,
                    onKeyEvent: (_, event) =>
                        _handleHeroTrackingTopBarKey(event),
                    onFocusChange: (focused) {
                      _markHeroActionFocused(_TvHeroAction.tracking, focused);
                    },
                    child: isTrackedAsync.when(
                      data: (isTracked) => MoviTrackSeriesButton(
                        focusNode: _trackSeriesFocusNode,
                        isTracked: isTracked,
                        size: 44,
                        iconSize: 28,
                        focusPadding: const EdgeInsets.all(5),
                        focusedBackgroundColor: const Color(0x807A7A7A),
                        focusedBorderColor: Theme.of(
                          context,
                        ).colorScheme.primary,
                        borderWidth: 2,
                        onPressed: () async {
                          final poster = _lastVm?.poster;
                          await ref
                              .read(seriesTrackingToggleProvider.notifier)
                              .toggle(
                                seriesId: seriesId,
                                title: mediaTitle,
                                poster: poster,
                              );
                        },
                      ),
                      loading: () => MoviTrackSeriesButton(
                        focusNode: _trackSeriesFocusNode,
                        isTracked: false,
                        size: 44,
                        iconSize: 28,
                        focusPadding: const EdgeInsets.all(5),
                        focusedBackgroundColor: const Color(0x807A7A7A),
                        focusedBorderColor: Theme.of(
                          context,
                        ).colorScheme.primary,
                        borderWidth: 2,
                        onPressed: _noop,
                      ),
                      error: (_, __) => MoviTrackSeriesButton(
                        focusNode: _trackSeriesFocusNode,
                        isTracked: false,
                        size: 44,
                        iconSize: 28,
                        focusPadding: const EdgeInsets.all(5),
                        focusedBackgroundColor: const Color(0x807A7A7A),
                        focusedBorderColor: Theme.of(
                          context,
                        ).colorScheme.primary,
                        borderWidth: 2,
                        onPressed: _noop,
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
          const SizedBox(width: 8),
          Focus(
            canRequestFocus: false,
            onKeyEvent: (_, event) => _handleHeroMoreKey(event),
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                _moreFocusNode.canRequestFocus = false;
              }
            },
            child: MoviDetailHeroActionButton(
              focusNode: _moreFocusNode,
              iconAsset: AppAssets.iconMore,
              semanticLabel: l10n.semanticsMoreActions,
              onPressed: _showMoreMenu,
              isWideLayout: isWideLayout,
              iconWidth: 25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeroOverlay({
    required String mediaTitle,
    required String yearText,
    required String seasonsCountText,
    required String ratingText,
    required String overviewText,
    Uri? logo,
  }) {
    return MoviDetailHeroDesktopOverlay(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            label: mediaTitle,
            child: logo == null
                ? Text(
                    mediaTitle,
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
                  )
                : MoviResponsiveLogo(
                    imageUrl: logo.toString(),
                    semanticLabel: mediaTitle,
                    alignment: Alignment.centerLeft,
                    maxWidth: 520,
                    reservedHeight: 72,
                    wideMaxHeight: 72,
                    tallMaxHeight: 128,
                    blockyMaxHeight: 160,
                    blockyRatioThreshold: 1.45,
                    overflowUpFactor: 1.0,
                    extraUpOffset: 18,
                    onErrorFallback: (_) => Text(
                      mediaTitle,
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
                  ),
          ),
          const SizedBox(height: 10),
          _buildMetaPills(
            yearText: yearText,
            seasonsCountText: seasonsCountText,
            ratingText: ratingText,
            alignment: WrapAlignment.start,
          ),
          if (overviewText.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 72,
              child: Text(
                overviewText,
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
          _buildActionButtons(mediaTitle: mediaTitle, expandPrimary: false),
        ],
      ),
    );
  }

  Widget _buildMobileHeroOverlay({
    required String mediaTitle,
    required String yearText,
    required String seasonsCountText,
    required String ratingText,
    Uri? logo,
  }) {
    final titleStyle =
        Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        );
    final screenWidth = MediaQuery.of(context).size.width;
    const heroPillBackground = Color(0x80383838);

    return Positioned(
      left: 20,
      right: 20,
      bottom: HomeLayoutConstants.heroMobileContentBottomInset,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildTvDetailMobileHeroLogo(
            mediaTitle: mediaTitle,
            titleStyle: titleStyle,
            maxWidth: screenWidth * 0.8,
            logo: logo,
          ),
          const SizedBox(height: 16),
          _buildMetaPills(
            yearText: yearText,
            seasonsCountText: seasonsCountText,
            ratingText: ratingText,
            alignment: WrapAlignment.center,
            pillColor: heroPillBackground,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDynamicPanel({
    required String mediaTitle,
    required String overviewText,
  }) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          HomeLayoutConstants.heroMobileContentBottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (overviewText.trim().isNotEmpty)
              _buildMobileOverview(overviewText)
            else
              const SizedBox(height: 8),
            const SizedBox(height: 16),
            _buildActionButtons(mediaTitle: mediaTitle, expandPrimary: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaPills({
    required String yearText,
    required String seasonsCountText,
    required String ratingText,
    required WrapAlignment alignment,
    Color? pillColor,
    List<Widget> leading = const [],
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: alignment,
      children: [
        ...leading,
        MoviPill(
          yearText,
          large: true,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: pillColor,
        ),
        MoviPill(
          seasonsCountText,
          large: true,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: pillColor,
        ),
        MoviPill(
          ratingText,
          large: true,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: pillColor,
          trailingIcon: const MoviAssetIcon(
            AppAssets.iconStarFilled,
            width: 18,
            height: 18,
            color: AppColors.ratingAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons({
    required String mediaTitle,
    required bool expandPrimary,
  }) {
    const iconActionFocusedBackground = Color(0x807A7A7A);
    final primaryButton = Consumer(
      builder: (context, ref, _) {
        final seriesId = widget.seriesId;
        final launchPlanAsync = ref.watch(
          seriesPlaybackLaunchPlanProvider(seriesId),
        );

        return MoviEnsureVisibleOnFocus(
          verticalAlignment: _heroFocusVerticalAlignment,
          child: Focus(
            canRequestFocus: false,
            onFocusChange: (focused) {
              _markHeroActionFocused(_TvHeroAction.primary, focused);
            },
            onKeyEvent: (_, event) => _handleHeroActionKey(
              _primaryActionFocusNode,
              event,
              rightNode: _changeVersionFocusNode,
            ),
            child: MoviPrimaryButton(
              focusNode: _primaryActionFocusNode,
              label: launchPlanAsync.when(
                data: (launchPlan) {
                  if (launchPlan != null &&
                      launchPlan.isResumeEligible &&
                      launchPlan.season != null &&
                      launchPlan.episode != null) {
                    final hasContinueWatchingPremium = ref
                        .watch(
                          canAccessPremiumFeatureProvider(
                            PremiumFeature.localContinueWatching,
                          ),
                        )
                        .maybeWhen(data: (value) => value, orElse: () => false);
                    if (hasContinueWatchingPremium) {
                      return AppLocalizations.of(
                        context,
                      )!.tvResumeSeasonEpisode(
                        launchPlan.season!,
                        launchPlan.episode!,
                      );
                    }
                    return AppLocalizations.of(context)!.homeWatchNow;
                  }
                  return AppLocalizations.of(context)!.homeWatchNow;
                },
                loading: () => AppLocalizations.of(context)!.homeWatchNow,
                error: (_, __) => AppLocalizations.of(context)!.homeWatchNow,
              ),
              assetIcon: AppAssets.iconPlay,
              buttonStyle: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              onPressed: () async {
                final hasContinueWatchingPremium = ref
                    .read(
                      canAccessPremiumFeatureProvider(
                        PremiumFeature.localContinueWatching,
                      ),
                    )
                    .maybeWhen(data: (value) => value, orElse: () => false);
                if (!hasContinueWatchingPremium) {
                  // Non-premium: always start from S1E1 (no resume).
                  // ignore: use_build_context_synchronously
                  await _openFirstEpisode(startFromBeginning: true);
                  return;
                }
                // ignore: use_build_context_synchronously
                await _playSeries(
                  context,
                  seriesId,
                  mediaTitle,
                  startFromBeginning: false,
                );
              },
            ),
          ),
        );
      },
    );

    final playButton = expandPrimary
        ? Expanded(child: primaryButton)
        : SizedBox(width: 320, child: primaryButton);

    return SizedBox(
      height: expandPrimary ? 55 : 48,
      child: Row(
        mainAxisSize: expandPrimary ? MainAxisSize.max : MainAxisSize.min,
        children: [
          playButton,
          const SizedBox(width: 12),
          Consumer(
            builder: (context, ref, _) {
              return MoviEnsureVisibleOnFocus(
                verticalAlignment: _heroFocusVerticalAlignment,
                child: Focus(
                  canRequestFocus: false,
                  onFocusChange: (focused) {
                    if (_changeVersionFocused == focused) return;
                    if (focused) {
                      _markHeroActionFocused(
                        _TvHeroAction.changeVersion,
                        focused,
                      );
                    }
                    setState(() => _changeVersionFocused = focused);
                  },
                  onKeyEvent: (_, event) => _handleHeroActionKey(
                    _changeVersionFocusNode,
                    event,
                    leftNode: _primaryActionFocusNode,
                    rightNode: _favoriteActionFocusNode,
                  ),
                  child: Semantics(
                    button: true,
                    label: AppLocalizations.of(context)!.actionChangeVersion,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          focusNode: _changeVersionFocusNode,
                          onTap: () async {
                            await _chooseSeriesVersion(mediaTitle);
                          },
                          borderRadius: BorderRadius.circular(22),
                          child: AnimatedScale(
                            scale: _changeVersionFocused ? 1.05 : 1,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: _changeVersionFocused
                                    ? iconActionFocusedBackground
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: _changeVersionFocused
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const MoviAssetIcon(
                                AppAssets.iconChange,
                                width: 28,
                                height: 28,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            height: 44,
            child: Consumer(
              builder: (context, ref, _) {
                final seriesId = widget.seriesId;
                final isFavoriteAsync = ref.watch(
                  tvIsFavoriteProvider(seriesId),
                );

                return isFavoriteAsync.when(
                  data: (isFavorite) => MoviEnsureVisibleOnFocus(
                    verticalAlignment: _heroFocusVerticalAlignment,
                    child: Focus(
                      canRequestFocus: false,
                      onFocusChange: (focused) {
                        _markHeroActionFocused(_TvHeroAction.favorite, focused);
                      },
                      onKeyEvent: (_, event) => _handleHeroActionKey(
                        _favoriteActionFocusNode,
                        event,
                        leftNode: _changeVersionFocusNode,
                      ),
                      child: MoviFavoriteButton(
                        focusNode: _favoriteActionFocusNode,
                        isFavorite: isFavorite,
                        size: 44,
                        iconSize: 28,
                        focusPadding: const EdgeInsets.all(5),
                        focusedBackgroundColor: iconActionFocusedBackground,
                        focusedBorderColor: Theme.of(
                          context,
                        ).colorScheme.primary,
                        borderWidth: 2,
                        onPressed: () async {
                          await ref
                              .read(tvToggleFavoriteProvider.notifier)
                              .toggle(seriesId);
                        },
                      ),
                    ),
                  ),
                  loading: () => MoviEnsureVisibleOnFocus(
                    verticalAlignment: _heroFocusVerticalAlignment,
                    child: Focus(
                      canRequestFocus: false,
                      onFocusChange: (focused) {
                        _markHeroActionFocused(_TvHeroAction.favorite, focused);
                      },
                      onKeyEvent: (_, event) => _handleHeroActionKey(
                        _favoriteActionFocusNode,
                        event,
                        leftNode: _changeVersionFocusNode,
                      ),
                      child: MoviFavoriteButton(
                        focusNode: _favoriteActionFocusNode,
                        isFavorite: false,
                        size: 44,
                        iconSize: 28,
                        focusPadding: const EdgeInsets.all(5),
                        focusedBackgroundColor: iconActionFocusedBackground,
                        focusedBorderColor: Theme.of(
                          context,
                        ).colorScheme.primary,
                        borderWidth: 2,
                        onPressed: _noop,
                      ),
                    ),
                  ),
                  error: (_, __) => MoviEnsureVisibleOnFocus(
                    verticalAlignment: _heroFocusVerticalAlignment,
                    child: Focus(
                      canRequestFocus: false,
                      onFocusChange: (focused) {
                        _markHeroActionFocused(_TvHeroAction.favorite, focused);
                      },
                      onKeyEvent: (_, event) => _handleHeroActionKey(
                        _favoriteActionFocusNode,
                        event,
                        leftNode: _changeVersionFocusNode,
                      ),
                      child: MoviFavoriteButton(
                        focusNode: _favoriteActionFocusNode,
                        isFavorite: false,
                        size: 44,
                        iconSize: 28,
                        focusPadding: const EdgeInsets.all(5),
                        focusedBackgroundColor: iconActionFocusedBackground,
                        focusedBorderColor: Theme.of(
                          context,
                        ).colorScheme.primary,
                        borderWidth: 2,
                        onPressed: _noop,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileOverview(String overviewText) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final synopsisWidth = screenWidth - 40;
        return SizedBox(
          width: synopsisWidth,
          child: Column(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: _overviewExpanded
                      ? const BoxConstraints()
                      : const BoxConstraints(maxHeight: 90),
                  child: Stack(
                    children: [
                      Text(
                        overviewText,
                        style: Theme.of(context).textTheme.bodyLarge,
                        softWrap: true,
                      ),
                      if (!_overviewExpanded)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            ignoring: true,
                            child: Container(
                              height: 41,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    cs.surface.withValues(alpha: 0),
                                    cs.surface,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 102,
                height: 25,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _overviewExpanded = !_overviewExpanded;
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _overviewExpanded
                                ? AppLocalizations.of(context)!.actionCollapse
                                : AppLocalizations.of(context)!.actionExpand,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _overviewExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: cs.onSurface.withValues(alpha: 0.7),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroImage(Uri? posterBackground, Uri? poster, Uri? backdrop) {
    return MoviHeroBackground(
      posterBackground: posterBackground?.toString(),
      poster: poster?.toString(),
      backdrop: backdrop?.toString(),
      placeholderType: PlaceholderType.series,
      imageStrategy: MoviHeroImageStrategy.backdropFirst,
    );
  }

  Widget _buildDistribution(List<MoviPerson> cast) {
    if (cast.isEmpty) return const SizedBox.shrink();
    _syncCastFocusNodes(cast.length);
    final horizontalPadding = _sectionHorizontalPadding(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: horizontalPadding,
            end: horizontalPadding,
          ),
          child: Text(
            AppLocalizations.of(context)!.tvDistribution,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: MoviPersonCard.listHeight,
          child: Builder(
            builder: (listContext) {
              return MoviVerticalEnsureVisibleTarget(
                targetContext: listContext,
                child: ListView.separated(
                  clipBehavior: Clip.none,
                  padding: EdgeInsetsDirectional.only(
                    start: horizontalPadding,
                    end: horizontalPadding,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: cast.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final p = cast[index];
                    return MoviEnsureVisibleOnFocus(
                      horizontalAlignment: 0.18,
                      verticalAlignment: 0.34,
                      child: Focus(
                        canRequestFocus: false,
                        onKeyEvent: (_, event) =>
                            _handleCastItemKey(index, event),
                        onFocusChange: (hasFocus) {
                          if (hasFocus) {
                            _lastFocusedCastIndex = index;
                          }
                        },
                        child: MoviPersonCard(
                          person: p,
                          focusNode: _castFocusNode(index),
                          onTap: (person) {
                            // Convertir MoviPerson en PersonSummary pour la navigation
                            final personSummary = PersonSummary(
                              id: PersonId(person.id),
                              name: person.name,
                              role: person.role,
                              photo: person.poster,
                            );
                            navigateToPersonDetail(
                              context,
                              ref,
                              person: personSummary,
                              triggerFocusNode: _castFocusNode(index),
                              originRegionId: AppFocusRegionId.tvDetailPrimary,
                              fallbackRegionId: AppFocusRegionId.tvDetailPrimary,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonsTabs(List<SeasonViewModel> seasons) {
    if (seasons.isEmpty) return const SizedBox.shrink();

    // Ensure tab controller length matches seasons length
    // This should already be handled in the build method, but double-check here
    if (_tabController.length != seasons.length) {
      if (_seasonTabListenerAttached) {
        _tabController.removeListener(_onSeasonTabChanged);
        _seasonTabListenerAttached = false;
      }
      _tabController.dispose();
      _tabController = TabController(length: seasons.length, vsync: this);
    }

    if (!_seasonTabListenerAttached) {
      _tabController.addListener(_onSeasonTabChanged);
      _seasonTabListenerAttached = true;
      // Charger immÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©diatement la saison sÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©lectionnÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©e si elle n'est pas prÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Âªte.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onSeasonTabChanged(),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final screenType = _screenTypeFor(context);
    final isTvLayout = screenType == ScreenType.tv;
    final isWideLayout =
        screenType == ScreenType.desktop || screenType == ScreenType.tv;
    final horizontalPadding = _sectionHorizontalPadding(context);
    final tabViewHeight = isWideLayout ? 360.0 : 600.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: horizontalPadding,
                    end: horizontalPadding,
                  ),
                  child: MoviEnsureVisibleOnFocus(
                    verticalAlignment: 0.38,
                    child: Focus(
                      focusNode: _seasonTabsFocusNode,
                      onFocusChange: (hasFocus) {
                        if (_seasonTabsFocused == hasFocus) return;
                        setState(() => _seasonTabsFocused = hasFocus);
                      },
                      onKeyEvent: (_, event) =>
                          _handleSeasonTabsKey(seasons, event),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: ExcludeFocus(
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            labelColor: Theme.of(context).colorScheme.onSurface,
                            unselectedLabelColor: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                            indicatorColor: _seasonTabsFocused
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            labelStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                            tabs: seasons.map((s) {
                              return Tab(
                                text: AppLocalizations.of(
                                  context,
                                )!.tvSeasonLabel(s.seasonNumber),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: tabViewHeight,
                  child: TabBarView(
                    controller: _tabController,
                    children: seasons.map((season) {
                      return _buildSeasonEpisodes(season);
                    }).toList(),
                  ),
                ),
              ],
            ),
            if (!isTvLayout)
              Positioned(
                top: 56,
                right: horizontalPadding,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.08),
                      child: IconButton(
                        padding: const EdgeInsets.all(10),
                        icon: Transform.flip(
                          flipX:
                              _episodeSortOrder == EpisodeSortOrder.descending,
                          child: const MoviAssetIcon(
                            AppAssets.iconSort,
                            width: 24,
                            height: 24,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _episodeSortOrder =
                                _episodeSortOrder == EpisodeSortOrder.ascending
                                ? EpisodeSortOrder.descending
                                : EpisodeSortOrder.ascending;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 48,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        cs.surface.withValues(alpha: 0.3),
                        cs.surface.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSeasonEpisodeFocusable({
    required int seasonNumber,
    required int visibleIndex,
    required int itemCount,
    required EpisodeViewModel episode,
    required bool hideSpoilers,
    bool enableVerticalScroll = true,
    required Widget Function(BuildContext, MoviInteractiveState) builder,
  }) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) =>
          _handleEpisodeItemKey(seasonNumber, visibleIndex, itemCount, event),
      onFocusChange: (focused) {
        _handleEpisodeFocusChanged(seasonNumber, visibleIndex, focused);
      },
      child: MoviEnsureVisibleOnFocus(
        enableVerticalScroll: enableVerticalScroll,
        horizontalAlignment: enableVerticalScroll ? null : 0.18,
        verticalAlignment: 0.38,
        child: MoviFocusableAction(
          focusNode: _episodeFocusNode(seasonNumber, visibleIndex),
          onPressed: () => _openEpisodePlayer(episode, seasonNumber),
          semanticLabel: hideSpoilers
              ? 'Episode ${episode.episodeNumber}'
              : episode.title,
          builder: builder,
        ),
      ),
    );
  }

  Widget _buildSeasonEpisodes(SeasonViewModel season) {
    if (season.isLoadingEpisodes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (season.episodes.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.tvNoEpisodesAvailable,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    final sortedEpisodes = List<EpisodeViewModel>.from(season.episodes);
    if (_episodeSortOrder == EpisodeSortOrder.descending) {
      sortedEpisodes.sort((a, b) => b.episodeNumber.compareTo(a.episodeNumber));
    } else {
      sortedEpisodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
    }

    _syncEpisodeFocusNodesForSeason(season.seasonNumber, sortedEpisodes.length);
    final activeSeasonNumber =
        (_tabController.index >= 0 && _tabController.index < seasons.length)
        ? seasons[_tabController.index].seasonNumber
        : null;
    if (activeSeasonNumber == season.seasonNumber &&
        _pendingEpisodeFocusSeasonNumber == season.seasonNumber) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _tryFulfillPendingEpisodeFocus();
      });
    }

    final watchedKeys =
        ref.watch(_watchedEpisodeKeysProvider(widget.seriesId)).value ??
        const <String>{};

    if (_useDesktopDetailLayout(context)) {
      return Builder(
        builder: (listContext) {
          return MoviVerticalEnsureVisibleTarget(
            targetContext: listContext,
            child: ListView.separated(
              clipBehavior: Clip.none,
              padding: EdgeInsetsDirectional.only(
                start: _sectionHorizontalPadding(context),
                end: _sectionHorizontalPadding(context),
                top: 20,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: sortedEpisodes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 18),
              itemBuilder: (context, index) {
                final episode = sortedEpisodes[index];
                final hideSpoilers =
                    _spoilerModeEnabled &&
                    !watchedKeys.contains(
                      '${season.seasonNumber}:${episode.episodeNumber}',
                    );
                return _buildSeasonEpisodeFocusable(
                  seasonNumber: season.seasonNumber,
                  visibleIndex: index,
                  itemCount: sortedEpisodes.length,
                  episode: episode,
                  hideSpoilers: hideSpoilers,
                  enableVerticalScroll: false,
                  builder: (context, state) {
                    return SizedBox(
                      width: 320,
                      child: _buildDesktopEpisodeCard(
                        episode,
                        hideSpoilers: hideSpoilers,
                        focused: state.focused,
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      );
    }

    return ListView.separated(
      clipBehavior: Clip.none,
      padding: const EdgeInsetsDirectional.only(start: 20, end: 20, top: 20),
      itemCount: sortedEpisodes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final episode = sortedEpisodes[index];
        final hideSpoilers =
            _spoilerModeEnabled &&
            !watchedKeys.contains(
              '${season.seasonNumber}:${episode.episodeNumber}',
            );
        return _buildSeasonEpisodeFocusable(
          seasonNumber: season.seasonNumber,
          visibleIndex: index,
          itemCount: sortedEpisodes.length,
          episode: episode,
          hideSpoilers: hideSpoilers,
          builder: (context, state) {
            final accent = Theme.of(context).colorScheme.primary;
            return MoviFocusFrame(
              scale: state.focused ? 1.015 : 1,
              borderRadius: BorderRadius.circular(18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: state.focused ? accent : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: _buildEpisodeCard(episode, hideSpoilers: hideSpoilers),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEpisodeCard(
    EpisodeViewModel episode, {
    required bool hideSpoilers,
  }) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        // La vignette doit laisser de la place au texte (titre + pills).
        // On garde un ratio 178:100 (~16:9) mais la largeur est auto-ajustÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©e.
        // La hauteur est volontairement stable (comme si le titre faisait 2 lignes),
        // pour ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©viter que la vignette "saute" entre 1 et 2 lignes.
        final thumbHeight = (constraints.maxWidth * 0.22).clamp(78.0, 92.0);
        const thumbAspectRatio = 178 / 100;
        final thumbWidth = (thumbHeight * thumbAspectRatio).clamp(120.0, 164.0);
        final thumbCacheWidth = _decodeDimensionForSize(
          context,
          thumbWidth,
          min: 240,
          max: 900,
        );
        final thumbCacheHeight = _decodeDimensionForSize(
          context,
          thumbHeight,
          min: 135,
          max: 506,
        );

        Widget thumbnail() {
          final url = _episodeStillUrl(episode.still, highQuality: false);
          final base = (episode.still == null || url.isEmpty)
              ? Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [cs.surfaceContainerHighest, cs.surfaceContainer],
                    ),
                  ),
                  child: const Center(
                    child: MoviAssetIcon(
                      AppAssets.iconAppLogoSvg,
                      width: 22,
                      height: 22,
                      color: Colors.white,
                    ),
                  ),
                )
              : MoviNetworkImage(
                  url,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  cacheWidth: thumbCacheWidth,
                  cacheHeight: thumbCacheHeight,
                  errorBuilder: (_, __, ___) =>
                      Container(color: cs.surfaceContainerHighest),
                );

          final effectiveBase = hideSpoilers
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    base,
                    BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.22),
                      ),
                    ),
                  ],
                )
              : base;

          final runtime = episode.runtime;
          if (runtime == null) return effectiveBase;

          return Stack(
            fit: StackFit.expand,
            children: [
              effectiveBase,
              Positioned(
                right: 8,
                bottom: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          _formatDuration(runtime),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ) ??
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: thumbWidth,
              height: thumbHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: thumbnail(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hideSpoilers
                        ? 'ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â°pisode ${episode.episodeNumber}'
                        : '${episode.episodeNumber}. ${episode.title}',
                    style:
                        Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ) ??
                        TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (episode.airDate != null)
                        MoviPill(
                          _formatDate(episode.airDate!),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          color: cs.surfaceContainerHighest,
                        ),
                    ],
                  ),
                  if (!episode.isAvailableInPlaylist) ...[
                    const SizedBox(height: 8),
                    MoviPill(
                      AppLocalizations.of(context)!.notYetAvailable,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: Colors.red.withValues(alpha: 0.5),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopEpisodeCard(
    EpisodeViewModel episode, {
    required bool hideSpoilers,
    required bool focused,
  }) {
    final cs = Theme.of(context).colorScheme;
    const cardRadius = 20.0;
    const imageAspectRatio = 178 / 100;
    final focusAccent = Theme.of(context).colorScheme.primary;

    Widget thumbnail() {
      final base = episode.still != null
          ? _buildEpisodeStillImage(
              episode,
              width: double.infinity,
              height: double.infinity,
              colorScheme: cs,
              highQuality: true,
            )
          : _buildEpisodeImagePlaceholder(
              width: double.infinity,
              height: double.infinity,
              colorScheme: cs,
            );

      if (!hideSpoilers) return base;
      return Stack(
        fit: StackFit.expand,
        children: [
          base,
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(color: Colors.black.withValues(alpha: 0.22)),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedScale(
          scale: focused ? 1.03 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(
                color: focused ? focusAccent : Colors.transparent,
                width: 2,
              ),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: focusAccent.withValues(alpha: 0.2),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(cardRadius),
              child: AspectRatio(
                aspectRatio: imageAspectRatio,
                child: thumbnail(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          hideSpoilers
              ? 'ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â°pisode ${episode.episodeNumber}'
              : '${episode.episodeNumber}. ${episode.title}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style:
              Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ) ??
              TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (episode.airDate != null)
              MoviPill(
                _formatDate(episode.airDate!),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: cs.surfaceContainerHighest,
              ),
            if (episode.runtime != null)
              MoviPill(
                _formatDuration(episode.runtime!),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: cs.surfaceContainerHighest,
              ),
            if (!episode.isAvailableInPlaylist)
              MoviPill(
                AppLocalizations.of(context)!.notYetAvailable,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.red.withValues(alpha: 0.5),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEpisodeStillImage(
    EpisodeViewModel episode, {
    required double width,
    required double height,
    required ColorScheme colorScheme,
    required bool highQuality,
  }) {
    final url = _episodeStillUrl(episode.still, highQuality: highQuality);
    final resolvedCacheWidth = width.isFinite
        ? _decodeDimensionForSize(
            context,
            width,
            min: highQuality ? 640 : 320,
            max: highQuality ? 1280 : 780,
          )
        : (highQuality ? 1280 : 780);
    final resolvedCacheHeight = height.isFinite
        ? _decodeDimensionForSize(
            context,
            height,
            min: highQuality ? 360 : 180,
            max: highQuality ? 720 : 440,
          )
        : (highQuality ? 720 : 440);

    return MoviNetworkImage(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      filterQuality: highQuality ? FilterQuality.high : FilterQuality.medium,
      cacheWidth: resolvedCacheWidth,
      cacheHeight: resolvedCacheHeight,
      errorBuilder: (_, __, ___) => _buildEpisodeImagePlaceholder(
        width: width,
        height: height,
        colorScheme: colorScheme,
      ),
    );
  }

  String _episodeStillUrl(Uri? still, {required bool highQuality}) {
    final url = still?.toString() ?? '';
    if (url.isEmpty) {
      return url;
    }

    return url.replaceFirst('/w185/', highQuality ? '/w780/' : '/w300/');
  }

  int _decodeDimensionForSize(
    BuildContext context,
    double logicalSize, {
    required int min,
    required int max,
  }) {
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final physical = (logicalSize * dpr).round();
    return physical.clamp(min, max);
  }

  Widget _buildEpisodeImagePlaceholder({
    required double width,
    required double height,
    required ColorScheme colorScheme,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth = width.isFinite ? width : constraints.maxWidth;
        final effectiveHeight = height.isFinite
            ? height
            : constraints.maxHeight;
        final shortestSide = effectiveWidth < effectiveHeight
            ? effectiveWidth
            : effectiveHeight;
        final logoSize = (shortestSide * 0.16).clamp(18.0, 30.0);

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surfaceContainerHighest,
                colorScheme.surfaceContainer,
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.15),
                    radius: 1.05,
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Center(
                child: MoviAssetIcon(
                  AppAssets.iconAppLogoSvg,
                  width: logoSize,
                  height: logoSize,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final locale = Localizations.localeOf(context);
    return DateFormat('d MMMM yyyy', locale.toString()).format(date);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remainingMinutes}m';
  }

  List<EpisodePlaybackSeasonSnapshot> _buildEpisodePlaybackSeasonSnapshots(
    List<SeasonViewModel> seasons,
  ) {
    return seasons
        .map(
          (season) => EpisodePlaybackSeasonSnapshot.fromEpisodeNumbers(
            seasonNumber: season.seasonNumber,
            episodeNumbers: season.episodes.map(
              (episode) => episode.episodeNumber,
            ),
          ),
        )
        .toList(growable: false);
  }

  VideoSource _buildEpisodePlayerSource({
    required PlaybackSelectionDecision decision,
    required PlaybackVariant variant,
    required String title,
    required Uri? poster,
    required bool startFromBeginning,
  }) {
    final launchPlan = decision.launchPlan;
    if (launchPlan != null) {
      return launchPlan.buildVideoSource(
        source: variant.videoSource,
        title: title,
        poster: poster,
        startFromBeginning: startFromBeginning,
      );
    }
    return VideoSource(
      url: variant.videoSource.url,
      title: title,
      contentId: widget.seriesId,
      tmdbId: variant.videoSource.tmdbId,
      contentType: ContentType.series,
      poster: poster,
      season: variant.videoSource.season,
      episode: variant.videoSource.episode,
      resumePosition: startFromBeginning
          ? Duration.zero
          : variant.videoSource.resumePosition,
    );
  }

  PlaybackSelectionPreferences _buildEpisodePlaybackPreferences() {
    return PlaybackSelectionPreferences(
      preferredAudioLanguageCode: ref.read(
        asp.currentPreferredAudioLanguageProvider,
      ),
      preferredSubtitleLanguageCode: ref.read(
        asp.currentPreferredSubtitleLanguageProvider,
      ),
      preferredQualityRank: ref
          .read(asp.currentPreferredPlaybackQualityProvider)
          ?.minimumQualityRank,
    );
  }

  Future<PlaybackSelectionDecision> _loadEpisodePlaybackSelection({
    required int seasonNumber,
    required int episodeNumber,
    required List<SeasonViewModel> seasons,
  }) async {
    final useCase = ref.read(resolveEpisodePlaybackSelectionUseCaseProvider);
    final userId = ref.read(currentUserIdProvider);
    final candidateSourceIds = ref
        .read(asp.appStateControllerProvider)
        .preferredIptvSourceIds;

    return useCase(
      seriesId: widget.seriesId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      seasonSnapshots: _buildEpisodePlaybackSeasonSnapshots(seasons),
      preferences: _buildEpisodePlaybackPreferences(),
      context: const PlaybackSelectionContext(contentType: ContentType.series),
      userId: userId,
      candidateSourceIds: candidateSourceIds,
    );
  }

  Future<PlaybackLaunchPlan?> _loadSeriesPlaybackLaunchPlan() {
    return ref.read(seriesPlaybackLaunchPlanProvider(widget.seriesId).future);
  }

  ({SeasonViewModel season, EpisodeViewModel episode})?
  _resolveSeriesPlaybackTarget({
    required List<SeasonViewModel> seasons,
    required PlaybackLaunchPlan? launchPlan,
  }) {
    final targetSeasonNumber = launchPlan?.season;
    final targetEpisodeNumber = launchPlan?.episode;
    if (targetSeasonNumber == null || targetEpisodeNumber == null) {
      return null;
    }

    for (final season in seasons) {
      if (season.seasonNumber != targetSeasonNumber) {
        continue;
      }
      for (final episode in season.episodes) {
        if (episode.episodeNumber == targetEpisodeNumber) {
          return (season: season, episode: episode);
        }
      }
      return null;
    }
    return null;
  }

  ({SeasonViewModel season, EpisodeViewModel episode})?
  _findSeasonEpisodeTarget({
    required List<SeasonViewModel> seasons,
    required int seasonNumber,
    required int episodeNumber,
  }) {
    for (final season in seasons) {
      if (season.seasonNumber != seasonNumber) {
        continue;
      }
      for (final episode in season.episodes) {
        if (episode.episodeNumber == episodeNumber) {
          return (season: season, episode: episode);
        }
      }
      return null;
    }
    return null;
  }

  List<SeasonViewModel> _currentSeriesSeasonsSnapshot() {
    final vmAsync = ref.read(
      tvDetailProgressiveControllerProvider(widget.seriesId),
    );
    final vm = vmAsync.value;
    return (vm?.seasons ?? seasons).toList(growable: false);
  }

  Future<void> _waitForSeasonLoadingToFinish({
    required int seasonNumber,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final startedAt = DateTime.now();
    while (DateTime.now().difference(startedAt) < timeout) {
      final seasonsSnapshot = _currentSeriesSeasonsSnapshot();
      SeasonViewModel? seasonSnapshot;
      for (final season in seasonsSnapshot) {
        if (season.seasonNumber == seasonNumber) {
          seasonSnapshot = season;
          break;
        }
      }
      if (seasonSnapshot == null || !seasonSnapshot.isLoadingEpisodes) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
  }

  Future<({SeasonViewModel season, EpisodeViewModel episode})?>
  _resolveSeriesPlaybackTargetWithLazyLoad({
    required int seasonNumber,
    required int episodeNumber,
  }) async {
    var seasonsSnapshot = _currentSeriesSeasonsSnapshot();
    var target = _findSeasonEpisodeTarget(
      seasons: seasonsSnapshot,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
    if (target != null) {
      return target;
    }

    SeasonViewModel? seasonSnapshot;
    for (final season in seasonsSnapshot) {
      if (season.seasonNumber == seasonNumber) {
        seasonSnapshot = season;
        break;
      }
    }
    if (seasonSnapshot == null) {
      return null;
    }

    if (seasonSnapshot.isLoadingEpisodes) {
      await _waitForSeasonLoadingToFinish(seasonNumber: seasonNumber);
    } else if (seasonSnapshot.episodes.isEmpty) {
      await ref
          .read(tvDetailProgressiveControllerProvider(widget.seriesId).notifier)
          .reloadSeasonEpisodes(seasonNumber);
    }

    seasonsSnapshot = _currentSeriesSeasonsSnapshot();
    return _findSeasonEpisodeTarget(
      seasons: seasonsSnapshot,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
    );
  }

  Future<void> _openFirstEpisode({required bool startFromBeginning}) async {
    final vmAsync = ref.read(
      tvDetailProgressiveControllerProvider(widget.seriesId),
    );
    final vm = vmAsync.value;
    final seasonsList = (vm?.seasons ?? seasons).toList(growable: false);

    if (seasonsList.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.snackbarLoadingEpisodes),
        ),
      );
      return;
    }

    final sortedSeasons = seasonsList.toList(growable: true)
      ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));
    final firstSeason = sortedSeasons.first;

    if (firstSeason.isLoadingEpisodes || firstSeason.episodes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.snackbarLoadingEpisodes),
        ),
      );
      return;
    }

    final sortedEpisodes = firstSeason.episodes.toList(growable: true)
      ..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
    final firstEpisode = sortedEpisodes.first;

    await _openEpisodePlayer(
      firstEpisode,
      firstSeason.seasonNumber,
      startFromBeginning: startFromBeginning,
    );
  }

  Future<void> _openEpisodePlayer(
    EpisodeViewModel episode,
    int seasonNumber, {
    bool startFromBeginning = false,
  }) async {
    try {
      final locator = ref.read(slProvider);
      final logger = locator<AppLogger>();
      final diagnostics = locator<PerformanceDiagnosticLogger>();
      final variantSelectionRepo =
          locator<PlaybackVariantSelectionLocalRepository>();
      final vmAsync = ref.read(
        tvDetailProgressiveControllerProvider(widget.seriesId),
      );
      final vm = vmAsync.value;
      final seasonsList = (vm?.seasons ?? seasons).toList(growable: false);
      final decision = await _loadEpisodePlaybackSelection(
        seasonNumber: seasonNumber,
        episodeNumber: episode.episodeNumber,
        seasons: seasonsList,
      );
      if (decision.isUnavailable || decision.rankedVariants.isEmpty) {
        logger.info(
          'Episode playback variants unavailable seriesId=${widget.seriesId}',
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.snackbarEpisodeUnavailableInPlaylist,
            ),
          ),
        );
        return;
      }

      final seriesTitle = vm?.title ?? mediaTitle;
      final episodeTitle = episode.title.isNotEmpty
          ? '$seriesTitle - S${seasonNumber.toString().padLeft(2, '0')}E${episode.episodeNumber.toString().padLeft(2, '0')} - ${episode.title}'
          : '$seriesTitle - S${seasonNumber.toString().padLeft(2, '0')}E${episode.episodeNumber.toString().padLeft(2, '0')}';
      final posterUri = vm?.poster;

      PlaybackVariant? selectedVariant = decision.selectedVariant;
      String? pinnedVariantId;
      try {
        pinnedVariantId = await variantSelectionRepo.getSelectedVariantId(
          widget.seriesId,
          ContentType.series,
        );
      } catch (_) {
        // Best-effort: ignore DB errors.
      }

      if (pinnedVariantId != null) {
        for (final v in decision.rankedVariants) {
          if (v.id == pinnedVariantId) {
            selectedVariant = v;
            break;
          }
        }
      }

      final pinnedVariantFound =
          pinnedVariantId != null &&
          selectedVariant != null &&
          selectedVariant.id == pinnedVariantId;
      if (decision.requiresManualSelection && !pinnedVariantFound) {
        final manual = await EpisodePlaybackVariantSheet.show(
          // ignore: use_build_context_synchronously
          context,
          episodeTitle: episodeTitle,
          variants: decision.rankedVariants,
        );
        if (manual == null || !mounted || !context.mounted) return;
        selectedVariant = manual;
        try {
          await variantSelectionRepo.upsertSelectedVariantId(
            contentId: widget.seriesId,
            contentType: ContentType.series,
            variantId: selectedVariant.id,
          );
        } catch (_) {
          // Best-effort: ignore DB errors.
        }
      }

      selectedVariant =
          selectedVariant ??
          (decision.rankedVariants.isNotEmpty
              ? decision.rankedVariants.first
              : null);
      if (selectedVariant == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.snackbarEpisodeUnavailableInPlaylist,
            ),
          ),
        );
        return;
      }

      diagnostics.mark(
        EpisodePlaybackPageTelemetry.operation,
        event: 'target_episode_selected',
        category: EpisodePlaybackPageTelemetry.category,
        context: EpisodePlaybackPageTelemetry.targetEpisodeSelectedContext(
          seriesId: widget.seriesId,
          seasonNumber: seasonNumber,
          episodeNumber: episode.episodeNumber,
          decision: decision,
          selectedVariant: selectedVariant,
          startFromBeginning: startFromBeginning,
        ),
      );
      diagnostics.mark(
        EpisodePlaybackPageTelemetry.operation,
        event: EpisodePlaybackPageTelemetry.resumeEvent(
          startFromBeginning: startFromBeginning,
          selectedVariant: selectedVariant,
        ),
        category: EpisodePlaybackPageTelemetry.category,
        context: EpisodePlaybackPageTelemetry.resumeContext(
          seriesId: widget.seriesId,
          seasonNumber: seasonNumber,
          episodeNumber: episode.episodeNumber,
          decision: decision,
          selectedVariant: selectedVariant,
          startFromBeginning: startFromBeginning,
        ),
      );
      if (!mounted) return;
      context.push(
        AppRouteNames.player,
        extra: _buildEpisodePlayerSource(
          decision: decision,
          variant: selectedVariant,
          title: episodeTitle,
          poster: posterUri,
          startFromBeginning: startFromBeginning,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.snackbarGenericError(e.toString()),
          ),
        ),
      );
    }
  }

  Future<void> _chooseSeriesVersion(String mediaTitle) async {
    try {
      final locator = ref.read(slProvider);
      final variantSelectionRepo =
          locator<PlaybackVariantSelectionLocalRepository>();
      final vmAsync = ref.read(
        tvDetailProgressiveControllerProvider(widget.seriesId),
      );
      final vm = vmAsync.value;
      if (vm == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.snackbarLoading),
          ),
        );
        return;
      }

      // On choisit une rÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©fÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©rence stable (ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©pisode de reprise si dispo, sinon S1E1).
      final launchPlan = await _loadSeriesPlaybackLaunchPlan();
      final target = _resolveSeriesPlaybackTarget(
        seasons: vm.seasons,
        launchPlan: launchPlan,
      );
      if (target == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.snackbarLoadingEpisodes,
            ),
          ),
        );
        return;
      }

      final seasonNumber = target.season.seasonNumber;
      final episodeNumber = target.episode.episodeNumber;

      final decision = await _loadEpisodePlaybackSelection(
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        seasons: vm.seasons,
      );
      final variants = decision.rankedVariants;
      if (!mounted) return;
      if (variants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.snackbarNoVersionAvailable,
            ),
          ),
        );
        return;
      }

      final episodeTitle =
          '$mediaTitle - S${seasonNumber.toString().padLeft(2, '0')}E${episodeNumber.toString().padLeft(2, '0')}';
      final manual = await EpisodePlaybackVariantSheet.show(
        context,
        episodeTitle: episodeTitle,
        variants: variants,
      );
      if (manual == null || !mounted || !context.mounted) return;

      await variantSelectionRepo.upsertSelectedVariantId(
        contentId: widget.seriesId,
        contentType: ContentType.series,
        variantId: manual.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.snackbarVersionSaved),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.snackbarGenericError(e.toString()),
          ),
        ),
      );
    }
  }

  Future<void> _playSeries(
    BuildContext context,
    String seriesId,
    String title, {
    bool startFromBeginning = false,
  }) async {
    try {
      final vmAsync = ref.read(tvDetailProgressiveControllerProvider(seriesId));
      final vm = vmAsync.value;
      if (vm == null) {
        if (!mounted) return;
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chargement des ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â©pisodes en cours...',
            ),
          ),
        );
        return;
      }

      final launchPlan = await _loadSeriesPlaybackLaunchPlan();
      final launchSeason = launchPlan?.season;
      final launchEpisode = launchPlan?.episode;
      final target = launchSeason != null && launchEpisode != null
          ? await _resolveSeriesPlaybackTargetWithLazyLoad(
              seasonNumber: launchSeason,
              episodeNumber: launchEpisode,
            )
          : _resolveSeriesPlaybackTarget(
              seasons: vm.seasons,
              launchPlan: launchPlan,
            );
      if (target == null) {
        await _openFirstEpisode(startFromBeginning: startFromBeginning);
        return;
      }

      await _openEpisodePlayer(
        target.episode,
        target.season.seasonNumber,
        startFromBeginning: startFromBeginning,
      );
    } catch (e) {
      final logger = ref.read(slProvider)<AppLogger>();
      logger.error(
        'Erreur lors de la reprise de la sÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â©rie: $e',
        e,
      );
      if (!mounted) return;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.snackbarGenericError(e.toString()),
          ),
        ),
      );
    }
  }

  Future<void> _showAddToListDialog(
    BuildContext context,
    WidgetRef ref,
    String seriesId,
  ) async {
    try {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.snackbarLoadingPlaylists),
        ),
      );

      final playlists = await ref.read(libraryPlaylistsProvider.future);

      // RÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©cupÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©rer les donnÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©es de la sÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©rie depuis le provider
      // VÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©rifier que le widget est encore montÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â© avant d'utiliser ref
      if (!mounted || !context.mounted) {
        messenger?.hideCurrentSnackBar();
        return;
      }
      messenger?.hideCurrentSnackBar();
      final vmAsync = ref.read(tvDetailProgressiveControllerProvider(seriesId));
      final vm = vmAsync.value;

      // Utiliser les donnÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©es du widget si le view model n'est pas disponible
      final title = vm?.title ?? mediaTitle;
      final yearTextValue = vm?.yearText ?? yearText;
      final poster = vm?.poster;

      // Filtrer les playlists selon le type de contenu
      final availablePlaylists = <LibraryPlaylistItem>[];

      for (final playlist in playlists) {
        // Exclure les sagas et acteurs
        if (playlist.id.startsWith('saga_') ||
            playlist.type == LibraryPlaylistType.actor) {
          continue;
        }

        // Playlists utilisateur uniquement
        if (playlist.type == LibraryPlaylistType.userPlaylist &&
            playlist.playlistId != null) {
          availablePlaylists.add(playlist);
        }
      }

      if (availablePlaylists.isEmpty) {
        messenger?.showSnackBar(
          const SnackBar(
            content: Text(
              'Aucune playlist disponible. CrÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©ez en une',
            ),
          ),
        );
        return;
      }

      if (!mounted || !context.mounted) return;

      final l10n = AppLocalizations.of(context)!;
      final container = ProviderScope.containerOf(context, listen: false);
      final playlistRepository = ref.read(slProvider)<PlaylistRepository>();
      final logger = ref.read(slProvider)<AppLogger>();
      final addPlaylistItem = AddPlaylistItem(playlistRepository);

      _showPlaylistActionSheet(
        l10n: l10n,
        playlists: availablePlaylists,
        onSelect: (playlist) {
          unawaited(() async {
            final canNotify = mounted && messenger != null;
            final playlistIdToInvalidate = playlist.playlistId;

            try {
              final year =
                  yearTextValue !=
                      'ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â'
                  ? int.tryParse(yearTextValue)
                  : null;

              await addPlaylistItem.call(
                playlistId: PlaylistId(playlist.playlistId!),
                item: PlaylistItem(
                  reference: ContentReference(
                    id: seriesId,
                    title: MediaTitle(title),
                    type: ContentType.series,
                    poster: poster,
                    year: year,
                  ),
                  addedAt: DateTime.now(),
                ),
              );

              container.invalidate(
                playlistItemsProvider(playlistIdToInvalidate!),
              );
              container.invalidate(
                playlistContentReferencesProvider(playlistIdToInvalidate),
              );
              container.invalidate(libraryPlaylistsProvider);

              if (canNotify) {
                _showTopNotification(
                  l10n,
                  messenger,
                  l10n.playlistAddedTo(playlist.title),
                );
              }
            } catch (e, stackTrace) {
              logger.log(
                LogLevel.error,
                'Erreur lors de l\'ajout ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â  la playlist: $e',
                error: e,
                stackTrace: stackTrace,
                category: 'tv_detail',
              );

              if (canNotify) {
                String errorMessage;
                if (e is StateError &&
                    e.message.contains(
                      'dÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©jÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â  dans cette playlist',
                    )) {
                  errorMessage =
                      'Ce mÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©dia est dÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©jÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â  dans cette playlist';
                } else {
                  errorMessage = l10n.errorWithMessage(e.toString());
                }

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            }
          }());
        },
      );
    } catch (e) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des playlists: $e'),
          ),
        );
      }
    }
  }

  void _showPlaylistActionSheet({
    required AppLocalizations l10n,
    required List<LibraryPlaylistItem> playlists,
    required void Function(LibraryPlaylistItem playlist) onSelect,
  }) {
    if (!mounted) return;
    if (_useDesktopDetailLayout(context)) {
      final actions = playlists
          .map(
            (playlist) => MoviTvActionMenuAction(
              label: playlist.title,
              onPressed: () => onSelect(playlist),
            ),
          )
          .toList(growable: false);
      unawaited(
        showMoviTvActionMenu(
          context: context,
          title: l10n.actionAddToList,
          actions: actions,
          cancelLabel: l10n.actionCancel,
        ),
      );
      return;
    }
    unawaited(
      showCupertinoModalPopup<void>(
        context: context,
        builder: (sheetContext) {
          return CupertinoActionSheet(
            title: Text(l10n.actionAddToList),
            actions: playlists
                .map(
                  (playlist) => CupertinoActionSheetAction(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      onSelect(playlist);
                    },
                    child: Text(
                      playlist.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: Text(l10n.actionCancel),
            ),
          );
        },
      ),
    );
  }

  void _showTopNotification(
    AppLocalizations l10n,
    ScaffoldMessengerState messenger,
    String message,
  ) {
    if (!mounted) return;
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => messenger.hideCurrentMaterialBanner(),
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    );
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      messenger.hideCurrentMaterialBanner();
    });
  }

  void _showMoreMenu() {
    final seriesId = widget.seriesId;
    final isAvailable =
        ref.read(_seriesAvailabilityProvider(seriesId)).value ?? false;
    final isSeen = ref.read(_seriesSeenProvider(seriesId)).value ?? false;
    final l10n = AppLocalizations.of(context)!;

    if (_useDesktopDetailLayout(context)) {
      final actions = <MoviTvActionMenuAction>[
        MoviTvActionMenuAction(
          label: l10n.actionRefreshMetadata,
          onPressed: _onRefreshMetadata,
        ),
        MoviTvActionMenuAction(
          label: _spoilerModeEnabled
              ? 'DÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â©sactiver le mode spoiler'
              : 'Activer le mode spoiler',
          onPressed: () {
            unawaited(_setSpoilerMode(!_spoilerModeEnabled));
          },
        ),
        MoviTvActionMenuAction(
          label: l10n.actionAddToList,
          onPressed: () => _showAddToListDialog(context, ref, seriesId),
        ),
      ];

      if (isAvailable) {
        actions.add(
          MoviTvActionMenuAction(
            label: isSeen ? l10n.actionMarkUnseen : l10n.actionMarkSeen,
            onPressed: () {
              if (isSeen) {
                _markAsUnseen(seriesId);
              } else {
                _markAsSeen(seriesId);
              }
            },
          ),
        );
      }

      actions.add(
        MoviTvActionMenuAction(
          label: l10n.actionReportProblem,
          onPressed: () {
            final tmdbId = int.tryParse(seriesId);
            if (tmdbId == null || tmdbId <= 0) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.errorReportUnavailableForContent),
                  ),
                );
              }
              return;
            }
            unawaited(
              ReportProblemSheet.show(
                context,
                ref,
                contentType: ContentType.series,
                tmdbId: tmdbId,
                contentTitle: mediaTitle,
                originRegionId: AppFocusRegionId.tvDetailPrimary,
                fallbackRegionId: AppFocusRegionId.tvDetailPrimary,
              ),
            );
          },
        ),
      );

      unawaited(
        showMoviTvActionMenu(
          context: context,
          title: 'Options',
          actions: actions,
          cancelLabel: l10n.actionCancel,
        ),
      );
      return;
    }

    unawaited(
      showCupertinoModalPopup<void>(
        context: context,
        builder: (sheetContext) {
          final actions = <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _onRefreshMetadata();
              },
              child: Text(l10n.actionRefreshMetadata),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                unawaited(_setSpoilerMode(!_spoilerModeEnabled));
              },
              child: Text(
                _spoilerModeEnabled
                    ? 'DÃƒÆ’Ã‚Â©sactiver le mode spoiler'
                    : 'Activer le mode spoiler',
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _showAddToListDialog(context, ref, seriesId);
              },
              child: Text(l10n.actionAddToList),
            ),
            if (isAvailable)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  if (isSeen) {
                    _markAsUnseen(seriesId);
                  } else {
                    _markAsSeen(seriesId);
                  }
                },
                child: Text(
                  isSeen ? l10n.actionMarkUnseen : l10n.actionMarkSeen,
                ),
              ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                final tmdbId = int.tryParse(seriesId);
                if (tmdbId == null || tmdbId <= 0) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.errorReportUnavailableForContent),
                      ),
                    );
                  }
                  return;
                }
                unawaited(
                  ReportProblemSheet.show(
                    context,
                    ref,
                    contentType: ContentType.series,
                    tmdbId: tmdbId,
                    contentTitle: mediaTitle,
                    originRegionId: AppFocusRegionId.tvDetailPrimary,
                    fallbackRegionId: AppFocusRegionId.tvDetailPrimary,
                  ),
                );
              },
              child: Text(l10n.actionReportProblem),
            ),
          ];

          return CupertinoActionSheet(
            title: const Text('Options'),
            actions: actions,
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: Text(l10n.actionCancel),
            ),
          );
        },
      ),
    );
  }

  Future<void> _markAsSeen(String seriesId) async {
    try {
      final useCase = ref.read(markSeriesAsSeenUseCaseProvider);
      final userId = ref.read(currentUserIdProvider);
      final vm = ref
          .read(tvDetailProgressiveControllerProvider(seriesId))
          .value;
      final poster = vm?.poster;
      final resolvedTitle = (vm?.title.trim().isNotEmpty ?? false)
          ? vm!.title
          : mediaTitle;

      // Pour une sÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©rie, on marque comme vu en ajoutant une entrÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©e avec progression 100%
      // La durÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©e par dÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©faut est de 45 minutes par ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©pisode
      List<Season> seasons = const <Season>[];
      try {
        seasons = await ref
            .read(tvRepositoryProvider)
            .getSeasons(SeriesId(seriesId));
      } catch (_) {
        seasons = const <Season>[];
      }

      await useCase(
        seriesId: seriesId,
        title: resolvedTitle,
        poster: poster,
        seasons: seasons,
        userId: userId,
      );

      _invalidateSeriesPlaybackState(seriesId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.actionMarkSeen)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.snackbarGenericError(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _markAsUnseen(String seriesId) async {
    try {
      final useCase = ref.read(markSeriesAsUnseenUseCaseProvider);
      final userId = ref.read(currentUserIdProvider);

      // Retirer de l'historique (retire tous les ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©pisodes de la sÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©rie)
      await useCase(seriesId, userId: userId);

      // Retirer de continue watching (retire tous les ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©pisodes de la sÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©rie)
      _invalidateSeriesPlaybackState(seriesId);

      // Invalider les providers pour mettre ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â  jour l'UI

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.actionMarkUnseen),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.snackbarGenericError(e.toString()),
            ),
          ),
        );
      }
    }
  }

  void _invalidateSeriesPlaybackState(String seriesId) {
    ref.invalidate(_seriesSeenStateProvider(seriesId));
    ref.invalidate(_watchedEpisodeKeysProvider(seriesId));
    ref.invalidate(_seriesSeenProvider(seriesId));
    ref.invalidate(seriesPlaybackLaunchPlanProvider(seriesId));
    ref.invalidate(
      hp.mediaHistoryProvider((contentId: seriesId, type: ContentType.series)),
    );
    ref.invalidate(
      inProgressHistoryEntryProvider((
        contentId: seriesId,
        type: ContentType.series,
      )),
    );
    ref.invalidate(
      latestPlaybackHistoryEntryProvider((
        contentId: seriesId,
        type: ContentType.series,
      )),
    );
    ref.invalidate(libraryPlaylistsProvider);
    ref.invalidate(hp.homeControllerProvider);
  }

  final _seriesAvailabilityProvider = FutureProvider.family<bool, String>((
    ref,
    seriesId,
  ) async {
    final locator = ref.read(slProvider);
    final iptvLocal = locator<IptvLocalRepository>();
    final accounts = await iptvLocal.getAccounts();

    for (final account in accounts) {
      final playlists = await iptvLocal.getPlaylists(account.id);
      for (final playlist in playlists) {
        if (seriesId.startsWith('xtream:')) {
          final streamIdStr = seriesId.substring(7);
          final streamId = int.tryParse(streamIdStr);
          if (streamId != null) {
            try {
              playlist.items.firstWhere(
                (item) =>
                    item.streamId == streamId &&
                    item.type == XtreamPlaylistItemType.series,
              );
              return true;
            } catch (_) {}
          }
        } else {
          final tmdbId = int.tryParse(seriesId);
          if (tmdbId != null) {
            try {
              playlist.items.firstWhere(
                (item) =>
                    item.tmdbId == tmdbId &&
                    item.type == XtreamPlaylistItemType.series,
              );
              return true;
            } catch (_) {}
          }
        }
      }
    }
    return false;
  });

  final _seriesSeenProvider = FutureProvider.family<bool, String>((
    ref,
    seriesId,
  ) async {
    try {
      final seenState = await ref.read(
        _seriesSeenStateProvider(seriesId).future,
      );
      return seenState != null;
    } catch (_) {
      return false;
    }
  });

  void _onRefreshMetadata() async {
    try {
      final locator = ref.read(slProvider);
      final repo = locator<TvRepository>();
      final id = SeriesId(widget.seriesId);
      await repo.refreshMetadata(id);
      // Invalider le provider pour forcer le rechargement
      ref.invalidate(tvDetailProgressiveControllerProvider(widget.seriesId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.metadataRefreshed),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorRefreshingMetadata,
            ),
          ),
        );
      }
    }
  }
}
