import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:movi/src/features/welcome/presentation/providers/welcome_providers.dart';

void main() {
  group('WelcomeController', () {
    test('toggleObscure flips isObscured', () {
      final container = ProviderContainer(
        overrides: [welcomeDioProvider.overrideWithValue(Dio())],
      );
      addTearDown(container.dispose);

      final ctrl = container.read(welcomeControllerProvider.notifier);
      final initial = container.read(welcomeControllerProvider);
      expect(initial.isObscured, isTrue);

      ctrl.toggleObscure();
      final after = container.read(welcomeControllerProvider);
      expect(after.isObscured, isFalse);
    });

    test('updateUrlPreview sets preview for valid url and clears error', () {
      final container = ProviderContainer(
        overrides: [welcomeDioProvider.overrideWithValue(Dio())],
      );
      addTearDown(container.dispose);

      final ctrl = container.read(welcomeControllerProvider.notifier);
      // Seed an error
      ctrl.state = ctrl.state.copyWith(errorMessage: 'err');

      ctrl.updateUrlPreview('http://example.com:8000');
      final state = container.read(welcomeControllerProvider);
      expect(state.endpointPreview, 'http://example.com:8000');
      expect(state.errorMessage, isNull);
    });

    test('copyWith preserves by default and clears via flags', () {
      final container = ProviderContainer(
        overrides: [welcomeDioProvider.overrideWithValue(Dio())],
      );
      addTearDown(container.dispose);

      final ctrl = container.read(welcomeControllerProvider.notifier);
      ctrl.state = const WelcomeUiState(
        isTesting: false,
        isObscured: true,
        errorMessage: 'E',
        endpointPreview: 'P',
      );

      // Preserve by default
      ctrl.state = ctrl.state.copyWith(isTesting: true);
      expect(ctrl.state.errorMessage, 'E');
      expect(ctrl.state.endpointPreview, 'P');

      // Clear explicitly
      ctrl.state = ctrl.state.copyWith(
        clearErrorMessage: true,
        clearEndpointPreview: true,
      );
      expect(ctrl.state.errorMessage, isNull);
      expect(ctrl.state.endpointPreview, isNull);
    });
  });
}