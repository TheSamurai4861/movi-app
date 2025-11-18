import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/theme/theme.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/core/models/models.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart';
import 'package:movi/src/features/tv/presentation/models/tv_detail_view_model.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/library/presentation/widgets/library_playlist_card.dart';
import 'package:movi/src/features/playlist/playlist.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class TvDetailPage extends ConsumerStatefulWidget {
  const TvDetailPage({super.key, this.media});

  final MoviMedia? media;

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

  @override
  void initState() {
    super.initState();
    _isTransitioningFromLoading = true;
    _primeFromArgs();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _primeFromArgs() {
    final m = widget.media;
    if (m != null) {
      mediaTitle = m.title;
      yearText = m.year?.toString() ?? '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(
          child: Text(
            'Aucun média à afficher (media null).',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    final vmAsync = ref.watch(
      tvDetailProgressiveControllerProvider(widget.media!.id),
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
                  child: SingleChildScrollView(
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
                                        cs.surface.withOpacity(0),
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
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => context.pop(),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 35,
                                            height: 35,
                                            child: Image.asset(
                                              AppAssets.iconBack,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.actionBack,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 25,
                                      height: 35,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: _showMoreMenu,
                                        child: Image.asset(AppAssets.iconMore),
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
                                        cs.surface.withOpacity(0),
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
                                        if (widget.media == null) {
                                          return Expanded(
                                            child: MoviPrimaryButton(
                                              label: AppLocalizations.of(
                                                context,
                                              )!.homeWatchNow,
                                              assetIcon: AppAssets.iconPlay,
                                              buttonStyle: FilledButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.accent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(32),
                                                ),
                                              ),
                                              onPressed: () => _playSeries(
                                                context,
                                                widget.media?.id,
                                                mediaTitle,
                                              ),
                                            ),
                                          );
                                        }
                                        final historyAsync = ref.watch(
                                          hp.mediaHistoryProvider((
                                            contentId: widget.media!.id,
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
                                                  return 'Reprendre S${entry.season!.toString().padLeft(2, '0')} E${entry.episode!.toString().padLeft(2, '0')}';
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
                                              backgroundColor: AppColors.accent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(32),
                                              ),
                                            ),
                                            onPressed: () => _playSeries(
                                              context,
                                              widget.media?.id,
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
                                          final seriesId = widget.media!.id;
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
                                                                  .withOpacity(
                                                                    0,
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
                                                            .withOpacity(0.7),
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
                                                          .withOpacity(0.7),
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
      return Image.asset(
        AppAssets.placeholderPosterMovie,
        fit: BoxFit.cover,
        alignment: const Alignment(0.0, -0.5),
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
            'Distribution',
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
                    ).colorScheme.onSurface.withOpacity(0.6),
                    indicatorColor: AppColors.accent,
                    labelStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                    tabs: seasons.map((s) {
                      return Tab(text: 'Saison ${s.seasonNumber}');
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
                        cs.surface.withOpacity(0.3),
                        cs.surface.withOpacity(0),
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
          'Aucun épisode disponible',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: episode.still != null
              ? Image.network(
                  episode.still!.toString(),
                  width: 178,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 178,
                    height: 100,
                    color: cs.surfaceContainerHighest,
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                    ),
                  ),
                )
              : Container(
                  width: 178,
                  height: 100,
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
                  color: Colors.red.withOpacity(0.5),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return months[month - 1];
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

  Future<void> _openEpisodePlayer(
    EpisodeViewModel episode,
    int seasonNumber,
  ) async {
    if (widget.media == null) return;

    try {
      final locator = ref.read(slProvider);
      final iptvLocal = locator<IptvLocalRepository>();
      final vault = locator<CredentialsVault>();
      final logger = locator<AppLogger>();
      final networkExecutor = locator<NetworkExecutor>();
      final urlBuilder = XtreamStreamUrlBuilder(
        iptvLocal: iptvLocal,
        vault: vault,
        networkExecutor: networkExecutor,
      );

      // Chercher l'item Xtream correspondant
      XtreamPlaylistItem? xtreamItem;
      final accounts = await iptvLocal.getAccounts();
      final seriesId = widget.media!.id;

      logger.debug(
        'Recherche de la série seriesId=$seriesId, saison=$seasonNumber, épisode=${episode.episodeNumber} dans ${accounts.length} comptes',
      );

      for (final account in accounts) {
        final playlists = await iptvLocal.getPlaylists(account.id);
        logger.debug('Compte ${account.id}: ${playlists.length} playlists');
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Épisode non disponible dans la playlist'),
          ),
        );
        return;
      }

      logger.debug(
        'Construction URL pour série streamId=${xtreamItem.streamId}, saison=$seasonNumber, épisode=${episode.episodeNumber}',
      );

      // Construire l'URL de streaming
      final streamUrl = await urlBuilder.buildStreamUrlFromSeriesItem(
        item: xtreamItem,
        seasonNumber: seasonNumber,
        episodeNumber: episode.episodeNumber,
      );
      if (streamUrl == null) {
        logger.error(
          'Impossible de construire l\'URL pour streamId=${xtreamItem.streamId}, saison=$seasonNumber, épisode=${episode.episodeNumber}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de construire l\'URL de streaming'),
          ),
        );
        return;
      }

      logger.debug('URL de streaming construite: $streamUrl');

      // Construire le titre de l'épisode
      // Récupérer le titre depuis le ViewModel via le provider
      final vmAsync = ref.read(
        tvDetailProgressiveControllerProvider(widget.media!.id),
      );
      final seriesTitle = vmAsync.value?.title ?? mediaTitle;
      final episodeTitle = episode.title.isNotEmpty
          ? '$seriesTitle - S${seasonNumber.toString().padLeft(2, '0')}E${episode.episodeNumber.toString().padLeft(2, '0')} - ${episode.title}'
          : '$seriesTitle - S${seasonNumber.toString().padLeft(2, '0')}E${episode.episodeNumber.toString().padLeft(2, '0')}';

      // Récupérer le poster depuis widget.media ou le view model
      Uri? posterUri = widget.media?.poster;
      if (posterUri == null && vmAsync.value != null) {
        posterUri = vmAsync.value!.poster;
      }

      // Ouvrir le player
      context.push(
        AppRouteNames.player,
        extra: VideoSource(
          url: streamUrl,
          title: episodeTitle,
          contentId: seriesId,
          contentType: ContentType.series,
          poster: posterUri,
          season: seasonNumber,
          episode: episode.episodeNumber,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _playSeries(
    BuildContext context,
    String? seriesId,
    String title,
  ) async {
    if (seriesId == null) return;

    // Pour une série, on ne peut pas jouer directement sans sélectionner un épisode
    // On pourrait ouvrir le premier épisode disponible, mais pour l'instant on affiche un message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sélectionnez un épisode pour le lire')),
    );
  }

  Future<void> _showAddToListDialog(
    BuildContext context,
    WidgetRef ref,
    String seriesId,
  ) async {
    try {
      final playlistsAsync = ref.read(libraryPlaylistsProvider);
      final playlists = await playlistsAsync.value;
      
      if (playlists == null || playlists.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucune playlist disponible')),
          );
        }
        return;
      }
      
      // Récupérer les données de la série depuis le provider
      final vmAsync = ref.read(tvDetailProgressiveControllerProvider(seriesId));
      final vm = await vmAsync.value;
      
      // Utiliser les données du widget si le view model n'est pas disponible
      final title = vm?.title ?? mediaTitle;
      final yearTextValue = vm?.yearText ?? yearText;
      final poster = widget.media?.poster ?? vm?.poster;
      
      // Filtrer les playlists selon le type de contenu
      final playlistRepository = ref.read(slProvider)<PlaylistRepository>();
      final availablePlaylists = <LibraryPlaylistItem>[];
      
      for (final playlist in playlists) {
        // Exclure les sagas et acteurs
        if (playlist.id.startsWith('saga_') || 
            playlist.type == LibraryPlaylistType.actor) {
          continue;
        }
        
        // Playlists favorites : séries uniquement pour les séries
        if (playlist.type == LibraryPlaylistType.favoriteSeries) {
          availablePlaylists.add(playlist);
          continue;
        }
        
        // Playlists favorites films : exclure pour les séries
        if (playlist.type == LibraryPlaylistType.favoriteMovies) {
          continue;
        }
        
        // Playlists utilisateur : vérifier le contenu
        if (playlist.type == LibraryPlaylistType.userPlaylist &&
            playlist.playlistId != null) {
          try {
            final playlistDetail = await playlistRepository.getPlaylist(
              PlaylistId(playlist.playlistId!),
            );
            
            // Si la playlist est vide, on peut ajouter
            if (playlistDetail.items.isEmpty) {
              availablePlaylists.add(playlist);
              continue;
            }
            
            // Vérifier si la playlist contient uniquement des séries
            final hasOnlySeries = playlistDetail.items.every(
              (item) => item.reference.type == ContentType.series,
            );
            
            // Si la playlist contient uniquement des séries, on peut ajouter la série
            if (hasOnlySeries) {
              availablePlaylists.add(playlist);
            }
            // Si la playlist contient des films, on ne peut pas ajouter une série
          } catch (_) {
            // En cas d'erreur, on inclut la playlist pour ne pas bloquer l'utilisateur
            availablePlaylists.add(playlist);
          }
        }
      }
      
      if (availablePlaylists.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucune playlist disponible pour les séries')),
          );
        }
        return;
      }
      
      showCupertinoModalPopup<void>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: Text(AppLocalizations.of(context)!.actionAddToList),
          actions: availablePlaylists.map((playlist) {
            return CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(ctx).pop();
                
                try {
                  if (playlist.type == LibraryPlaylistType.favoriteSeries) {
                    // Toggle favori
                    await ref.read(tvToggleFavoriteProvider.notifier).toggle(seriesId);
                    ref.invalidate(tvIsFavoriteProvider(seriesId));
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ajouté à "${playlist.title}"'),
                        ),
                      );
                    }
                  } else if (playlist.type == LibraryPlaylistType.userPlaylist &&
                      playlist.playlistId != null) {
                    // Ajouter à la playlist utilisateur
                    final addPlaylistItem = AddPlaylistItem(
                      ref.read(slProvider)<PlaylistRepository>(),
                    );
                    
                    // Utiliser les données disponibles
                    final year = yearTextValue != '—' ? int.tryParse(yearTextValue) : null;
                    
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
                    
                    // Invalider tous les providers nécessaires
                    ref.invalidate(playlistItemsProvider(playlist.playlistId!));
                    ref.invalidate(playlistContentReferencesProvider(playlist.playlistId!));
                    ref.invalidate(libraryPlaylistsProvider);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ajouté à "${playlist.title}"'),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                      ),
                    );
                  }
                }
              },
              child: Text(playlist.title),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.actionCancel),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des playlists: $e'),
          ),
        );
      }
    }
  }

  void _showMoreMenu() {
    if (widget.media == null) return;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final seriesId = widget.media!.id;
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
      final locator = ref.read(slProvider);
      final historyRepo = locator<HistoryLocalRepository>();

      // Pour une série, on marque comme vu en ajoutant une entrée avec progression 100%
      // La durée par défaut est de 45 minutes par épisode
      final duration = const Duration(minutes: 45);
      await historyRepo.upsertPlay(
        contentId: seriesId,
        type: ContentType.series,
        title: mediaTitle,
        poster: widget.media?.poster,
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
      final historyRepo = locator<HistoryLocalRepository>();
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
    if (widget.media == null) return;
    try {
      final locator = ref.read(slProvider);
      final repo = locator<TvRepository>();
      final id = SeriesId(widget.media!.id);
      await repo.refreshMetadata(id);
      // Invalider le provider pour forcer le rechargement
      ref.invalidate(tvDetailProgressiveControllerProvider(widget.media!.id));
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
