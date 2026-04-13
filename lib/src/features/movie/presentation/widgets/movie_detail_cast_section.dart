import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';

class MovieDetailCastSection extends ConsumerStatefulWidget {
  const MovieDetailCastSection({
    super.key,
    required this.cast,
    this.horizontalPadding = 20,
    this.firstItemFocusNode,
    this.onRequestPrimaryActionFocus,
    this.onFocusedActorIndexChanged,
    this.focusRequestId,
    this.focusRequestIndex,
  });
  final List<MoviPerson> cast;
  final double horizontalPadding;
  final FocusNode? firstItemFocusNode;
  final VoidCallback? onRequestPrimaryActionFocus;
  final ValueChanged<int>? onFocusedActorIndexChanged;
  final int? focusRequestId;
  final int? focusRequestIndex;

  @override
  ConsumerState<MovieDetailCastSection> createState() =>
      _MovieDetailCastSectionState();
}

class _MovieDetailCastSectionState
    extends ConsumerState<MovieDetailCastSection> {
  late List<FocusNode> _itemFocusNodes = _buildFocusNodes(widget.cast.length);

  List<FocusNode> _buildFocusNodes(int count) {
    return List<FocusNode>.generate(count, (index) {
      if (index == 0 && widget.firstItemFocusNode != null) {
        return widget.firstItemFocusNode!;
      }
      return FocusNode(debugLabel: 'MovieCastItem-$index');
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
  void didUpdateWidget(covariant MovieDetailCastSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cast.length != widget.cast.length ||
        oldWidget.firstItemFocusNode != widget.firstItemFocusNode) {
      _disposeOwnedFocusNodes();
      _itemFocusNodes = _buildFocusNodes(widget.cast.length);
    }
    if (oldWidget.focusRequestId != widget.focusRequestId) {
      _requestFocusAtIndex(widget.focusRequestIndex);
    }
  }

  void _requestFocusAtIndex(int? index) {
    if (index == null || index < 0 || index >= _itemFocusNodes.length) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final node = _itemFocusNodes[index];
      if (!node.canRequestFocus || node.context == null) {
        return;
      }
      node.requestFocus();
    });
  }

  @override
  void dispose() {
    _disposeOwnedFocusNodes();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MoviPersonCard.listHeight,
      child: Builder(
        builder: (listContext) => MoviVerticalEnsureVisibleTarget(
          targetContext: listContext,
          child: ListView.separated(
            clipBehavior: Clip.none,
            padding: EdgeInsetsDirectional.only(
              start: widget.horizontalPadding,
              end: widget.horizontalPadding,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: widget.cast.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final p = widget.cast[index];
              return Focus(
                canRequestFocus: false,
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    widget.onFocusedActorIndexChanged?.call(index);
                  }
                },
                onKeyEvent: (_, event) {
                  if (event is! KeyDownEvent) {
                    return KeyEventResult.ignored;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    widget.onRequestPrimaryActionFocus?.call();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: MoviEnsureVisibleOnFocus(
                  isLeadingEdge: index == 0,
                  isTrailingEdge: index == widget.cast.length - 1,
                  consumeBackwardEdgeKey: true,
                  horizontalAlignment: 0.18,
                  child: MoviPersonCard(
                    person: p,
                    focusNode: _itemFocusNodes[index],
                    onTap: (person) {
                      final personSummary = PersonSummary(
                        id: PersonId(person.id),
                        name: person.name,
                        role: person.role,
                        photo: person.poster,
                      );
                      navigateToPersonDetail(
                        context,
                        ref,
                        person: personSummary,
                        triggerFocusNode: _itemFocusNodes[index],
                        originRegionId: AppFocusRegionId.movieDetailPrimary,
                        fallbackRegionId: AppFocusRegionId.movieDetailPrimary,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
