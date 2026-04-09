import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/parental/domain/entities/pin_recovery_result.dart';
import 'package:movi/src/core/parental/domain/repositories/pin_recovery_repository.dart';
import 'package:movi/src/core/parental/presentation/pages/pin_recovery_page.dart';
import 'package:movi/src/core/parental/presentation/providers/pin_recovery_providers.dart';

void main() {
  Widget buildHarness(PinRecoveryRepository repository) {
    return ProviderScope(
      overrides: [pinRecoveryRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(
        locale: Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PinRecoveryPage(profileId: 'profile-1')),
      ),
    );
  }

  testWidgets(
    'keeps the request step visible when sending the recovery code fails',
    (tester) async {
      await tester.pumpWidget(
        buildHarness(
          const _FakePinRecoveryRepository(
            requestResult: PinRecoveryResult.failure(
              PinRecoveryStatus.notAvailable,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Envoyer le code').first);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'La récupération du code PIN par e-mail est indisponible pour le moment.',
        ),
        findsOneWidget,
      );
      expect(find.text('Code de récupération'), findsNothing);
      expect(find.text('Envoyer le code'), findsOneWidget);
    },
  );

  testWidgets('pops back to the previous page after a successful PIN reset', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        pinRecoveryRepositoryProvider.overrideWithValue(
          const _FakePinRecoveryRepository(
            requestResult: PinRecoveryResult.success(),
            verifyResult: PinRecoveryResult.success(resetToken: 'reset-token'),
            resetResult: PinRecoveryResult.success(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const PinRecoveryPage(profileId: 'profile-1'),
                      ),
                    );
                  },
                  child: const Text('Ouvrir recovery'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ouvrir recovery'), findsOneWidget);

    await tester.tap(find.text('Ouvrir recovery'));
    await tester.pumpAndSettle();

    final controller = container.read(pinRecoveryControllerProvider.notifier);
    await controller.requestCode(profileId: 'profile-1');
    controller.setCode('12345678');
    await controller.verify();
    controller.setNewPin('1234');
    controller.setConfirmPin('1234');
    await controller.resetPin();
    await tester.pumpAndSettle();

    expect(find.text('Ouvrir recovery'), findsOneWidget);
    expect(find.byType(PinRecoveryPage), findsNothing);

    container.dispose();
  });

  testWidgets(
    'reopening pin recovery starts from a reset state after a successful reset',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          pinRecoveryRepositoryProvider.overrideWithValue(
            const _FakePinRecoveryRepository(
              requestResult: PinRecoveryResult.success(),
              verifyResult: PinRecoveryResult.success(
                resetToken: 'reset-token',
              ),
              resetResult: PinRecoveryResult.success(),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const PinRecoveryPage(profileId: 'profile-1'),
                        ),
                      );
                    },
                    child: const Text('Ouvrir recovery'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ouvrir recovery'));
      await tester.pumpAndSettle();

      final controller = container.read(pinRecoveryControllerProvider.notifier);
      await controller.requestCode(profileId: 'profile-1');
      controller.setCode('12345678');
      await controller.verify();
      controller.setNewPin('1234');
      controller.setConfirmPin('1234');
      await controller.resetPin();
      await tester.pumpAndSettle();

      expect(find.byType(PinRecoveryPage), findsNothing);

      await tester.tap(find.text('Ouvrir recovery'));
      await tester.pumpAndSettle();

      expect(find.byType(PinRecoveryPage), findsOneWidget);
      expect(find.text('Envoyer le code'), findsOneWidget);
      expect(find.text('Code de récupération'), findsNothing);

      container.dispose();
    },
  );
}

class _FakePinRecoveryRepository implements PinRecoveryRepository {
  const _FakePinRecoveryRepository({
    required this.requestResult,
    this.verifyResult = const PinRecoveryResult.failure(
      PinRecoveryStatus.invalid,
    ),
    this.resetResult = const PinRecoveryResult.failure(
      PinRecoveryStatus.invalid,
    ),
  });

  final PinRecoveryResult requestResult;
  final PinRecoveryResult verifyResult;
  final PinRecoveryResult resetResult;

  @override
  Future<PinRecoveryResult> requestRecoveryCode({String? profileId}) async {
    return requestResult;
  }

  @override
  Future<PinRecoveryResult> resetPin({
    required String resetToken,
    required String newPin,
  }) async {
    return resetResult;
  }

  @override
  Future<PinRecoveryResult> verifyRecoveryCode(String code) async {
    return verifyResult;
  }
}
