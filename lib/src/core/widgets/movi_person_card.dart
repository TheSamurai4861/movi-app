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
class MoviPersonCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nameStyle =
        theme.textTheme.titleSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        );
    final roleStyle =
        theme.textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: const Color(0xFFA6A6A6),
        ) ??
        const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFFA6A6A6),
        );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap?.call(person),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPoster(context),
            const SizedBox(height: 12),
            MoviMarqueeText(
              text: person.name,
              style: nameStyle,
              maxWidth: width,
            ),
            const SizedBox(height: 4),
            MoviMarqueeText(
              text: person.role,
              style: roleStyle,
              maxWidth: width,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: width,
        height: height,
        child: _buildPersonImage(
          person.poster,
          width,
          height,
          placeholderType: PlaceholderType.person,
        ),
      ),
    );
    if (heroTag == null) return image;
    return Hero(tag: heroTag!, child: image);
  }
}
