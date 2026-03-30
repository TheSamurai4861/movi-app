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
    const overlaySpec = MoviHeroOverlaySpec(
      topHeightRatio: 0.2,
      bottomHeightRatio: 0.4,
      globalTintOpacity: 0,
      topStops: [0.0, 1.0],
      topOpacities: [1.0, 0.0],
      bottomStops: [0.0, 0.22, 0.46, 0.68, 0.84, 1.0],
      bottomOpacities: [0.0, 0.04, 0.12, 0.28, 0.58, 1.0],
      showGlobalTint: false,
    );

    return SizedBox(
      height: height,
      width: double.infinity,
      child: MoviHeroScene(
        background: _buildHeroImage(context, photo),
        imageHeight: height,
        overlaySpec: overlaySpec,
        children: [
          Positioned(
            top: 8,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 47,
                  height: 47,
                  child: MoviFocusableAction(
                    onPressed: () => context.pop(),
                    semanticLabel: 'Retour',
                    builder: (context, state) {
                      return MoviFocusFrame(
                        scale: state.focused ? 1.04 : 1,
                        padding: const EdgeInsets.all(6),
                        borderRadius: BorderRadius.circular(999),
                        backgroundColor: state.focused
                            ? Colors.white.withValues(alpha: 0.14)
                            : Colors.transparent,
                        child: SizedBox(
                          width: 35,
                          height: 35,
                          child: const MoviAssetIcon(
                            AppAssets.iconBack,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.personMoviesCount(moviesCount, showsCount),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
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
