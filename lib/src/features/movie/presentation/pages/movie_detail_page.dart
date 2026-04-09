import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/theme/app_colors.dart';
import 'package:movi/src/core/focus/movi_focus_restore_policy.dart';
import 'package:movi/src/core/focus/movi_route_focus_boundary.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/logging/operation_context.dart';
import 'package:movi/src/core/performance/domain/performance_diagnostic_logger.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart'
    as mdp;
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/library/presentation/widgets/add_to_playlist_action_sheet.dart';
import 'package:movi/src/features/library/presentation/widgets/library_playlist_card.dart';
import 'package:movi/src/features/playlist/playlist.dart';
import 'package:movi/src/features/movie/presentation/widgets/movie_hero_image.dart';
import 'package:movi/src/features/movie/presentation/widgets/movie_detail_synopsis_section.dart';
import 'package:movi/src/features/movie/presentation/widgets/movie_detail_cast_section.dart';
import 'package:movi/src/features/movie/presentation/widgets/movie_detail_saga_section.dart';
import 'package:movi/src/features/movie/presentation/widgets/movie_detail_recommendations_section.dart';
import 'package:movi/src/features/movie/presentation/widgets/movie_playback_variant_sheet.dart';
import 'package:movi/src/features/player/domain/entities/playback_selection_decision.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/core/parental/presentation/utils/parental_reason_localizer.dart';
import 'package:movi/src/core/parental/presentation/widgets/restricted_content_sheet.dart';
import 'package:movi/src/core/reporting/presentation/widgets/report_problem_sheet.dart';

class MovieDetailPage extends ConsumerStatefulWidget {
  const MovieDetailPage({super.key, required this.movieId});

  final String movieId;

  @override
  ConsumerState<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends ConsumerState<MovieDetailPage>
    with TickerProviderStateMixin {
  static const double _heroFocusVerticalAlignment = 0.08;
  bool _isTransitioningFromLoading = true;
  String mediaTitle = '—';
  String yearText = '—';
  bool _changeVersionFocused = false;
  String durationText = '—';
  String ratingText = '—';
  String overviewText = '';
  List<MoviPerson> cast = const [];
  List<MoviMedia> recommendations = const [];
  Timer? _autoRefreshTimer;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _loadingTimeout = Duration(seconds: 15);
  final FocusNode _primaryActionFocusNode = FocusNode(
    debugLabel: 'MovieDetailPrimaryAction',
  );
  final FocusNode _changeVersionFocusNode = FocusNode(
    debugLabel: 'MovieDetailChangeVersion',
  );
  final FocusNode _favoriteActionFocusNode = FocusNode(
    debugLabel: 'MovieDetailFavoriteAction',
  );
  final FocusNode _firstCastItemFocusNode = FocusNode(
    debugLabel: 'MovieDetailFirstCastItem',
  );
  final FocusNode _heroBackFocusNode = FocusNode(debugLabel: 'MovieDetailBack');
  final FocusNode _heroMoreFocusNode = FocusNode(debugLabel: 'MovieDetailMore')
    ..canRequestFocus = false;
  int _lastFocusedCastIndex = 0;
  int _castFocusRequestId = 0;
  int? _castFocusRequestIndex;
  OverlayEntry? _markUnseenToastEntry;
  AnimationController? _markUnseenToastController;

  @override
  void initState() {
    super.initState();
    _isTransitioningFromLoading = true;
    _startAutoRefreshTimer();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _primaryActionFocusNode.dispose();
    _changeVersionFocusNode.dispose();
    _favoriteActionFocusNode.dispose();
    _firstCastItemFocusNode.dispose();
    _heroBackFocusNode.dispose();
    _heroMoreFocusNode.dispose();
    _markUnseenToastController?.dispose();
    _markUnseenToastEntry?.remove();
    super.dispose();
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    final mediaId = widget.movieId;
    _autoRefreshTimer = Timer(_loadingTimeout, () {
      if (!mounted || _retryCount >= _maxRetries) return;
      final vmAsync = ref.read(mdp.movieDetailControllerProvider(mediaId));
      // Si toujours en chargement après le timeout, relancer
      if (vmAsync.isLoading) {
        _retryCount++;
        ref.invalidate(mdp.movieDetailControllerProvider(mediaId));
        _startAutoRefreshTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final movieId = widget.movieId;
    final profile = ref.watch(currentProfileProvider);
    final hasRestrictions =
        profile != null && (profile.isKid || profile.pegiLimit != null);

    if (hasRestrictions) {
      final content = ContentReference(
        id: movieId,
        type: ContentType.movie,
        title: MediaTitle(movieId),
      );
      final decisionAsync = ref.watch(
        parental.contentAgeDecisionProvider(content),
      );

      return decisionAsync.when(
        loading: () => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: const OverlaySplash(),
        ),
        error: (_, __) => _buildAllowedDetailScaffold(context, movieId),
        data: (decision) {
          if (decision.isAllowed) {
            return _buildAllowedDetailScaffold(context, movieId);
          }

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

    return _buildAllowedDetailScaffold(context, movieId);
  }

  Widget _buildAllowedDetailScaffold(BuildContext context, String movieId) {
    final vmAsync = ref.watch(mdp.movieDetailControllerProvider(movieId));

    // Détecter les erreurs et relancer automatiquement
    vmAsync.whenOrNull(
      error: (e, st) {
        if (mounted && _retryCount < _maxRetries) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _retryCount++;
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  ref.invalidate(mdp.movieDetailControllerProvider(movieId));
                  _startAutoRefreshTimer();
                }
              });
            }
          });
        }
      },
      data: (_) {
        // Le chargement a réussi, annuler le timer et réinitialiser
        _autoRefreshTimer?.cancel();
        _retryCount = 0;
      },
    );

    return vmAsync.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: OverlaySplash(
          message: AppLocalizations.of(context)!.overlayPreparingMetadata,
        ),
      ),
      error: (e, st) => _buildErrorScaffold(e),
      data: (vm) {
        // Démarrer la transition d'opacité après un court délai
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
        return _buildWithValues(
          mediaTitle: vm.title,
          logo: vm.logo,
          yearText: vm.yearText,
          durationText: vm.durationText,
          ratingText: vm.ratingText,
          overviewText: vm.overviewText,
          cast: vm.cast,
          recommendations: vm.recommendations,
          isLoading: _isTransitioningFromLoading,
          poster: vm.poster,
          posterBackground: vm.posterBackground,
          backdrop: vm.backdrop,
          sagaLink: vm.sagaLink,
          movieId: movieId,
        );
      },
    );
  }

  KeyEventResult _handleHeroBackKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.ignored;
    }
    _heroMoreFocusNode.canRequestFocus = true;
    _heroMoreFocusNode.requestFocus();
    return KeyEventResult.handled;
  }

  KeyEventResult _handleHeroMoreKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _heroBackFocusNode.requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handlePrimaryActionKey(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey != LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.ignored;
    }
    _focusNearestCastItemFromPrimary();
    return KeyEventResult.handled;
  }

  KeyEventResult _handleSecondaryActionKey(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey != LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.ignored;
    }
    _focusFirstCastItem();
    return KeyEventResult.handled;
  }

  void _focusFirstCastItem() {
    if (_firstCastItemFocusNode.context == null ||
        !_firstCastItemFocusNode.canRequestFocus) {
      return;
    }
    _firstCastItemFocusNode.requestFocus();
  }

  void _focusNearestCastItemFromPrimary() {
    if (!mounted) return;
    setState(() {
      _castFocusRequestIndex = _lastFocusedCastIndex;
      _castFocusRequestId++;
    });
  }

  void _handleCastFocusChanged(int index) {
    _lastFocusedCastIndex = index;
  }

  Widget _buildErrorScaffold(Object e) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Text(
          AppLocalizations.of(context)!.errorWithMessage(e.toString()),
          style: const TextStyle(color: Colors.white),
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

  Widget _buildWithValues({
    required String mediaTitle,
    Uri? logo,
    required String yearText,
    required String durationText,
    required String ratingText,
    required String overviewText,
    required List<MoviPerson> cast,
    required List<MoviMedia> recommendations,
    required bool isLoading,
    Uri? poster,
    Uri? posterBackground,
    Uri? backdrop,
    SagaSummary? sagaLink,
    required String movieId,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isWideLayout = _useDesktopDetailLayout(context);
    return SwipeBackWrapper(
      child: MoviRouteFocusBoundary(
        restorePolicy: MoviFocusRestorePolicy(
          initialFocusNode: _primaryActionFocusNode,
          fallbackFocusNode: _heroBackFocusNode,
        ),
        requestInitialFocusOnMount: true,
        onUnhandledBack: () {
          if (!mounted || !context.mounted) return false;
          context.pop();
          return true;
        },
        debugLabel: 'MovieDetailRouteFocus',
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
                        // Rafraîchir aussi le contenu local après la sync
                        ref.invalidate(
                          mdp.movieDetailControllerProvider(movieId),
                        );
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MoviDetailHeroScene(
                              isWideLayout: isWideLayout,
                              background: _buildHeroImage(
                                poster: poster,
                                posterBackground: posterBackground,
                                backdrop: backdrop,
                              ),
                              children: [
                                _buildHeroTopBar(isWideLayout: isWideLayout),
                                if (isWideLayout)
                                  _buildDesktopHeroOverlay(
                                    mediaTitle: mediaTitle,
                                    logo: logo,
                                    yearText: yearText,
                                    durationText: durationText,
                                    ratingText: ratingText,
                                    overviewText: overviewText,
                                    movieId: movieId,
                                  ),
                              ],
                            ),
                            if (!isWideLayout)
                              _buildMobileMetaSection(
                                mediaTitle: mediaTitle,
                                logo: logo,
                                yearText: yearText,
                                durationText: durationText,
                                ratingText: ratingText,
                                overviewText: overviewText,
                                movieId: movieId,
                              ),
                            const SizedBox(height: AppSpacing.xl),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsetsDirectional.only(
                                    start: _sectionHorizontalPadding(context),
                                    end: _sectionHorizontalPadding(context),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.castTitle,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s),
                                MovieDetailCastSection(
                                  cast: cast,
                                  firstItemFocusNode: _firstCastItemFocusNode,
                                  focusRequestId: _castFocusRequestId,
                                  focusRequestIndex: _castFocusRequestIndex,
                                  onRequestPrimaryActionFocus: () {
                                    if (_primaryActionFocusNode.context != null &&
                                        _primaryActionFocusNode.canRequestFocus) {
                                      _primaryActionFocusNode.requestFocus();
                                    }
                                  },
                                  onFocusedActorIndexChanged:
                                      _handleCastFocusChanged,
                                  horizontalPadding: _sectionHorizontalPadding(
                                    context,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.l),
                                // Section saga (si le film fait partie d'une saga)
                                if (sagaLink != null)
                                  MovieDetailSagaSection(
                                    sagaLink: sagaLink,
                                    currentMovieId: widget.movieId,
                                    horizontalPadding:
                                        _sectionHorizontalPadding(context),
                                  ),
                                // Section recommandations
                                MovieDetailRecommendationsSection(
                                  items: recommendations,
                                  horizontalPadding: _sectionHorizontalPadding(
                                    context,
                                  ),
                                ),
                                const SizedBox(height: 70),
                              ],
                            ),
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
    );
  }

  Widget _buildHeroImage({Uri? poster, Uri? posterBackground, Uri? backdrop}) {
    return MovieHeroImage(
      poster: poster,
      posterBackground: posterBackground,
      backdrop: backdrop,
    );
  }

  Widget _buildHeroTopBar({required bool isWideLayout}) {
    final l10n = AppLocalizations.of(context)!;
    return MoviDetailHeroTopBar(
      isWideLayout: isWideLayout,
      horizontalPadding: _sectionHorizontalPadding(context),
      leading: Focus(
        canRequestFocus: false,
        onKeyEvent: (_, event) => _handleHeroBackKey(event),
        child: MoviDetailHeroActionButton(
          focusNode: _heroBackFocusNode,
          iconAsset: AppAssets.iconBack,
          semanticLabel: l10n.semanticsBack,
          onPressed: () => context.pop(),
          isWideLayout: isWideLayout,
        ),
      ),
      trailing: Focus(
        canRequestFocus: false,
        onKeyEvent: (_, event) => _handleHeroMoreKey(event),
        onFocusChange: (hasFocus) {
          if (!hasFocus) {
            _heroMoreFocusNode.canRequestFocus = false;
          }
        },
        child: MoviDetailHeroActionButton(
          focusNode: _heroMoreFocusNode,
          iconAsset: AppAssets.iconMore,
          semanticLabel: l10n.semanticsMoreActions,
          onPressed: _showMoreMenu,
          isWideLayout: isWideLayout,
          iconWidth: 25,
        ),
      ),
    );
  }

  Widget _buildDesktopHeroOverlay({
    required String mediaTitle,
    Uri? logo,
    required String yearText,
    required String durationText,
    required String ratingText,
    required String overviewText,
    required String movieId,
  }) {
    final titleStyle =
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
        );
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
                    style: titleStyle,
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
                      style: titleStyle,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          _buildMetaPills(
            yearText: yearText,
            durationText: durationText,
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
          _buildActionButtons(
            mediaTitle: mediaTitle,
            movieId: movieId,
            expandPrimary: false,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMetaSection({
    required String mediaTitle,
    Uri? logo,
    required String yearText,
    required String durationText,
    required String ratingText,
    required String overviewText,
    required String movieId,
  }) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 20, end: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.m),
          Semantics(
            header: true,
            label: mediaTitle,
            child: logo == null
                ? Text(mediaTitle, style: titleStyle, textAlign: TextAlign.left)
                : Transform.translate(
                    offset: const Offset(0, -16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: (screenWidth * 0.82).clamp(220.0, 420.0),
                        maxHeight: 56,
                      ),
                      child: Image.network(
                        logo.toString(),
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) =>
                            Text(mediaTitle, style: titleStyle),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.m),
          _buildMetaPills(
            yearText: yearText,
            durationText: durationText,
            ratingText: ratingText,
            alignment: WrapAlignment.center,
            pillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: AppSpacing.m),
          _buildActionButtons(
            mediaTitle: mediaTitle,
            movieId: movieId,
            expandPrimary: true,
          ),
          const SizedBox(height: AppSpacing.s),
          MovieDetailSynopsisSection(text: overviewText),
        ],
      ),
    );
  }

  Widget _buildMetaPills({
    required String yearText,
    required String durationText,
    required String ratingText,
    required WrapAlignment alignment,
    Color? pillColor,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: alignment,
      children: [
        MoviPill(
          yearText,
          large: true,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: pillColor,
        ),
        MoviPill(
          durationText,
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
    required String movieId,
    required bool expandPrimary,
  }) {
    final cs = Theme.of(context).colorScheme;
    const iconActionFocusedBackground = Color(0x807A7A7A);
    final launchPlanAsync = ref.watch(
      mdp.moviePlaybackLaunchPlanProvider(movieId),
    );
    final isFavoriteAsync = ref.watch(mdp.movieIsFavoriteProvider(movieId));

    final primaryButton = MoviEnsureVisibleOnFocus(
      verticalAlignment: _heroFocusVerticalAlignment,
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (_, event) => _handlePrimaryActionKey(event),
        child: MoviPrimaryButton(
          focusNode: _primaryActionFocusNode,
          label: launchPlanAsync.when(
            data: (launchPlan) => launchPlan?.isResumeEligible == true
                ? AppLocalizations.of(context)!.resumePlayback
                : AppLocalizations.of(context)!.homeWatchNow,
            loading: () => AppLocalizations.of(context)!.homeWatchNow,
            error: (_, __) => AppLocalizations.of(context)!.homeWatchNow,
          ),
          assetIcon: AppAssets.iconPlay,
          buttonStyle: FilledButton.styleFrom(
            backgroundColor: cs.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          onPressed: () async {
            _playMovie(context, mediaTitle, startFromBeginning: false);
          },
        ),
      ),
    );

    final playButton = expandPrimary
        ? Expanded(child: primaryButton)
        : SizedBox(width: 320, child: primaryButton);
    final changeVersionButton = Semantics(
      button: true,
      label: AppLocalizations.of(context)!.actionChangeVersion,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: const Key('movie_change_version_button'),
            focusNode: _changeVersionFocusNode,
            onTap: () async {
              await _chooseMovieVersionAndPlay(mediaTitle);
            },
            onFocusChange: (focused) {
              if (_changeVersionFocused == focused) return;
              setState(() => _changeVersionFocused = focused);
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
                        ? cs.primary
                        : cs.primary.withValues(alpha: 0),
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
    );

    final isAvailable =
        ref.watch(mdp.movieAvailabilityOnIptvProvider(movieId)).value ?? true;

    return SizedBox(
      height: expandPrimary ? 55 : 48,
      child: Row(
        mainAxisSize: expandPrimary ? MainAxisSize.max : MainAxisSize.min,
        children: [
          playButton,
          if (isAvailable) ...[
            const SizedBox(width: 12),
            MoviEnsureVisibleOnFocus(
              verticalAlignment: _heroFocusVerticalAlignment,
              child: Focus(
                canRequestFocus: false,
                onKeyEvent: (_, event) => _handleSecondaryActionKey(event),
                child: changeVersionButton,
              ),
            ),
            const SizedBox(width: 12),
          ] else ...[
            const SizedBox(width: 12),
          ],
          SizedBox(
            width: 44,
            height: 44,
            child: MoviEnsureVisibleOnFocus(
              verticalAlignment: _heroFocusVerticalAlignment,
              child: Focus(
                canRequestFocus: false,
                onKeyEvent: (_, event) => _handleSecondaryActionKey(event),
                child: isFavoriteAsync.when(
                  data: (isFavorite) => MoviFavoriteButton(
                    isFavorite: isFavorite,
                    focusNode: _favoriteActionFocusNode,
                    size: 44,
                    iconSize: 28,
                    focusPadding: const EdgeInsets.all(5),
                    focusedBackgroundColor: iconActionFocusedBackground,
                    focusedBorderColor: cs.primary,
                    borderWidth: 2,
                    onPressed: () async {
                      await ref
                          .read(mdp.movieToggleFavoriteProvider.notifier)
                          .toggle(movieId);
                    },
                  ),
                  loading: () => MoviFavoriteButton(
                    isFavorite: false,
                    focusNode: _favoriteActionFocusNode,
                    size: 44,
                    iconSize: 28,
                    focusPadding: const EdgeInsets.all(5),
                    focusedBackgroundColor: iconActionFocusedBackground,
                    focusedBorderColor: cs.primary,
                    borderWidth: 2,
                    onPressed: () {},
                  ),
                  error: (_, __) => MoviFavoriteButton(
                    isFavorite: false,
                    focusNode: _favoriteActionFocusNode,
                    size: 44,
                    iconSize: 28,
                    focusPadding: const EdgeInsets.all(5),
                    focusedBackgroundColor: iconActionFocusedBackground,
                    focusedBorderColor: cs.primary,
                    borderWidth: 2,
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ({String movieId, String title, int? releaseYear, Uri? poster})
  _buildPlaybackSelectionArgs({
    required String movieId,
    required String title,
  }) {
    final currentViewModel = ref
        .read(mdp.movieDetailControllerProvider(movieId))
        .value;
    final releaseYear = currentViewModel == null
        ? null
        : int.tryParse(currentViewModel.yearText);

    return (
      movieId: movieId,
      title: title,
      releaseYear: releaseYear,
      poster: currentViewModel?.poster,
    );
  }

  Future<void> _showAddToListDialog(
    BuildContext context,
    WidgetRef ref,
    String movieId,
  ) async {
    try {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.snackbarLoadingPlaylists),
        ),
      );

      final playlists = await ref.read(libraryPlaylistsProvider.future);

      // Récupérer les données du film depuis le provider
      // Vérifier que le widget est encore monté avant d'utiliser ref
      if (!mounted || !context.mounted) {
        messenger?.hideCurrentSnackBar();
        return;
      }
      messenger?.hideCurrentSnackBar();
      final vmAsync = ref.read(mdp.movieDetailControllerProvider(movieId));
      final vm = vmAsync.value;

      // Utiliser les données du widget si le view model n'est pas disponible
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
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.snackbarNoPlaylistsAvailableCreateOne,
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

      showAddToPlaylistActionSheet(
        context: context,
        l10n: l10n,
        playlists: availablePlaylists,
        onSelect: (playlist) async {
          final canNotify = mounted && messenger != null;
          final playlistIdToInvalidate = playlist.playlistId;

          try {
            final year = yearTextValue != '—'
                ? int.tryParse(yearTextValue)
                : null;

            await addPlaylistItem.call(
              playlistId: PlaylistId(playlist.playlistId!),
              item: PlaylistItem(
                reference: ContentReference(
                  id: movieId,
                  title: MediaTitle(title),
                  type: ContentType.movie,
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
            if (!mounted || !context.mounted) return;
            logger.log(
              LogLevel.error,
              AppLocalizations.of(context)!.errorAddToPlaylist(e.toString()),
              error: e,
              stackTrace: stackTrace,
              category: 'movie_detail',
            );

            if (canNotify) {
              String errorMessage;
              if (e is StateError &&
                  e.message.contains('déjà dans cette playlist')) {
                errorMessage = AppLocalizations.of(
                  context,
                )!.errorAlreadyInPlaylist;
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
        },
      );
    } catch (e) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorLoadingPlaylists(e.toString()),
            ),
          ),
        );
      }
    }
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

  Future<void> _showMarkUnseenFeedback() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final isMobile = _screenTypeFor(context) == ScreenType.mobile;
    const toastBg = Color(0xFF35363D);

    if (isMobile) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: toastBg,
          content: Text(
            l10n.actionMarkUnseen,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    _markUnseenToastController?.dispose();
    _markUnseenToastEntry?.remove();

    final overlay = Overlay.of(context, rootOverlay: true);

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _markUnseenToastController = controller;
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );
    final leftPadding = _sectionHorizontalPadding(context);
    final topPadding = MediaQuery.of(context).padding.top + 58;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        return Positioned(
          top: topPadding,
          left: leftPadding,
          child: IgnorePointer(
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.15, 0),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: Material(
                  color: Colors.transparent,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: toastBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Text(
                        l10n.actionMarkUnseen,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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
    );

    _markUnseenToastEntry = entry;
    overlay.insert(entry);
    await controller.forward();
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await controller.reverse();
    if (!mounted) return;
    entry.remove();
    if (identical(_markUnseenToastEntry, entry)) {
      _markUnseenToastEntry = null;
    }
    if (identical(_markUnseenToastController, controller)) {
      _markUnseenToastController = null;
    }
    controller.dispose();
  }

  void _showMoreMenu() {
    final movieId = widget.movieId;
    final isAvailable =
        ref.read(mdp.movieAvailabilityProvider(movieId)).value ?? false;
    final isSeen = ref.read(mdp.movieSeenProvider(movieId)).value ?? false;
    final l10n = AppLocalizations.of(context)!;

    final actions = <MoviTvActionMenuAction>[
      MoviTvActionMenuAction(
        label: l10n.actionChangeMetadata,
        onPressed: _onChangeMetadata,
      ),
      MoviTvActionMenuAction(
        label: l10n.actionAddToList,
        onPressed: () => _showAddToListDialog(context, ref, movieId),
      ),
    ];

    if (isAvailable) {
      actions.add(
        MoviTvActionMenuAction(
          label: isSeen ? l10n.actionMarkUnseen : l10n.actionMarkSeen,
          onPressed: () {
            if (isSeen) {
              _markAsUnseen(movieId);
            } else {
              _markAsSeen(movieId, mediaTitle);
            }
          },
        ),
      );
    }

    actions.add(
      MoviTvActionMenuAction(
        label: l10n.actionReportProblem,
        onPressed: () {
          final tmdbId = int.tryParse(movieId);
          if (tmdbId == null || tmdbId <= 0) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(
                      context,
                    )!.errorReportUnavailableForContent,
                  ),
                ),
              );
            }
            return;
          }
          unawaited(
            ReportProblemSheet.show(
              context,
              ref,
              contentType: ContentType.movie,
              tmdbId: tmdbId,
              contentTitle: mediaTitle,
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
  }

  Future<void> _markAsSeen(String movieId, String title) async {
    try {
      final usecase = ref.read(mdp.markMovieAsSeenUseCaseProvider);
      final userId = ref.read(currentUserIdProvider);
      final vm = ref.read(mdp.movieDetailControllerProvider(movieId)).value;
      final poster = vm?.poster;
      final resolvedTitle = (vm?.title.trim().isNotEmpty ?? false)
          ? vm!.title
          : title;
      await usecase(
        movieId: movieId,
        title: resolvedTitle,
        poster: poster,
        userId: userId,
      );

      // Invalider les providers pour mettre à jour l'UI
      ref.invalidate(
        hp.mediaHistoryProvider((contentId: movieId, type: ContentType.movie)),
      );
      ref.invalidate(mdp.moviePlaybackLaunchPlanProvider(movieId));
      ref.invalidate(mdp.movieHistoryProvider(movieId));
      ref.invalidate(mdp.movieSeenProvider(movieId));
      ref.invalidate(libraryPlaylistsProvider);

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
              AppLocalizations.of(context)!.errorWithMessage(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _markAsUnseen(String movieId) async {
    try {
      final usecase = ref.read(mdp.markMovieAsUnseenUseCaseProvider);
      final userId = ref.read(currentUserIdProvider);
      await usecase(movieId, userId: userId);

      // Invalider les providers pour mettre à jour l'UI
      ref.invalidate(
        hp.mediaHistoryProvider((contentId: movieId, type: ContentType.movie)),
      );
      ref.invalidate(mdp.moviePlaybackLaunchPlanProvider(movieId));
      ref.invalidate(mdp.movieHistoryProvider(movieId));
      ref.invalidate(mdp.movieSeenProvider(movieId));
      ref.invalidate(libraryPlaylistsProvider);
      ref.invalidate(hp.homeControllerProvider);

      if (mounted) {
        await _showMarkUnseenFeedback();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorWithMessage(e.toString()),
            ),
          ),
        );
      }
    }
  }

  void _onChangeMetadata() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.featureComingSoon)),
    );
  }

  Future<void> _playMovie(
    BuildContext context,
    String title, {
    bool startFromBeginning = false,
  }) async {
    return runWithOperationId(() async {
      final logger = ref.read(slProvider)<AppLogger>();
      final diagnostics = ref.read(slProvider)<PerformanceDiagnosticLogger>();
      final stopwatch = Stopwatch()..start();
      try {
        final decision = await _loadMoviePlaybackSelection(title);
        if (decision.isUnavailable) {
          diagnostics.completed(
            'movie_play_action',
            elapsed: stopwatch.elapsed,
            result: 'unavailable',
            context: <String, Object?>{
              'movieId': widget.movieId,
              'reason': decision.reason.name,
            },
          );
          if (!mounted || !context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.movieNotAvailableInPlaylist,
              ),
            ),
          );
          return;
        }

        var source = decision.selectedVariant?.videoSource;
        if (!mounted || !context.mounted) return;

        // Si l'utilisateur a déjà choisi une "version" pour ce film, on la réapplique
        // même lors d'une reprise, sans repasser par la bottom sheet.
        try {
          final userId = ref.read(currentUserIdProvider);
          final repo = ref.read(
            slProvider,
          )<PlaybackVariantSelectionLocalRepository>();
          final pinnedVariantId = await repo.getSelectedVariantId(
            widget.movieId,
            ContentType.movie,
            userId: userId,
          );
          if (pinnedVariantId != null) {
            for (final v in decision.rankedVariants) {
              if (v.id == pinnedVariantId) {
                source = v.videoSource;
                break;
              }
            }
          }
        } catch (_) {
          // Best-effort: ignore DB errors.
        }

        if (decision.requiresManualSelection) {
          // Si une variante mémorisée a été appliquée ci-dessus, on ne demande pas
          // à nouveau la sélection.
          if (source != null) {
            // proceed
          } else {
            if (!mounted || !context.mounted) return;
            final selectedVariant = await MoviePlaybackVariantSheet.show(
              context,
              movieTitle: title,
              variants: decision.rankedVariants,
              triggerFocusNode: _primaryActionFocusNode,
            );
            if (selectedVariant == null || !mounted || !context.mounted) {
              return;
            }
            try {
              final userId = ref.read(currentUserIdProvider);
              final repo = ref.read(
                slProvider,
              )<PlaybackVariantSelectionLocalRepository>();
              unawaited(
                repo.upsertSelectedVariantId(
                  contentId: widget.movieId,
                  contentType: ContentType.movie,
                  variantId: selectedVariant.id,
                  userId: userId,
                ),
              );
            } catch (_) {
              // Best-effort persistence: ignore errors.
            }
            source = selectedVariant.videoSource;
          }
        }

        // ignore: dead_code, unnecessary_null_comparison
        if (source == null) {
          diagnostics.completed(
            'movie_play_action',
            elapsed: stopwatch.elapsed,
            result: 'missing_source',
            context: <String, Object?>{
              'movieId': widget.movieId,
              'reason': decision.reason.name,
            },
          );
          if (!mounted || !context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.movieNotAvailableInPlaylist,
              ),
            ),
          );
          return;
        }

        if (!mounted || !context.mounted) return;
        diagnostics.completed(
          'movie_play_action',
          elapsed: stopwatch.elapsed,
          result: decision.disposition.name,
          context: <String, Object?>{
            'movieId': widget.movieId,
            'reason': decision.reason.name,
            'variants': decision.rankedVariants.length,
          },
        );
        final effectiveSource =
            decision.launchPlan?.buildVideoSource(
              source: source,
              startFromBeginning: startFromBeginning,
            ) ??
            source;
        context.push(AppRouteNames.player, extra: effectiveSource);
      } catch (e, st) {
        diagnostics.failed(
          'movie_play_action',
          elapsed: stopwatch.elapsed,
          error: e,
          stackTrace: st,
          context: <String, Object?>{'movieId': widget.movieId},
        );
        logger.error(
          AppLocalizations.of(context)!.errorPlaybackFailed(e.toString()),
          e,
          st,
        );
        if (!mounted || !context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorWithMessage(e.toString()),
            ),
          ),
        );
      }
    }, prefix: 'play');
  }

  Future<void> _chooseMovieVersionAndPlay(String title) async {
    return runWithOperationId(() async {
      final decision = await _loadMoviePlaybackSelection(title);
      if (!mounted || !context.mounted) return;
      if (decision.rankedVariants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.movieNotAvailableInPlaylist,
            ),
          ),
        );
        return;
      }

      final selectedVariant = await MoviePlaybackVariantSheet.show(
        context,
        movieTitle: title,
        variants: decision.rankedVariants,
        triggerFocusNode: _changeVersionFocusNode,
      );
      if (selectedVariant == null || !mounted || !context.mounted) return;

      try {
        final userId = ref.read(currentUserIdProvider);
        final repo = ref.read(
          slProvider,
        )<PlaybackVariantSelectionLocalRepository>();
        unawaited(
          repo.upsertSelectedVariantId(
            contentId: widget.movieId,
            contentType: ContentType.movie,
            variantId: selectedVariant.id,
            userId: userId,
          ),
        );
      } catch (_) {
        // Best-effort persistence: ignore errors.
      }

      if (!mounted || !context.mounted) return;
      final effectiveSource =
          decision.launchPlan?.buildVideoSource(
            source: selectedVariant.videoSource,
          ) ??
          selectedVariant.videoSource;
      context.push(AppRouteNames.player, extra: effectiveSource);
    }, prefix: 'play');
  }

  Future<PlaybackSelectionDecision> _loadMoviePlaybackSelection(
    String title,
  ) async {
    final args = _buildPlaybackSelectionArgs(
      movieId: widget.movieId,
      title: title,
    );
    return ref.read(mdp.moviePlaybackSelectionProvider(args).future);
  }
}
