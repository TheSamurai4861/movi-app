import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:movi/src/features/movie/domain/entities/movie.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/data/services/xtream_lookup_service.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await sl.reset();
  });

  test(
    'movieDetailControllerProvider falls back to Xtream data when TMDB detail load fails',
    () async {
      final localePreferences = _MemoryLocalePreferences();
      final logger = _MemoryLogger();
      final iptvLocal = _FakeIptvLocalRepository(
        accounts: <XtreamAccount>[
          XtreamAccount(
            id: 'xtream-a',
            alias: 'Salon',
            endpoint: XtreamEndpoint.parse('https://provider.example'),
            username: 'demo',
            status: XtreamAccountStatus.active,
            createdAt: DateTime(2026, 3, 30),
          ),
        ],
        playlistsByAccount: <String, List<XtreamPlaylist>>{
          'xtream-a': <XtreamPlaylist>[
            const XtreamPlaylist(
              id: 'playlist-a',
              accountId: 'xtream-a',
              title: 'Movies',
              type: XtreamPlaylistType.movies,
              items: <XtreamPlaylistItem>[
                XtreamPlaylistItem(
                  accountId: 'xtream-a',
                  categoryId: 'movies',
                  categoryName: 'Movies',
                  streamId: 99,
                  title: 'Inception',
                  type: XtreamPlaylistItemType.movie,
                  overview: 'Dreams within dreams.',
                  posterUrl: 'https://provider.example/posters/inception.jpg',
                  containerExtension: 'mp4',
                  rating: 8.8,
                  releaseYear: 2010,
                  tmdbId: 27205,
                ),
              ],
            ),
          ],
        },
      );

      sl.registerSingleton<LocalePreferences>(localePreferences);
      sl.registerSingleton<AppLogger>(logger);
      sl.registerSingleton<XtreamLookupService>(
        XtreamLookupService(iptvLocal: iptvLocal, logger: logger),
      );
      sl.registerSingleton<TmdbImageResolver>(const TmdbImageResolver());

      final container = ProviderContainer(
        overrides: [
          movieRepositoryProvider.overrideWithValue(_FailingMovieRepository()),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(localePreferences.dispose);

      container.read(appStateControllerProvider).setActiveIptvSources({
        'xtream-a',
      });

      final detail = await container.read(
        movieDetailControllerProvider('xtream:99').future,
      );

      expect(detail.title, 'Inception');
      expect(detail.yearText, '2010');
      expect(detail.durationText, '—');
      expect(detail.ratingText, '8.8');
      expect(detail.overviewText, 'Dreams within dreams.');
      expect(
        detail.poster,
        Uri.parse('https://provider.example/posters/inception.jpg'),
      );
      expect(
        logger.events.any(
          (event) =>
              event.level == LogLevel.warn &&
              event.message.contains('Failed to load TMDB movie'),
        ),
        isTrue,
      );
    },
  );
}

class _FailingMovieRepository implements MovieRepository {
  @override
  Future<Movie> getMovie(MovieId id) async {
    throw StateError('TMDB unavailable');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call: $invocation');
  }
}

class _FakeIptvLocalRepository implements IptvLocalRepository {
  _FakeIptvLocalRepository({
    this.accounts = const <XtreamAccount>[],
    this.playlistsByAccount = const <String, List<XtreamPlaylist>>{},
  });

  final List<XtreamAccount> accounts;
  final Map<String, List<XtreamPlaylist>> playlistsByAccount;

  @override
  Future<List<XtreamAccount>> getAccounts() async => accounts;

  @override
  Future<List<StalkerAccount>> getStalkerAccounts() async =>
      const <StalkerAccount>[];

  @override
  Future<List<XtreamPlaylist>> getPlaylists(
    String accountId, {
    int? itemLimit,
  }) async {
    return playlistsByAccount[accountId] ?? const <XtreamPlaylist>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call: $invocation');
  }
}

class _MemoryLogger implements AppLogger {
  final List<LogEvent> events = <LogEvent>[];

  @override
  void debug(String message, {String? category}) {
    log(LogLevel.debug, message, category: category);
  }

  @override
  void info(String message, {String? category}) {
    log(LogLevel.info, message, category: category);
  }

  @override
  void warn(String message, {String? category}) {
    log(LogLevel.warn, message, category: category);
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {
    events.add(
      LogEvent(
        timestamp: DateTime(2026, 3, 30),
        level: level,
        message: message,
        category: category,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}

class _MemoryLocalePreferences implements LocalePreferences {
  final StreamController<String> _languageController =
      StreamController<String>.broadcast();
  final StreamController<ThemeMode> _themeController =
      StreamController<ThemeMode>.broadcast();

  String _languageCode = 'en-US';
  ThemeMode _themeMode = ThemeMode.system;

  @override
  String get languageCode => _languageCode;

  @override
  Stream<String> get languageStream => _languageController.stream;

  @override
  Stream<String> get languageStreamWithInitial async* {
    yield _languageCode;
    yield* _languageController.stream;
  }

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  Stream<ThemeMode> get themeStream => _themeController.stream;

  @override
  Stream<ThemeMode> get themeStreamWithInitial async* {
    yield _themeMode;
    yield* _themeController.stream;
  }

  @override
  Future<void> setLanguageCode(String code) async {
    _languageCode = code;
    _languageController.add(code);
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _themeController.add(mode);
  }

  @override
  Future<void> dispose() async {
    await _languageController.close();
    await _themeController.close();
  }
}
