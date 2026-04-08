import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/app_update/application/check_app_update_requirement.dart';
import 'package:movi/src/core/app_update/domain/entities/app_update_decision.dart';
import 'package:movi/src/core/di/injector.dart';
import 'package:movi/src/core/startup/app_startup_provider.dart' as app_startup;
import 'package:movi/src/core/startup/domain/startup_contracts.dart';

final appUpdateDecisionProvider = FutureProvider<AppUpdateDecision>((ref) async {
  final startupResult = await ref.watch(app_startup.appStartupProvider.future);
  if (startupResult.kind != StartupOutcomeKind.ready) {
    return AppUpdateDecision.allow(
      currentVersion: 'unknown',
      platform: 'unknown',
      checkedAt: DateTime.now().toUtc(),
      reasonCode: 'app_update_skipped_startup_not_ready',
    );
  }

  if (!sl.isRegistered<CheckAppUpdateRequirement>()) {
    if (kReleaseMode) {
      throw StateError(
        'CheckAppUpdateRequirement is not registered in release mode.',
      );
    }

    return AppUpdateDecision.allow(
      currentVersion: 'debug',
      platform: 'debug',
      checkedAt: DateTime.now().toUtc(),
      reasonCode: 'app_update_skipped_missing_registration',
    );
  }

  final useCase = sl<CheckAppUpdateRequirement>();
  return useCase();
});
