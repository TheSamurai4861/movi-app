import 'package:flutter/widgets.dart';
import 'package:movi/src/core/widgets/widgets.dart';

class MovieHeroImage extends StatelessWidget {
  const MovieHeroImage({super.key, this.poster, this.backdrop});

  final Uri? poster;
  final Uri? backdrop;

  @override
  Widget build(BuildContext context) {
    final uri = poster ?? backdrop;
    if (uri == null) {
      return const MoviPlaceholderCard(
        type: PlaceholderType.movie,
        fit: BoxFit.cover,
        alignment: Alignment(0.0, -0.5),
        borderRadius: BorderRadius.zero,
      );
    }
    final mq = MediaQuery.of(context);
    final rawPx = (mq.size.width * mq.devicePixelRatio).round();
    final cacheWidth = rawPx.clamp(480, 1920);
    return Image.network(
      uri.toString(),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.medium,
      alignment: const Alignment(0.0, -0.5),
    );
  }
}
