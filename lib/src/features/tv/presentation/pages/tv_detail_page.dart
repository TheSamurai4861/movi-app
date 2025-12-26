import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart';
import 'package:movi/src/features/tv/presentation/models/tv_detail_view_model.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/iptv/data/services/xtream_stream_url_builder_impl.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/library/presentation/providers/library_remote_providers.dart';
import 'package:movi/src/features/library/presentation/widgets/library_playlist_card.dart';
import 'package:movi/src/features/playlist/playlist.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/core/parental/presentation/utils/parental_reason_localizer.dart';
import 'package:movi/src/core/parental/presentation/widgets/restricted_content_sheet.dart';
import 'package:movi/src/core/reporting/presentation/widgets/report_problem_sheet.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;

class TvDetailPage extends ConsumerStatefulWidget {
  const TvDetailPage({super.key, required this.seriesId});

  final String seriesId;

  @override
  ConsumerState<TvDetailPage> createState() => _TvDetailPageState();
}

enum EpisodeSortOrder { ascending, descending }

class _TvDetailPageState extends ConsumerState<TvDetailPage>
    with TickerProviderStateMixin {
  bool _overviewExpanded = false;
  bool _isTransitioningFromLoading = true;
  late TabController _tabController;
  EpisodeSortOrder _episodeSortOrder = EpisodeSortOrder.ascending;
  String mediaTitle = '—';
  String yearText = '—';
  String seasonsCountText = '—';
  String ratingText = '—';
  String overviewText = '';
  List<MoviPerson> cast = const [];
  List<SeasonViewModel> seasons = const [];
  Timer? _autoRefreshTimer;
  Timer? _seasonsCheckTimer;
  int _retryCount = 0;
  final Map<int, DateTime> _seasonLoadingStartTimes = {};
  static const int _maxRetries = 3;
  static const Duration _loadingTimeout = Duration(seconds: 15);
  static const Duration _seasonLoadingTimeout = Duration(seconds: 10);
  static const Duration _seasonsCheckInterval = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _isTransitioningFromLoading = true;
    _tabController = TabController(length: 1, vsync: this);
    _startAutoRefreshTimer();
    _startSeasonsCheckTimer();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _seasonsCheckTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    final mediaId = widget.seriesId;

    _autoRefreshTimer = Timer(_loadingTimeout, () {
      // Vérifier mounted AVANT d'utiliser ref
      if (!mounted) return;
      if (_retryCount >= _maxRetries) return;

      try {
        final vmAsync = ref.read(
          tvDetailProgressiveControllerProvider(mediaId),
        );
        // Si toujours en chargement après le timeout, relancer
        if (vmAsync.isLoading && mounted) {
          _retryCount++;
          ref.invalidate(tvDetailProgressiveControllerProvider(mediaId));
          if (mounted) {
            _startAutoRefreshTimer();
          }
        }
      } catch (e) {
        // Ignorer les erreurs si le widget est démonté
        if (mounted) {
          rethrow;
        }
      }
    });
  }

  void _startSeasonsCheckTimer() {
    _seasonsCheckTimer?.cancel();
    final mediaId = widget.seriesId;

    _seasonsCheckTimer = Timer.periodic(_seasonsCheckInterval, (timer) {
      // Vérifier mounted AVANT d'utiliser ref
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final vmAsync = ref.read(
          tvDetailProgressiveControllerProvider(mediaId),
        );
        final vm = vmAsync.value;

        if (vm == null) return;

        bool shouldReload = false;

        // Vérifier chaque saison
        for (final season in vm.seasons) {
          final seasonKey = season.seasonNumber;

          // Si la saison est en chargement
          if (season.isLoadingEpisodes) {
            // Enregistrer le moment où le chargement a commencé
            if (!_seasonLoadingStartTimes.containsKey(seasonKey)) {
              _seasonLoadingStartTimes[seasonKey] = DateTime.now();
            } else {
              // Vérifier si le chargement prend trop de temps
              final loadingStart = _seasonLoadingStartTimes[seasonKey]!;
              final loadingDuration = DateTime.now().difference(loadingStart);
              if (loadingDuration > _seasonLoadingTimeout && mounted) {
                // Le chargement prend trop de temps, relancer
                try {
                  final logger = ref.read(slProvider)<AppLogger>();
                  logger.debug(
                    'Saison ${season.seasonNumber} en chargement depuis ${loadingDuration.inSeconds}s, relance automatique',
                    category: 'tv_detail',
                  );
                  _seasonLoadingStartTimes.remove(seasonKey);
                  shouldReload = true;
                } catch (e) {
                  // Ignorer les erreurs si le widget est démonté
                  if (mounted) {
                    rethrow;
                  }
                }
              }
            }
          } else {
            // La saison n'est plus en chargement, retirer du tracking
            _seasonLoadingStartTimes.remove(seasonKey);

            // Vérifier si la saison devrait avoir des épisodes mais n'en a pas
            // (saisons normales sauf saison 0 qui peut être vide)
            // Ne vérifier qu'une seule fois par saison pour éviter les relances multiples
            if (season.episodes.isEmpty &&
                season.seasonNumber > 0 &&
                !season.isLoadingEpisodes &&
                !_seasonLoadingStartTimes.containsKey(seasonKey)) {
              // Marquer cette saison comme vérifiée pour éviter les vérifications multiples
              _seasonLoadingStartTimes[seasonKey] = DateTime.now();

              // Vérifier si des épisodes Xtream existent pour cette saison
              _checkIfSeasonShouldHaveEpisodes(season.seasonNumber).then((
                shouldHave,
              ) {
                // Vérifier mounted AVANT d'utiliser ref
                if (!mounted) return;
                if (shouldHave) {
                  try {
                    final logger = ref.read(slProvider)<AppLogger>();
                    logger.debug(
                      'Saison ${season.seasonNumber} devrait avoir des épisodes (trouvés dans le cache Xtream) mais n\'en a pas, relance automatique',
                      category: 'tv_detail',
                    );
                    _seasonLoadingStartTimes.remove(seasonKey);
                    if (mounted) {
                      ref.invalidate(
                        tvDetailProgressiveControllerProvider(mediaId),
                      );
                    }
                  } catch (e) {
                    // Ignorer les erreurs si le widget est démonté
                    if (mounted) {
                      rethrow;
                    }
                  }
                } else {
                  // Retirer du tracking si pas d'épisodes attendus
                  if (mounted) {
                    _seasonLoadingStartTimes.remove(seasonKey);
                  }
                }
              });
            }
          }
        }

        // Relancer le chargement si nécessaire
        if (shouldReload && mounted) {
          ref.invalidate(tvDetailProgressiveControllerProvider(mediaId));
        }
      } catch (e) {
        // Ignorer les erreurs si le widget est démonté
        if (mounted) {
          rethrow;
        }
      }
    });
  }

  /// Vérifie si une saison devrait avoir des épisodes en vérifiant le cache Xtream
  Future<bool> _checkIfSeasonShouldHaveEpisodes(int seasonNumber) async {
    try {
      // Vérifier mounted AVANT d'utiliser ref
      if (!mounted) return false;

      final locator = ref.read(slProvider);
      final iptvLocal = locator<IptvLocalRepository>();

      // Vérifier si c'est un ID Xtream
      String? seriesId;
      String? accountId;

      if (widget.seriesId.startsWith('xtream:')) {
        final streamIdStr = widget.seriesId.substring(7);
        final streamId = int.tryParse(streamIdStr);
        if (streamId == null) return false;

        final accounts = await iptvLocal.getAccounts();
        for (final account in accounts) {
          final playlists = await iptvLocal.getPlaylists(account.id);
          for (final playlist in playlists) {
            final found = playlist.items.firstWhere(
              (item) =>
                  item.streamId == streamId &&
                  item.type == XtreamPlaylistItemType.series,
              orElse: () => playlist.items.first,
            );
            if (found.streamId == streamId) {
              seriesId = streamId.toString();
              accountId = account.id;
              break;
            }
          }
          if (accountId != null) break;
        }
      } else {
        // Chercher par tmdbId
        final tmdbId = int.tryParse(widget.seriesId);
        if (tmdbId == null) return false;

        final accounts = await iptvLocal.getAccounts();
        for (final account in accounts) {
          final playlists = await iptvLocal.getPlaylists(account.id);
          for (final playlist in playlists) {
            final found = playlist.items.firstWhere(
              (item) =>
                  item.tmdbId == tmdbId &&
                  item.type == XtreamPlaylistItemType.series &&
                  item.streamId > 0,
              orElse: () => playlist.items.first,
            );
            if (found.tmdbId == tmdbId && found.streamId > 0) {
              seriesId = found.streamId.toString();
              accountId = account.id;
              break;
            }
          }
          if (accountId != null) break;
        }
      }

      if (seriesId == null || accountId == null) return false;

      // Vérifier si des épisodes existent dans le cache pour cette saison
      final allEpisodes = await iptvLocal.getAllEpisodesForSeries(
        accountId: accountId,
        seriesId: int.parse(seriesId),
      );

      // Vérifier si cette saison a des épisodes dans le cache
      return allEpisodes.containsKey(seasonNumber) &&
          allEpisodes[seasonNumber]!.isNotEmpty;
    } catch (e) {
      // En cas d'erreur, ne pas relancer
      return false;
    }
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
      final decisionAsync = ref.watch(parental.contentAgeDecisionProvider(content));
      return decisionAsync.when(
        loading: () => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: const OverlaySplash(),
        ),
        error: (_, __) => _buildAllowedDetail(context, mediaId),
        data: (decision) {
          if (decision.isAllowed) return _buildAllowedDetail(context, mediaId);

          final l10n = AppLocalizations.of(context)!;
          final localizedReason = getLocalizedParentalReason(context, decision.reason);
          final displayMessage = localizedReason ?? l10n.parentalContentRestrictedDefault;

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
                    Text(
                      displayMessage,
                      textAlign: TextAlign.center,
                    ),
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
                        ref.invalidate(parental.contentAgeDecisionProvider(content));
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

    // Gérer les erreurs et les états dans build() avec vérifications mounted
    // Ne pas utiliser ref.listen() car il peut s'exécuter après le démontage
    vmAsync.whenOrNull(
      error: (e, st) {
        // Utiliser addPostFrameCallback pour éviter d'utiliser ref directement dans whenOrNull
        if (mounted && _retryCount < _maxRetries) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _retryCount++;
            Future.delayed(const Duration(seconds: 2), () {
              // Vérifier mounted AVANT d'utiliser ref
              if (!mounted) return;
              try {
                ref.invalidate(tvDetailProgressiveControllerProvider(mediaId));
                if (mounted) {
                  _startAutoRefreshTimer();
                }
              } catch (e) {
                // Ignorer les erreurs si le widget est démonté
                if (mounted) {
                  rethrow;
                }
              }
            });
          });
        }
      },
      data: (_) {
        // Le chargement a réussi, annuler le timer et réinitialiser
        if (mounted) {
          _autoRefreshTimer?.cancel();
          _retryCount = 0;
        }
      },
    );

    return vmAsync.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const OverlaySplash(),
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

        // Vérifier les saisons qui sont en chargement et les tracker
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
          poster: vm.poster,
          backdrop: vm.backdrop,
        );
      },
    );
  }

  Widget _buildErrorScaffold(Object e) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Text('Erreur: $e', style: const TextStyle(color: Colors.white)),
      ),
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
    Uri? poster,
    Uri? backdrop,
  }) {
    final cs = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.headlineSmall;
    const heroHeight = 400.0;
    const overlayHeight = 200.0;
    return SwipeBackWrapper(
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
                        tvDetailProgressiveControllerProvider(widget.seriesId),
                      );
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: heroHeight,
                            width: double.infinity,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _buildHeroImage(poster, backdrop),
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          cs.surface,
                                          cs.surface.withValues(alpha: 0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  left: 20,
                                  right: 20,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => context.pop(),
                                        child: SizedBox(
                                          width: 35,
                                          height: 35,
                                          child: Image.asset(
                                            AppAssets.iconBack,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 25,
                                        height: 35,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: _showMoreMenu,
                                          child: Image.asset(
                                            AppAssets.iconMore,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: overlayHeight,
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
                              ],
                            ),
                          ),
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
                                  mediaTitle,
                                  style: titleStyle,
                                  textAlign: TextAlign.left,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 28,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      MoviPill(
                                        yearText,
                                        large: true,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        color: cs.surfaceContainerHighest,
                                      ),
                                      const SizedBox(width: 8),
                                      MoviPill(
                                        seasonsCountText,
                                        large: true,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        color: cs.surfaceContainerHighest,
                                      ),
                                      const SizedBox(width: 8),
                                      MoviPill(
                                        ratingText,
                                        large: true,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        color: cs.surfaceContainerHighest,
                                        trailingIcon: Image.asset(
                                          AppAssets.iconStarFilled,
                                          width: 18,
                                          height: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 55,
                                  child: Row(
                                    children: [
                                      Consumer(
                                        builder: (context, ref, _) {
                                          final seriesId = widget.seriesId;
                                          final historyAsync = ref.watch(
                                            hp.mediaHistoryProvider((
                                              contentId: seriesId,
                                              type: ContentType.series,
                                            )),
                                          );
                                          return Expanded(
                                            child: MoviPrimaryButton(
                                              label: historyAsync.when(
                                                data: (entry) {
                                                  if (entry != null &&
                                                      entry.season != null &&
                                                      entry.episode != null) {
                                                    return AppLocalizations.of(
                                                      context,
                                                    )!.tvResumeSeasonEpisode(
                                                      entry.season!,
                                                      entry.episode!,
                                                    );
                                                  }
                                                  return AppLocalizations.of(
                                                    context,
                                                  )!.homeWatchNow;
                                                },
                                                loading: () =>
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.homeWatchNow,
                                                error: (_, __) =>
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.homeWatchNow,
                                              ),
                                              assetIcon: AppAssets.iconPlay,
                                              buttonStyle: FilledButton.styleFrom(
                                                backgroundColor: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(32),
                                                ),
                                              ),
                                              onPressed: () => _playSeries(
                                                context,
                                                seriesId,
                                                mediaTitle,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: Consumer(
                                          builder: (context, ref, _) {
                                            final seriesId = widget.seriesId;
                                            final isFavoriteAsync = ref.watch(
                                              tvIsFavoriteProvider(seriesId),
                                            );
                                            return isFavoriteAsync.when(
                                              data: (isFavorite) =>
                                                  MoviFavoriteButton(
                                                    isFavorite: isFavorite,
                                                    onPressed: () async {
                                                      await ref
                                                          .read(
                                                            tvToggleFavoriteProvider
                                                                .notifier,
                                                          )
                                                          .toggle(seriesId);
                                                    },
                                                  ),
                                              loading: () => MoviFavoriteButton(
                                                isFavorite: false,
                                                onPressed: () {},
                                              ),
                                              error: (_, __) =>
                                                  MoviFavoriteButton(
                                                    isFavorite: false,
                                                    onPressed: () {},
                                                  ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final screenWidth = MediaQuery.of(
                                      context,
                                    ).size.width;
                                    final synopsisWidth = screenWidth - 40;
                                    return SizedBox(
                                      width: synopsisWidth,
                                      child: Column(
                                        children: [
                                          AnimatedSize(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                            alignment: Alignment.topLeft,
                                            child: ConstrainedBox(
                                              constraints: _overviewExpanded
                                                  ? const BoxConstraints()
                                                  : const BoxConstraints(
                                                      maxHeight: 90,
                                                    ),
                                              child: Stack(
                                                children: [
                                                  Text(
                                                    overviewText,
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodyLarge,
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
                                                              begin: Alignment
                                                                  .topCenter,
                                                              end: Alignment
                                                                  .bottomCenter,
                                                              colors: [
                                                                cs.surface
                                                                    .withValues(
                                                                      alpha: 0,
                                                                    ),
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
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                GestureDetector(
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onTap: () {
                                                    setState(() {
                                                      _overviewExpanded =
                                                          !_overviewExpanded;
                                                    });
                                                  },
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        _overviewExpanded
                                                            ? AppLocalizations.of(
                                                                context,
                                                              )!.actionCollapse
                                                            : AppLocalizations.of(
                                                                context,
                                                              )!.actionExpand,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: cs.onSurface
                                                              .withValues(
                                                                alpha: 0.7,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Icon(
                                                        _overviewExpanded
                                                            ? Icons
                                                                  .keyboard_arrow_up
                                                            : Icons
                                                                  .keyboard_arrow_down,
                                                        color: cs.onSurface
                                                            .withValues(
                                                              alpha: 0.7,
                                                            ),
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
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildDistribution(cast),
                          const SizedBox(height: 32),
                          if (seasons.isNotEmpty) _buildSeasonsTabs(seasons),
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
    );
  }

  Widget _buildHeroImage(Uri? poster, Uri? backdrop) {
    final Uri? uri = poster ?? backdrop;
    if (uri == null) {
      return MoviPlaceholderCard(
        type: PlaceholderType.series,
        fit: BoxFit.cover,
        alignment: const Alignment(0.0, -0.5),
        borderRadius: BorderRadius.zero,
      );
    }
    final mq = MediaQuery.of(context);
    final int rawPx = (mq.size.width * mq.devicePixelRatio).round();
    final int cacheWidth = rawPx.clamp(480, 1920);
    return Image.network(
      uri.toString(),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      alignment: const Alignment(0.0, -0.5),
    );
  }

  Widget _buildDistribution(List<MoviPerson> cast) {
    if (cast.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 20, end: 20),
          child: Text(
            AppLocalizations.of(context)!.tvDistribution,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 286,
          child: ListView.separated(
            padding: const EdgeInsetsDirectional.only(start: 20, end: 12),
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final p = cast[index];
              return MoviPersonCard(
                person: p,
                onTap: (person) {
                  // Convertir MoviPerson en PersonSummary pour la navigation
                  final personSummary = PersonSummary(
                    id: PersonId(person.id),
                    name: person.name,
                    role: person.role,
                    photo: person.poster,
                  );
                  context.push(AppRouteNames.person, extra: personSummary);
                },
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
      _tabController.dispose();
      _tabController = TabController(length: seasons.length, vsync: this);
    }

    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 20, end: 20),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Theme.of(context).colorScheme.onSurface,
                    unselectedLabelColor: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    indicatorColor: Theme.of(context).colorScheme.primary,
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
                SizedBox(
                  height: 600,
                  child: TabBarView(
                    controller: _tabController,
                    children: seasons.map((season) {
                      return _buildSeasonEpisodes(season);
                    }).toList(),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 56,
              right: 20,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _episodeSortOrder =
                        _episodeSortOrder == EpisodeSortOrder.ascending
                        ? EpisodeSortOrder.descending
                        : EpisodeSortOrder.ascending;
                  });
                },
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Image.asset(AppAssets.iconSort),
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

  Widget _buildSeasonEpisodes(SeasonViewModel season) {
    // Afficher un indicateur de chargement si les épisodes sont en cours de chargement
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

    return ListView.separated(
      padding: const EdgeInsetsDirectional.only(start: 20, end: 20, top: 20),
      itemCount: sortedEpisodes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final episode = sortedEpisodes[index];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openEpisodePlayer(episode, season.seasonNumber),
          child: _buildEpisodeCard(episode),
        );
      },
    );
  }

  Widget _buildEpisodeCard(EpisodeViewModel episode) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Prendre la moitié de la largeur disponible
        final imageWidth = constraints.maxWidth / 2;
        final imageHeight = imageWidth * (100 / 178); // Conserver le ratio 178:100
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: episode.still != null
                  ? Image.network(
                      episode.still!.toString(),
                      width: imageWidth,
                      height: imageHeight,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: imageWidth,
                        height: imageHeight,
                        color: cs.surfaceContainerHighest,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                        ),
                      ),
                    )
                  : Container(
                      width: imageWidth,
                      height: imageHeight,
                      color: cs.surfaceContainerHighest,
                      child: const Icon(Icons.live_tv, color: Colors.white54),
                    ),
            ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${episode.episodeNumber}. ${episode.title}',
                style:
                    Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ) ??
                    TextStyle(
                      fontSize: 16,
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
                  if (episode.runtime != null)
                    MoviPill(
                      _formatDuration(episode.runtime!),
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

  /// Détecte si une saison utilise la numérotation globale ou relative
  ///
  /// Retourne true si la saison utilise la numérotation globale (ex: épisode 1055),
  /// false si elle utilise la numérotation relative (ex: épisode 1, 2, 3...).
  bool _isSeasonUsingGlobalNumbering(
    int seasonNumber,
    List<SeasonViewModel> seasons,
  ) {
    // Trouver la saison
    final season = seasons.firstWhere(
      (s) => s.seasonNumber == seasonNumber,
      orElse: () => seasons.firstOrNull ?? seasons.first,
    );

    if (season.episodes.isEmpty) return false;

    // Si le premier épisode de la saison a un numéro > 1, c'est probablement global
    final firstEpisodeNumber = season.episodes.first.episodeNumber;
    if (firstEpisodeNumber > 1) {
      return true;
    }

    // Si le numéro du dernier épisode est supérieur au nombre d'épisodes dans la saison,
    // c'est probablement global
    final lastEpisodeNumber = season.episodes.last.episodeNumber;
    if (lastEpisodeNumber > season.episodes.length) {
      return true;
    }

    // Sinon, c'est probablement relatif
    return false;
  }

  /// Convertit le numéro d'épisode TMDB en numéro relatif à la saison pour Xtream
  ///
  /// Détecte automatiquement si la saison utilise la numérotation globale ou relative.
  /// Si globale (ex: épisode 1055 pour la saison 21), convertit en relatif (ex: épisode 55).
  /// Si relative (ex: épisode 1, 2, 3...), utilise le numéro tel quel.
  int _convertTmdbEpisodeToXtream(
    int tmdbEpisodeNumber,
    int seasonNumber,
    List<SeasonViewModel> seasons,
  ) {
    // Détecter si la saison utilise la numérotation globale
    final isGlobal = _isSeasonUsingGlobalNumbering(seasonNumber, seasons);

    if (!isGlobal) {
      // La saison utilise déjà la numérotation relative, utiliser le numéro tel quel
      return tmdbEpisodeNumber;
    }

    // La saison utilise la numérotation globale, convertir en relatif
    // Calculer le nombre total d'épisodes dans toutes les saisons précédentes
    // IMPORTANT: Exclure la saison 0 car elle n'existe pas dans Xtream
    int totalEpisodesBefore = 0;
    for (final season in seasons) {
      // Ignorer la saison 0 (épisodes spéciaux qui n'existent pas dans Xtream)
      if (season.seasonNumber > 0 && season.seasonNumber < seasonNumber) {
        totalEpisodesBefore += season.episodes.length;
      }
    }

    // Convertir en numéro relatif à la saison
    final xtreamEpisodeNumber = tmdbEpisodeNumber - totalEpisodesBefore;

    // Gérer les cas limites : si le calcul donne un numéro <= 0, utiliser 1 comme fallback
    return xtreamEpisodeNumber > 0 ? xtreamEpisodeNumber : 1;
  }

  Future<void> _openEpisodePlayer(
    EpisodeViewModel episode,
    int seasonNumber,
  ) async {
    try {
      final locator = ref.read(slProvider);
      final iptvLocal = locator<IptvLocalRepository>();
      final vault = locator<CredentialsVault>();
      final logger = locator<AppLogger>();
      final networkExecutor = locator<NetworkExecutor>();
      final urlBuilder = XtreamStreamUrlBuilderImpl(
        iptvLocal: iptvLocal,
        vault: vault,
        networkExecutor: networkExecutor,
      );

      // Récupérer le ViewModel pour obtenir toutes les saisons et convertir le numéro d'épisode
      final vmAsync = ref.read(
        tvDetailProgressiveControllerProvider(widget.seriesId),
      );
      final vm = vmAsync.value;

      // Convertir le numéro d'épisode TMDB en numéro Xtream
      int xtreamEpisodeNumber = episode.episodeNumber;
      if (vm != null && vm.seasons.isNotEmpty) {
        final isGlobal = _isSeasonUsingGlobalNumbering(
          seasonNumber,
          vm.seasons,
        );
        final convertedNumber = _convertTmdbEpisodeToXtream(
          episode.episodeNumber,
          seasonNumber,
          vm.seasons,
        );

        if (isGlobal) {
          logger.debug(
            'Conversion épisode TMDB->Xtream (global): S${seasonNumber}E${episode.episodeNumber} (TMDB global) -> S${seasonNumber}E$convertedNumber (Xtream relatif)',
          );
        } else {
          logger.debug(
            'Épisode déjà en numérotation relative: S${seasonNumber}E${episode.episodeNumber} (pas de conversion nécessaire)',
          );
        }
        xtreamEpisodeNumber = convertedNumber;
      } else {
        logger.debug(
          'ViewModel non disponible ou saisons vides, utilisation du numéro d\'épisode original: ${episode.episodeNumber}',
        );
      }

      // Chercher l'item Xtream correspondant
      XtreamPlaylistItem? xtreamItem;
      final activeSourceIds =
          ref.read(asp.appStateControllerProvider).preferredIptvSourceIds;
      final xtreamAccounts = await iptvLocal.getAccounts();
      final stalkerAccounts = await iptvLocal.getStalkerAccounts();
      final accountIds = <String>{
        ...xtreamAccounts.map((a) => a.id),
        ...stalkerAccounts.map((a) => a.id),
      };
      if (activeSourceIds.isEmpty) {
        accountIds.clear();
      } else {
        accountIds.removeWhere((id) => !activeSourceIds.contains(id));
      }
      final seriesId = widget.seriesId;

      logger.debug(
        'Recherche de la série seriesId=$seriesId, saison=$seasonNumber, épisode=$xtreamEpisodeNumber (Xtream) dans ${accountIds.length} comptes',
      );

      for (final accountId in accountIds) {
        final playlists = await iptvLocal.getPlaylists(accountId);
        logger.debug('Compte $accountId: ${playlists.length} playlists');
        // Recherche globale dans toutes les playlists (movies et series)
        // car certaines séries peuvent être mal catégorisées
        for (final playlist in playlists) {
          logger.debug(
            'Playlist ${playlist.title} (${playlist.type.name}): ${playlist.items.length} items',
          );
          // Si l'ID commence par "xtream:", chercher par streamId
          if (seriesId.startsWith('xtream:')) {
            final streamIdStr = seriesId.substring(7);
            final streamId = int.tryParse(streamIdStr);
            if (streamId != null) {
              try {
                // Chercher dans tous les items, peu importe le type
                final found = playlist.items.firstWhere(
                  (item) => item.streamId == streamId,
                );
                logger.debug(
                  'Série trouvée: ${found.title} (streamId=${found.streamId}, tmdbId=${found.tmdbId}, type=${found.type.name})',
                );
                // Vérifier que c'est bien une série et que le streamId est valide
                if (found.type != XtreamPlaylistItemType.series) {
                  logger.debug(
                    'Item trouvé n\'est pas une série (type=${found.type.name}), continuer la recherche',
                  );
                  continue;
                }
                if (found.streamId == 0) {
                  logger.debug(
                    'Série trouvée avec streamId invalide (${found.streamId}), continuer la recherche',
                  );
                  continue;
                }
                xtreamItem = found;
              } catch (_) {
                // Item non trouvé, continuer la recherche
                logger.debug(
                  'Série avec streamId=$streamId non trouvée dans ${playlist.title}',
                );
              }
            }
          } else {
            // Sinon, chercher par tmdbId
            final tmdbId = int.tryParse(seriesId);
            if (tmdbId != null) {
              try {
                // Chercher dans tous les items, peu importe le type
                // Chercher toutes les occurrences pour trouver celle avec un streamId valide
                final candidates = playlist.items
                    .where(
                      (item) =>
                          item.tmdbId == tmdbId &&
                          item.type == XtreamPlaylistItemType.series,
                    )
                    .toList();

                if (candidates.isNotEmpty) {
                  // Préférer celle avec un streamId valide (non nul)
                  final validCandidate = candidates.firstWhere(
                    (item) => item.streamId > 0,
                    orElse: () => candidates.first,
                  );

                  logger.debug(
                    'Série trouvée: ${validCandidate.title} (streamId=${validCandidate.streamId}, tmdbId=${validCandidate.tmdbId}, type=${validCandidate.type.name})',
                  );

                  // Si le streamId est toujours 0, continuer la recherche dans d'autres playlists
                  if (validCandidate.streamId == 0) {
                    logger.debug(
                      'Série trouvée avec streamId invalide (${validCandidate.streamId}), continuer la recherche',
                    );
                    continue;
                  }

                  xtreamItem = validCandidate;
                }
              } catch (_) {
                // Item non trouvé, continuer la recherche
                logger.debug(
                  'Série avec tmdbId=$tmdbId non trouvée dans ${playlist.title}',
                );
              }
            }
          }

          if (xtreamItem != null) break;
        }
        if (xtreamItem != null) break;
      }

      if (xtreamItem == null) {
        logger.info('Série seriesId=$seriesId non trouvée dans les playlists');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Épisode non disponible dans la playlist'),
          ),
        );
        return;
      }

      logger.debug(
        'Construction URL pour série streamId=${xtreamItem.streamId}, saison=$seasonNumber, épisode=$xtreamEpisodeNumber (Xtream)',
      );

      // Vérifier si l'épisode est en cache avant de construire l'URL
      final cachedEpisodeData = await iptvLocal.getEpisodeData(
        accountId: xtreamItem.accountId,
        seriesId: xtreamItem.streamId,
        seasonNumber: seasonNumber,
        episodeNumber: xtreamEpisodeNumber,
      );
      if (cachedEpisodeData != null) {
        logger.debug(
          'Épisode trouvé en cache: S${seasonNumber}E$xtreamEpisodeNumber -> episodeId=${cachedEpisodeData.episodeId}',
        );
      } else {
        logger.debug(
          'Épisode NON trouvé en cache: S${seasonNumber}E$xtreamEpisodeNumber, chargement depuis l\'API...',
        );
      }

      // Construire l'URL de streaming
      final streamUrl = await urlBuilder.buildStreamUrlFromSeriesItem(
        item: xtreamItem,
        seasonNumber: seasonNumber,
        episodeNumber: xtreamEpisodeNumber,
      );
      if (streamUrl == null) {
        logger.error(
          'Impossible de construire l\'URL pour streamId=${xtreamItem.streamId}, saison=$seasonNumber, épisode=$xtreamEpisodeNumber',
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de construire l\'URL de streaming'),
          ),
        );
        return;
      }

      logger.debug('URL de streaming construite: $streamUrl');

      // Construire le titre de l'épisode
      // Utiliser le ViewModel déjà récupéré
      final seriesTitle = vm?.title ?? mediaTitle;
      // Afficher le numéro d'épisode TMDB dans le titre (pour l'utilisateur)
      final episodeTitle = episode.title.isNotEmpty
          ? '$seriesTitle - S${seasonNumber.toString().padLeft(2, '0')}E${episode.episodeNumber.toString().padLeft(2, '0')} - ${episode.title}'
          : '$seriesTitle - S${seasonNumber.toString().padLeft(2, '0')}E${episode.episodeNumber.toString().padLeft(2, '0')}';

      // Récupérer le poster depuis le view model
      final posterUri = vm?.poster;

      // Récupérer la position de reprise depuis l'historique
      // Utiliser le numéro d'épisode TMDB pour l'historique (c'est ce qui est stocké)
      Duration? resumePosition;
      try {
        // Utiliser le repository hybride (local + Supabase si disponible)
        final historyRepo = ref.read(hybridPlaybackHistoryRepositoryProvider);
        final historyEntry = await historyRepo.getEntry(
          seriesId,
          ContentType.series,
          season: seasonNumber,
          episode: episode.episodeNumber,
        );
        resumePosition = historyEntry?.lastPosition;
      } catch (e) {
        // Ignorer les erreurs de récupération de l'historique
        logger.debug('Impossible de récupérer la position de reprise: $e');
      }

      // Ouvrir le player
      // Utiliser le numéro d'épisode TMDB pour l'affichage dans le player
      if (!mounted) return;
      context.push(
        AppRouteNames.player,
        extra: VideoSource(
          url: streamUrl.toString(),
          title: episodeTitle,
          contentId: seriesId,
          tmdbId: xtreamItem.tmdbId ?? int.tryParse(seriesId),
          contentType: ContentType.series,
          poster: posterUri,
          season: seasonNumber,
          episode:
              episode.episodeNumber, // Utiliser le numéro TMDB pour l'affichage
          resumePosition: resumePosition,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _playSeries(
    BuildContext context,
    String seriesId,
    String title,
  ) async {
    try {
      // Récupérer l'historique pour trouver l'épisode à reprendre
      // Utiliser le repository hybride (local + Supabase si disponible)
      final historyRepo = ref.read(hybridPlaybackHistoryRepositoryProvider);
      final historyEntry = await historyRepo.getEntry(
        seriesId,
        ContentType.series,
      );

      // Si pas d'historique ou pas d'épisode en cours, afficher un message
      if (historyEntry == null ||
          historyEntry.season == null ||
          historyEntry.episode == null) {
        if (!mounted) return;
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sélectionnez un épisode pour le lire')),
        );
        return;
      }

      final seasonNumber = historyEntry.season!;
      final episodeNumber = historyEntry.episode!;

      // Récupérer le ViewModel pour trouver l'épisode
      final vmAsync = ref.read(tvDetailProgressiveControllerProvider(seriesId));
      final vm = vmAsync.value;
      if (vm == null) {
        if (!mounted) return;
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chargement des épisodes en cours...')),
        );
        return;
      }

      // Trouver la saison dans le ViewModel
      final season = vm.seasons.firstWhere(
        (s) => s.seasonNumber == seasonNumber,
        orElse: () {
          // Si la saison n'existe pas, utiliser la première saison disponible
          if (vm.seasons.isEmpty) {
            throw StateError('Aucune saison disponible');
          }
          return vm.seasons.first;
        },
      );

      // Vérifier si les épisodes sont chargés pour cette saison
      if (season.isLoadingEpisodes || season.episodes.isEmpty) {
        if (!mounted) return;
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chargement des épisodes en cours...')),
        );
        return;
      }

      final episode = season.episodes.firstWhere(
        (e) => e.episodeNumber == episodeNumber,
        orElse: () => season.episodes.first,
      );

      // Lancer l'épisode à reprendre
      await _openEpisodePlayer(episode, seasonNumber);
    } catch (e) {
      final logger = ref.read(slProvider)<AppLogger>();
      logger.error('Erreur lors de la reprise de la série: $e', e);
      if (!mounted) return;
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
        const SnackBar(content: Text('Chargement des playlists...')),
      );

      final playlists = await ref.read(libraryPlaylistsProvider.future);

      // Récupérer les données de la série depuis le provider
      // Vérifier que le widget est encore monté avant d'utiliser ref
      if (!mounted || !context.mounted) {
        messenger?.hideCurrentSnackBar();
        return;
      }
      messenger?.hideCurrentSnackBar();
      final vmAsync = ref.read(
        tvDetailProgressiveControllerProvider(seriesId),
      );
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune playlist disponible. Créez en une'),
            ),
          );
        }
        return;
      }

      if (!mounted || !context.mounted) return;

      final container = ProviderScope.containerOf(context, listen: false);
      final playlistRepository = ref.read(slProvider)<PlaylistRepository>();
      final logger = ref.read(slProvider)<AppLogger>();
      final addPlaylistItem = AddPlaylistItem(playlistRepository);

      showCupertinoModalPopup<void>(
        context: context,
        builder: (ctx) {
          final actions = <CupertinoActionSheetAction>[];

          // Ajouter les playlists existantes
          actions.addAll(availablePlaylists.map((playlist) {
            return CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final canNotify = mounted && context.mounted;
                final l10n = AppLocalizations.of(context)!;
                final messenger = ScaffoldMessenger.maybeOf(context);
                final playlistIdToInvalidate = playlist.playlistId;

                try {
                  // Ajouter à la playlist utilisateur
                  // Utiliser les données disponibles
                  final year =
                      yearTextValue != '—' ? int.tryParse(yearTextValue) : null;

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

                  // Vérifier que le widget est encore monté avant d'utiliser ref
                  // Invalider tous les providers nécessaires
                  // Note: Ces invalidations ne causeront pas de rebuild du dialogue
                  // car nous utilisons ref.read au lieu de ref.watch
                  container.invalidate(
                    playlistItemsProvider(playlistIdToInvalidate!),
                  );
                  container.invalidate(
                    playlistContentReferencesProvider(
                      playlistIdToInvalidate,
                    ),
                  );
                  container.invalidate(libraryPlaylistsProvider);

                  if (canNotify && messenger != null) {
                    _showTopNotification(
                      l10n,
                      messenger,
                      l10n.playlistAddedTo(playlist.title),
                    );
                  }
                } catch (e, stackTrace) {
                  // Logger l'erreur pour le debug (logger déjà capturé)
                  logger.log(
                    LogLevel.error,
                    'Erreur lors de l\'ajout à la playlist: $e',
                    error: e,
                    stackTrace: stackTrace,
                    category: 'tv_detail',
                  );

                  if (canNotify) {
                    // Gérer spécifiquement l'erreur de doublon
                    String errorMessage;
                    if (e is StateError &&
                        e.message.contains(
                          'déjà dans cette playlist',
                        )) {
                      errorMessage = 'Ce média est déjà dans cette playlist';
                    } else {
                      errorMessage = l10n.errorWithMessage(e.toString());
                    }

                    messenger?.showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
              child: Text(playlist.title),
            );
          }));

          return CupertinoActionSheet(
            title: Text(AppLocalizations.of(context)!.actionAddToList),
            actions: actions,
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppLocalizations.of(context)!.actionCancel),
            ),
          );
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
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final seriesId = widget.seriesId;
            final isAvailableAsync = ref.watch(
              _seriesAvailabilityProvider(seriesId),
            );
            final isSeenAsync = ref.watch(_seriesSeenProvider(seriesId));

            final isAvailable = isAvailableAsync.value ?? false;
            final isSeen = isSeenAsync.value ?? false;

            final actions = <Widget>[
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _onRefreshMetadata();
                },
                child: Text(
                  AppLocalizations.of(context)!.actionRefreshMetadata,
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showAddToListDialog(context, ref, seriesId);
                },
                child: Text(AppLocalizations.of(context)!.actionAddToList),
              ),
            ];

            // Ajouter l'option vu/non vu seulement si la série est disponible
            if (isAvailable) {
              if (isSeen) {
                actions.add(
                  CupertinoActionSheetAction(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _markAsUnseen(seriesId);
                    },
                    child: Text(AppLocalizations.of(context)!.actionMarkUnseen),
                  ),
                );
              } else {
                actions.add(
                  CupertinoActionSheetAction(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _markAsSeen(seriesId);
                    },
                    child: Text(AppLocalizations.of(context)!.actionMarkSeen),
                  ),
                );
              }
            }

            actions.add(
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  final tmdbId = int.tryParse(seriesId);
                  if (tmdbId == null || tmdbId <= 0) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Signalement indisponible pour ce contenu.'),
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
                    ),
                  );
                },
                child: Text(AppLocalizations.of(context)!.actionReportProblem),
              ),
            );

            return CupertinoActionSheet(
              title: Text(mediaTitle),
              actions: actions,
              cancelButton: CupertinoActionSheetAction(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(AppLocalizations.of(context)!.actionCancel),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _markAsSeen(String seriesId) async {
    try {
      // Utiliser le repository hybride (local + Supabase si disponible)
      final historyRepo = ref.read(hybridPlaybackHistoryRepositoryProvider);
      final poster =
          ref.read(tvDetailProgressiveControllerProvider(seriesId)).value?.poster;

      // Pour une série, on marque comme vu en ajoutant une entrée avec progression 100%
      // La durée par défaut est de 45 minutes par épisode
      final duration = const Duration(minutes: 45);
      await historyRepo.upsertPlay(
        contentId: seriesId,
        type: ContentType.series,
        title: mediaTitle,
        poster: poster,
        position: duration, // Position à 100% pour marquer comme vu
        duration: duration,
      );

      // Invalider les providers pour mettre à jour l'UI
      ref.invalidate(_seriesSeenProvider(seriesId));
      ref.invalidate(libraryPlaylistsProvider);
      ref.invalidate(hp.homeControllerProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.actionMarkSeen)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _markAsUnseen(String seriesId) async {
    try {
      final locator = ref.read(slProvider);
      // Utiliser le repository hybride (local + Supabase si disponible)
      final historyRepo = ref.read(hybridPlaybackHistoryRepositoryProvider);
      final continueWatchingRepo = locator<ContinueWatchingLocalRepository>();

      // Retirer de l'historique (retire tous les épisodes de la série)
      await historyRepo.remove(seriesId, ContentType.series);

      // Retirer de continue watching (retire tous les épisodes de la série)
      await continueWatchingRepo.remove(seriesId, ContentType.series);

      // Invalider les providers pour mettre à jour l'UI
      ref.invalidate(_seriesSeenProvider(seriesId));
      ref.invalidate(libraryPlaylistsProvider);
      ref.invalidate(hp.homeControllerProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.actionMarkUnseen),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
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
      final locator = ref.read(slProvider);
      final historyRepo = locator<HistoryLocalRepository>();
      final entries = await historyRepo.readAll(ContentType.series);
      final entry = entries.firstWhere(
        (e) => e.contentId == seriesId,
        orElse: () => throw StateError('Entry not found'),
      );
      if (entry.duration == null || entry.duration!.inSeconds <= 0) {
        return false;
      }
      final progress =
          (entry.lastPosition?.inSeconds ?? 0) / entry.duration!.inSeconds;
      return progress >= 0.9;
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
