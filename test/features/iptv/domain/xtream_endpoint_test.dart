import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';

void main() {
  group('XtreamEndpoint.parse / tryParse', () {
    test('parse accepte une URL complète sans chemin', () {
      final endpoint = XtreamEndpoint.parse('http://example.com');
      expect(endpoint.host, 'example.com');
    });

    test('tryParse renvoie null pour une URL invalide', () {
      final endpoint = XtreamEndpoint.tryParse('not a url');
      expect(endpoint, isNull);
    });
  });

  group('XtreamEndpoint.buildUri', () {
    test('ajoute player_api.php sur une URL sans chemin', () {
      final endpoint = XtreamEndpoint.parse('http://example.com');
      final uri = endpoint.buildUri({'username': 'u', 'password': 'p'});
      expect(uri.path, '/player_api.php');
      expect(uri.queryParameters['username'], 'u');
      expect(uri.queryParameters['password'], 'p');
    });

    test('remplace get.php par player_api.php', () {
      final endpoint = XtreamEndpoint.parse(
        'http://example.com/get.php?foo=bar',
      );
      final uri = endpoint.buildUri({'username': 'u'});
      expect(uri.path.toLowerCase(), contains('player_api.php'));
      expect(uri.queryParameters['foo'], 'bar');
      expect(uri.queryParameters['username'], 'u');
    });

    test('préserve player_api.php existant et fusionne les query params', () {
      final endpoint = XtreamEndpoint.parse(
        'http://example.com/player_api.php?existing=1',
      );
      final uri = endpoint.buildUri({'added': '2'});
      expect(uri.path, '/player_api.php');
      expect(uri.queryParameters['existing'], '1');
      expect(uri.queryParameters['added'], '2');
    });
  });
}
