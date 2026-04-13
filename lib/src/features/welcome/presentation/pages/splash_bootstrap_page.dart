// lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';

class SplashBootstrapPage extends ConsumerStatefulWidget {
  const SplashBootstrapPage({super.key});

  @override
  ConsumerState<SplashBootstrapPage> createState() =>
      _SplashBootstrapPageState();
}

class _SplashBootstrapPageState extends ConsumerState<SplashBootstrapPage> {
  final FocusNode _loadingFocusNode = FocusNode(
    debugLabel: 'SplashBootstrapLoading',
  );
  final FocusNode _retryFocusNode = FocusNode(
    debugLabel: 'SplashBootstrapRetry',
  );

  @override
  void dispose() {
    _loadingFocusNode.dispose();
    _retryFocusNode.dispose();
    super.dispose();
  }

  void _retryLaunch() {
    final orchestrator = ref.read(appLaunchOrchestratorProvider.notifier);
    orchestrator.reset();
    ref.read(appLaunchRunnerProvider)('retry');
  }

  @override
  Widget build(BuildContext context) {
    final launchState = ref.watch(appLaunchStateProvider);
    final error = launchState.error;
    final initialFocusNode = error == null
        ? _loadingFocusNode
        : _retryFocusNode;

    return PopScope(
      canPop: false,
      child: FocusRegionScope(
        regionId: AppFocusRegionId.splashBootstrapPrimary,
        binding: FocusRegionBinding(
          resolvePrimaryEntryNode: () => initialFocusNode,
          resolveFallbackEntryNode: () => initialFocusNode,
        ),
        requestFocusOnMount: true,
        handleDirectionalExits: false,
        debugLabel: 'SplashBootstrapRegion',
        child: Scaffold(
          body: error == null
              ? Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    final stage = ref.watch(homeBootstrapProgressStageProvider);
                    final recoveryMessage = launchState.recoveryMessage;
                    final message =
                        launchState.phase == AppLaunchPhase.preloadCompleteHome
                        ? switch (stage) {
                            HomeBootstrapProgressStage.loadingMoviesAndSeries =>
                              l10n.overlayLoadingMoviesAndSeries,
                            HomeBootstrapProgressStage.loadingCategories =>
                              l10n.overlayLoadingCategories,
                            HomeBootstrapProgressStage.openingHome =>
                              l10n.overlayOpeningHome,
                            null => l10n.overlayPreparingHome,
                          }
                        : l10n.overlayPreparingHome;
                    final displayMessage = recoveryMessage == null
                        ? message
                        : '$message - $recoveryMessage';
                    return Focus(
                      focusNode: _loadingFocusNode,
                      child: OverlaySplash(message: displayMessage),
                    );
                  },
                )
              : Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return LaunchErrorPanel(
                      message: l10n.errorPrepareHome,
                      retryLabel: l10n.actionRetry,
                      onRetry: _retryLaunch,
                      retryFocusNode: _retryFocusNode,
                    );
                  },
                ),
        ),
      ),
    );
  }
}
