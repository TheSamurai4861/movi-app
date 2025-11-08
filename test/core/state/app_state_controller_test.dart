import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/state/app_state.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';

void main() {
  group('AppStateController', () {
    late AppStateController controller;

    late LocalePreferences localePreferences;

    setUp(() {
      localePreferences = LocalePreferences();
      controller = AppStateController(localePreferences);
    });

    test('initial state is default', () {
      expect(controller.state, const AppState());
    });

    test('setThemeMode updates theme mode', () {
      controller.setThemeMode(ThemeMode.dark);
      expect(controller.state.themeMode, ThemeMode.dark);
    });

    test('setConnectivity updates status', () {
      controller.setConnectivity(false);
      expect(controller.state.isOnline, isFalse);
    });

    test('can add and remove iptv source', () {
      controller.addIptvSource('account1');
      expect(controller.state.activeIptvSources, ['account1']);
      controller.removeIptvSource('account1');
      expect(controller.state.activeIptvSources, isEmpty);
    });

    test('setPreferredLocale updates locale and store', () async {
      await controller.setPreferredLocale('fr-FR');
      expect(controller.state.preferredLocale, 'fr-FR');
      expect(localePreferences.languageCode, 'fr-FR');
    });
  });
}
