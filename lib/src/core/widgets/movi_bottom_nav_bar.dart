import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/l10n/app_localizations.dart';

const _kNavHeight = 72.0;
const _kContainerPadding = 5.0;
const _kAndroidBottomSpacing = 32.0;
const _kSelectedBackground = Color(0xFF262626); // 100% opacity
const _kBarBackground = Color(0x4D666666); // ~30% opacity pour laisser le blur visible
const _kAnimationDuration = Duration(milliseconds: 300);

class MoviBottomNavItem {
  const MoviBottomNavItem({required this.label, required this.icon});

  final String label;
  final String icon;
}

/// Floating bottom navigation bar with blurred background and rounded items.
class MoviBottomNavBar extends ConsumerWidget {
  MoviBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    List<MoviBottomNavItem>? navItems,
  }) : assert(selectedIndex >= 0),
       _customItems = navItems,
       assert(
         (navItems ?? _defaultItems).isNotEmpty,
         'MoviBottomNavBar requires at least one item.',
       );

  static const double height = _kNavHeight;

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<MoviBottomNavItem>? _customItems;

  static const List<MoviBottomNavItem> _defaultItems = [
    MoviBottomNavItem(label: 'Accueil', icon: AppAssets.navHome),
    MoviBottomNavItem(label: 'Recherche', icon: AppAssets.navSearch),
    MoviBottomNavItem(label: 'Bibliothèque', icon: AppAssets.navLibrary),
    MoviBottomNavItem(label: 'Paramètres', icon: AppAssets.navSettings),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _customItems ?? _localizedItems(context);
    assert(
      selectedIndex < (items.length),
      'selectedIndex ($selectedIndex) must be within the items list.',
    );

    final theme = Theme.of(context);
    final accentColor = ref.watch(asp.currentAccentColorProvider);
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
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _MoviBottomNavItemWidget(
                    item: items[i],
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

  List<MoviBottomNavItem> _localizedItems(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      MoviBottomNavItem(label: loc.navHome, icon: AppAssets.navHome),
      MoviBottomNavItem(label: loc.navSearch, icon: AppAssets.navSearch),
      MoviBottomNavItem(label: loc.navLibrary, icon: AppAssets.navLibrary),
      MoviBottomNavItem(label: loc.navSettings, icon: AppAssets.navSettings),
    ];
  }
}

class _MoviBottomNavItemWidget extends StatefulWidget {
  const _MoviBottomNavItemWidget({
    required this.item,
    required this.index,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.textStyle,
  });

  final MoviBottomNavItem item;
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
            color: widget.isSelected
                ? _kSelectedBackground
                : Colors.transparent,
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
                      widget.item.icon,
                      key: ValueKey('${widget.item.icon}-${widget.isSelected}'),
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
                          'label-${widget.item.label}-${widget.isSelected}',
                        ),
                        duration: _kAnimationDuration,
                        style: effectiveStyle,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            widget.item.label,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      )
                    : SizedBox.shrink(
                        key: ValueKey(
                          'empty-${widget.item.label}-${widget.isSelected}',
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
