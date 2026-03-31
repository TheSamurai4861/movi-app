import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/performance/domain/performance_diagnostic_logger.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/responsive/presentation/widgets/responsive_layout.dart';
import 'package:movi/src/features/home/presentation/widgets/home_hero_carousel.dart';
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/shared/data/services/tmdb_cache_data_source.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/services/tmdb_id_resolver_service.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

void main() {
  testWidgets(
    'mounts inside ResponsiveLayout without inherited widget access during initState',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final locator = GetIt.asNewInstance();
      locator.registerSingleton<TmdbCacheDataSource>(
        _FakeTmdbCacheDataSource(),
      );
      locator.registerSingleton<TmdbImageResolver>(const TmdbImageResolver());
      locator.registerSingleton<TmdbMovieRemoteDataSource>(
        _FakeTmdbMovieRemoteDataSource(),
      );
      locator.registerSingleton<TmdbTvRemoteDataSource>(
        _FakeTmdbTvRemoteDataSource(),
      );
      locator.registerSingleton<TmdbIdResolverService>(
        _FakeTmdbIdResolverService(),
      );
      locator.registerSingleton<LocalePreferences>(_FakeLocalePreferences());
      locator.registerSingleton<PerformanceDiagnosticLogger>(
        PerformanceDiagnosticLogger(_SilentLogger()),
      );
      addTearDown(() async {
        await locator.reset();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [slProvider.overrideWithValue(locator)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ResponsiveLayout(
              child: Scaffold(
                body: HomeHeroCarousel(
                  items: <ContentReference>[
                    ContentReference(
                      id: 'local-invalid-id',
                      title: MediaTitle('Smoke Test Hero'),
                      type: ContentType.movie,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeHeroCarousel), findsOneWidget);
    },
  );
}

class _FakeTmdbCacheDataSource implements TmdbCacheDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTmdbMovieRemoteDataSource implements TmdbMovieRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTmdbTvRemoteDataSource implements TmdbTvRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTmdbIdResolverService implements TmdbIdResolverService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocalePreferences implements LocalePreferences {
  @override
  String get languageCode => 'en-US';

  @override
  Stream<String> get languageStream => const Stream<String>.empty();

  @override
  Stream<String> get languageStreamWithInitial async* {
    yield languageCode;
  }

  @override
  ThemeMode get themeMode => ThemeMode.system;

  @override
  Stream<ThemeMode> get themeStream => const Stream<ThemeMode>.empty();

  @override
  Stream<ThemeMode> get themeStreamWithInitial async* {
    yield themeMode;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SilentLogger implements AppLogger {
  @override
  void debug(String message, {String? category}) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void info(String message, {String? category}) {}

  @override
  void log(
    LogLevel level,
    String message, {
    String? category,
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  void warn(String message, {String? category}) {}
}
