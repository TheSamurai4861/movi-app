import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/app_assets.dart';

const _kNavHeight = 72.0;
const _kContainerPadding = 5.0;
const _kSelectedBackground = Color(0xB32E2E2E); // 70% opacity
const _kBarBackground = Color(0x80666666); // 50% opacity
const _kActiveTextColor = Color(0xFF5493DE);
const _kAnimationDuration = Duration(milliseconds: 300);

class MoviBottomNavItem {
  const MoviBottomNavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });

  final String label;
  final String activeIcon;
  final String inactiveIcon;
}

/// Floating bottom navigation bar with blurred background and rounded items.
class MoviBottomNavBar extends StatelessWidget {
  MoviBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    List<MoviBottomNavItem>? navItems,
  })  : assert(selectedIndex >= 0),
        items = navItems ?? _defaultItems,
        assert((navItems ?? _defaultItems).isNotEmpty,
            'MoviBottomNavBar requires at least one item.');

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<MoviBottomNavItem> items;

  static const List<MoviBottomNavItem> _defaultItems = [
    MoviBottomNavItem(
      label: 'Accueil',
      activeIcon: AppAssets.navHomeActive,
      inactiveIcon: AppAssets.navHome,
    ),
    MoviBottomNavItem(
      label: 'Recherche',
      activeIcon: AppAssets.navSearchActive,
      inactiveIcon: AppAssets.navSearch,
    ),
    MoviBottomNavItem(
      label: 'Bibliothèque',
      activeIcon: AppAssets.navLibraryActive,
      inactiveIcon: AppAssets.navLibrary,
    ),
    MoviBottomNavItem(
      label: 'Paramètres',
      activeIcon: AppAssets.navSettingsActive,
      inactiveIcon: AppAssets.navSettings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    assert(selectedIndex < items.length,
        'selectedIndex ($selectedIndex) must be within the items list.');

    final theme = Theme.of(context);
    final unselectedTextColor = Colors.white.withOpacity(0.7);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
                    selectedTextColor: _kActiveTextColor,
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

class _MoviBottomNavItemWidget extends StatelessWidget {
  const _MoviBottomNavItemWidget({
    required this.item,
    required this.index,
    required this.isSelected,
    required this.onTap,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.textStyle,
  });

  final MoviBottomNavItem item;
  final int index;
  final bool isSelected;
  final ValueChanged<int> onTap;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (textStyle ?? const TextStyle(fontSize: 12)).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: isSelected ? selectedTextColor : unselectedTextColor,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(999),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: AnimatedContainer(
          duration: _kAnimationDuration,
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? _kSelectedBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                isSelected ? item.activeIcon : item.inactiveIcon,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
              AnimatedSwitcher(
                duration: _kAnimationDuration,
                child: isSelected
                    ? Padding(
                        key: ValueKey('label-${item.label}'),
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.label,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: effectiveStyle,
                        ),
                      )
                    : SizedBox.shrink(key: ValueKey('empty-${item.label}')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double moviNavBarHeight() => _kNavHeight;
