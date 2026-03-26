import 'package:flutter/widgets.dart';
import 'package:movi/src/core/widgets/widgets.dart';

class MovieHeroImage extends StatelessWidget {
  const MovieHeroImage({
    super.key,
    this.posterBackground,
    this.poster,
    this.backdrop,
  });

  final Uri? posterBackground;
  final Uri? poster;
  final Uri? backdrop;

  @override
  Widget build(BuildContext context) {
    return MoviHeroBackground(
      posterBackground: posterBackground?.toString(),
      poster: poster?.toString(),
      backdrop: backdrop?.toString(),
      placeholderType: PlaceholderType.movie,
      imageStrategy: MoviHeroImageStrategy.backdropFirst,
    );
  }
}
