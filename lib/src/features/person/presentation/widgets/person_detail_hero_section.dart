import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/widgets.dart';

/// Displays the hero section for a person with background image, gradient,
/// top bar (back button), name and movie/series counts.
class PersonDetailHeroSection extends StatelessWidget {
  const PersonDetailHeroSection({
    super.key,
    required this.photo,
    required this.name,
    required this.moviesCount,
    required this.showsCount,
    this.height = 500.0,
  });

  final Uri? photo;
  final String name;
  final int moviesCount;
  final int showsCount;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildHeroImage(context, photo),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.pop(),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 35,
                        height: 35,
                        child: Image.asset(AppAssets.iconBack),
                      ),
                    ],
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xFF141414),
                    Color(0x00000000),
                  ],
                ),
              ),
              padding: const EdgeInsets.only(
                bottom: 24,
                left: 20,
                right: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!
                        .personMoviesCount(moviesCount, showsCount),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context, Uri? photo) {
    if (photo == null) {
      return const MoviPlaceholderCard(
        type: PlaceholderType.person,
        fit: BoxFit.cover,
        alignment: Alignment(0.0, 0.1),
        borderRadius: BorderRadius.zero,
      );
    }
    final mq = MediaQuery.of(context);
    final int rawPx = (mq.size.width * mq.devicePixelRatio).round();
    final int cacheWidth = rawPx.clamp(480, 1920);
    return Image.network(
      photo.toString(),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      alignment: const Alignment(0.0, 0.1),
      errorBuilder: (_, __, ___) => const MoviPlaceholderCard(
        type: PlaceholderType.person,
        fit: BoxFit.cover,
        alignment: Alignment(0.0, 0.1),
        borderRadius: BorderRadius.zero,
      ),
    );
  }
}