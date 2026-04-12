import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
import 'package:movi/src/features/tv/data/repositories/tv_repository_impl.dart';

Map<String, dynamic> _minimalTvJson({
  required List<Map<String, Object?>> logos,
  List<Map<String, Object?>> cast = const [],
  bool logoPngExhausted = false,
  bool castExhausted = false,
}) {
  return {
    'id': 42,
    'name': 'Show',
    'overview': 'O',
    'poster_path': '/p.png',
    'backdrop_path': '/b.jpg',
    'first_air_date': '2021-01-01',
    'status': 'Returning',
    'vote_average': 7.0,
    'genres': <Map<String, String>>[],
    'credits': {
      'cast': cast,
      'crew': <Map<String, Object?>>[],
    },
    'seasons': <Map<String, Object?>>[
      {
        'id': 1,
        'name': 'S1',
        'overview': '',
        'poster_path': null,
        'air_date': null,
        'season_number': 1,
        'episode_count': 1,
      },
    ],
    'recommendations': {'results': <Map<String, Object?>>[]},
    'images': {'logos': logos},
    '__movi_preferred_image_lang': 'en',
    if (logoPngExhausted) '__movi_logo_png_exhausted': true,
    if (castExhausted) '__movi_cast_exhausted': true,
  };
}

void main() {
  group('TvRepositoryImpl.cacheSatisfiesFullShowLoad', () {
    test('false when cast present but no logo and not exhausted (hero vs fiche bug)',
        () {
      final dto = TmdbTvDetailDto.fromJson(
        _minimalTvJson(
          logos: const [],
          cast: [
            {
              'id': 1,
              'name': 'Actor',
              'character': 'X',
              'profile_path': null,
            },
          ],
        ),
      );
      expect(dto.cast, isNotEmpty);
      expect(dto.logoPath, isNull);
      expect(dto.logoPngExhausted, isFalse);
      expect(TvRepositoryImpl.cacheSatisfiesFullShowLoad(dto), isFalse);
    });

    test('false when logoPath is set but cast is empty', () {
      final dto = TmdbTvDetailDto.fromJson(
        _minimalTvJson(
          logos: [
            {
              'file_path': '/l.png',
              'iso_639_1': 'en',
              'vote_average': 1.0,
              'width': 300,
              'height': 100,
            },
          ],
        ),
      );
      expect(dto.logoPath, isNotNull);
      expect(dto.cast, isEmpty);
      expect(TvRepositoryImpl.cacheSatisfiesFullShowLoad(dto), isFalse);
    });

    test('true when logoPath is set and cast is present', () {
      final dto = TmdbTvDetailDto.fromJson(
        _minimalTvJson(
          logos: [
            {
              'file_path': '/l.png',
              'iso_639_1': 'en',
              'vote_average': 1.0,
              'width': 300,
              'height': 100,
            },
          ],
          cast: [
            {
              'id': 1,
              'name': 'Actor',
              'character': 'X',
              'profile_path': null,
            },
          ],
        ),
      );
      expect(dto.logoPath, isNotNull);
      expect(dto.cast, isNotEmpty);
      expect(TvRepositoryImpl.cacheSatisfiesFullShowLoad(dto), isTrue);
    });

    test('true when logo and cast are both exhausted (stops refetch loop)', () {
      final dto = TmdbTvDetailDto.fromJson(
        _minimalTvJson(
          logos: const [],
          logoPngExhausted: true,
          castExhausted: true,
        ),
      );
      expect(dto.logoPath, isNull);
      expect(dto.cast, isEmpty);
      expect(TvRepositoryImpl.cacheSatisfiesFullShowLoad(dto), isTrue);
    });
  });
}
