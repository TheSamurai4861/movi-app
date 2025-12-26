// lib/src/features/shell/presentation/widgets/navigation/sidebar_nav_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movi/src/core/theme/app_colors.dart';

/// Item de navigation pour la sidebar (Desktop / TV).
///
/// UI demandée :
/// - Container 48x48 avec radius max
/// - Icône SVG 32x32
/// - Selected : fond AppColors.secondaryDarkBackground + icône accent
/// - Unselected : fond transparent + icône AppColors.lightTextSecondary
///
/// UX demandée :
/// - Hover (PC) : fond léger + icône un peu plus claire
/// - Press (clic) : petit "fade" du fond
/// - Focus (TV/Clavier) : outline
/// - SVG : on force la coloration
/// - Pas de Semantics/label
/// - Zone cliquable strictement 48x48
class SidebarNavItem extends StatefulWidget {
  const SidebarNavItem({
    super.key,
    required this.assetPath,
    required this.selected,
    required this.onTap,
    required this.tooltip,
    this.accentColor,
    this.selectedBackgroundColor,
    this.unselectedIconColor,
    this.focusOutlineWidth = 2,
    this.enableHover = true,
  });

  /// Chemin de l'icône SVG (ex: assets/icons/home.svg)
  final String assetPath;

  /// Sélectionné ?
  final bool selected;

  /// Action au tap/clic.
  final VoidCallback onTap;

  /// Tooltip déjà localisé (via AppLocalizations dans le parent).
  final String tooltip;

  /// Optionnel : couleur d’accent forcée. Sinon Theme.colorScheme.primary.
  final Color? accentColor;

  /// Optionnel : background selected. Sinon AppColors.secondaryDarkBackground.
  final Color? selectedBackgroundColor;

  /// Optionnel : couleur icône non sélectionnée. Sinon AppColors.lightTextSecondary.
  final Color? unselectedIconColor;

  /// Épaisseur du contour focus.
  final double focusOutlineWidth;

  /// Désactive les effets hover (utile TV).
  final bool enableHover;

  @override
  State<SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<SidebarNavItem> {
  static const double _boxSize = 48;
  static const double _iconSize = 32;
  static const double _radius = 24;

  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final accent = widget.accentColor ?? theme.colorScheme.primary;
    final selectedBg =
        widget.selectedBackgroundColor ?? AppColors.secondaryDarkBackground;
    final unselectedIcon =
        widget.unselectedIconColor ?? AppColors.lightTextSecondary;

    // Hover = fond léger + icône un peu plus claire
    final hoverBg = AppColors.secondaryDarkBackground.withValues(alpha: 0.55);
    final hoverIcon =
        Color.lerp(unselectedIcon, theme.colorScheme.onSurface, 0.35) ??
            unselectedIcon;

    // Press = fade du fond
    final pressedOverlay = AppColors.secondaryDarkBackground.withValues(alpha: 0.80);

    final effectiveHovered = widget.enableHover ? _hovered : false;

    final iconColor =
        widget.selected ? accent : (effectiveHovered ? hoverIcon : unselectedIcon);

    final baseBg = widget.selected
        ? selectedBg
        : (effectiveHovered ? hoverBg : Colors.transparent);

    final bgColor = _pressed ? pressedOverlay : baseBg;

    final border =
        _focused ? Border.all(color: accent, width: widget.focusOutlineWidth) : null;

    Widget core = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: SizedBox(
        width: _boxSize,
        height: _boxSize,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(_radius),
            border: border,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            widget.assetPath,
            width: _iconSize,
            height: _iconSize,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
        ),
      ),
    );

    core = FocusableActionDetector(
      onShowFocusHighlight: (v) {
        if (_focused == v) return;
        setState(() => _focused = v);
      },
      mouseCursor:
          widget.enableHover ? SystemMouseCursors.click : MouseCursor.defer,
      child: widget.enableHover
          ? MouseRegion(
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: core,
            )
          : core,
    );

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 450),
      child: core,
    );
  }
}
