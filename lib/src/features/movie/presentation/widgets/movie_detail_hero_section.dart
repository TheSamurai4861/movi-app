import 'package:flutter/material.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/features/movie/presentation/widgets/movie_hero_image.dart';

class MovieDetailHeroSection extends StatelessWidget {
  const MovieDetailHeroSection({
    super.key,
    this.poster,
    this.backdrop,
    required this.onBack,
    required this.onMore,
    this.height = 400,
    this.overlayHeight = 200,
  });

  final Uri? poster;
  final Uri? backdrop;
  final VoidCallback onBack;
  final VoidCallback onMore;
  final double height;
  final double overlayHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MovieHeroImage(poster: poster, backdrop: backdrop),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF141414), Color(0x00000000)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onBack,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 35,
                        height: 35,
                        child: Image(image: AssetImage(AppAssets.iconBack)),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 25,
                  height: 35,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onMore,
                    child: const Image(image: AssetImage(AppAssets.iconMore)),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: overlayHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xFF141414)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
