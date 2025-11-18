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
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';

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
  bool _edgeSwipeActive = false;
  double _edgeSwipeStartX = 0.0;
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
          isLoading: false,
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
    return Scaffold(
      backgroundColor: cs.surface,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (details) {
          final dx = details.globalPosition.dx;
          if (dx <= 24) {
            _edgeSwipeActive = true;
            _edgeSwipeStartX = dx;
          } else {
            _edgeSwipeActive = false;
          }
        },
        onHorizontalDragUpdate: (details) {
          if (!_edgeSwipeActive) return;
          final moved = details.globalPosition.dx - _edgeSwipeStartX;
          if (moved > 80) {
            _edgeSwipeActive = false;
            if (mounted) context.pop();
          }
        },
        onHorizontalDragEnd: (_) {
          _edgeSwipeActive = false;
        },
        child: SafeArea(
          top: true,
          bottom: true,
          child: Opacity(
            opacity: isLoading ? 0.99 : 1.0,
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
                                    Expanded(
                                      child: MoviPrimaryButton(
                                        label: AppLocalizations.of(
                                          context,
                                        )!.homeWatchNow,
                                        assetIcon: AppAssets.iconPlay,
                                        buttonStyle: FilledButton.styleFrom(
                                          backgroundColor: AppColors.accent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              32,
                                            ),
                                          ),
                                        ),
                                        onPressed: () => _playSeries(
                                          context,
                                          widget.media?.id,
                                          mediaTitle,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: MoviFavoriteButton(
                                        isFavorite: false,
                                        onPressed: () {},
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
      final urlBuilder = XtreamStreamUrlBuilder(
        iptvLocal: iptvLocal,
        vault: vault,
      );

      // Chercher l'item Xtream correspondant
      XtreamPlaylistItem? xtreamItem;
      final accounts = await iptvLocal.getAccounts();
      final seriesId = widget.media!.id;

      for (final account in accounts) {
        final playlists = await iptvLocal.getPlaylists(account.id);
        for (final playlist in playlists) {
          if (playlist.type != XtreamPlaylistType.series) continue;

          // Si l'ID commence par "xtream:", chercher par streamId
          if (seriesId.startsWith('xtream:')) {
            final streamIdStr = seriesId.substring(7);
            final streamId = int.tryParse(streamIdStr);
            if (streamId != null) {
              try {
                xtreamItem = playlist.items.firstWhere(
                  (item) =>
                      item.streamId == streamId &&
                      item.type == XtreamPlaylistItemType.series,
                );
              } catch (_) {
                // Item non trouvé, continuer la recherche
              }
            }
          } else {
            // Sinon, chercher par tmdbId
            final tmdbId = int.tryParse(seriesId);
            if (tmdbId != null) {
              try {
                xtreamItem = playlist.items.firstWhere(
                  (item) =>
                      item.tmdbId == tmdbId &&
                      item.type == XtreamPlaylistItemType.series,
                );
              } catch (_) {
                // Item non trouvé, continuer la recherche
              }
            }
          }

          if (xtreamItem != null) break;
        }
        if (xtreamItem != null) break;
      }

      if (xtreamItem == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Épisode non disponible dans la playlist'),
          ),
        );
        return;
      }

      // Construire l'URL de streaming
      final streamUrl = await urlBuilder.buildStreamUrlFromSeriesItem(
        item: xtreamItem,
        seasonNumber: seasonNumber,
        episodeNumber: episode.episodeNumber,
      );
      if (streamUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de construire l\'URL de streaming'),
          ),
        );
        return;
      }

      // Construire le titre de l'épisode
      // Récupérer le titre depuis le ViewModel via le provider
      final vmAsync = ref.read(
        tvDetailProgressiveControllerProvider(widget.media!.id),
      );
      final seriesTitle = vmAsync.value?.title ?? mediaTitle;
      final episodeTitle = episode.title.isNotEmpty
          ? '$seriesTitle - S${seasonNumber.toString().padLeft(2, '0')}E${episode.episodeNumber.toString().padLeft(2, '0')} - ${episode.title}'
          : '$seriesTitle - S${seasonNumber.toString().padLeft(2, '0')}E${episode.episodeNumber.toString().padLeft(2, '0')}';

      // Ouvrir le player
      context.push(
        AppRouteNames.player,
        extra: VideoSource(url: streamUrl, title: episodeTitle),
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

  void _showMoreMenu() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        return CupertinoActionSheet(
          title: Text(mediaTitle),
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                _onRefreshMetadata();
              },
              child: Text(AppLocalizations.of(context)!.actionRefreshMetadata),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Text(AppLocalizations.of(context)!.actionAddToList),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Text(AppLocalizations.of(context)!.actionMarkSeen),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Text(AppLocalizations.of(context)!.actionMarkUnseen),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Text(AppLocalizations.of(context)!.actionReportProblem),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.actionCancel),
          ),
        );
      },
    );
  }

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
