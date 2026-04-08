import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/features/welcome/presentation/pages/welcome_source_loading_page.dart';

void main() {
  test('restores the selected local source when active sources are empty', () {
    final resolution = resolveWelcomeSourceLoadingSourceResolution(
      activeSourceIds: const <String>{},
      knownSourceIds: const <String>{'source_a', 'source_b'},
      selectedSourceId: 'source_b',
    );

    expect(resolution.canContinue, isTrue);
    expect(resolution.activeSourceIds, <String>{'source_b'});
    expect(resolution.selectedSourceId, 'source_b');
    expect(resolution.showSourceSelectionAction, isFalse);
  });

  test(
    'restores the only local source when no active source is registered',
    () {
      final resolution = resolveWelcomeSourceLoadingSourceResolution(
        activeSourceIds: const <String>{},
        knownSourceIds: const <String>{'sole_source'},
        selectedSourceId: null,
      );

      expect(resolution.canContinue, isTrue);
      expect(resolution.activeSourceIds, <String>{'sole_source'});
      expect(resolution.selectedSourceId, 'sole_source');
      expect(resolution.showSourceSelectionAction, isFalse);
    },
  );

  test('requires manual source selection when multiple local sources remain', () {
    final resolution = resolveWelcomeSourceLoadingSourceResolution(
      activeSourceIds: const <String>{},
      knownSourceIds: const <String>{'source_a', 'source_b'},
      selectedSourceId: 'stale_source',
    );

    expect(resolution.canContinue, isFalse);
    expect(
      resolution.errorMessage,
      "Aucune source active n'est s\u00E9lectionn\u00E9e. Choisissez une source avant de relancer le chargement.",
    );
    expect(resolution.showSourceSelectionAction, isTrue);
  });

  test(
    'offers source selection on failure when another local source exists',
    () {
      final shouldOffer = shouldOfferWelcomeSourceSelectionOnFailure(
        knownSourceIds: const <String>{'source_a', 'source_b'},
        activeSourceIds: const <String>{'source_a'},
      );

      expect(shouldOffer, isTrue);
    },
  );

  test(
    'does not offer source selection on failure when no alternative source exists',
    () {
      final shouldOffer = shouldOfferWelcomeSourceSelectionOnFailure(
        knownSourceIds: const <String>{'source_a'},
        activeSourceIds: const <String>{'source_a'},
      );

      expect(shouldOffer, isFalse);
    },
  );

  test('formats timeout failures with a user-facing retry message', () {
    final message = formatWelcomeSourceLoadingErrorMessage(
      TimeoutException('xtream timeout'),
    );

    expect(
      message,
      'Le chargement de la source a expir\u00E9. V\u00E9rifiez votre connexion ou choisissez une autre source.',
    );
  });

  test('strips the Exception prefix from generic loading failures', () {
    final message = formatWelcomeSourceLoadingErrorMessage(
      Exception('Le catalogue IPTV est vide'),
    );

    expect(message, 'Le catalogue IPTV est vide');
  });
}
