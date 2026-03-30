import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/movie/presentation/utils/movie_playback_variant_descriptor_builder.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

void main() {
  const builder = MoviePlaybackVariantDescriptorBuilder();

  test('keeps only useful differences when shared tags are identical', () {
    final descriptors = builder.build(<PlaybackVariant>[
      _variant(
        sourceLabel: 'Salon',
        id: '1',
        qualityLabel: '4K',
        audioLanguageLabel: 'VF',
      ),
      _variant(
        sourceLabel: 'Chambre',
        id: '2',
        qualityLabel: '4K',
        audioLanguageLabel: 'VO',
      ),
    ]);

    expect(descriptors[0].title, 'Version 1');
    expect(descriptors[0].tags, <String>['VF']);
    expect(descriptors[1].title, 'Version 2');
    expect(descriptors[1].tags, <String>['VO']);
  });

  test('adds the source only when it helps to distinguish identical tags', () {
    final descriptors = builder.build(<PlaybackVariant>[
      _variant(
        sourceLabel: 'Salon',
        id: '1',
        qualityLabel: '4K',
        audioLanguageLabel: 'VF',
      ),
      _variant(
        sourceLabel: 'Chambre',
        id: '2',
        qualityLabel: '4K',
        audioLanguageLabel: 'VF',
      ),
    ]);

    expect(descriptors[0].tags, <String>['Salon']);
    expect(descriptors[1].tags, <String>['Chambre']);
  });
}

PlaybackVariant _variant({
  required String sourceLabel,
  required String id,
  String? qualityLabel,
  String? audioLanguageLabel,
  String? subtitleLanguageLabel,
  bool? hasSubtitles,
}) {
  return PlaybackVariant(
    id: 'source-$id:$id',
    sourceId: 'source-$id',
    sourceLabel: sourceLabel,
    videoSource: VideoSource(
      url: 'https://video.example/$id.mp4',
      title: 'The Matrix',
      contentId: '603',
      contentType: ContentType.movie,
    ),
    contentType: ContentType.movie,
    rawTitle: 'The.Matrix.1999',
    normalizedTitle: 'The Matrix',
    qualityLabel: qualityLabel,
    qualityRank: qualityLabel == null ? null : 3,
    audioLanguageLabel: audioLanguageLabel,
    subtitleLanguageLabel: subtitleLanguageLabel,
    hasSubtitles: hasSubtitles,
  );
}
