import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Affiche un logo TMDB (ou autre) avec une hauteur adaptative selon son ratio.
///
/// Objectifs UX :
/// - Si le logo est **large** (ratio >= [wideRatioThreshold]) il reste compact.
/// - Si le ratio se rapproche du **carré** ou du **rectangle vertical**
///   (ratio <= [blockyRatioThreshold]) : plus de hauteur max ([blockyMaxHeight]).
/// - Entre les deux : hauteur intermédiaire ([tallMaxHeight]).
/// Le logo peut remonter sur le hero (overflow vers le haut) sans pousser le contenu dessous.
class MoviResponsiveLogo extends StatefulWidget {
  const MoviResponsiveLogo({
    super.key,
    required this.imageUrl,
    required this.semanticLabel,
    required this.alignment,
    required this.maxWidth,
    this.reservedHeight = 64,
    this.wideMaxHeight = 64,
    this.tallMaxHeight = 112,
    this.blockyMaxHeight = 136,
    this.wideRatioThreshold = 2.0,
    this.blockyRatioThreshold = 1.35,
    this.overflowUpFactor = 1.0,
    this.extraUpOffset = 0,
    this.filterQuality = FilterQuality.high,
    this.onErrorFallback,
  });

  final String imageUrl;
  final String semanticLabel;
  final Alignment alignment;
  final double maxWidth;

  /// Hauteur réservée dans la mise en page (le logo peut déborder vers le haut).
  final double reservedHeight;

  /// Hauteur max quand le logo est "large".
  final double wideMaxHeight;

  /// Hauteur max quand le logo est moins large (entre carré et bannière).
  final double tallMaxHeight;

  /// Hauteur max quand le logo est plutôt **carré** ou **vertical** (ratio w/h bas).
  final double blockyMaxHeight;

  final double wideRatioThreshold;

  /// Seuil (largeur / hauteur) : en dessous, logo considéré comme carré / portrait.
  final double blockyRatioThreshold;

  /// Contrôle l'overlap vers le haut, en pourcentage de l'overflow disponible.
  ///
  /// - 1.0: remonte au maximum (ne consomme que [reservedHeight] dans le layout)
  /// - 0.5: remonte à moitié (effet "moitié dans le hero, moitié dessous")
  /// - 0.0: aucun overlap (le logo est contenu dans [reservedHeight])
  final double overflowUpFactor;

  /// Décalage supplémentaire vers le haut (px) pour bien "coller" le logo au backdrop.
  final double extraUpOffset;
  final FilterQuality filterQuality;

  /// Widget fallback si l'image échoue.
  final WidgetBuilder? onErrorFallback;

  @override
  State<MoviResponsiveLogo> createState() => _MoviResponsiveLogoState();
}

class _MoviResponsiveLogoState extends State<MoviResponsiveLogo> {
  double? _ratio;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  bool get _isSvg {
    final raw = widget.imageUrl.trim();
    final uri = Uri.tryParse(raw);
    final path = (uri?.path ?? raw).toLowerCase();
    return path.endsWith('.svg');
  }

  @override
  void initState() {
    super.initState();
    _resolveRatio();
  }

  @override
  void didUpdateWidget(covariant MoviResponsiveLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _ratio = null;
      _unlisten();
      _resolveRatio();
    }
  }

  @override
  void dispose() {
    _unlisten();
    super.dispose();
  }

  void _unlisten() {
    final stream = _stream;
    final listener = _listener;
    if (stream != null && listener != null) {
      try {
        stream.removeListener(listener);
      } catch (_) {
        // Defensive: stream may already be disposed by engine internals.
      }
    }
    _stream = null;
    _listener = null;
  }

  void _resolveRatio() {
    if (_isSvg) {
      // Les SVG ne passent pas par ImageProvider (et n'exposent pas width/height ici).
      // On garde un ratio inconnu => on utilisera les valeurs "tall/blocky".
      return;
    }
    final provider = NetworkImage(widget.imageUrl);
    final stream = provider.resolve(const ImageConfiguration());
    _stream = stream;

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        final w = info.image.width.toDouble();
        final h = info.image.height.toDouble();
        if (w > 0 && h > 0 && mounted) {
          setState(() => _ratio = w / h);
        }
        try {
          stream.removeListener(listener);
        } catch (_) {
          // Defensive: stream may be disposed before callback cleanup.
        }
        if (identical(_stream, stream) && identical(_listener, listener)) {
          _stream = null;
          _listener = null;
        }
      },
      onError: (_, __) {
        try {
          stream.removeListener(listener);
        } catch (_) {
          // Defensive: stream may be disposed before callback cleanup.
        }
        if (identical(_stream, stream) && identical(_listener, listener)) {
          _stream = null;
          _listener = null;
        }
      },
    );

    _listener = listener;
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _ratio;
    final maxH = _maxHeightForRatio(ratio);
    final reserved = widget.reservedHeight;

    // Si le logo est "grand" (tall), on ne pousse pas le layout :
    // on réserve une hauteur fixe et on remonte l'excédent vers le haut.
    final factor = widget.overflowUpFactor.clamp(0.0, 1.0);
    final overflowUp = math.max(0.0, maxH - reserved) * factor;
    final extraUp = widget.extraUpOffset.clamp(0.0, 200.0);

    return Semantics(
      header: true,
      label: widget.semanticLabel,
      child: SizedBox(
        height: reserved,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.translate(
              offset: Offset(0, -(overflowUp + extraUp)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: widget.maxWidth,
                  maxHeight: maxH,
                ),
                child: _isSvg
                    ? SvgPicture.network(
                        widget.imageUrl,
                        fit: BoxFit.contain,
                        alignment: widget.alignment,
                        placeholderBuilder: (_) => const SizedBox.shrink(),
                      )
                    : Image.network(
                        widget.imageUrl,
                        fit: BoxFit.contain,
                        alignment: widget.alignment,
                        filterQuality: widget.filterQuality,
                        errorBuilder: (context, __, ___) {
                          final fallback = widget.onErrorFallback;
                          if (fallback != null) return fallback(context);
                          return const SizedBox.shrink();
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _maxHeightForRatio(double? ratio) {
    if (ratio == null) {
      return widget.tallMaxHeight;
    }
    if (ratio >= widget.wideRatioThreshold) {
      return widget.wideMaxHeight;
    }
    if (ratio <= widget.blockyRatioThreshold) {
      return widget.blockyMaxHeight;
    }
    return widget.tallMaxHeight;
  }
}
