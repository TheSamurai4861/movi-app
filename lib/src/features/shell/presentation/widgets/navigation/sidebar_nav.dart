// lib/src/features/shell/presentation/widgets/navigation/sidebar_nav.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movi/src/core/theme/app_colors.dart';
import 'package:movi/src/features/shell/presentation/widgets/navigation/sidebar_nav_item.dart';

/// Barre de navigation verticale (Desktop / TV).
///
/// Aucun texte "brut" : le label/tooltip doit être déjà localisé côté destinations.
class SidebarNav extends StatefulWidget {
  const SidebarNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.width = 72,
    this.backgroundColor = AppColors.darkBackground,
    this.showRightDivider = true,
    this.dividerColor,
    this.logo,
    this.itemGap = 20,
    this.focusNode,
    this.autofocus = false,
    this.enableHover = true,
    this.onFocusedIndexChanged,
  });

  /// Index sélectionné.
  final int selectedIndex;

  /// Callback quand on sélectionne une destination.
  final ValueChanged<int> onDestinationSelected;

  /// Destinations fournies par le parent (shell_destinations.dart).
  final List<SidebarDestination> destinations;

  /// Largeur de la barre.
  final double width;

  /// Couleur de fond de la barre.
  final Color backgroundColor;

  /// Affiche un séparateur vertical à droite.
  final bool showRightDivider;

  /// Couleur du séparateur (par défaut: Theme.outlineVariant).
  final Color? dividerColor;

  /// Widget de logo affiché en haut (optionnel).
  final Widget? logo;

  /// Espacement vertical entre items.
  final double itemGap;

  /// FocusNode externe (optionnel) pour contrôler le focus depuis le shell.
  final FocusNode? focusNode;

  /// Autofocus du conteneur focusable.
  final bool autofocus;

  /// Désactive les comportements de hover (utile TV).
  final bool enableHover;
  final ValueChanged<int>? onFocusedIndexChanged;

  @override
  State<SidebarNav> createState() => _SidebarNavState();
}

/// Modèle simple de destination pour la sidebar.
/// (Construit depuis shell_destinations.dart)
class SidebarDestination {
  const SidebarDestination({required this.assetPath, required this.tooltip});

  final String assetPath;
  final String tooltip;
}

class _SidebarNavState extends State<SidebarNav> {
  late final FocusNode _internalFocusNode = FocusNode(debugLabel: 'SidebarNav');
  late List<FocusNode> _itemFocusNodes = _buildItemFocusNodes(
    widget.destinations.length,
  );

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode;

  List<FocusNode> _buildItemFocusNodes(int count) {
    return List<FocusNode>.generate(
      count,
      (index) => FocusNode(debugLabel: 'SidebarNavItem-$index'),
      growable: false,
    );
  }

  void _disposeItemFocusNodes() {
    for (final node in _itemFocusNodes) {
      node.dispose();
    }
  }

  void _focusSelectedItem() {
    if (_itemFocusNodes.isEmpty) return;
    final index = widget.selectedIndex.clamp(0, _itemFocusNodes.length - 1);
    widget.onFocusedIndexChanged?.call(index);
    _itemFocusNodes[index].requestFocus();
  }

  int _currentFocusedIndex() {
    final focusedIndex = _itemFocusNodes.indexWhere(
      (node) => node.hasPrimaryFocus || node.hasFocus,
    );
    if (focusedIndex != -1) {
      return focusedIndex;
    }
    return widget.selectedIndex.clamp(0, _itemFocusNodes.length - 1);
  }

  KeyEventResult _handleSidebarDirection(LogicalKeyboardKey key) {
    if (_itemFocusNodes.isEmpty) return KeyEventResult.ignored;
    if (key != LogicalKeyboardKey.arrowDown &&
        key != LogicalKeyboardKey.arrowUp) {
      return KeyEventResult.ignored;
    }

    final currentIndex = _currentFocusedIndex();
    final targetIndex = key == LogicalKeyboardKey.arrowDown
        ? (currentIndex + 1).clamp(0, _itemFocusNodes.length - 1)
        : (currentIndex - 1).clamp(0, _itemFocusNodes.length - 1);

    if (targetIndex == currentIndex) {
      return KeyEventResult.handled;
    }

    _itemFocusNodes[targetIndex].requestFocus();
    widget.onFocusedIndexChanged?.call(targetIndex);
    return KeyEventResult.handled;
  }

  @override
  void didUpdateWidget(covariant SidebarNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.destinations.length != widget.destinations.length) {
      _disposeItemFocusNodes();
      _itemFocusNodes = _buildItemFocusNodes(widget.destinations.length);
    }
    if (oldWidget.selectedIndex != widget.selectedIndex &&
        _focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusSelectedItem();
        }
      });
    }
  }

  @override
  void dispose() {
    _disposeItemFocusNodes();
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dividerColor =
        widget.dividerColor ??
        Theme.of(context).dividerTheme.color ??
        Theme.of(context).colorScheme.outlineVariant;

    final sidebar = Container(
      width: widget.width,
      color: widget.backgroundColor,
      child: SafeArea(
        top: true,
        bottom: true,
        left: false,
        right: false,
        child: FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: Focus(
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              return _handleSidebarDirection(event.logicalKey);
            },
            onFocusChange: (hasFocus) {
              if (hasFocus) {
                _focusSelectedItem();
              }
            },
            child: Column(
              children: [
                if (widget.logo != null) ...[
                  const SizedBox(height: 16),
                  Center(child: widget.logo),
                  const SizedBox(height: 16),
                ] else ...[
                  const SizedBox(height: 8),
                ],
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (
                          int i = 0;
                          i < widget.destinations.length;
                          i++
                        ) ...[
                          FocusTraversalOrder(
                            order: NumericFocusOrder(i.toDouble()),
                            child: SidebarNavItem(
                              assetPath: widget.destinations[i].assetPath,
                              tooltip: widget.destinations[i].tooltip,
                              selected: widget.selectedIndex == i,
                              onTap: () {
                                widget.onFocusedIndexChanged?.call(i);
                                widget.onDestinationSelected(i);
                              },
                              focusNode: _itemFocusNodes[i],
                              enableHover: widget.enableHover,
                            ),
                          ),
                          if (i != widget.destinations.length - 1)
                            SizedBox(height: widget.itemGap),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );

    if (!widget.showRightDivider) return sidebar;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        sidebar,
        VerticalDivider(thickness: 1, width: 1, color: dividerColor),
      ],
    );
  }
}
