// lib/src/features/home/presentation/widgets/home_hero_section.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/utils/app_assets.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../core/widgets/movi_favorite_button.dart';
import '../../../../core/widgets/movi_pill.dart';
import '../../../../core/widgets/movi_primary_button.dart';
import '../../../movie/domain/entities/movie_summary.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/data/services/tmdb_cache_data_source.dart';
import '../../../../shared/data/services/tmdb_image_resolver.dart';

class HomeHeroSection extends StatefulWidget {
  const HomeHeroSection({super.key, required this.movie});
  final MovieSummary? movie;

  @override
  State<HomeHeroSection> createState() => _HomeHeroSectionState();
}

class _HomeHeroSectionState extends State<HomeHeroSection> {
  bool _favorite = false;

  late final TmdbCacheDataSource _cache = sl<TmdbCacheDataSource>();
  late final TmdbImageResolver _images = sl<TmdbImageResolver>();

  // Convertit n'importe quoi (String, Uri, etc.) en String? propre pour un URL d'image.
  String? _coerceUrl(dynamic v) {
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    if (v is Uri) return v.toString();
    final s = v.toString();
    return s.isEmpty || s == 'null' ? null : s;
  }

  Future<_HeroMeta?> _loadMeta(MovieSummary m) async {
    if (m.tmdbId == null) return null;

    final data = await _cache.getMovieDetail(m.tmdbId!);
    if (data == null) return null;

    final imagesMap = (data['images'] as Map<String, dynamic>?) ?? const {};
    final posters = (imagesMap['posters'] as List<dynamic>? ?? const []);
    final logos = (imagesMap['logos'] as List<dynamic>? ?? const []);

    final posterNoLangPath =
        _selectPosterNoLang(posters) ?? data['poster_path']?.toString();
    final logoPath = _selectLogoFrEnNoLang(logos);

    // Qualité MAX (original) sur le hero → en String
    final poster = _images.poster(posterNoLangPath, size: 'original').toString();
    final backdrop = _images.backdrop(data['backdrop_path']?.toString(), size: 'original').toString();
    final logo = _images.logo(logoPath).toString();

    final overview = (data['overview']?.toString() ?? '').trim();
    final vote = (data['vote_average'] as num?)?.toDouble();
    final year = _parseYear(data['release_date']?.toString());

    return _HeroMeta(
      poster: poster,
      backdrop: backdrop,
      logo: logo,
      overview: overview.isEmpty ? null : overview,
      year: year,
      rating: vote,
    );
  }

  String? _selectPosterNoLang(List<dynamic> posters) {
    if (posters.isEmpty) return null;
    String? pathOf(Map<String, dynamic> m) => m['file_path']?.toString();
    num scoreOf(Map<String, dynamic> m) => (m['vote_average'] as num?) ?? 0;

    final list = posters.cast<Map<String, dynamic>>();

    final noLang = list.where((m) => m['iso_639_1'] == null).toList()
      ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (noLang.isNotEmpty) return pathOf(noLang.first);

    final en = list.where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'en')).toList()
      ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (en.isNotEmpty) return pathOf(en.first);

    list.sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    return pathOf(list.first);
  }

  String? _selectLogoFrEnNoLang(List<dynamic> logos) {
    if (logos.isEmpty) return null;
    String? pathOf(Map<String, dynamic> m) => m['file_path']?.toString();
    num scoreOf(Map<String, dynamic> m) => (m['vote_average'] as num?) ?? 0;

    final list = logos.cast<Map<String, dynamic>>();

    final fr = list.where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'fr')).toList()
      ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (fr.isNotEmpty) return pathOf(fr.first);

    final en = list.where((m) => (m['iso_639_1']?.toString().toLowerCase() == 'en')).toList()
      ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (en.isNotEmpty) return pathOf(en.first);

    final noLang = list.where((m) => m['iso_639_1'] == null).toList()
      ..sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    if (noLang.isNotEmpty) return pathOf(noLang.first);

    list.sort((a, b) => scoreOf(b).compareTo(scoreOf(a)));
    return pathOf(list.first);
  }

  int? _parseYear(String? raw) =>
      (raw != null && raw.isNotEmpty) ? int.tryParse(raw.substring(0, 4)) : null;

  @override
  Widget build(BuildContext context) {
    const double totalHeight = 690;
    const double overlayHeight = 125;

    final movie = widget.movie;

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: movie == null
          ? _HeroSkeleton(overlayHeight: overlayHeight)
          : FutureBuilder<_HeroMeta?>(
              future: _loadMeta(movie),
              builder: (context, snap) {
                final meta = snap.data;

                // Tous les candidats convertis en String? avant coalescing
                final String? bgSrc = _coerceUrl(meta?.backdrop)
                    ?? _coerceUrl(movie.backdrop)
                    ?? _coerceUrl(meta?.poster)
                    ?? _coerceUrl(movie.poster);

                final hasLogo = (meta?.logo ?? '').isNotEmpty;
                final showYear = (meta?.year ?? movie.releaseYear) != null;
                final yearText = (meta?.year ?? movie.releaseYear)?.toString() ?? '—';
                final ratingText = (meta?.rating != null)
                    ? meta!.rating!.toStringAsFixed(meta.rating! >= 10 ? 0 : 1)
                    : null;
                final hasSynopsis = (meta?.overview?.isNotEmpty ?? false);

                Widget buildBackground() {
                  return (bgSrc != null && bgSrc.isNotEmpty)
                      ? Image.network(
                          bgSrc,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) =>
                              Container(color: const Color(0xFF222222)),
                        )
                      : Container(color: const Color(0xFF222222));
                }

                return Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          buildBackground(),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              height: overlayHeight,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Color(0xFF141414), Color(0x00141414)],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: overlayHeight - 100,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 100),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: hasLogo
                                        ? Image.network(
                                            meta!.logo!,
                                            height: 100,
                                            errorBuilder: (_, __, ___) =>
                                                _TitleFallback(movie.title.value),
                                          )
                                        : _TitleFallback(movie.title.value),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (showYear) MoviPill(yearText, large: true),
                        if (showYear && ratingText != null) const SizedBox(width: 8),
                        if (ratingText != null) MoviPill(ratingText, large: true),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (hasSynopsis)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Text(
                          meta!.overview!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (hasSynopsis) const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: MoviPrimaryButton(
                              label: 'Regarder maintenant',
                              assetIcon: AppAssets.iconPlay,
                              onPressed: () => context.push(AppRouteNames.movie),
                            ),
                          ),
                          const SizedBox(width: 16),
                          MoviFavoriteButton(
                            isFavorite: _favorite,
                            onPressed: () => setState(() => _favorite = !_favorite),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
    );
  }
}

class _TitleFallback extends StatelessWidget {
  const _TitleFallback(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _HeroMeta {
  const _HeroMeta({
    this.poster,
    this.backdrop,
    this.logo,
    this.overview,
    this.year,
    this.rating,
  });

  final String? poster;
  final String? backdrop;
  final String? logo;
  final String? overview;
  final int? year;
  final double? rating;
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton({required this.overlayHeight});
  final double overlayHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: const Color(0xFF222222)),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: overlayHeight,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xFF141414), Color(0x00141414)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: overlayHeight - 100,
                child: Center(
                  child: Image.asset(AppAssets.iconAppLogo, height: 100),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: const [
              Expanded(
                child: SizedBox(height: 48),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
