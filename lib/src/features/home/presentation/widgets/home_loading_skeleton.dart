import 'package:flutter/material.dart';
import 'package:movi/src/features/home/presentation/widgets/home_layout_constants.dart';

/// Widget affichant un skeleton de chargement pour les sections IPTV.
class HomeLoadingSkeleton extends StatelessWidget {
  const HomeLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: HomeLayoutConstants.mediaCardWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: HomeLayoutConstants.mediaCardWidth,
              height: HomeLayoutConstants.mediaCardPosterHeight,
              child: const ColoredBox(color: Color(0xFF222222)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: HomeLayoutConstants.mediaCardWidth * 0.8,
            height: 16,
            child: const ColoredBox(color: Color(0xFF333333)),
          ),
        ],
      ),
    );
  }
}
