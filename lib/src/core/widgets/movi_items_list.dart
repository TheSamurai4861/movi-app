// lib/src/core/widgets/movi_items_list.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Horizontal list section with a title aligned to the left edge,
/// capable of notifying the visible range on horizontal scroll to enable
/// lazy enrichment of items (TMDB fetch on demand).
///
/// Patch:
/// - Garde de visibilité VERTICALE (évite d’enrichir des sections lointaines)
/// - Déduplication des callbacks (ne renvoie pas 20x la même plage)
class MoviItemsList extends StatefulWidget {
  const MoviItemsList({
    super.key,
    required this.title,
    required this.items,
    this.itemSpacing = 16,
    this.horizontalPadding = const EdgeInsets.symmetric(horizontal: 20),
    this.titlePadding = 20,
    this.subtitle,
    // Lazy-enrich hooks:
    this.onViewportChanged,
    this.estimatedItemWidth,
    this.preloadAhead = 2,
  }) : assert(itemSpacing >= 0, 'itemSpacing must be non-negative');

  /// Section title displayed above the list.
  final String title;

  /// Optional secondary label displayed to the right of the title.
  final String? subtitle;

  /// Cards/widgets displayed horizontally.
  final List<Widget> items;

  /// Spacing between each card in the horizontal list.
  final double itemSpacing;

  /// Padding applied to the horizontal list.
  final EdgeInsetsGeometry horizontalPadding;

  /// Left/right padding applied to the title text row.
  final double titlePadding;

  /// Called when the horizontal viewport likely exposes a new range.
  /// Signature: (startIndex, countVisibleApprox).
  final void Function(int start, int count)? onViewportChanged;

  /// Estimated width of a single card (for range calc). If null, no callback.
  final double? estimatedItemWidth;

  /// How many items to preload ahead of viewport on each side.
  final int preloadAhead;

  @override
  State<MoviItemsList> createState() => _MoviItemsListState();
}

class _MoviItemsListState extends State<MoviItemsList> {
  final _ctrl = ScrollController();
  Timer? _debounce;

  int? _lastStart;
  int? _lastCount;

  double get _hPadStart {
    if (widget.horizontalPadding is EdgeInsets) {
      return (widget.horizontalPadding as EdgeInsets).left;
    }
    if (widget.horizontalPadding is EdgeInsetsDirectional) {
      return (widget.horizontalPadding as EdgeInsetsDirectional).start;
    }
    return 0;
  }

  double get _hPadEnd {
    if (widget.horizontalPadding is EdgeInsets) {
      return (widget.horizontalPadding as EdgeInsets).right;
    }
    if (widget.horizontalPadding is EdgeInsetsDirectional) {
      return (widget.horizontalPadding as EdgeInsetsDirectional).end;
    }
    return 0;
  }

  void _notifyViewportChangedDebounced() {
    if (widget.onViewportChanged == null || widget.estimatedItemWidth == null) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), _notifyViewportChangedNow);
  }

  bool _isRoughlyVerticallyVisible() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;

    final size = box.size;
    final pos = box.localToGlobal(Offset.zero);
    final screenH = MediaQuery.of(context).size.height;

    const double margin = 150; // marge pour précharger un peu avant/après
    final top = pos.dy;
    final bottom = top + size.height;

    return bottom > -margin && top < screenH + margin;
  }

  void _notifyViewportChangedNow() {
    if (!mounted) return;
    if (widget.onViewportChanged == null || widget.estimatedItemWidth == null) return;

    // Garde verticale : ne notifie pas si la section est loin de l'écran.
    if (!_isRoughlyVerticallyVisible()) return;

    // Largeur disponible pour les cartes, hors padding horizontal.
    final viewportWidth = context.size?.width ?? 0;
    double effectiveWidth = viewportWidth - _hPadStart - _hPadEnd;
    if (effectiveWidth <= 0) return;

    final unit = widget.estimatedItemWidth! + widget.itemSpacing;
    if (unit <= 0) return;

    if (widget.items.isEmpty) return;

    // Position actuelle (offset) -> index de départ approximatif (borné).
    int start = (_ctrl.offset / unit).floor();
    final maxIndex = widget.items.length - 1;
    if (start < 0) start = 0;
    if (start > maxIndex) start = maxIndex;

    // Nombre d’éléments visibles approximatif (borné à [1 .. len]).
    int visible = (effectiveWidth / unit).ceil();
    if (visible < 1) visible = 1;
    if (visible > widget.items.length) visible = widget.items.length;

    final preload = widget.preloadAhead;

    final startWithPreload = math.max(0, start - preload);
    final endWithPreload = math.min(maxIndex, start + visible - 1 + preload);
    final count = math.max(0, endWithPreload - startWithPreload + 1);

    // Dédup : n'appelle pas si on renvoie la même plage
    if (_lastStart == startWithPreload && _lastCount == count) return;
    _lastStart = startWithPreload;
    _lastCount = count;

    widget.onViewportChanged!.call(startWithPreload, count);
  }

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_notifyViewportChangedDebounced);

    // Appel initial (post-frame) SI la section est visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyViewportChangedNow();
    });
  }

  @override
  void didUpdateWidget(covariant MoviItemsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si le nombre d’items change, renvoyer une info de viewport (si visible).
    if (oldWidget.items.length != widget.items.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyViewportChangedNow();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl
      ..removeListener(_notifyViewportChangedDebounced)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: widget.titlePadding,
            end: widget.titlePadding,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.subtitle != null)
                Text(
                  widget.subtitle!,
                  style: textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFA6A6A6),
                      ) ??
                      const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFA6A6A6),
                      ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          controller: _ctrl,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: widget.horizontalPadding,
          child: Row(
            children: [
              for (int i = 0; i < widget.items.length; i++) ...[
                widget.items[i],
                if (i != widget.items.length - 1) SizedBox(width: widget.itemSpacing),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
