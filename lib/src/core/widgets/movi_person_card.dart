import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/models/models.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/widgets/movi_marquee_text.dart';

Image _buildPersonImage(String source, double width, double height) {
  final errorPlaceholder = Container(
    width: width,
    height: height,
    color: const Color(0xFF222222),
    child: const Center(
      child: Icon(Icons.broken_image, size: 32, color: Colors.white54),
    ),
  );

  if (source.startsWith('http')) {
    return Image.network(
      source,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => errorPlaceholder,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
    );
  }

  return Image.asset(
    source,
    width: width,
    height: height,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => errorPlaceholder,
  );
}

/// Card representing a person (actor, director…). Shares dimensions with media cards.
class MoviPersonCard extends StatelessWidget {
  const MoviPersonCard({
    super.key,
    required this.person,
    this.width = 150,
    this.height = 225,
  });

  final MoviPerson person;
  final double width;
  final double height;

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
      onTap: () => context.push(AppRouteNames.person),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: width,
                height: height,
                child: _buildPersonImage(person.poster, width, height),
              ),
            ),
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
}
