import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/features/home/presentation/widgets/home_hero_filter_bar.dart';

class HomeHeroOverlayDebugPage extends StatelessWidget {
  const HomeHeroOverlayDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: const Text('Hero Overlay Matrix')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verification Targets',
                          style: textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check that the bottom fade visually eats the image, with no hard seam above the surface block. This matrix isolates light poster, dark poster, wide left text, and skeleton states.',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 24.0;
                      final isTwoColumns = constraints.maxWidth >= 1120;
                      final tileWidth = isTwoColumns
                          ? (constraints.maxWidth - spacing) / 2
                          : constraints.maxWidth;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(
                            width: tileWidth,
                            child: const _PreviewTile(
                              title: 'Mobile / Light Poster',
                              caption:
                                  'Bright artwork with strong highlights. The lower fade should still melt into the surface.',
                              child: _MobileHeroPreview(
                                tone: _PosterTone.light,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: tileWidth,
                            child: const _PreviewTile(
                              title: 'Mobile / Dark Poster',
                              caption:
                                  'Dark artwork with low contrast. The fade should feel dense enough without floating.',
                              child: _MobileHeroPreview(tone: _PosterTone.dark),
                            ),
                          ),
                          SizedBox(
                            width: tileWidth,
                            child: const _PreviewTile(
                              title: 'Wide / Left Text',
                              caption:
                                  'Desktop-style hero with left-aligned text. Validate side fade readability and bottom merge.',
                              child: _WideHeroPreview(),
                            ),
                          ),
                          SizedBox(
                            width: tileWidth,
                            child: const _PreviewTile(
                              title: 'Placeholder / Skeleton',
                              caption:
                                  'Bottom-only overlay on a neutral background. The fade must stay attached to the image area.',
                              child: _SkeletonHeroPreview(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({
    required this.title,
    required this.caption,
    required this.child,
  });

  final String title;
  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(caption, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _MobileHeroPreview extends StatelessWidget {
  const _MobileHeroPreview({required this.tone});

  final _PosterTone tone;

  static const double _heroHeight = 292;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: _PreviewShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _heroHeight,
                child: MoviHeroScene(
                  background: _PosterBackdrop(tone: tone),
                  imageHeight: _heroHeight,
                  overlaySpec: MoviHeroOverlaySpec.home(isWideLayout: false),
                  children: const [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 12,
                      child: HomeHeroFilterBar(),
                    ),
                  ],
                ),
              ),
              const _MobileMetaStub(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WideHeroPreview extends StatelessWidget {
  const _WideHeroPreview();

  static const double _heroHeight = 520;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _PreviewShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _heroHeight,
            child: MoviHeroScene(
              background: const _PosterBackdrop(tone: _PosterTone.light),
              imageHeight: _heroHeight,
              overlaySpec: MoviHeroOverlaySpec.home(isWideLayout: true),
              children: [
                const Positioned(
                  left: 0,
                  right: 0,
                  top: 12,
                  child: HomeHeroFilterBar(),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 50,
                      end: 50,
                      top: 48,
                      bottom: 32,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'The Fade Must Eat The Frame',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  theme.textTheme.displaySmall?.copyWith(
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
                            const SizedBox(height: 16),
                            const Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                MoviPill('2025', large: true),
                                MoviPill('2h 18m', large: true),
                                MoviPill('8.7', large: true),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 72,
                              child: Text(
                                'Use this wide case to validate that the side fade supports the text and that the bottom merge does not look like a separate layer laid under the artwork.',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    theme.textTheme.bodyLarge?.copyWith(
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
                            const SizedBox(height: 16),
                            const SizedBox(
                              width: 320,
                              child: MoviPrimaryButton(
                                label: 'Watch now',
                                assetIcon: AppAssets.iconPlay,
                              ),
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
          _SurfaceStub(
            child: Row(
              children: [
                Expanded(
                  child: _RailStubLine(
                    widthFactor: 0.64,
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RailStubLine(
                    widthFactor: 0.42,
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonHeroPreview extends StatelessWidget {
  const _SkeletonHeroPreview();

  static const double _heroHeight = 292;

  @override
  Widget build(BuildContext context) {
    final overlaySpec = MoviHeroOverlaySpec.homeBottomOnly(isWideLayout: false);
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: _PreviewShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _heroHeight,
                child: MoviHeroScene(
                  background: const ColoredBox(color: Color(0xFF222222)),
                  imageHeight: _heroHeight,
                  overlaySpec: overlaySpec,
                  children: [
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 12,
                      child: HomeHeroFilterBar(),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: overlaySpec.bottomHeightFor(_heroHeight) - 88,
                      child: Center(
                        child: SizedBox(
                          width: 200,
                          height: 96,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SvgPicture.asset(
                              AppAssets.iconAppLogoSvg,
                              colorFilter: ColorFilter.mode(
                                theme.colorScheme.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _SurfaceStub(
                child: Column(
                  children: [
                    _RailStubLine(
                      widthFactor: 0.82,
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 12),
                    _RailStubLine(
                      widthFactor: 1,
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 12),
                    _RailStubLine(
                      widthFactor: 0.68,
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileMetaStub extends StatelessWidget {
  const _MobileMetaStub();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SurfaceStub(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Bottom Fade Alignment Check',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              MoviPill(
                '2025',
                large: true,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              MoviPill(
                '2h 18m',
                large: true,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              MoviPill(
                '8.7',
                large: true,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const MoviPrimaryButton(
            label: 'Watch now',
            assetIcon: AppAssets.iconPlay,
          ),
          const SizedBox(height: 12),
          Text(
            'The image should disappear into this surface block without any visible seam.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SurfaceStub extends StatelessWidget {
  const _SurfaceStub({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );
  }
}

class _PreviewShell extends StatelessWidget {
  const _PreviewShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.colorScheme.surfaceContainerHighest),
        ),
        child: child,
      ),
    );
  }
}

class _RailStubLine extends StatelessWidget {
  const _RailStubLine({required this.widthFactor, required this.color});

  final double widthFactor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 18,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _PosterBackdrop extends StatelessWidget {
  const _PosterBackdrop({required this.tone});

  final _PosterTone tone;

  @override
  Widget build(BuildContext context) {
    final isLight = tone == _PosterTone.light;
    final baseStart = isLight
        ? const Color(0xFFE7D0AE)
        : const Color(0xFF0D1824);
    final baseEnd = isLight ? const Color(0xFF785D47) : const Color(0xFF091015);
    final glowA = isLight ? const Color(0xFFFFD8A8) : const Color(0xFF2C6E73);
    final glowB = isLight ? const Color(0xFF8CC8E5) : const Color(0xFF1E3450);
    final glowC = isLight ? const Color(0xFF2F2014) : const Color(0xFF070D13);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [baseStart, baseEnd],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _GlowBlob(
            alignment: const Alignment(-0.78, -0.72),
            width: 240,
            height: 240,
            color: glowA,
          ),
          _GlowBlob(
            alignment: const Alignment(0.92, -0.18),
            width: 220,
            height: 220,
            color: glowB,
          ),
          _GlowBlob(
            alignment: const Alignment(-0.1, 0.24),
            width: 280,
            height: 360,
            color: glowC,
            rotation: isLight ? -0.22 : 0.18,
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: isLight ? 0.12 : 0.02),
                    Colors.transparent,
                    Colors.black.withValues(alpha: isLight ? 0.18 : 0.34),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.alignment,
    required this.width,
    required this.height,
    required this.color,
    this.rotation = 0,
  });

  final Alignment alignment;
  final double width;
  final double height;
  final Color color;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(math.max(width, height)),
            color: color.withValues(alpha: 0.28),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.46),
                blurRadius: 120,
                spreadRadius: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PosterTone { light, dark }
