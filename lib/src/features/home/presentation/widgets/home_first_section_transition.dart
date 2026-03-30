import 'package:flutter/material.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/features/home/presentation/widgets/home_layout_constants.dart';

class HomeFirstSectionTransition extends StatelessWidget {
  const HomeFirstSectionTransition({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final screenType = ScreenTypeResolver.instance.resolve(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );
    final isLargeScreen =
        screenType == ScreenType.desktop || screenType == ScreenType.tv;

    if (!enabled || !isLargeScreen) {
      return child;
    }

    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: IgnorePointer(
            ignoring: true,
            child: SizedBox(
              height: HomeLayoutConstants.heroDesktopFirstSectionShieldHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [cs.surface, cs.surface.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: HomeLayoutConstants.heroDesktopFirstSectionInset,
          ),
          child: child,
        ),
      ],
    );
  }
}
