import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import '../../../home/presentation/providers/home_providers.dart' as hp;
import '../models/playlist_args.dart';
import '../../../home/presentation/widgets/home_hero_section.dart';
import '../../../../core/utils/app_spacing.dart';
import '../../../../core/widgets/movi_media_card.dart';
import '../../../../core/models/movi_media.dart';

class PlaylistDetailPage extends ConsumerWidget {
  const PlaylistDetailPage({super.key, this.args});

  final PlaylistDetailArgs? args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = args?.title ?? 'Playlist';
    final categoryKey = args?.categoryKey;
    final state = ref.watch(hp.homeControllerProvider);
    final items = (categoryKey != null)
        ? (state.iptvLists[categoryKey] ?? const <ContentReference>[])
        : const <ContentReference>[];
    const double cardWidth = 150;
    const double posterHeight = 226;
    const double textHeight = 20; // hauteur approximative du titre sous l'affiche
    const double textMarginTop = 12; // marge entre affiche et texte
    const double gridGapH = 24; // 24px de gap horizontal au lieu de 16
    const double gridGapV = 16; // gap vertical inchangé
    final double gridWidth = (cardWidth * 2) + gridGapH; // 2 affiches + gap
    final double itemHeight = posterHeight + textMarginTop + textHeight;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // Header: row retour (55 top, 20 left) + titre centré
            SizedBox(
              height: 120,
              child: Stack(
                children: [
                  Positioned(
                    left: 20,
                    top: 75,
                    child: InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset('assets/icons/back.png', width: 35, height: 35),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 80,
                    child: Center(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Grille centrée: largeur exacte = 2 cartes + gap 16
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: gridWidth,
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: gridGapV,
                      crossAxisSpacing: gridGapH,
                      childAspectRatio: cardWidth / itemHeight,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final r = items[index];
                      final poster = r.poster?.toString() ?? '';
                      const String yearStr = '';
                      const String ratingStr = '';
                      final media = MoviMedia(
                        id: r.id,
                        title: r.title.value,
                        poster: poster,
                        year: yearStr,
                        rating: ratingStr,
                        type: r.type == ContentType.series
                            ? MoviMediaType.series
                            : MoviMediaType.movie,
                      );
                      return MoviMediaCard(media: media);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
