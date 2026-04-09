import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/storage/repositories/history_local_repository.dart';
import 'package:movi/src/features/library/data/repositories/hybrid_playback_history_repository.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

final class _LocalFake implements HistoryLocalRepository {
  @override
  Future<void> upsertPlay({
    required String contentId,
    required ContentType type,
    required String title,
    Uri? poster,
    DateTime? playedAt,
    Duration? position,
    Duration? duration,
    int? season,
    int? episode,
    String userId = 'default',
  }) async {}

  @override
  Future<void> remove(
    String contentId,
    ContentType type, {
    String userId = 'default',
  }) async {}

  @override
  Future<List<HistoryEntry>> readAll(
    ContentType type, {
    String userId = 'default',
  }) async {
    return const <HistoryEntry>[];
  }

  @override
  Future<HistoryEntry?> getSeriesResumeState(
    String seriesId, {
    String userId = 'default',
  }) async {
    return null;
  }

  @override
  Future<HistoryEntry?> getEntry(
    String contentId,
    ContentType type, {
    int? season,
    int? episode,
    String userId = 'default',
  }) async {
    return null;
  }
}

void main() {
  test(
    'hybrid persist debug log does not include userId/email/token',
    () async {
      final repo = HybridPlaybackHistoryRepository(
        local: _LocalFake(),
        defaultUserId: 'user@example.com',
        remote: null,
      );

      final prints = <String>[];

      await runZoned(
        () async {
          await repo.upsertPlay(
            contentId: 'movie-123',
            type: ContentType.movie,
            title: 'Test',
            position: const Duration(seconds: 10),
            duration: const Duration(minutes: 10),
            userId: 'user@example.com',
          );
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) {
            prints.add(line);
          },
        ),
      );

      final blob = prints.join('\n').toLowerCase();
      expect(blob.contains('userid='), isFalse);
      expect(blob.contains('@'), isFalse);
      expect(blob.contains('token'), isFalse);
      expect(blob.contains('password'), isFalse);
    },
  );
}
