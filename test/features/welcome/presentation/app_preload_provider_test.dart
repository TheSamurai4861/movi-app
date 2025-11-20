import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/startup/app_startup_provider.dart' as startup;
import 'package:movi/src/features/home/presentation/providers/home_providers.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class FakeLocalePreferences implements LocalePreferences {
  FakeLocalePreferences(this._languageCode, this._themeMode);
  String _languageCode;
  ThemeMode _themeMode;
  final _languageController = StreamController<String>.broadcast();
  final _themeController = StreamController<ThemeMode>.broadcast();
  @override
  String get languageCode => _languageCode;
  @override
  Stream<String> get languageStream => _languageController.stream;
  @override
  ThemeMode get themeMode => _themeMode;
  @override
  Stream<ThemeMode> get themeStream => _themeController.stream;
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

class FakeIptvLocalRepository extends IptvLocalRepository {
  @override
  Future<List<XtreamAccount>> getAccounts() async => <XtreamAccount>[];
}

class FakeHomeControllerSuccess extends HomeController {
  @override
  HomeState build() => const HomeState();
  @override
  Future<void> load() async {
    state = state.copyWith(
      hero: [
        MovieSummary(
          id: MovieId('1'),
          title: MediaTitle('t'),
          poster: Uri.parse('http://x'),
        ),
      ],
    );
  }
}

class FakeHomeControllerTimeoutNoPartial extends HomeController {
  @override
  HomeState build() => const HomeState();
  @override
  Future<void> load() async {
    throw TimeoutException('simulated');
  }
}

class FakeHomeControllerTimeoutWithPartial extends HomeController {
  @override
  HomeState build() => const HomeState();
  @override
  Future<void> load() async {
    state = state.copyWith(
      hero: [
        MovieSummary(
          id: MovieId('1'),
          title: MediaTitle('t'),
          poster: Uri.parse('http://x'),
        ),
      ],
    );
    throw TimeoutException('simulated');
  }
}

void main() {
  group('appPreloadProvider', () {
    late GetIt locator;
    late AppStateController appState;

    setUp(() {
      sl.reset();
      locator = sl;
      final locale = FakeLocalePreferences('fr-FR', ThemeMode.system);
      appState = AppStateController(locale)..attachLocaleStream();
      locator.registerSingleton<LocalePreferences>(locale);
      locator.registerSingleton<AppStateController>(appState);
      locator.registerSingleton<IptvLocalRepository>(FakeIptvLocalRepository());
    });

    test('success completes without error', () async {
      final container = ProviderContainer(
        overrides: [
          startup.appStartupProvider.overrideWith((ref) async {}),
          homeControllerProvider.overrideWith(FakeHomeControllerSuccess.new),
          slProvider.overrideWithValue(locator),
          appStateControllerProvider.overrideWith((ref) => appState),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(container.read(appPreloadProvider.future), completes);
    });

    test('timeout with no partial throws AppPreloadTimeoutException', () async {
      final container = ProviderContainer(
        overrides: [
          startup.appStartupProvider.overrideWith((ref) async {}),
          homeControllerProvider.overrideWith(FakeHomeControllerTimeoutNoPartial.new),
          slProvider.overrideWithValue(locator),
          appStateControllerProvider.overrideWith((ref) => appState),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(appPreloadProvider.future),
        throwsA(isA<AppPreloadTimeoutException>()),
      );
    });

    test('timeout with partial data resolves without error', () async {
      final container = ProviderContainer(
        overrides: [
          startup.appStartupProvider.overrideWith((ref) async {}),
          homeControllerProvider.overrideWith(FakeHomeControllerTimeoutWithPartial.new),
          slProvider.overrideWithValue(locator),
          appStateControllerProvider.overrideWith((ref) => appState),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(container.read(appPreloadProvider.future), completes);
    });
  });
}