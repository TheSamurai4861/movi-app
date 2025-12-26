// lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';

class SplashBootstrapPage extends ConsumerWidget {
  const SplashBootstrapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launchState = ref.watch(appLaunchStateProvider);
    final error = launchState.error;

    if (error == null) {
      return Scaffold(
        body: OverlaySplash(
          message: AppLocalizations.of(context)!.overlayPreparingHome,
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: LaunchErrorPanel(
        message: l10n.errorPrepareHome,
        retryLabel: l10n.actionRetry,
        onRetry: () {
          final orchestrator =
              ref.read(appLaunchOrchestratorProvider.notifier);
          orchestrator.reset();
          ref.read(appLaunchRunnerProvider)('retry');
        },
      ),
    );
  }
}
