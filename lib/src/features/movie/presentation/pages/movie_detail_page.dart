import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/theme/theme.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/core/models/models.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart' as hp;
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/core/widgets/movi_favorite_button.dart';

class MovieDetailPage extends ConsumerStatefulWidget {
  const MovieDetailPage({super.key, this.media});

  final MoviMedia? media;

  @override
  ConsumerState<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends ConsumerState<MovieDetailPage>
    with TickerProviderStateMixin {
  bool _overviewExpanded = false;
  String mediaTitle = '—';
  String yearText = '—';
  String durationText = '—';
  String ratingText = '—';
  String overviewText = '';
  List<MoviPerson> cast = const [];
  List<MoviMedia> recommendations = const [];

  @override
  void initState() {
    super.initState();
    _primeFromArgs();
  }

  void _primeFromArgs() {
    final m = widget.media;
    if (m != null) {
      mediaTitle = m.title;
      yearText = m.year?.toString() ?? '—';
      ratingText = m.rating?.toStringAsFixed(1) ?? '—';
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
    final vmAsync = ref.watch(movieDetailControllerProvider(widget.media!.id));
    return vmAsync.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const OverlaySplash(),
      ),
      error: (e, st) => _buildErrorScaffold(e),
      data: (vm) => _buildWithValues(
        mediaTitle: vm.title,
        yearText: vm.yearText,
        durationText: vm.durationText,
        ratingText: vm.ratingText,
        overviewText: vm.overviewText,
        cast: vm.cast,
        recommendations: vm.recommendations,
        isLoading: false,
        poster: vm.poster,
        backdrop: vm.backdrop,
        sagaLink: vm.sagaLink,
      ),
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
    required String durationText,
    required String ratingText,
    required String overviewText,
    required List<MoviPerson> cast,
    required List<MoviMedia> recommendations,
    required bool isLoading,
    Uri? poster,
    Uri? backdrop,
    SagaSummary? sagaLink,
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
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF141414),
                                        Color(0x00000000),
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
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
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
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0x00000000),
                                        Color(0xFF141414),
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
                                      color: const Color(0xFF292929),
                                    ),
                                    const SizedBox(width: 8),
                                    MoviPill(
                                      durationText,
                                      large: true,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      color: const Color(0xFF292929),
                                    ),
                                    const SizedBox(width: 8),
                                    MoviPill(
                                      ratingText,
                                      large: true,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      color: const Color(0xFF292929),
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
                                                backgroundColor: AppColors.accent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(
                                                    32,
                                                  ),
                                                ),
                                              ),
                                              onPressed: () => _playMovie(
                                                context,
                                                widget.media!.id,
                                                mediaTitle,
                                              ),
                                            ),
                                          );
                                        }
                                        final historyAsync = ref.watch(
                                          hp.mediaHistoryProvider((contentId: widget.media!.id, type: ContentType.movie)),
                                        );
                                        return Expanded(
                                          child: MoviPrimaryButton(
                                            label: historyAsync.when(
                                              data: (entry) => entry != null ? 'Reprendre la lecture' : AppLocalizations.of(context)!.homeWatchNow,
                                              loading: () => AppLocalizations.of(context)!.homeWatchNow,
                                              error: (_, __) => AppLocalizations.of(context)!.homeWatchNow,
                                            ),
                                            assetIcon: AppAssets.iconPlay,
                                            buttonStyle: FilledButton.styleFrom(
                                              backgroundColor: AppColors.accent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(
                                                  32,
                                                ),
                                              ),
                                            ),
                                            onPressed: () => _playMovie(
                                              context,
                                              widget.media!.id,
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
                                          final movieId = widget.media!.id;
                                          final isFavoriteAsync = ref.watch(
                                            movieIsFavoriteProvider(movieId),
                                          );
                                          return isFavoriteAsync.when(
                                            data: (isFavorite) => MoviFavoriteButton(
                                              isFavorite: isFavorite,
                                              onPressed: () async {
                                                await ref.read(
                                                  movieToggleFavoriteProvider.notifier,
                                                ).toggle(movieId);
                                              },
                                            ),
                                            loading: () => MoviFavoriteButton(
                                              isFavorite: false,
                                              onPressed: () {},
                                            ),
                                            error: (_, __) => MoviFavoriteButton(
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
                                                        decoration:
                                                            const BoxDecoration(
                                                              gradient: LinearGradient(
                                                                begin: Alignment
                                                                    .topCenter,
                                                                end: Alignment
                                                                    .bottomCenter,
                                                                colors: [
                                                                  Color(
                                                                    0x00000000,
                                                                  ),
                                                                  Color(
                                                                    0xFF141414,
                                                                  ),
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
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Icon(
                                                      _overviewExpanded
                                                          ? Icons
                                                                .keyboard_arrow_up
                                                          : Icons
                                                                .keyboard_arrow_down,
                                                      color: Colors.white70,
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 20,
                                end: 20,
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.castTitle,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 286,
                              child: ListView.separated(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 20,
                                  end: 12,
                                ),
                                scrollDirection: Axis.horizontal,
                                itemCount: cast.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 16),
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
                                      context.push(
                                        AppRouteNames.person,
                                        extra: personSummary,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Section saga (si le film fait partie d'une saga)
                            if (sagaLink != null)
                              Consumer(
                                builder: (context, ref, _) {
                                  final sagaMoviesAsync = ref.watch(sagaMoviesProvider(sagaLink));
                                  return sagaMoviesAsync.when(
                                    data: (sagaMovies) {
                                      if (sagaMovies.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          MoviItemsList(
                                            title: 'Saga ${sagaLink.title.display}',
                                            estimatedItemWidth: 150,
                                            estimatedItemHeight: 258,
                                            titlePadding: 20,
                                            horizontalPadding:
                                                const EdgeInsetsDirectional.only(
                                                  start: 20,
                                                  end: 0,
                                                ),
                                            action: Padding(
                                              padding: const EdgeInsetsDirectional.only(end: 20),
                                              child: Consumer(
                                                builder: (context, ref, _) {
                                                  final sagaId = sagaLink.id.value;
                                                  final isFavoriteAsync = ref.watch(
                                                    sagaIsFavoriteProvider(sagaId),
                                                  );
                                                  return isFavoriteAsync.when(
                                                    data: (isFavorite) => MoviFavoriteButton(
                                                      isFavorite: isFavorite,
                                                      onPressed: () async {
                                                        await ref.read(
                                                          sagaToggleFavoriteProvider.notifier,
                                                        ).toggle(sagaId, sagaLink);
                                                      },
                                                    ),
                                                    loading: () => MoviFavoriteButton(
                                                      isFavorite: false,
                                                      onPressed: () {},
                                                    ),
                                                    error: (_, __) => MoviFavoriteButton(
                                                      isFavorite: false,
                                                      onPressed: () {},
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            items: sagaMovies
                                                .map(
                                                  (m) => MoviMediaCard(
                                                    media: m,
                                                    heroTag: 'saga_${m.id}',
                                                    highlightBorder: m.id == widget.media?.id,
                                                    onTap: (mm) => context.push(
                                                      AppRouteNames.movie,
                                                      extra: mm,
                                                    ),
                                                  ),
                                                )
                                                .toList(growable: false),
                                          ),
                                          const SizedBox(height: 24),
                                        ],
                                      );
                                    },
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, __) => const SizedBox.shrink(),
                                  );
                                },
                              ),
                            // Section recommandations
                            if (recommendations.isNotEmpty)
                              MoviItemsList(
                                title: AppLocalizations.of(
                                  context,
                                )!.recommendationsTitle,
                                estimatedItemWidth: 150,
                                estimatedItemHeight: 258,
                                titlePadding: 20,
                                horizontalPadding:
                                    const EdgeInsetsDirectional.only(
                                      start: 20,
                                      end: 0,
                                    ),
                                items: recommendations
                                    .map(
                                      (m) => MoviMediaCard(
                                        media: m,
                                        heroTag: 'reco_${m.id}',
                                        onTap: (mm) => context.push(
                                          AppRouteNames.movie,
                                          extra: mm,
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            const SizedBox(height: 70),
                          ],
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
                _onChangeMetadata();
              },
              child: Text(AppLocalizations.of(context)!.actionChangeMetadata),
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
      final repo = locator<MovieRepository>();
      final id = MovieId(widget.media!.id);
      await repo.refreshMetadata(id);
      // Invalider le provider pour forcer le rechargement
      ref.invalidate(movieDetailControllerProvider(widget.media!.id));
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

  void _onChangeMetadata() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.featureComingSoon)),
    );
  }

  Future<void> _playMovie(
    BuildContext context,
    String movieId,
    String title,
  ) async {
    try {
      final locator = ref.read(slProvider);
      final iptvLocal = locator<IptvLocalRepository>();
      final vault = locator<CredentialsVault>();
      final logger = locator<AppLogger>();
      final urlBuilder = XtreamStreamUrlBuilder(
        iptvLocal: iptvLocal,
        vault: vault,
      );

      // Chercher l'item Xtream correspondant
      XtreamPlaylistItem? xtreamItem;
      final accounts = await iptvLocal.getAccounts();

      logger.debug(
        'Recherche du film movieId=$movieId dans ${accounts.length} comptes',
      );

      for (final account in accounts) {
        final playlists = await iptvLocal.getPlaylists(account.id);
        logger.debug('Compte ${account.id}: ${playlists.length} playlists');

        // Recherche globale dans toutes les playlists (movies et series)
        // car certains films peuvent être mal catégorisés
        for (final playlist in playlists) {
          logger.debug(
            'Playlist ${playlist.title} (${playlist.type.name}): ${playlist.items.length} items',
          );

          // Si l'ID commence par "xtream:", chercher par streamId
          if (movieId.startsWith('xtream:')) {
            final streamIdStr = movieId.substring(7);
            final streamId = int.tryParse(streamIdStr);
            logger.debug('Recherche par streamId=$streamId (xtream)');
            if (streamId != null) {
              try {
                // Chercher dans tous les items, peu importe le type
                xtreamItem = playlist.items.firstWhere(
                  (item) => item.streamId == streamId,
                );
                logger.debug(
                  'Film trouvé: ${xtreamItem.title} (streamId=${xtreamItem.streamId}, tmdbId=${xtreamItem.tmdbId}, type=${xtreamItem.type.name})',
                );
              } catch (_) {
                // Item non trouvé, continuer la recherche
                logger.debug(
                  'Film avec streamId=$streamId non trouvé dans ${playlist.title}',
                );
              }
            }
          } else {
            // Sinon, chercher par tmdbId
            final tmdbId = int.tryParse(movieId);
            logger.debug('Recherche par tmdbId=$tmdbId');
            if (tmdbId != null) {
              try {
                // Chercher dans tous les items, peu importe le type
                xtreamItem = playlist.items.firstWhere(
                  (item) => item.tmdbId == tmdbId,
                );
                logger.debug(
                  'Film trouvé: ${xtreamItem.title} (streamId=${xtreamItem.streamId}, tmdbId=${xtreamItem.tmdbId}, type=${xtreamItem.type.name})',
                );
              } catch (_) {
                // Item non trouvé, continuer la recherche
                logger.debug(
                  'Film avec tmdbId=$tmdbId non trouvé dans ${playlist.title}',
                );
              }
            }
          }

          if (xtreamItem != null) break;
        }
        if (xtreamItem != null) break;
      }

      if (xtreamItem == null) {
        logger.info('Film movieId=$movieId non trouvé dans les playlists');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Film non disponible dans la playlist')),
        );
        return;
      }

      // Construire l'URL de streaming
      // Vérifier que c'est bien un film, sinon adapter
      String? streamUrl;
      if (xtreamItem.type == XtreamPlaylistItemType.movie) {
        streamUrl = await urlBuilder.buildStreamUrlFromMovieItem(xtreamItem);
      } else {
        // Si c'est une série trouvée par erreur, on ne peut pas la lire comme un film
        logger.warn(
          'Item trouvé est de type ${xtreamItem.type.name}, pas un film',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le média trouvé n\'est pas un film')),
        );
        return;
      }

      if (streamUrl == null) {
        logger.error(
          'Impossible de construire l\'URL pour streamId=${xtreamItem.streamId}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de construire l\'URL de streaming'),
          ),
        );
        return;
      }

      logger.debug('URL de streaming construite: $streamUrl');

      // Récupérer le poster depuis widget.media ou le view model
      Uri? posterUri = widget.media?.poster;
      if (posterUri == null && widget.media != null) {
        final vmAsync = ref.read(movieDetailControllerProvider(widget.media!.id));
        vmAsync.whenData((vm) {
          posterUri = vm.poster;
        });
      }

      // Ouvrir le player
      context.push(
        AppRouteNames.player,
        extra: VideoSource(
          url: streamUrl,
          title: title,
          contentId: movieId,
          contentType: ContentType.movie,
          poster: posterUri,
        ),
      );
    } catch (e, st) {
      final logger = ref.read(slProvider)<AppLogger>();
      logger.error('Erreur lors de la lecture du film: $e', e, st);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }
}
