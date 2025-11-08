
import '../../../core/config/models/app_config.dart';
import '../../../core/network/network_executor.dart';
import '../../../core/preferences/locale_preferences.dart';

class TmdbClient {
  TmdbClient(
    this._executor,
    this._config,
    this._localePreferences,
  );

  final NetworkExecutor _executor;
  final AppConfig _config;
  final LocalePreferences _localePreferences;

  static const _host = 'api.themoviedb.org';
  static const _version = '3';

  Future<R> get<R>({
    required String path,
    Map<String, dynamic>? query,
    required R Function(Map<String, dynamic> json) mapper,
  }) {
    final apiKey = _config.network.tmdbApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('TMDB API key is missing from configuration.');
    }
    final params = <String, dynamic>{
      'api_key': apiKey,
      'language': _localePreferences.languageCode,
      ...?query,
    };

    final uri = Uri.https(_host, '/$_version/$path', params.map((k, v) => MapEntry(k, '$v')));

    return _executor.run<Map<String, dynamic>, R>(
      request: (client) => client.getUri<Map<String, dynamic>>(uri),
      mapper: mapper,
    );
  }

  Future<Map<String, dynamic>> getJson(String path, {Map<String, dynamic>? query}) {
    return get<Map<String, dynamic>>(path: path, query: query, mapper: (json) => json);
  }
}
