import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/player/domain/entities/playback_launch_plan.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/shared/domain/services/media_resume_decision.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

void main() {
  test('builds a source with the canonical target and resume position', () {
    const plan = PlaybackLaunchPlan(
      contentType: ContentType.series,
      targetContentId: '37854',
      season: 2,
      episode: 15,
      resumePosition: Duration(minutes: 7),
      reasonCode: ResumeReasonCode.applied,
      isResumeEligible: true,
    );

    final source = plan.buildVideoSource(
      source: const VideoSource(
        url: 'https://provider.example/series/stream.mkv',
        title: 'Provider title',
        contentId: 'provider-id',
        contentType: ContentType.series,
        season: 99,
        episode: 99,
      ),
      title: 'One Piece - S02E15',
    );

    expect(source.url, 'https://provider.example/series/stream.mkv');
    expect(source.title, 'One Piece - S02E15');
    expect(source.contentId, '37854');
    expect(source.contentType, ContentType.series);
    expect(source.season, 2);
    expect(source.episode, 15);
    expect(source.resumePosition, const Duration(minutes: 7));
  });

  test('resets resume position when start from beginning is requested', () {
    const plan = PlaybackLaunchPlan(
      contentType: ContentType.movie,
      targetContentId: '603',
      resumePosition: Duration(minutes: 12),
      reasonCode: ResumeReasonCode.applied,
      isResumeEligible: true,
    );

    final source = plan.buildVideoSource(
      source: const VideoSource(
        url: 'https://provider.example/movie/stream.mp4',
        contentId: 'provider-id',
        contentType: ContentType.movie,
      ),
      startFromBeginning: true,
    );

    expect(source.contentId, '603');
    expect(source.contentType, ContentType.movie);
    expect(source.resumePosition, Duration.zero);
  });
}
