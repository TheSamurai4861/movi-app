import 'package:flutter/material.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/features/home/presentation/widgets/home_layout_constants.dart';

/// Durées et comportements de transition du hero d'accueil.
@immutable
class HeroTransitionPolicy {
  const HeroTransitionPolicy({
    required this.backgroundFade,
    required this.overlayFade,
    required this.mobileSizeAnimation,
    required this.enableStackedOverlayFades,
  });

  final Duration backgroundFade;
  final Duration overlayFade;
  final Duration mobileSizeAnimation;
  final bool enableStackedOverlayFades;

  static const HeroTransitionPolicy standard = HeroTransitionPolicy(
    backgroundFade: HomeLayoutConstants.heroFadeDuration,
    overlayFade: HomeLayoutConstants.heroFadeDuration,
    mobileSizeAnimation: Duration(milliseconds: 300),
    enableStackedOverlayFades: true,
  );

  static const HeroTransitionPolicy television = HeroTransitionPolicy(
    backgroundFade: Duration(milliseconds: 400),
    overlayFade: Duration.zero,
    mobileSizeAnimation: Duration.zero,
    enableStackedOverlayFades: false,
  );

  static const HeroTransitionPolicy reducedMotion = HeroTransitionPolicy(
    backgroundFade: Duration.zero,
    overlayFade: Duration.zero,
    mobileSizeAnimation: Duration.zero,
    enableStackedOverlayFades: false,
  );

  static HeroTransitionPolicy resolve(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    if (mq != null && mq.disableAnimations) {
      return reducedMotion;
    }

    final size = mq?.size ?? MediaQuery.sizeOf(context);
    final screenType = context.resolveScreenType(size.width, size.height);
    if (screenType == ScreenType.tv) {
      return television;
    }
    return standard;
  }

  Widget wrapOverlayTransition({
    required Widget child,
    required Widget? previousChild,
    required Animation<double> animation,
  }) {
    if (!enableStackedOverlayFades || overlayFade == Duration.zero) {
      return child;
    }
    return FadeTransition(opacity: animation, child: child);
  }

  Widget buildOverlaySwitcher({
    required Key key,
    required Widget child,
    required Duration duration,
    Alignment alignment = Alignment.centerLeft,
  }) {
    if (!enableStackedOverlayFades || duration == Duration.zero) {
      return KeyedSubtree(key: key, child: child);
    }

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (switchChild, animation) =>
          FadeTransition(opacity: animation, child: switchChild),
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        children: [...previous, if (current != null) current],
      ),
      child: KeyedSubtree(key: key, child: child),
    );
  }
}
