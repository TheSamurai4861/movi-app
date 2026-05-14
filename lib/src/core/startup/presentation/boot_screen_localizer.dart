import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/startup/domain/startup_recovery_mapper.dart';
import 'package:movi/src/core/startup/presentation/boot_action_handler.dart';
import 'package:movi/src/core/startup/presentation/boot_screen_model.dart';
import 'package:movi/src/features/welcome/domain/enum.dart';

BootScreenModel localizeBootScreenModel({
  required BootScreenModel model,
  required AppLocalizations l10n,
}) {
  final localizedTitle = _localizedTitle(model, l10n);
  final localizedMessage = _localizedMessage(model, l10n);
  final localizedPrimaryLabel = model.primaryAction == null
      ? null
      : _localizedActionLabel(model.primaryAction!, l10n);
  final localizedSecondaryLabel = model.secondaryAction == null
      ? null
      : _localizedActionLabel(model.secondaryAction!, l10n);

  return BootScreenModel(
    screenType: model.screenType,
    title: localizedTitle,
    message: localizedMessage,
    secondaryMessage: model.secondaryMessage,
    reasonCode: model.reasonCode,
    primaryAction: model.primaryAction,
    primaryActionLabel: localizedPrimaryLabel,
    secondaryAction: model.secondaryAction,
    secondaryActionLabel: localizedSecondaryLabel,
    destination: model.destination,
    isInteractive: model.isInteractive,
    initialFocus: model.initialFocus,
    severity: model.severity,
    showLogo: model.showLogo,
    showProgress: model.showProgress,
    metadata: model.metadata,
  );
}

String? _localizedTitle(BootScreenModel model, AppLocalizations l10n) {
  if (model.screenType == BootScreenType.technicalFailure) {
    return l10n.bootFailureTitle;
  }

  if (model.screenType != BootScreenType.actionRequired) {
    return model.title;
  }

  if (model.destination == BootstrapDestination.auth) {
    return l10n.bootActionAuthTitle;
  }
  if (model.destination == BootstrapDestination.welcomeUser) {
    return l10n.bootActionProfileTitle;
  }
  if (model.destination == BootstrapDestination.chooseSource) {
    return l10n.bootActionSourceSelectionTitle;
  }

  return switch (model.reasonCode) {
    StartupRecoveryReasonCodes.catalogSyncTimeout =>
      l10n.bootRecoverySourceTimeoutTitle,
    StartupRecoveryReasonCodes.catalogProviderError =>
      l10n.bootRecoverySourceProviderTitle,
    StartupRecoveryReasonCodes.catalogCredentialsInvalid =>
      l10n.bootRecoverySourceCredentialsTitle,
    StartupRecoveryReasonCodes.catalogEmpty =>
      l10n.bootRecoverySourceEmptyTitle,
    _ => l10n.bootActionSourceRequiredTitle,
  };
}

String _localizedMessage(BootScreenModel model, AppLocalizations l10n) {
  if (model.screenType == BootScreenType.technicalFailure) {
    return l10n.bootFailureMessage;
  }

  return switch (model.reasonCode) {
    'technical_startup' => l10n.bootLoadingPreparingLaunch,
    'session_check' => l10n.bootLoadingCheckingSession,
    'profile_check' => l10n.bootLoadingCheckingProfile,
    'source_check' => l10n.bootLoadingCheckingSource,
    'catalog_preparing' => l10n.bootLoadingPreparingCatalog,
    'opening_home' || 'home_ready' => l10n.overlayOpeningHome,
    'auth_required' => l10n.bootActionAuthMessage,
    'profile_required' => l10n.bootActionProfileMessage,
    'source_required' => l10n.bootActionSourceRequiredMessage,
    'source_selection_required' => l10n.bootActionSourceSelectionMessage,
    StartupRecoveryReasonCodes.catalogSyncTimeout =>
      l10n.bootRecoverySourceTimeoutMessage,
    StartupRecoveryReasonCodes.catalogProviderError =>
      l10n.bootRecoverySourceProviderMessage,
    StartupRecoveryReasonCodes.catalogCredentialsInvalid =>
      l10n.bootRecoverySourceCredentialsMessage,
    StartupRecoveryReasonCodes.catalogEmpty =>
      l10n.bootRecoverySourceEmptyMessage,
    _ => model.message,
  };
}

String _localizedActionLabel(BootActionIntent action, AppLocalizations l10n) {
  return switch (action) {
    BootActionIntent.retry => l10n.actionRetry,
    BootActionIntent.exportLogs => l10n.bootActionExportLogs,
    BootActionIntent.login => l10n.bootActionLogin,
    BootActionIntent.createProfile => l10n.actionContinue,
    BootActionIntent.chooseProfile => l10n.bootActionChooseProfile,
    BootActionIntent.addSource => l10n.bootActionAddSource,
    BootActionIntent.chooseSource => l10n.bootActionChooseSource,
    BootActionIntent.reconnectSource => l10n.bootActionReconnectSource,
    BootActionIntent.resyncSource => l10n.bootActionResyncSource,
    BootActionIntent.openHome => l10n.bootActionOpenHome,
    BootActionIntent.retryHomeSections => l10n.homePartialActionRetrySections,
    BootActionIntent.retryLibrary => l10n.homePartialActionRetryLibrary,
  };
}
