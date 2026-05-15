import 'package:flutter/material.dart';
import 'package:movi/src/core/responsive/presentation/extensions/tv_ui_scale_context.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/widgets/movi_marquee_text.dart';
import 'package:movi/src/core/widgets/movi_network_image.dart';
import 'package:movi/src/core/widgets/movi_placeholder_card.dart';

Widget _buildPersonImage(
  Uri? poster,
  double width,
  double height, {
  PlaceholderType? placeholderType,
}) {
  final Widget errorPlaceholder = (placeholderType == null)
      ? Container(
          width: width,
          height: height,
          color: const Color(0xFF222222),
          child: const Center(
            child: Icon(Icons.broken_image, size: 32, color: Colors.white54),
          ),
        )
      : MoviPlaceholderCard(
          type: placeholderType,
          width: width,
          height: height,
        );

  if (poster == null) return errorPlaceholder;
  final source = poster.toString().trim();
  if (source.isEmpty) return errorPlaceholder;
  final scheme = poster.scheme.toLowerCase();
  if (scheme == 'http' || scheme == 'https') {
    return MoviNetworkImage(
      poster.toString(),
      width: width,
      height: height,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      cacheWidth: (width * 2).toInt(),
      cacheHeight: (height * 2).toInt(),
      errorBuilder: (_, __, ___) => errorPlaceholder,
    );
  }
  final assetPath = scheme == 'asset' ? poster.path : source;

  return Image.asset(
    assetPath,
    width: width,
    height: height,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => errorPlaceholder,
    cacheWidth: (width * 2).toInt(),
    cacheHeight: (height * 2).toInt(),
  );
}

/// Card representing a person (actor, director…). Shares dimensions with media cards.
class MoviPersonCard extends StatefulWidget {
  static const double listHeight = 286;

  static double listHeightForScale(double scale) => listHeight * scale;

  const MoviPersonCard({
    super.key,
    required this.person,
    this.width = 150,
    this.height = 225,
    this.onTap,
    this.heroTag,
    this.focusNode,
  });

  final MoviPerson person;
  final double width;
  final double height;
  final ValueChanged<MoviPerson>? onTap;
  final Object? heroTag;
  final FocusNode? focusNode;

  @override
  State<MoviPersonCard> createState() => _MoviPersonCardState();
}

class _MoviPersonCardState extends State<MoviPersonCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final uiScale = context.tvUiScale;
    final scaledWidth = widget.width * uiScale;
    final scaledHeight = widget.height * uiScale;
    final focusRadius = 18.0 * uiScale;
    final focusBorderWidth = 2.0 * uiScale;
    final focusBlurRadius = 18.0 * uiScale;
    final focusSpreadRadius = 2.0 * uiScale;
    final nameRoleGap = 12.0 * uiScale;
    final roleGap = 4.0 * uiScale;
    final theme = Theme.of(context);
    final focusBorderColor = theme.colorScheme.primary;
    final nameStyle =
        theme.textTheme.titleSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ) ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.2,
        );
    final roleStyle =
        theme.textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFA6A6A6),
          height: 1.2,
        ) ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFFA6A6A6),
          height: 1.2,
        );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        focusNode: widget.focusNode,
        onTap: widget.onTap == null
            ? null
            : () => widget.onTap?.call(widget.person),
        onFocusChange: (focused) {
          if (_focused == focused) return;
          setState(() => _focused = focused);
        },
        borderRadius: BorderRadius.circular(focusRadius),
        child: AnimatedScale(
          scale: _focused ? 1.035 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: scaledWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.all(focusBorderWidth),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(focusRadius),
                    border: Border.all(
                      color: _focused ? focusBorderColor : Colors.transparent,
                      width: focusBorderWidth,
                    ),
                    boxShadow: _focused
                        ? [
                            BoxShadow(
                              color: focusBorderColor.withValues(alpha: 0.18),
                              blurRadius: focusBlurRadius,
                              spreadRadius: focusSpreadRadius,
                            ),
                          ]
                        : null,
                  ),
                  child: _buildPoster(
                    context,
                    width: scaledWidth,
                    height: scaledHeight,
                    uiScale: uiScale,
                  ),
                ),
                SizedBox(height: nameRoleGap),
                MoviMarqueeText(
                  text: widget.person.name,
                  style: nameStyle,
                  maxWidth: scaledWidth,
                ),
                SizedBox(height: roleGap),
                MoviMarqueeText(
                  text: widget.person.role,
                  style: roleStyle,
                  maxWidth: scaledWidth,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoster(
    BuildContext context, {
    required double width,
    required double height,
    required double uiScale,
  }) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(16 * uiScale),
      child: SizedBox(
        width: width,
        height: height,
        child: _buildPersonImage(
          widget.person.poster,
          width,
          height,
          placeholderType: PlaceholderType.person,
        ),
      ),
    );
    if (widget.heroTag == null) return image;
    return Hero(tag: widget.heroTag!, child: image);
  }
}
