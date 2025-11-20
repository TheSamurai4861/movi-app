import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/player/data/repositories/media_kit_video_player_repository.dart';

void main() {
  group('MediaKitVideoPlayerRepository', () {
    // No media_kit initialization required for pure utility tests
    test('toEngineVolume clamps and scales', () {
      expect(MediaKitVideoPlayerRepository.toEngineVolume(-1.0), 0.0);
      expect(MediaKitVideoPlayerRepository.toEngineVolume(0.0), 0.0);
      expect(MediaKitVideoPlayerRepository.toEngineVolume(0.5), 50.0);
      expect(MediaKitVideoPlayerRepository.toEngineVolume(1.0), 100.0);
      expect(MediaKitVideoPlayerRepository.toEngineVolume(2.0), 100.0);
    });

    // Engine-dependent behavior is covered in integration; keep unit tests pure
  });
}