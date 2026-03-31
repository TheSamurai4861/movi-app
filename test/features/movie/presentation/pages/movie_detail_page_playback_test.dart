import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/performance/domain/performance_diagnostic_logger.dart';
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/movie/presentation/models/movie_detail_view_model.dart';
import 'package:movi/src/features/movie/presentation/pages/movie_detail_page.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart'
    as mdp;
import 'package:movi/src/features/movie/presentation/widgets/movie_playback_variant_sheet.dart';
import 'package:movi/src/features/player/domain/entities/playback_selection_decision.dart';
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'Watch launches directly when playback selection is unambiguous',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final logger = _SilentLogger();
      sl.registerSingleton<AppLogger>(logger);
      sl.registerSingleton<PerformanceDiagnosticLogger>(
        PerformanceDiagnosticLogger(logger),
      );

      final container = ProviderContainer(
        overrides: [
          currentProfileProvider.overrideWithValue(null),
          mdp.movieDetailControllerProvider.overrideWith(
            (ref, movieId) async => _movieViewModel(),
          ),
          mdp.moviePlaybackSelectionProvider.overrideWith(
            (ref, args) async => PlaybackSelectionDecision(
              disposition: PlaybackSelectionDisposition.autoPlay,
              reason: PlaybackSelectionReason.singlePlayableVariant,
              rankedVariants: <PlaybackVariant>[_variant('Salon', '1')],
              selectedVariant: _variant('Salon', '1'),
            ),
          ),
          mdp.movieAvailabilityOnIptvProvider.overrideWith(
            (ref, movieId) async => true,
          ),
          mdp.movieIsFavoriteProvider.overrideWith(
            (ref, movieId) async => false,
          ),
          hp.mediaHistoryProvider.overrideWith((ref, args) async => null),
        ],
      );
      addTearDown(container.dispose);

      final pushedSources = <VideoSource>[];
      final router = _buildRouter(
        onPlayerOpened: (source) => pushedSources.add(source),
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Watch'));
      await tester.pumpAndSettle();

      expect(find.byType(MoviePlaybackVariantSheet), findsNothing);
      expect(pushedSources, hasLength(1));
      expect(pushedSources.single.url, 'https://video.example/1.mp4');
    },
  );

  testWidgets('Watch opens the selector when several ranked variants remain', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final logger = _SilentLogger();
    sl.registerSingleton<AppLogger>(logger);
    sl.registerSingleton<PerformanceDiagnosticLogger>(
      PerformanceDiagnosticLogger(logger),
    );

    final container = ProviderContainer(
      overrides: [
        currentProfileProvider.overrideWithValue(null),
        mdp.movieDetailControllerProvider.overrideWith(
          (ref, movieId) async => _movieViewModel(),
        ),
        mdp.moviePlaybackSelectionProvider.overrideWith(
          (ref, args) async => PlaybackSelectionDecision(
            disposition: PlaybackSelectionDisposition.manualSelection,
            reason: PlaybackSelectionReason.ambiguousVariants,
            rankedVariants: <PlaybackVariant>[
              _variant(
                'Salon',
                '1',
                rawTitle: 'The.Matrix.1999.1080p.TRUEFRENCH',
                qualityLabel: 'Full HD',
              ),
              _variant(
                'Chambre',
                '2',
                rawTitle: 'The.Matrix.1999.2160p.VOSTFR',
              ),
            ],
          ),
        ),
        mdp.movieAvailabilityOnIptvProvider.overrideWith(
          (ref, movieId) async => true,
        ),
        mdp.movieIsFavoriteProvider.overrideWith((ref, movieId) async => false),
        hp.mediaHistoryProvider.overrideWith((ref, args) async => null),
      ],
    );
    addTearDown(container.dispose);

    final pushedSources = <VideoSource>[];
    final router = _buildRouter(
      onPlayerOpened: (source) => pushedSources.add(source),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Watch'));
    await tester.pumpAndSettle();

    expect(find.byType(MoviePlaybackVariantSheet), findsOneWidget);
    expect(find.text('The.Matrix.1999.1080p.TRUEFRENCH'), findsOneWidget);
    expect(find.text('The.Matrix.1999.2160p.VOSTFR'), findsOneWidget);

    await tester.tap(find.text('The.Matrix.1999.2160p.VOSTFR'));
    await tester.pumpAndSettle();

    expect(pushedSources, hasLength(1));
    expect(pushedSources.single.url, 'https://video.example/2.mp4');
  });

  testWidgets(
    'Watch selector exposes useful variant labels for manual choice',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final logger = _SilentLogger();
      sl.registerSingleton<AppLogger>(logger);
      sl.registerSingleton<PerformanceDiagnosticLogger>(
        PerformanceDiagnosticLogger(logger),
      );

      final container = ProviderContainer(
        overrides: [
          currentProfileProvider.overrideWithValue(null),
          mdp.movieDetailControllerProvider.overrideWith(
            (ref, movieId) async => _movieViewModel(),
          ),
          mdp.moviePlaybackSelectionProvider.overrideWith(
            (ref, args) async => PlaybackSelectionDecision(
              disposition: PlaybackSelectionDisposition.manualSelection,
              reason: PlaybackSelectionReason.ambiguousVariants,
              rankedVariants: <PlaybackVariant>[
                _variant(
                  'Salon',
                  '1',
                  rawTitle: 'The.Matrix.1999.2160p.VF.VOSTFR',
                  qualityLabel: '4K',
                  audioLanguageLabel: 'VF',
                  subtitleLanguageLabel: 'FR',
                ),
                _variant(
                  'Chambre',
                  '2',
                  rawTitle: 'The.Matrix.1999.1080p.VO.SUB',
                  qualityLabel: 'Full HD',
                  audioLanguageLabel: 'VO',
                  hasSubtitles: true,
                ),
              ],
            ),
          ),
          mdp.movieAvailabilityOnIptvProvider.overrideWith(
            (ref, movieId) async => true,
          ),
          mdp.movieIsFavoriteProvider.overrideWith(
            (ref, movieId) async => false,
          ),
          hp.mediaHistoryProvider.overrideWith((ref, args) async => null),
        ],
      );
      addTearDown(container.dispose);

      final router = _buildRouter(onPlayerOpened: (_) {});
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Watch'));
      await tester.pumpAndSettle();

      expect(find.byType(MoviePlaybackVariantSheet), findsOneWidget);
      expect(find.text('The.Matrix.1999.2160p.VF.VOSTFR'), findsOneWidget);
      expect(find.text('The.Matrix.1999.1080p.VO.SUB'), findsOneWidget);
      expect(find.text('4K'), findsNothing);
      expect(find.text('VF'), findsNothing);
      expect(find.text('ST FR'), findsNothing);
      expect(find.text('Full HD'), findsNothing);
      expect(find.text('VO'), findsNothing);
      expect(find.text('ST'), findsNothing);
    },
  );

  testWidgets(
    'Versions stays lazy and does not compute playback selection during build',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final logger = _SilentLogger();
      sl.registerSingleton<AppLogger>(logger);
      sl.registerSingleton<PerformanceDiagnosticLogger>(
        PerformanceDiagnosticLogger(logger),
      );

      var selectionCalls = 0;
      final container = ProviderContainer(
        overrides: [
          currentProfileProvider.overrideWithValue(null),
          mdp.movieDetailControllerProvider.overrideWith(
            (ref, movieId) async => _movieViewModel(),
          ),
          mdp.moviePlaybackSelectionProvider.overrideWith((ref, args) async {
            selectionCalls += 1;
            return PlaybackSelectionDecision(
              disposition: PlaybackSelectionDisposition.manualSelection,
              reason: PlaybackSelectionReason.ambiguousVariants,
              rankedVariants: <PlaybackVariant>[
                _variant('Salon', '1'),
                _variant('Chambre', '2'),
              ],
            );
          }),
          mdp.movieAvailabilityOnIptvProvider.overrideWith(
            (ref, movieId) async => true,
          ),
          mdp.movieIsFavoriteProvider.overrideWith(
            (ref, movieId) async => false,
          ),
          hp.mediaHistoryProvider.overrideWith((ref, args) async => null),
        ],
      );
      addTearDown(container.dispose);

      final router = _buildRouter(onPlayerOpened: (_) {});
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Versions'), findsOneWidget);
      expect(selectionCalls, 0);

      await tester.tap(find.text('Versions'));
      await tester.pumpAndSettle();

      expect(selectionCalls, 1);
      expect(find.byType(MoviePlaybackVariantSheet), findsOneWidget);
    },
  );

  testWidgets('Versions is hidden when IPTV availability is false', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final logger = _SilentLogger();
    sl.registerSingleton<AppLogger>(logger);
    sl.registerSingleton<PerformanceDiagnosticLogger>(
      PerformanceDiagnosticLogger(logger),
    );

    final container = ProviderContainer(
      overrides: [
        currentProfileProvider.overrideWithValue(null),
        mdp.movieDetailControllerProvider.overrideWith(
          (ref, movieId) async => _movieViewModel(),
        ),
        mdp.moviePlaybackSelectionProvider.overrideWith(
          (ref, args) async => PlaybackSelectionDecision(
            disposition: PlaybackSelectionDisposition.autoPlay,
            reason: PlaybackSelectionReason.singlePlayableVariant,
            rankedVariants: <PlaybackVariant>[_variant('Salon', '1')],
            selectedVariant: _variant('Salon', '1'),
          ),
        ),
        mdp.movieAvailabilityOnIptvProvider.overrideWith(
          (ref, movieId) async => false,
        ),
        mdp.movieIsFavoriteProvider.overrideWith((ref, movieId) async => false),
        hp.mediaHistoryProvider.overrideWith((ref, args) async => null),
      ],
    );
    addTearDown(container.dispose);

    final router = _buildRouter(onPlayerOpened: (_) {});
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Watch'), findsOneWidget);
    expect(find.text('Versions'), findsNothing);
  });
}

GoRouter _buildRouter({
  required void Function(VideoSource source) onPlayerOpened,
}) {
  return GoRouter(
    initialLocation: '/movie',
    routes: <RouteBase>[
      GoRoute(
        path: '/movie',
        builder: (context, state) => const MovieDetailPage(movieId: '603'),
      ),
      GoRoute(
        path: '/player',
        builder: (context, state) {
          final source = state.extra! as VideoSource;
          onPlayerOpened(source);
          return const Scaffold(body: Text('Player page'));
        },
      ),
    ],
  );
}

MovieDetailViewModel _movieViewModel() {
  return MovieDetailViewModel(
    title: 'The Matrix',
    yearText: '1999',
    durationText: '2h 16m',
    ratingText: '8.7',
    overviewText: 'Neo discovers the Matrix.',
    cast: const [],
    recommendations: const [],
    poster: null,
    posterBackground: null,
    backdrop: null,
    language: 'en-US',
  );
}

PlaybackVariant _variant(
  String sourceLabel,
  String id, {
  String? rawTitle,
  String? qualityLabel,
  String? audioLanguageLabel,
  String? subtitleLanguageLabel,
  bool? hasSubtitles,
}) {
  return PlaybackVariant(
    id: 'source-$id:$id',
    sourceId: 'source-$id',
    sourceLabel: sourceLabel,
    videoSource: VideoSource(
      url: 'https://video.example/$id.mp4',
      title: 'The Matrix',
      contentId: '603',
      contentType: ContentType.movie,
    ),
    contentType: ContentType.movie,
    rawTitle: rawTitle ?? 'The.Matrix.1999',
    normalizedTitle: 'The Matrix',
    qualityLabel: qualityLabel,
    qualityRank: qualityLabel == null ? null : 3,
    audioLanguageLabel: audioLanguageLabel,
    subtitleLanguageLabel: subtitleLanguageLabel,
    hasSubtitles: hasSubtitles,
  );
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
