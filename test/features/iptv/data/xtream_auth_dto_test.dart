import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/iptv/data/dtos/xtream_auth_dto.dart';

void main() {
  group('XtreamAuthDto.fromJson', () {
    test('parse un user_info complet avec expiration', () {
      final dto = XtreamAuthDto.fromJson({
        'user_info': {
          'status': 'Active',
          'message': 'OK',
          'exp_date': '1700000000',
        },
      });

      expect(dto.status, 'Active');
      expect(dto.message, 'OK');
      expect(dto.expiration, isNotNull);
      expect(dto.isAuthorized, isTrue);
    });

    test('gère une réponse partielle sans user_info', () {
      final dto = XtreamAuthDto.fromJson({});

      expect(dto.status, isNotEmpty);
      expect(dto.message, isA<String>());
      expect(dto.expiration, isNull);
    });

    test('gère un exp_date nul ou 0', () {
      final dtoNull = XtreamAuthDto.fromJson({
        'user_info': {'exp_date': null},
      });
      final dtoZero = XtreamAuthDto.fromJson({
        'user_info': {'exp_date': 0},
      });

      expect(dtoNull.expiration, isNull);
      expect(dtoZero.expiration, isNull);
    });
  });
}
