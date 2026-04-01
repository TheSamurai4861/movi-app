// lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';

class SplashBootstrapPage extends ConsumerWidget {
  const SplashBootstrapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launchState = ref.watch(appLaunchStateProvider);
    final error = launchState.error;

    if (error == null) {
      final l10n = AppLocalizations.of(context)!;
      final stage = ref.watch(homeBootstrapProgressStageProvider);
      final recoveryMessage = launchState.recoveryMessage;
      final message = launchState.phase == AppLaunchPhase.preloadCompleteHome
          ? switch (stage) {
              HomeBootstrapProgressStage.loadingMoviesAndSeries =>
                l10n.overlayLoadingMoviesAndSeries,
              HomeBootstrapProgressStage.loadingCategories =>
                l10n.overlayLoadingCategories,
              HomeBootstrapProgressStage.openingHome => l10n.overlayOpeningHome,
              null => l10n.overlayPreparingHome,
            }
          : l10n.overlayPreparingHome;
      final displayMessage = recoveryMessage == null
          ? message
          : '$message · $recoveryMessage';
      return Scaffold(body: OverlaySplash(message: displayMessage));
    }

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: LaunchErrorPanel(
        message: l10n.errorPrepareHome,
        retryLabel: l10n.actionRetry,
        onRetry: () {
          final orchestrator = ref.read(appLaunchOrchestratorProvider.notifier);
          orchestrator.reset();
          ref.read(appLaunchRunnerProvider)('retry');
        },
      ),
    );
  }
}
