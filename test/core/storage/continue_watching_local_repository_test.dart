import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/storage/repositories/continue_watching_local_repository.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

import '../../helpers/database_initializer.dart';

void main() {
  setUpAll(() async {
    await initTestDatabase();
  });

  test('continue watching upsert/list/remove', () async {
    final repo = const ContinueWatchingLocalRepositoryImpl();

    final now = DateTime.now();
    await repo.upsert(
      ContinueWatchingEntry(
        contentId: '550',
        type: ContentType.movie,
        title: 'Fight Club',
        poster: Uri.parse('https://image.tmdb.org/t/p/w500/poster1.jpg'),
        position: const Duration(minutes: 42),
        duration: const Duration(minutes: 139),
        updatedAt: now,
      ),
    );
    await repo.upsert(
      ContinueWatchingEntry(
        contentId: '1399',
        type: ContentType.series,
        title: 'Game of Thrones',
        poster: Uri.parse('https://image.tmdb.org/t/p/w500/poster2.jpg'),
        position: const Duration(minutes: 10),
        duration: const Duration(minutes: 55),
        season: 1,
        episode: 2,
        updatedAt: now.add(const Duration(minutes: 1)),
      ),
    );

    final movies = await repo.readAll(ContentType.movie);
    expect(movies.length, 1);
    expect(movies.first.contentId, '550');

    final shows = await repo.readAll(ContentType.series);
    expect(shows.length, 1);
    expect(shows.first.season, 1);
    expect(shows.first.episode, 2);

    await repo.remove('550', ContentType.movie);
    final moviesAfter = await repo.readAll(ContentType.movie);
    expect(moviesAfter, isEmpty);
  });
}

