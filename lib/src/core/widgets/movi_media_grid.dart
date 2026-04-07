import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';

/// Grille média avec navigation TV explicite.
///
/// Cette grille ne gère que la navigation interne d'une collection :
/// - gauche/droite dans la ligne courante
/// - haut/bas dans la colonne courante
/// - stop en bord de ligne
/// - sortie verticale optionnelle vers un header ou un footer
///
/// La page garde la responsabilité du header, du retour et de la restauration.
class MoviMediaGrid extends StatefulWidget {
  const MoviMediaGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.pageHorizontalPadding = 20,
    this.cardWidth = 150,
    this.posterHeight = 225,
    this.itemHeight = 262,
    this.gridGapH = 24,
    this.gridGapV = 16,
    this.focusBleed = 12,
    this.minLargeCardWidth = 112,
    this.firstItemFocusNode,
    this.footerFocusNode,
    this.onExitUp,
    this.padding = EdgeInsets.zero,
  });

  final int itemCount;
  final Widget Function(
    BuildContext context,
    int index,
    FocusNode focusNode,
    double cardWidth,
    double posterHeight,
  ) itemBuilder;
  final double pageHorizontalPadding;
  final double cardWidth;
  final double posterHeight;
  final double itemHeight;
  final double gridGapH;
  final double gridGapV;
  final double focusBleed;
  final double minLargeCardWidth;
  final FocusNode? firstItemFocusNode;
  final FocusNode? footerFocusNode;
  final bool Function()? onExitUp;
  final EdgeInsetsGeometry padding;

  @override
  State<MoviMediaGrid> createState() => _MoviMediaGridState();
}

class _MoviMediaGridState extends State<MoviMediaGrid> {
  late List<FocusNode> _itemFocusNodes = _buildFocusNodes(widget.itemCount);

  List<FocusNode> _buildFocusNodes(int count) {
    return List<FocusNode>.generate(count, (index) {
      if (index == 0 && widget.firstItemFocusNode != null) {
        return widget.firstItemFocusNode!;
      }
      return FocusNode(debugLabel: 'MoviMediaGridItem-$index');
    }, growable: false);
  }

  void _disposeOwnedFocusNodes() {
    for (final node in _itemFocusNodes) {
      if (identical(node, widget.firstItemFocusNode)) {
        continue;
      }
      node.dispose();
    }
  }

  @override
  void didUpdateWidget(covariant MoviMediaGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount ||
        oldWidget.firstItemFocusNode != widget.firstItemFocusNode) {
      _disposeOwnedFocusNodes();
      _itemFocusNodes = _buildFocusNodes(widget.itemCount);
    }
  }

  @override
  void dispose() {
    _disposeOwnedFocusNodes();
    super.dispose();
  }

  ScreenType _screenTypeFor(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ScreenTypeResolver.instance.resolve(size.width, size.height);
  }

  bool _isLargeScreen(BuildContext context) {
    final screenType = _screenTypeFor(context);
    return screenType == ScreenType.desktop || screenType == ScreenType.tv;
  }

  double _slotWidthFor(double availableWidth, int crossAxisCount) {
    return (availableWidth - (widget.gridGapH * (crossAxisCount - 1))) /
        crossAxisCount;
  }

  bool _requestFocusIfAvailable(FocusNode? node) {
    if (node == null || !node.canRequestFocus || node.context == null) {
      return false;
    }
    node.requestFocus();
    return true;
  }

  KeyEventResult _handleGridDirection(
    KeyEvent event,
    int index,
    int crossAxisCount,
  ) {
    if (event is! KeyDownEvent || widget.itemCount == 0) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final lastItemIndex = widget.itemCount - 1;
    int? targetIndex;

    if (key == LogicalKeyboardKey.arrowLeft) {
      if (index % crossAxisCount == 0) {
        return KeyEventResult.handled;
      }
      targetIndex = index - 1;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      final isLastColumn = (index % crossAxisCount) == crossAxisCount - 1;
      if (isLastColumn || index >= lastItemIndex) {
        return KeyEventResult.handled;
      }
      targetIndex = index + 1;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      if (index - crossAxisCount < 0) {
        final handled = widget.onExitUp?.call() ?? false;
        return handled ? KeyEventResult.handled : KeyEventResult.ignored;
      }
      targetIndex = index - crossAxisCount;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      final proposedIndex = index + crossAxisCount;
      if (proposedIndex > lastItemIndex) {
        final handled = _requestFocusIfAvailable(widget.footerFocusNode);
        return handled ? KeyEventResult.handled : KeyEventResult.handled;
      }
      targetIndex = proposedIndex;
    }

    if (targetIndex == null) {
      return KeyEventResult.ignored;
    }

    var candidateIndex = targetIndex;
    if (candidateIndex > lastItemIndex) {
      candidateIndex = lastItemIndex;
    }

    while (candidateIndex >= 0 && candidateIndex <= lastItemIndex) {
      final targetNode = _itemFocusNodes[candidateIndex];
      if (targetNode.canRequestFocus && targetNode.context != null) {
        targetNode.requestFocus();
        return KeyEventResult.handled;
      }

      if (key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.arrowDown) {
        candidateIndex -= 1;
        continue;
      }
      break;
    }

    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) {
      return const SizedBox.shrink();
    }

    final posterAspectRatio = widget.posterHeight / widget.cardWidth;
    final cardChromeHeight = widget.itemHeight - widget.posterHeight;
    final baseLayoutCardWidth = widget.cardWidth + widget.focusBleed;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth - (widget.pageHorizontalPadding * 2);
        final isLargeScreen = _isLargeScreen(context);

        int crossAxisCount =
            (availableWidth / (baseLayoutCardWidth + widget.gridGapH))
                .floor()
                .clamp(1, 6);

        if (crossAxisCount < 1) {
          crossAxisCount = 1;
        } else if (crossAxisCount == 1 && availableWidth >= 300) {
          crossAxisCount = 2;
        }

        if (isLargeScreen) {
          crossAxisCount += 2;
          while (crossAxisCount > 1 &&
              (_slotWidthFor(availableWidth, crossAxisCount) -
                      widget.focusBleed) <
                  widget.minLargeCardWidth) {
            crossAxisCount--;
          }
        }

        final layoutCardWidth = _slotWidthFor(availableWidth, crossAxisCount);
        final resolvedCardWidth = layoutCardWidth - widget.focusBleed;
        final resolvedPosterHeight = resolvedCardWidth * posterAspectRatio;
        final layoutItemHeight =
            resolvedPosterHeight + cardChromeHeight + widget.focusBleed;
        final gridWidth =
            (layoutCardWidth * crossAxisCount) +
            widget.gridGapH * (crossAxisCount - 1);

        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.pageHorizontalPadding,
            ),
            child: SizedBox(
              width: gridWidth,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: widget.padding,
                itemCount: widget.itemCount,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: widget.gridGapV,
                  crossAxisSpacing: widget.gridGapH,
                  childAspectRatio: layoutCardWidth / layoutItemHeight,
                ),
                itemBuilder: (context, index) {
                  return Focus(
                    canRequestFocus: false,
                    onKeyEvent: (_, event) =>
                        _handleGridDirection(event, index, crossAxisCount),
                    child: Center(
                      child: widget.itemBuilder(
                        context,
                        index,
                        _itemFocusNodes[index],
                        resolvedCardWidth,
                        resolvedPosterHeight,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
