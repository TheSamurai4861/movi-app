// lib/src/features/shell/presentation/layouts/app_shell_mobile_layout.dart

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:movi/src/features/shell/presentation/navigation/shell_retention_policy.dart';
import 'package:movi/src/features/shell/presentation/widgets/regions/shell_content_host.dart';
import 'package:movi/src/features/shell/presentation/widgets/navigation/sidebar_nav.dart';

const _kNavHeight = 72.0;
const _kContainerPadding = 5.0;
const _kAndroidBottomSpacing = 32.0;

const _kSelectedBackground = Color(0xFF262626); // 100% opacity
const _kBarBackground = Color.fromARGB(199, 102, 102, 102); // ~30% opacity pour laisser le blur visible

const _kAnimationDuration = Duration(milliseconds: 300);

/// Layout Mobile :
/// - Contenu en plein écran
/// - Bottom nav flottante avec blur (conservée)
///
/// Choix validés :
/// 1) On garde le style (blur + floating)
/// 2) Même retention policy que desktop (Home+Search keepAlive, Library+Settings reset)
/// 3) Label visible uniquement sur l’onglet sélectionné
/// 4) Accent depuis Theme.colorScheme.primary (cohérent AppTheme)
/// 5) Items depuis buildSidebarDestinations(context) (source unique)
/// 6) Blur conservé
/// 7) Back/Escape : on ne touche pas (géré ailleurs / système)
class AppShellMobileLayout extends StatelessWidget {
  const AppShellMobileLayout({
    super.key,
    required this.selectedIndex,
    required this.onNavTap,
    required this.destinations,
    required this.pageBuilders,
  });

  final int selectedIndex;
  final ValueChanged<int> onNavTap;

  /// Destinations déjà localisées (assetPath + tooltip).
  final List<SidebarDestination> destinations;

  /// Pages du shell sous forme de builders (même ordre que destinations).
  final List<WidgetBuilder> pageBuilders;

  @override
  Widget build(BuildContext context) {
    // Même policy que desktop
    final keepAliveIndices = ShellRetentionPolicy.keepAliveIndices();

    final bottomOffset = moviNavBarBottomOffset(context);

    return Stack(
      children: [
        Positioned.fill(
          child: SafeArea(
            child: ShellContentHost(
              selectedIndex: selectedIndex,
              pageBuilders: pageBuilders,
              keepAliveIndices: keepAliveIndices,
              showEphemeralSwitchLoading: true,
              loadingLabel: null,
            ),
          ),
        ),

        // Bottom nav flottante
        Positioned(
          left: 16,
          right: 16,
          bottom: bottomOffset,
          child: MoviBottomNavBar(
            selectedIndex: selectedIndex,
            onItemSelected: onNavTap,
            destinations: destinations,
          ),
        ),
      ],
    );
  }
}

/// Floating bottom navigation bar with blurred background and rounded items.
/// - Label seulement quand sélectionné.
/// - Aucun texte brut : label = destinations[i].tooltip (déjà localisé).
class MoviBottomNavBar extends StatelessWidget {
  const MoviBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.destinations,
  }) : assert(selectedIndex >= 0);

  static const double height = _kNavHeight;

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<SidebarDestination> destinations;

  @override
  Widget build(BuildContext context) {
    assert(
      selectedIndex < destinations.length,
      'selectedIndex ($selectedIndex) must be within the destinations list.',
    );

    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final unselectedTextColor = Colors.white.withValues(alpha: 0.7);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: _kNavHeight,
          width: double.infinity,
          padding: const EdgeInsets.all(_kContainerPadding),
          decoration: BoxDecoration(
            color: _kBarBackground,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _MoviBottomNavItemWidget(
                    label: destinations[i].tooltip,
                    svgAssetPath: destinations[i].assetPath,
                    index: i,
                    isSelected: selectedIndex == i,
                    onTap: onItemSelected,
                    accentColor: accentColor,
                    selectedTextColor: accentColor,
                    unselectedTextColor: unselectedTextColor,
                    textStyle: theme.textTheme.labelSmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoviBottomNavItemWidget extends StatefulWidget {
  const _MoviBottomNavItemWidget({
    required this.label,
    required this.svgAssetPath,
    required this.index,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.textStyle,
  });

  final String label;
  final String svgAssetPath;

  final int index;
  final bool isSelected;

  final ValueChanged<int> onTap;

  final Color accentColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;

  final TextStyle? textStyle;

  @override
  State<_MoviBottomNavItemWidget> createState() =>
      _MoviBottomNavItemWidgetState();
}

class _MoviBottomNavItemWidgetState extends State<_MoviBottomNavItemWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _translateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _kAnimationDuration,
      vsync: this,
    );

    // Initialiser à la valeur finale si déjà sélectionné (pas d'animation au premier build)
    _controller.value = widget.isSelected ? 1.0 : 0.0;

    _translateAnimation = Tween<double>(
      begin: 0.0,
      end: -4.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_MoviBottomNavItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (widget.textStyle ?? const TextStyle(fontSize: 12))
        .copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: widget.isSelected
              ? widget.selectedTextColor
              : widget.unselectedTextColor,
        );

    final iconColor = widget.isSelected ? widget.accentColor : Colors.white70;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onTap(widget.index),
        borderRadius: BorderRadius.circular(999),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: AnimatedContainer(
          duration: _kAnimationDuration,
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: widget.isSelected ? _kSelectedBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _translateAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _translateAnimation.value),
                    child: SvgPicture.asset(
                      widget.svgAssetPath,
                      key: ValueKey('${widget.svgAssetPath}-${widget.isSelected}'),
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                    ),
                  );
                },
              ),
              AnimatedSwitcher(
                duration: _kAnimationDuration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: widget.isSelected
                    ? AnimatedDefaultTextStyle(
                        key: ValueKey(
                          'label-${widget.label}-${widget.isSelected}',
                        ),
                        duration: _kAnimationDuration,
                        style: effectiveStyle,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      )
                    : SizedBox.shrink(
                        key: ValueKey(
                          'empty-${widget.label}-${widget.isSelected}',
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double moviNavBarHeight() => _kNavHeight;

double moviNavBarBottomOffset(BuildContext context) {
  final bottomInset = MediaQuery.of(context).padding.bottom;
  if (defaultTargetPlatform == TargetPlatform.android) {
    return bottomInset + _kAndroidBottomSpacing;
  }
  return bottomInset;
}
