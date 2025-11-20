import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/models/movi_media.dart';
import 'package:movi/src/features/tv/presentation/models/tv_detail_view_model.dart';
import 'package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart';
import 'package:movi/src/features/tv/presentation/pages/tv_detail_page.dart';

class _FakeLogger implements AppLogger {
  @override
  void log(LogLevel level, String message, {String? category, Object? error, StackTrace? stackTrace}) {}
  @override
  void debug(String message, {String? category}) => log(LogLevel.debug, message, category: category);
  @override
  void info(String message, {String? category}) => log(LogLevel.info, message, category: category);
  @override
  void warn(String message, {String? category}) => log(LogLevel.warn, message, category: category);
  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) => log(LogLevel.error, message, error: error, stackTrace: stackTrace);
}

void main() {
  testWidgets('TvDetailPage affiche bouton Expand/Collapse (i18n)', (tester) async {
    final slFake = GetIt.asNewInstance();
    slFake.registerSingleton<AppLogger>(_FakeLogger());

    final vm = TvDetailViewModel(
      title: 'Titre',
      yearText: '2024',
      seasonsCountText: '2 saisons',
      ratingText: '8.0',
      overviewText: 'Résumé très très long qui nécessite un contrôle Expand/Collapse.',
      cast: const [],
      seasons: const [],
      poster: null,
      backdrop: null,
      language: 'fr-FR',
    );

    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          slProvider.overrideWithValue(slFake),
          tvDetailProgressiveControllerProvider.overrideWith(() {
            return _FakeProgressiveController(AsyncValue.data(vm));
          }),
        ],
        child: MaterialApp(
          locale: const Locale('fr', 'FR'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: TvDetailPage(
              media: MoviMedia(
                id: '1',
                title: 'Titre',
                type: MoviMediaType.series,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Agrandir'), findsOneWidget);

    await tester.tap(find.text('Agrandir'));
    await tester.pump();

    expect(find.text('Rétrécir'), findsOneWidget);
  }, skip: true);
}

class _FakeProgressiveController extends TvDetailProgressiveController {
  _FakeProgressiveController(this._state) : super('1');
  final AsyncValue<TvDetailViewModel> _state;
  @override
  AsyncValue<TvDetailViewModel> build() => _state;
}