import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
import 'package:movi/src/features/tv/presentation/models/tv_detail_view_model.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/synopsis.dart';

void main() {
  test('fromDomain builds cast from actors only and deduplicates by person id', () {
    final detail = TvShow(
      id: SeriesId('42'),
      tmdbId: 42,
      title: MediaTitle('Series'),
      synopsis: Synopsis('Overview'),
      poster: Uri.parse('https://image.tmdb.org/t/p/w780/poster.jpg'),
      cast: <PersonSummary>[
        PersonSummary(
          id: PersonId('1'),
          tmdbId: 1,
          name: 'Actor One',
          role: null,
          photo: Uri.parse('https://image.tmdb.org/t/p/w185/a1.jpg'),
        ),
        PersonSummary(
          id: PersonId('1'),
          tmdbId: 1,
          name: 'Actor One Duplicate',
          role: 'Lead',
          photo: Uri.parse('https://image.tmdb.org/t/p/w185/a1b.jpg'),
        ),
        PersonSummary(
          id: PersonId('2'),
          tmdbId: 2,
          name: 'Actor Two',
          role: 'Support',
          photo: Uri.parse('https://image.tmdb.org/t/p/w185/a2.jpg'),
        ),
      ],
      creators: <PersonSummary>[
        PersonSummary(
          id: PersonId('10'),
          tmdbId: 10,
          name: 'Creator One',
          role: 'Creator',
        ),
      ],
    );

    final vm = TvDetailViewModel.fromDomain(detail: detail, language: 'en-US');

    expect(vm.cast, hasLength(2));
    expect(
      vm.cast.map((p) => p.name),
      containsAll(<String>['Actor One', 'Actor Two']),
    );
    expect(vm.cast.map((p) => p.name), isNot(contains('Creator One')));
    expect(vm.cast.first.role, 'Actor');
  });
}
