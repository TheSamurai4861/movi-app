import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/l10n/app_localizations.dart';

const _kNavHeight = 72.0;
const _kContainerPadding = 5.0;
const _kSelectedBackground = Color(0xB32E2E2E); // 70% opacity
const _kBarBackground = Color(0x80666666); // 50% opacity
const _kActiveTextColor = Color.fromRGBO(38, 120, 217, 1);
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
  }) : assert(selectedIndex >= 0),
       _customItems = navItems,
       assert(
         (navItems ?? _defaultItems).isNotEmpty,
         'MoviBottomNavBar requires at least one item.',
       );

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<MoviBottomNavItem>? _customItems;

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
    final items = _customItems ?? _localizedItems(context);
    assert(
      selectedIndex < (items.length),
      'selectedIndex ($selectedIndex) must be within the items list.',
    );

    final theme = Theme.of(context);
    final unselectedTextColor = Colors.white.withValues(alpha: 0.7);

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

  List<MoviBottomNavItem> _localizedItems(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      MoviBottomNavItem(
        label: loc.navHome,
        activeIcon: AppAssets.navHomeActive,
        inactiveIcon: AppAssets.navHome,
      ),
      MoviBottomNavItem(
        label: loc.navSearch,
        activeIcon: AppAssets.navSearchActive,
        inactiveIcon: AppAssets.navSearch,
      ),
      MoviBottomNavItem(
        label: loc.navLibrary,
        activeIcon: AppAssets.navLibraryActive,
        inactiveIcon: AppAssets.navLibrary,
      ),
      MoviBottomNavItem(
        label: loc.navSettings,
        activeIcon: AppAssets.navSettingsActive,
        inactiveIcon: AppAssets.navSettings,
      ),
    ];
  }
}

class _MoviBottomNavItemWidget extends StatefulWidget {
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
  State<_MoviBottomNavItemWidget> createState() =>
      _MoviBottomNavItemWidgetState();
}

class _MoviBottomNavItemWidgetState extends State<_MoviBottomNavItemWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _translateAnimation;
  String _currentIcon = '';

  @override
  void initState() {
    super.initState();
    _currentIcon = widget.isSelected
        ? widget.item.activeIcon
        : widget.item.inactiveIcon;
    if (_currentIcon.isEmpty) {
      _currentIcon = widget.item.inactiveIcon.isNotEmpty
          ? widget.item.inactiveIcon
          : widget.item.activeIcon;
    }
    _controller = AnimationController(
      duration: _kAnimationDuration,
      vsync: this,
    );

    _translateAnimation = Tween<double>(
      begin: 0.0,
      end: -4.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.isSelected) {
      _controller.forward();
    }

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && !widget.isSelected) {
        if (mounted) {
          final newIcon = widget.item.inactiveIcon.isNotEmpty
              ? widget.item.inactiveIcon
              : widget.item.activeIcon;
          setState(() {
            _currentIcon = newIcon;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(_MoviBottomNavItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        final newIcon = widget.item.activeIcon.isNotEmpty
            ? widget.item.activeIcon
            : widget.item.inactiveIcon;
        setState(() {
          _currentIcon = newIcon;
        });
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
                    child: _currentIcon.isNotEmpty
                        ? Image.asset(
                            _currentIcon,
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                          )
                        : Image.asset(
                            widget.isSelected
                                ? widget.item.activeIcon
                                : widget.item.inactiveIcon,
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
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
