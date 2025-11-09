// lib/src/core/widgets/movi_items_list.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Section horizontale avec titre aligné à gauche.
/// Notifie la plage approximative d’items visibles sur le scroll horizontal
/// pour permettre un enrichissement paresseux (TMDB on-demand).
///
/// Corrections intégrées :
/// - Garde de visibilité VERTICALE (n’enrichit pas les sections hors écran)
/// - Déduplication des callbacks (évite d’envoyer 20x la même plage)
class MoviItemsList extends StatefulWidget {
  const MoviItemsList({
    super.key,
    required this.title,
    required this.items,
    this.itemSpacing = 16,
    this.horizontalPadding = const EdgeInsets.symmetric(horizontal: 20),
    this.titlePadding = 20,
    this.subtitle,
    // Hooks lazy-enrich :
    this.onViewportChanged,
    this.estimatedItemWidth,
    this.preloadAhead = 2,
  }) : assert(itemSpacing >= 0, 'itemSpacing must be non-negative');

  /// Titre de la section.
  final String title;

  /// Surtitre optionnel affiché à droite.
  final String? subtitle;

  /// Cartes/widgets affichés horizontalement.
  final List<Widget> items;

  /// Espacement entre cartes.
  final double itemSpacing;

  /// Padding horizontal de la liste.
  final EdgeInsetsGeometry horizontalPadding;

  /// Padding gauche/droite de la ligne de titre.
  final double titlePadding;

  /// Callback quand le viewport horizontal expose une nouvelle plage.
  /// Signature: (startIndex, countApprox).
  final void Function(int start, int count)? onViewportChanged;

  /// Largeur estimée d’une carte (incluant son contenu, hors spacing).
  /// Si null, aucun callback n’est émis.
  final double? estimatedItemWidth;

  /// Nombre d’items à précharger de chaque côté du viewport.
  final int preloadAhead;

  @override
  State<MoviItemsList> createState() => _MoviItemsListState();
}

class _MoviItemsListState extends State<MoviItemsList> {
  final ScrollController _ctrl = ScrollController();
  Timer? _debounce;

  int? _lastStart;
  int? _lastCount;

  double get _hPadStart {
    final p = widget.horizontalPadding;
    if (p is EdgeInsets) return p.left;
    if (p is EdgeInsetsDirectional) return p.start;
    return 0;
    // (Si autre type d’EdgeInsetsGeometry, on retourne 0 par défaut.)
  }

  double get _hPadEnd {
    final p = widget.horizontalPadding;
    if (p is EdgeInsets) return p.right;
    if (p is EdgeInsetsDirectional) return p.end;
    return 0;
  }

  void _notifyViewportChangedDebounced() {
    if (widget.onViewportChanged == null || widget.estimatedItemWidth == null) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), _notifyViewportChangedNow);
  }

  /// Renvoie true si la section est grossièrement visible verticalement
  /// (avec une marge pour précharger un peu avant/après).
  bool _isRoughlyVerticallyVisible() {
    final ro = context.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return false;

    final size = ro.size;
    final topLeft = ro.localToGlobal(Offset.zero);
    final screenH = MediaQuery.of(context).size.height;

    const margin = 150.0;
    final top = topLeft.dy;
    final bottom = top + size.height;

    // visible si pas entièrement au-dessus ni entièrement en-dessous,
    // avec une marge pour le préchargement.
    return bottom > -margin && top < screenH + margin;
  }

  void _notifyViewportChangedNow() {
    if (!mounted) return;
    final cb = widget.onViewportChanged;
    final cardW = widget.estimatedItemWidth;
    if (cb == null || cardW == null) return;

    // Garde verticale : éviter le travail pour les sections hors écran.
    if (!_isRoughlyVerticallyVisible()) return;

    // Largeur utile pour les cartes (hors padding horizontal).
    final viewportWidth = (context.size?.width ?? 0);
    double effectiveWidth = viewportWidth - _hPadStart - _hPadEnd;
    if (effectiveWidth <= 0) return;

    final unit = cardW + widget.itemSpacing;
    if (unit <= 0) return;

    if (widget.items.isEmpty) return;

    // Index de départ approximatif selon l’offset horizontal.
    int start = (_ctrl.hasClients ? (_ctrl.offset / unit).floor() : 0);
    final maxIndex = widget.items.length - 1;
    if (start < 0) start = 0;
    if (start > maxIndex) start = maxIndex;

    // Nombre d’éléments visibles approximatif.
    int visible = (effectiveWidth / unit).ceil();
    if (visible < 1) visible = 1;
    if (visible > widget.items.length) visible = widget.items.length;

    final preload = widget.preloadAhead;
    final startWithPreload = math.max(0, start - preload);
    final endWithPreload = math.min(maxIndex, start + visible - 1 + preload);
    final count = math.max(0, endWithPreload - startWithPreload + 1);

    // Déduplication : ne pas rappeler si la même plage a déjà été envoyée.
    if (_lastStart == startWithPreload && _lastCount == count) return;
    _lastStart = startWithPreload;
    _lastCount = count;

    cb(startWithPreload, count);
  }

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_notifyViewportChangedDebounced);

    // Premier calcul post-build, si la section est visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyViewportChangedNow();
    });
  }

  @override
  void didUpdateWidget(covariant MoviItemsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la taille de la liste change, recalcul post-frame (si visible).
    if (oldWidget.items.length != widget.items.length ||
        oldWidget.estimatedItemWidth != widget.estimatedItemWidth ||
        oldWidget.itemSpacing != widget.itemSpacing) {
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
                if (i != widget.items.length - 1)
                  SizedBox(width: widget.itemSpacing),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
