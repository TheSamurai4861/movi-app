import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/startup/presentation/boot_screen_model.dart';
import 'package:movi/src/core/startup/presentation/boot_screen_providers.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';

void main() {
  test(
    'bootScreenModelProvider projects AppLaunchState without side effects',
    () {
      final container = ProviderContainer(
        overrides: [
          appLaunchStateProvider.overrideWithValue(
            const AppLaunchState(
              status: AppLaunchStatus.success,
              destination: BootstrapDestination.auth,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final model = container.read(bootScreenModelProvider);

      expect(model.screenType, BootScreenType.actionRequired);
      expect(model.reasonCode, 'auth_required');
      expect(model.destination, BootstrapDestination.auth);
    },
  );
}
