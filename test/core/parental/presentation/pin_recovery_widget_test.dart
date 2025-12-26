import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/parental/domain/entities/pin_recovery_result.dart';
import 'package:movi/src/core/parental/domain/repositories/pin_recovery_repository.dart';
import 'package:movi/src/core/parental/presentation/pages/pin_recovery_page.dart';
import 'package:movi/src/core/parental/presentation/providers/pin_recovery_providers.dart';
import 'package:movi/src/core/parental/presentation/widgets/restricted_content_sheet.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/router/app_route_paths.dart';

void main() {
  testWidgets('shows validation error when code is not 8 digits', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pinRecoveryRepositoryProvider.overrideWithValue(
            _FakePinRecoveryRepository(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PinRecoveryPage(profileId: 'profile-id'),
        ),
      ),
    );

    await tester.tap(find.text('Send code'));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, '1234567');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('Enter the 8-digit code'), findsOneWidget);
  });

  testWidgets('navigates to pin recovery route from link', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const _SheetHost(),
        ),
        GoRoute(
          path: AppRoutePaths.pinRecovery,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Pin Recovery Route')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Récupérer le code PIN'));
    await tester.pumpAndSettle();

    expect(find.text('Pin Recovery Route'), findsOneWidget);
  });
}

class _SheetHost extends ConsumerWidget {
  const _SheetHost();

  static const Profile _profile = Profile(
    id: 'profile-id',
    accountId: 'account-id',
    name: 'Test',
    color: 0xFF000000,
    hasPin: true,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            RestrictedContentSheet.show(
              context,
              ref,
              profile: _profile,
            );
          },
          child: const Text('Open Sheet'),
        ),
      ),
    );
  }
}

class _FakePinRecoveryRepository implements PinRecoveryRepository {
  @override
  Future<PinRecoveryResult> requestRecoveryCode({String? profileId}) async {
    return const PinRecoveryResult.success();
  }

  @override
  Future<PinRecoveryResult> verifyRecoveryCode(String code) async {
    return const PinRecoveryResult.failure(PinRecoveryStatus.invalid);
  }

  @override
  Future<PinRecoveryResult> resetPin({
    required String resetToken,
    required String newPin,
  }) async {
    return const PinRecoveryResult.success();
  }
}
