import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/startup/domain/startup_recovery_mapper.dart';
import 'package:movi/src/core/startup/presentation/boot_action_handler.dart';
import 'package:movi/src/core/startup/presentation/boot_screen_model.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';

final class BootScreenMapper {
  const BootScreenMapper();

  BootScreenModel fromLaunchState(AppLaunchState state) {
    return switch (state.status) {
      AppLaunchStatus.idle => _loading(
        message: 'Preparation du lancement',
        reasonCode: 'technical_startup',
        phase: state.phase,
      ),
      AppLaunchStatus.running => _running(state),
      AppLaunchStatus.failure => _technicalFailure(state),
      AppLaunchStatus.success => _success(state),
    };
  }

  BootScreenModel _running(AppLaunchState state) {
    return switch (state.phase) {
      AppLaunchPhase.auth => _loading(
        message: 'Verification de la session',
        reasonCode: 'session_check',
        phase: state.phase,
      ),
      AppLaunchPhase.profiles => _loading(
        message: 'Verification du profil',
        reasonCode: 'profile_check',
        phase: state.phase,
      ),
      AppLaunchPhase.sources ||
      AppLaunchPhase.localAccounts ||
      AppLaunchPhase.sourceSelection => _loading(
        message: 'Verification de la source',
        reasonCode: 'source_check',
        phase: state.phase,
      ),
      AppLaunchPhase.preloadCompleteHome => BootScreenModel(
        screenType: BootScreenType.catalogLoading,
        message: 'Preparation du catalogue',
        reasonCode: 'catalog_preparing',
        isInteractive: false,
        initialFocus: BootFocusTarget.none,
        severity: BootScreenSeverity.info,
        showLogo: true,
        showProgress: true,
        metadata: _metadata(state),
      ),
      AppLaunchPhase.done => _loading(
        message: "Ouverture de l'accueil",
        reasonCode: 'opening_home',
        phase: state.phase,
      ),
      AppLaunchPhase.init || AppLaunchPhase.startup => _loading(
        message: 'Preparation du lancement',
        reasonCode: 'technical_startup',
        phase: state.phase,
      ),
    };
  }

  BootScreenModel _success(AppLaunchState state) {
    return switch (state.destination) {
      BootstrapDestination.auth => _actionRequired(
        title: 'Connexion requise',
        message: 'Connectez-vous pour continuer.',
        reasonCode: state.recovery?.reasonCode ?? 'auth_required',
        primaryAction: BootActionIntent.login,
        primaryActionLabel: 'Se connecter',
        destination: state.destination,
        state: state,
      ),
      BootstrapDestination.welcomeUser => _actionRequired(
        title: 'Profil requis',
        message: 'Creez ou choisissez un profil pour continuer.',
        reasonCode: 'profile_required',
        primaryAction: BootActionIntent.createProfile,
        primaryActionLabel: 'Continuer',
        destination: state.destination,
        state: state,
      ),
      BootstrapDestination.welcomeSources =>
        state.recoveryPlan != null
            ? _sourceRecovery(state)
            : _actionRequired(
                title: 'Source requise',
                message: 'Ajoutez ou reconnectez une source pour continuer.',
                reasonCode: state.recovery?.reasonCode ?? 'source_required',
                primaryAction: state.recovery?.isRetryable == true
                    ? BootActionIntent.resyncSource
                    : BootActionIntent.addSource,
                primaryActionLabel: state.recovery?.isRetryable == true
                    ? 'Reessayer'
                    : 'Ajouter une source',
                secondaryAction: state.recovery?.isRetryable == true
                    ? BootActionIntent.chooseSource
                    : null,
                secondaryActionLabel: state.recovery?.isRetryable == true
                    ? 'Changer de source'
                    : null,
                destination: state.destination,
                state: state,
              ),
      BootstrapDestination.chooseSource => _actionRequired(
        title: 'Selection de source',
        message: 'Choisissez la source a utiliser.',
        reasonCode: 'source_selection_required',
        primaryAction: BootActionIntent.chooseSource,
        primaryActionLabel: 'Choisir une source',
        destination: state.destination,
        state: state,
      ),
      BootstrapDestination.home => BootScreenModel(
        screenType: BootScreenType.openingHome,
        message: "Ouverture de l'accueil",
        reasonCode: state.criteria.isHomeReady ? 'home_ready' : 'opening_home',
        isInteractive: false,
        initialFocus: BootFocusTarget.none,
        severity: BootScreenSeverity.info,
        showLogo: true,
        showProgress: true,
        destination: state.destination,
        metadata: _metadata(state),
      ),
      null => _loading(
        message: "Ouverture de l'accueil",
        reasonCode: 'opening_home',
        phase: state.phase,
      ),
    };
  }

  BootScreenModel _loading({
    required String message,
    required String reasonCode,
    required AppLaunchPhase phase,
  }) {
    return BootScreenModel(
      screenType: BootScreenType.simpleLoading,
      message: message,
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
      title: _sourceRecoveryTitle(plan.reasonCode),
      message: _sourceRecoveryMessage(plan.reasonCode),
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

  String _sourceRecoveryTitle(String reasonCode) {
    return switch (reasonCode) {
      StartupRecoveryReasonCodes.catalogSyncTimeout =>
        'La source ne repond pas',
      StartupRecoveryReasonCodes.catalogProviderError =>
        'Impossible de charger la source',
      StartupRecoveryReasonCodes.catalogCredentialsInvalid =>
        'Connexion a la source impossible',
      StartupRecoveryReasonCodes.catalogEmpty => 'Aucun contenu trouve',
      _ => 'Source requise',
    };
  }

  String _sourceRecoveryMessage(String reasonCode) {
    return switch (reasonCode) {
      StartupRecoveryReasonCodes.catalogSyncTimeout =>
        'Reessayez la synchronisation ou changez de source.',
      StartupRecoveryReasonCodes.catalogProviderError =>
        'Reessayez le chargement ou changez de source.',
      StartupRecoveryReasonCodes.catalogCredentialsInvalid =>
        'Reconnectez la source pour continuer.',
      StartupRecoveryReasonCodes.catalogEmpty =>
        'Resynchronisez la source ou choisissez-en une autre.',
      _ => 'Ajoutez ou reconnectez une source pour continuer.',
    };
  }

  String _labelForAction(BootActionIntent action) {
    return switch (action) {
      BootActionIntent.retry => 'Reessayer',
      BootActionIntent.exportLogs => 'Exporter les logs',
      BootActionIntent.login => 'Se connecter',
      BootActionIntent.createProfile => 'Continuer',
      BootActionIntent.chooseProfile => 'Choisir un profil',
      BootActionIntent.addSource => 'Ajouter une source',
      BootActionIntent.chooseSource => 'Changer de source',
      BootActionIntent.reconnectSource => 'Reconnecter la source',
      BootActionIntent.resyncSource => 'Resynchroniser',
      BootActionIntent.openHome => "Ouvrir l'accueil",
      BootActionIntent.retryHomeSections => 'Reessayer',
      BootActionIntent.retryLibrary => 'Reessayer',
    };
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
      metadata: _metadata(state),
    );
  }

  BootScreenModel _technicalFailure(AppLaunchState state) {
    return BootScreenModel(
      screenType: BootScreenType.technicalFailure,
      title: 'Lancement interrompu',
      message: 'Une erreur empeche le lancement.',
      secondaryMessage: state.recoveryMessage,
      reasonCode: state.recovery?.reasonCode ?? 'technical_failure',
      primaryAction: BootActionIntent.retry,
      primaryActionLabel: 'Reessayer',
      secondaryAction: BootActionIntent.exportLogs,
      secondaryActionLabel: 'Exporter les logs',
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
