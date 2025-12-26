import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Liste horizontale avec titre et sous-titre optionnel.
/// Émet des fenêtres d'index visibles (start, count) pour l’enrichissement paresseux.
/// Optimisations :
/// - garde de visibilité verticale,
/// - debounce des notifications,
/// - déduplication des fenêtres envoyées,
/// - calcul robuste du padding horizontal (RTL/LTR),
/// - prise en compte des changements de largeur via LayoutBuilder.
class MoviItemsList extends StatefulWidget {
  const MoviItemsList({
    super.key,
    required this.title,
    required this.items,
    this.subtitle,
    this.action,
    this.itemSpacing = 16,
    this.horizontalPadding = const EdgeInsets.symmetric(horizontal: 20),
    this.titlePadding = 20,
    this.onViewportChanged,
    this.estimatedItemWidth,
    this.estimatedItemHeight,
    this.preloadAhead = 2,
    this.verticalPreloadMargin = 150,
    this.debounceMs = 240,
  }) : assert(itemSpacing >= 0, 'itemSpacing must be non-negative');

  final String title;
  final String? subtitle;
  final List<Widget> items;

  /// Action optionnelle à droite du header (ex: bouton "Voir tout").
  final Widget? action;

  /// Espacement entre cartes.
  final double itemSpacing;

  /// Padding horizontal appliqué sur la rangée de cartes.
  final EdgeInsetsGeometry horizontalPadding;

  /// Padding appliqué à la ligne de titre.
  final double titlePadding;

  /// Callback lorsque la fenêtre visible a potentiellement changé.
  /// Signature: (startIndexInclus, count>=1).
  final void Function(int start, int count)? onViewportChanged;

  /// Largeur estimée d’une carte (hors spacing). Sans valeur, aucun callback n’est émis.
  final double? estimatedItemWidth;

  /// Hauteur estimée d’une carte; utilisée pour contraindre la `ListView` horizontale.
  /// Si non renseignée, une hauteur par défaut est appliquée.
  final double? estimatedItemHeight;

  /// Marge de préchargement verticale (px) avant/après l’entrée à l’écran.
  final double verticalPreloadMargin;

  /// Nombre d’items à précharger de chaque côté de la fenêtre visible.
  final int preloadAhead;

  /// Durée du debounce des notifications de viewport.
  final int debounceMs;

  @override
  State<MoviItemsList> createState() => _MoviItemsListState();
}

class _MoviItemsListState extends State<MoviItemsList> {
  final ScrollController _hCtrl = ScrollController();
  ScrollPosition? _vpos; // position du scroll vertical parent
  Timer? _debounce;

  int? _lastStart;
  int? _lastCount;
  double? _lastViewportWidth;
  
  // Flag pour éviter l'accumulation de callbacks
  bool _pendingNotify = false;

  // ---- Utilities

  EdgeInsets _resolvedHorizontalPadding(BuildContext context) {
    return widget.horizontalPadding.resolve(Directionality.of(context));
  }

  double _effectiveViewportWidth(BoxConstraints constraints) {
    final pads = _resolvedHorizontalPadding(context);
    final width = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : (context.size?.width ?? 0);
    final effective = width - pads.left - pads.right;
    return effective > 0 ? effective : 0;
  }

  void _scheduleNotify() {
    if (widget.onViewportChanged == null || widget.estimatedItemWidth == null) {
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: widget.debounceMs), _notifyNow);
  }
  
  /// Planifie un callback de notification si aucun n'est déjà en attente
  void _scheduleNotifyIfNeeded() {
    if (_pendingNotify || !mounted) return;
    _pendingNotify = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingNotify = false;
      if (mounted) {
        _attachVerticalListener();
        _notifyNow();
      }
    });
  }

  void _attachVerticalListener() {
    final pos = Scrollable.maybeOf(context)?.position;
    if (_vpos == pos) return;
    _vpos?.isScrollingNotifier.removeListener(_scheduleNotify);
    _vpos = pos;
    _vpos?.isScrollingNotifier.addListener(_scheduleNotify);
  }

  bool _isRoughlyVerticallyVisible() {
    final ro = context.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return false;
    final size = ro.size;
    final topLeft = ro.localToGlobal(Offset.zero);
    final screenH = MediaQuery.of(context).size.height;
    final margin = widget.verticalPreloadMargin;
    final top = topLeft.dy;
    final bottom = top + size.height;
    return bottom > -margin && top < screenH + margin;
  }

  void _notifyNow() {
    if (!mounted) return;
    final cb = widget.onViewportChanged;
    final cardW = widget.estimatedItemWidth;
    if (cb == null || cardW == null) return;
    if (!_isRoughlyVerticallyVisible()) return;
    if (!_hCtrl.hasClients) return;
    if (widget.items.isEmpty) return;

    // On récupère la largeur connue via _lastViewportWidth (mise à jour par LayoutBuilder).
    final viewportWidth = _lastViewportWidth ?? (context.size?.width ?? 0);
    if (viewportWidth <= 0) return;

    final unit = cardW + widget.itemSpacing;
    if (unit <= 0) return;

    final pads = _resolvedHorizontalPadding(context);
    final effectiveWidth = viewportWidth - pads.left - pads.right;
    if (effectiveWidth <= 0) return;

    final maxIndex = widget.items.length - 1;
    int start = (_hCtrl.offset / unit).floor();
    if (start < 0) start = 0;
    if (start > maxIndex) start = maxIndex;

    int visible = (effectiveWidth / unit).ceil();
    if (visible < 1) visible = 1;
    if (visible > widget.items.length) visible = widget.items.length;

    final preload = widget.preloadAhead;
    final startWithPreload = math.max(0, start - preload);
    final endWithPreload = math.min(maxIndex, start + visible - 1 + preload);
    final count = math.max(0, endWithPreload - startWithPreload + 1);

    if (_lastStart == startWithPreload && _lastCount == count) return;
    _lastStart = startWithPreload;
    _lastCount = count;

    cb(startWithPreload, count);
  }

  // ---- Lifecycle

  @override
  void initState() {
    super.initState();
    _hCtrl.addListener(_scheduleNotify);
    _scheduleNotifyIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attachVerticalListener();
    _scheduleNotifyIfNeeded();
  }

  @override
  void didUpdateWidget(covariant MoviItemsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length ||
        oldWidget.estimatedItemWidth != widget.estimatedItemWidth ||
        oldWidget.itemSpacing != widget.itemSpacing ||
        oldWidget.horizontalPadding != widget.horizontalPadding) {
      _scheduleNotifyIfNeeded();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _vpos?.isScrollingNotifier.removeListener(_scheduleNotify);
    _vpos = null;
    _hCtrl
      ..removeListener(_scheduleNotify)
      ..dispose();
    super.dispose();
  }

  // ---- UI

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (widget.items.isEmpty) return const SizedBox.shrink();

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
                  style:
                      textTheme.bodyMedium?.copyWith(
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
              if (widget.action != null) const SizedBox(width: 8),
              if (widget.action != null) widget.action!,
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final width =
                _effectiveViewportWidth(
                  constraints,
                ) + // largeur utile (sans padding)
                _resolvedHorizontalPadding(context).left +
                _resolvedHorizontalPadding(context).right;
            if (_lastViewportWidth != width) {
              _lastViewportWidth = width;
              // On notifie avec debounce pour limiter la pression en cas de resize.
              _scheduleNotify();
            }
            // Liste horizontale construite paresseusement pour éviter le chargement massif d'images.
            return SizedBox(
              height: widget.estimatedItemHeight ?? 240,
              child: ListView.separated(
                controller: _hCtrl,
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: widget.horizontalPadding,
                cacheExtent: widget.estimatedItemWidth != null
                    ? (widget.estimatedItemWidth! * 2)
                    : null,
                itemCount: widget.items.length,
                itemBuilder: (context, i) => widget.items[i],
                separatorBuilder: (context, _) =>
                    SizedBox(width: widget.itemSpacing),
              ),
            );
          },
        ),
      ],
    );
  }
}
