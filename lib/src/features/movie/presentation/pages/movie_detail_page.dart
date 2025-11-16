import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/theme/theme.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/core/models/models.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart';
import 'package:movi/l10n/app_localizations.dart';

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
      loading: () => _buildWithValues(
        mediaTitle: mediaTitle,
        yearText: yearText,
        durationText: '—',
        ratingText: ratingText,
        overviewText: '',
        cast: const [],
        recommendations: const [],
        isLoading: true,
        poster: widget.media?.poster,
        backdrop: null,
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
  }) {
    final cs = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.headlineSmall;
    const heroHeight = 590.0;
    const overlayHeight = 283.0;
    return Scaffold(
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
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 20,
                          end: 20,
                          top: 4,
                          bottom: 4,
                        ),
                        child: SizedBox(
                          height: 35,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 35,
                                    height: 35,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => context.pop(),
                                      child: Image.asset(AppAssets.iconBack),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.actionBack,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: 25,
                                height: 35,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {},
                                  child: Image.asset(AppAssets.iconMore),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: heroHeight + 98,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            SizedBox(
                              height: heroHeight,
                              width: double.infinity,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _buildHeroImage(poster, backdrop),
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
                                ],
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Padding(
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                      width: 353,
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
                                                          decoration: const BoxDecoration(
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
                                                  child: Text(
                                                    AppLocalizations.of(
                                                      context,
                                                    )!.actionExpand,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                SizedBox(
                                                  width: 25,
                                                  height: 25,
                                                  child: AnimatedRotation(
                                                    turns: 0.5,
                                                    duration: const Duration(
                                                      milliseconds: 500,
                                                    ),
                                                    curve: Curves.easeInOut,
                                                    child: Image.asset(
                                                      AppAssets.iconExtend,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        start: 20,
                                        end: 20,
                                      ),
                                      child: SizedBox(
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
                                                  backgroundColor:
                                                      AppColors.accent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          32,
                                                        ),
                                                  ),
                                                ),
                                                onPressed: () {},
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            SizedBox(
                                              width: 55,
                                              height: 55,
                                              child: MoviFavoriteButton(
                                                isFavorite: false,
                                                onPressed: () {},
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
                                return MoviPersonCard(person: p);
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          MoviItemsList(
                            title: AppLocalizations.of(
                              context,
                            )!.recommendationsTitle,
                            estimatedItemWidth: 150,
                            estimatedItemHeight: 258,
                            titlePadding: 20,
                            horizontalPadding: const EdgeInsetsDirectional.only(
                              start: 20,
                              end: 0,
                            ),
                            items: recommendations
                                .map((m) => MoviMediaCard(media: m))
                                .toList(growable: false),
                          ),
                          const SizedBox(height: 100),
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
    );
  }

  Widget _buildHeroImage(Uri? poster, Uri? backdrop) {
    final Uri? uri = poster ?? backdrop;
    if (uri == null) {
      return Container(color: AppColors.darkSurface);
    }
    return Image.network(
      uri.toString(),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
    );
  }
}
