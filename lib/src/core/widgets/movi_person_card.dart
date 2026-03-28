import 'package:flutter/material.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/widgets/movi_marquee_text.dart';
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
    return Image.network(
      poster.toString(),
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => errorPlaceholder,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      cacheWidth: (width * 2).toInt(),
      cacheHeight: (height * 2).toInt(),
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

  const MoviPersonCard({
    super.key,
    required this.person,
    this.width = 150,
    this.height = 225,
    this.onTap,
    this.heroTag,
  });

  final MoviPerson person;
  final double width;
  final double height;
  final ValueChanged<MoviPerson>? onTap;
  final Object? heroTag;

  @override
  State<MoviPersonCard> createState() => _MoviPersonCardState();
}

class _MoviPersonCardState extends State<MoviPersonCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
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
        onTap: widget.onTap == null
            ? null
            : () => widget.onTap?.call(widget.person),
        onFocusChange: (focused) {
          if (_focused == focused) return;
          setState(() => _focused = focused);
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedScale(
          scale: _focused ? 1.035 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: widget.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _focused ? focusBorderColor : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: _focused
                        ? [
                            BoxShadow(
                              color: focusBorderColor.withValues(alpha: 0.18),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: _buildPoster(context),
                ),
                const SizedBox(height: 12),
                MoviMarqueeText(
                  text: widget.person.name,
                  style: nameStyle,
                  maxWidth: widget.width,
                ),
                const SizedBox(height: 4),
                MoviMarqueeText(
                  text: widget.person.role,
                  style: roleStyle,
                  maxWidth: widget.width,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoster(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: _buildPersonImage(
          widget.person.poster,
          widget.width,
          widget.height,
          placeholderType: PlaceholderType.person,
        ),
      ),
    );
    if (widget.heroTag == null) return image;
    return Hero(tag: widget.heroTag!, child: image);
  }
}
