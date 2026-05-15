import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/startup/presentation/boot_action_handler.dart';
import 'package:movi/src/core/startup/presentation/boot_screen_model.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';

final class BootScreenMapper {
  const BootScreenMapper();

  BootScreenModel fromLaunchState(AppLaunchState state) {
    return switch (state.status) {
      AppLaunchStatus.idle => _loading(reasonCode: 'technical_startup', phase: state.phase),
      AppLaunchStatus.running => _running(state),
      AppLaunchStatus.failure => _technicalFailure(state),
      AppLaunchStatus.success => _success(state),
    };
  }

  BootScreenModel _running(AppLaunchState state) {
    return switch (state.phase) {
      AppLaunchPhase.auth => _loading(reasonCode: 'session_check', phase: state.phase),
      AppLaunchPhase.profiles => _loading(reasonCode: 'profile_check', phase: state.phase),
      AppLaunchPhase.sources ||
      AppLaunchPhase.localAccounts ||
      AppLaunchPhase.sourceSelection => _loading(reasonCode: 'source_check', phase: state.phase),
      AppLaunchPhase.preloadCompleteHome => BootScreenModel(
        screenType: BootScreenType.catalogLoading,
        message: 'catalog_preparing',
        reasonCode: 'catalog_preparing',
        isInteractive: false,
        initialFocus: BootFocusTarget.none,
        severity: BootScreenSeverity.info,
        showLogo: true,
        showProgress: true,
        metadata: <String, Object?>{
          ..._metadata(state),
          'catalogCacheReady': state.criteria.hasIptvCatalogReady,
        },
      ),
      AppLaunchPhase.done => _loading(reasonCode: 'opening_home', phase: state.phase),
      AppLaunchPhase.init || AppLaunchPhase.startup => _loading(
        reasonCode: 'technical_startup',
        phase: state.phase,
      ),
    };
  }

  BootScreenModel _success(AppLaunchState state) {
    return switch (state.destination) {
      BootstrapDestination.auth => _actionRequired(
        title: 'auth_required',
        message: 'auth_required',
        reasonCode: state.recovery?.reasonCode ?? 'auth_required',
        primaryAction: BootActionIntent.login,
        primaryActionLabel: _labelForAction(BootActionIntent.login),
        destination: state.destination,
        state: state,
      ),
      BootstrapDestination.welcomeUser => _actionRequired(
        title: 'profile_required',
        message: 'profile_required',
        reasonCode: 'profile_required',
        primaryAction: BootActionIntent.createProfile,
        primaryActionLabel: _labelForAction(BootActionIntent.createProfile),
        destination: state.destination,
        state: state,
        metadata: const <String, Object?>{'profileAction': 'create_or_select'},
      ),
      BootstrapDestination.welcomeSources =>
        state.recoveryPlan != null
            ? _sourceRecovery(state)
            : _actionRequired(
                title: 'source_required',
                message: 'source_required',
                reasonCode: state.recovery?.reasonCode ?? 'source_required',
                primaryAction: state.recovery?.isRetryable == true
                    ? BootActionIntent.resyncSource
                    : BootActionIntent.addSource,
                primaryActionLabel: _labelForAction(
                  state.recovery?.isRetryable == true
                      ? BootActionIntent.resyncSource
                      : BootActionIntent.addSource,
                ),
                secondaryAction: state.recovery?.isRetryable == true
                    ? BootActionIntent.chooseSource
                    : null,
                secondaryActionLabel: state.recovery?.isRetryable == true
                    ? _labelForAction(BootActionIntent.chooseSource)
                    : null,
                destination: state.destination,
                state: state,
              ),
      BootstrapDestination.chooseSource => _actionRequired(
        title: 'source_selection_required',
        message: 'source_selection_required',
        reasonCode: 'source_selection_required',
        primaryAction: BootActionIntent.chooseSource,
        primaryActionLabel: _labelForAction(BootActionIntent.chooseSource),
        destination: state.destination,
        state: state,
      ),
      BootstrapDestination.home => BootScreenModel(
        screenType: BootScreenType.openingHome,
        message: state.criteria.isHomeReady ? 'home_ready' : 'opening_home',
        reasonCode: state.criteria.isHomeReady ? 'home_ready' : 'opening_home',
        isInteractive: false,
        initialFocus: BootFocusTarget.none,
        severity: BootScreenSeverity.info,
        showLogo: true,
        showProgress: true,
        destination: state.destination,
        metadata: _metadata(state),
      ),
      null => _loading(reasonCode: 'opening_home', phase: state.phase),
    };
  }

  BootScreenModel _loading({
    required String reasonCode,
    required AppLaunchPhase phase,
  }) {
    return BootScreenModel(
      screenType: BootScreenType.simpleLoading,
      message: reasonCode,
      reasonCode: reasonCode,
      isInteractive: false,
      initialFocus: BootFocusTarget.none,
      severity: BootScreenSeverity.info,
      showLogo: true,
      showProgress: true,
      metadata: <String, Object?>{'phase': phase.name},
    );
  }

  BootScreenModel _sourceRecovery(AppLaunchState state) {
    final plan = state.recoveryPlan!;
    final primaryAction = plan.actions.first.toBootActionIntent();
    final secondaryAction = plan.actions.length > 1
        ? plan.actions[1].toBootActionIntent()
        : null;

    return _actionRequired(
      title: plan.reasonCode,
      message: plan.reasonCode,
      reasonCode: plan.reasonCode,
      primaryAction: primaryAction,
      primaryActionLabel: _labelForAction(primaryAction),
      secondaryAction: secondaryAction,
      secondaryActionLabel: secondaryAction == null
          ? null
          : _labelForAction(secondaryAction),
      destination: state.destination,
      state: state,
    );
  }

  String _labelForAction(BootActionIntent action) {
    return action.name;
  }

  BootScreenModel _actionRequired({
    required String title,
    required String message,
    required String reasonCode,
    required BootActionIntent primaryAction,
    required String primaryActionLabel,
    required BootstrapDestination? destination,
    required AppLaunchState state,
    BootActionIntent? secondaryAction,
    String? secondaryActionLabel,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    return BootScreenModel(
      screenType: BootScreenType.actionRequired,
      title: title,
      message: message,
      reasonCode: reasonCode,
      primaryAction: primaryAction,
      primaryActionLabel: primaryActionLabel,
      secondaryAction: secondaryAction,
      secondaryActionLabel: secondaryActionLabel,
      destination: destination,
      isInteractive: true,
      initialFocus: BootFocusTarget.primaryAction,
      severity: BootScreenSeverity.warning,
      showLogo: true,
      showProgress: false,
      metadata: <String, Object?>{..._metadata(state), ...metadata},
    );
  }

  BootScreenModel _technicalFailure(AppLaunchState state) {
    return BootScreenModel(
      screenType: BootScreenType.technicalFailure,
      title: 'technical_failure',
      message: 'technical_failure',
      secondaryMessage: state.recoveryMessage,
      reasonCode: state.recovery?.reasonCode ?? 'technical_failure',
      primaryAction: BootActionIntent.retry,
      primaryActionLabel: _labelForAction(BootActionIntent.retry),
      secondaryAction: BootActionIntent.exportLogs,
      secondaryActionLabel: _labelForAction(BootActionIntent.exportLogs),
      isInteractive: true,
      initialFocus: BootFocusTarget.primaryAction,
      severity: BootScreenSeverity.error,
      showLogo: true,
      showProgress: false,
      metadata: _metadata(state),
    );
  }

  Map<String, Object?> _metadata(AppLaunchState state) {
    return <String, Object?>{
      'status': state.status.name,
      'phase': state.phase.name,
      'destination': state.destination?.name,
      'hasHomeReadyCriteria': state.criteria.isHomeReady,
      'runId': state.runId,
    };
  }
}
