// lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/startup/presentation/boot_action_executor.dart';
import 'package:movi/src/core/startup/presentation/boot_action_handler.dart';
import 'package:movi/src/core/startup/presentation/boot_screen_localizer.dart';
import 'package:movi/src/core/startup/presentation/boot_screen_model.dart';
import 'package:movi/src/core/startup/presentation/boot_screen_providers.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_screen_renderer.dart';
import 'package:movi/src/core/utils/unawaited.dart';
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
  final FocusNode _primaryActionFocusNode = FocusNode(
    debugLabel: 'SplashBootstrapPrimaryAction',
  );
  final FocusNode _secondaryActionFocusNode = FocusNode(
    debugLabel: 'SplashBootstrapSecondaryAction',
  );

  @override
  void dispose() {
    _loadingFocusNode.dispose();
    _primaryActionFocusNode.dispose();
    _secondaryActionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleBootAction(BootActionIntent intent) async {
    if (!mounted) return;
    final model = ref.read(bootScreenModelProvider);
    await executeBootAction(
      context,
      ref,
      BootActionRequest(intent: intent, reasonCode: model.reasonCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final launchState = ref.watch(appLaunchStateProvider);
    final bootModel = ref.watch(bootScreenModelProvider);
    final showRecovery = launchState.error != null || bootModel.isInteractive;
    final entryFocus = showRecovery
        ? _primaryActionFocusNode
        : _loadingFocusNode;

    return PopScope(
      canPop: false,
      child: FocusRegionScope(
        regionId: AppFocusRegionId.splashBootstrapPrimary,
        binding: FocusRegionBinding(
          resolvePrimaryEntryNode: () => entryFocus,
          resolveFallbackEntryNode: () => entryFocus,
        ),
        requestFocusOnMount: true,
        handleDirectionalExits: false,
        debugLabel: 'SplashBootstrapRegion',
        child: Scaffold(
          body: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              final stage = ref.watch(homeBootstrapProgressStageProvider);
              final localizedBootModel = localizeBootScreenModel(
                model: bootModel,
                l10n: l10n,
              );
              final recoveryMessage = launchState.recoveryMessage;
              final String baseMessage =
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
                  : localizedBootModel.message;
              final displayMessage = recoveryMessage == null
                  ? baseMessage
                  : '$baseMessage - $recoveryMessage';
              final catalogSecondary =
                  localizedBootModel.screenType ==
                          BootScreenType.catalogLoading &&
                      launchState.criteria.hasIptvCatalogReady
                  ? l10n.bootCatalogLocalCacheReady
                  : null;

              return BootScreenRenderer(
                model: localizedBootModel,
                forceRecovery: launchState.error != null,
                primaryActionFocusNode: _primaryActionFocusNode,
                secondaryActionFocusNode: _secondaryActionFocusNode,
                loadingFocusNode: _loadingFocusNode,
                loadingMessageOverride: displayMessage,
                catalogSecondaryMessage: catalogSecondary,
                onAction: (BootActionIntent intent) {
                  unawaited(_handleBootAction(intent));
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
