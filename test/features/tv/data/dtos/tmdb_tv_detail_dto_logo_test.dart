import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
import 'package:movi/src/shared/domain/services/tmdb_image_selector_service.dart';

Map<String, dynamic> _minimalTvJson({
  required List<Map<String, Object?>> logos,
  List<Map<String, Object?>> cast = const [],
  bool logoPngExhausted = false,
  String preferredImageLang = 'en',
}) {
  return {
    'id': 99,
    'name': 'Test Show',
    'overview': 'Overview',
    'poster_path': '/poster.png',
    'backdrop_path': '/bd.jpg',
    'first_air_date': '2020-01-01',
    'status': 'Ended',
    'vote_average': 8.0,
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
    '__movi_preferred_image_lang': preferredImageLang,
    if (logoPngExhausted) '__movi_logo_png_exhausted': true,
  };
}

void main() {
  group('TmdbTvDetailDto logo', () {
    test('fromJson uses TmdbImageSelectorService rules (PNG wide logo)', () {
      final logos = <Map<String, Object?>>[
        {
          'file_path': '/wide_en.png',
          'iso_639_1': 'en',
          'vote_average': 5.0,
          'width': 400,
          'height': 100,
        },
      ];
      final expected = TmdbImageSelectorService.selectLogoPath(
        logos,
        preferredLang: 'fr',
      );
      final dto = TmdbTvDetailDto.fromJson(
        _minimalTvJson(logos: logos, preferredImageLang: 'fr'),
      );
      expect(dto.logoPath, expected);
      expect(dto.logoPath, '/wide_en.png');
    });

    test('toCache round-trips __movi_logo_png_exhausted', () {
      final dto = TmdbTvDetailDto.fromJson(
        _minimalTvJson(
          logos: const <Map<String, Object?>>[],
          logoPngExhausted: true,
        ),
      );
      expect(dto.logoPngExhausted, isTrue);
      final again = TmdbTvDetailDto.fromCache(dto.toCache());
      expect(again.logoPngExhausted, isTrue);
    });

    test('copyWith can set logoPath without dropping exhausted flag', () {
      final base = TmdbTvDetailDto.fromJson(
        _minimalTvJson(
          logos: const <Map<String, Object?>>[],
          logoPngExhausted: true,
        ),
      );
      final withLogo = base.copyWith(logoPath: '/merged.png');
      expect(withLogo.logoPath, '/merged.png');
      expect(withLogo.logoPngExhausted, isTrue);
    });
  });
}
