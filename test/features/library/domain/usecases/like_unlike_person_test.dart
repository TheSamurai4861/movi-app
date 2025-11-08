import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/features/library/domain/usecases/like_person.dart';
import 'package:movi/src/features/library/domain/usecases/unlike_person.dart';
import 'package:movi/src/core/storage/repositories/watchlist_local_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

import '../../../../helpers/database_initializer.dart';

void main() {
  setUpAll(() async {
    await initTestDatabase();
  });

  test(
    'LikePerson and UnlikePerson update watchlist for person type',
    () async {
      const id = PersonId('287');
      final repo = const WatchlistLocalRepositoryImpl();
      final like = LikePerson(repo);
      final unlike = UnlikePerson(repo);

      // Ensure clean state
      await repo.remove(id.value, ContentType.person);
      expect(await repo.exists(id.value, ContentType.person), isFalse);

      await like(
        id: id,
        name: 'Brad Pitt',
        photo: Uri.parse('https://image.tmdb.org/t/p/w500/brad.jpg'),
      );
      expect(await repo.exists(id.value, ContentType.person), isTrue);

      await unlike(id);
      expect(await repo.exists(id.value, ContentType.person), isFalse);
    },
  );
}
