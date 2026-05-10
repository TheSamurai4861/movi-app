import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/startup/domain/boot_contracts.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';

void handleHomeDegradationAction(
  WidgetRef ref,
  hp.HomeController controller,
  RecoveryAction action,
) {
  ref.read(hp.homeDegradationNoticeProvider.notifier).set(null);
  switch (action) {
    case RecoveryAction.retryHomeSections:
      unawaited(controller.refresh(reason: 'homeDegradationRetry'));
    case RecoveryAction.retryLibrary:
      ref.invalidate(hp.homeInProgressProvider);
    case RecoveryAction.resyncSource:
      unawaited(_resyncSourceThenRefreshHome(ref, controller));
    default:
      unawaited(controller.refresh(reason: 'homeDegradationRetry'));
  }
}

Future<void> _resyncSourceThenRefreshHome(
  WidgetRef ref,
  hp.HomeController controller,
) async {
  await ref
      .read(libraryCloudSyncControllerProvider.notifier)
      .syncNow(reason: 'homeDegradation');
  await controller.refresh(reason: 'homeDegradationResync');
  ref.invalidate(hp.homeInProgressProvider);
}

/// Widget affichant un message d'erreur sur la page d'accueil.
class HomeErrorBanner extends StatelessWidget {
  const HomeErrorBanner({super.key, this.notice, this.onAction});

  final hp.HomeDegradationNotice? notice;
  final ValueChanged<RecoveryAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentNotice = notice;
    final primaryAction = currentNotice?.primaryAction;
    final secondaryAction = currentNotice?.secondaryAction;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 180, maxWidth: 560),
              child: Text(
                _messageFor(context, currentNotice),
                style:
                    (theme.textTheme.bodyMedium?.copyWith(color: Colors.red)) ??
                    theme.textTheme.bodyMedium,
              ),
            ),
            if (primaryAction != null && onAction != null)
              FilledButton.tonal(
                onPressed: () => onAction!(primaryAction),
                child: Text(_labelFor(primaryAction)),
              ),
            if (secondaryAction != null && onAction != null)
              TextButton(
                onPressed: () => onAction!(secondaryAction),
                child: Text(_labelFor(secondaryAction)),
              ),
          ],
        ),
      ),
    );
  }

  String _messageFor(BuildContext context, hp.HomeDegradationNotice? notice) {
    if (notice == null) {
      return AppLocalizations.of(context)!.homeErrorSwipeToRetry;
    }
    if (notice.actions.contains(RecoveryAction.retryHomeSections) &&
        notice.actions.contains(RecoveryAction.retryLibrary)) {
      return "Certaines sections n'ont pas pu etre chargees.";
    }
    if (notice.actions.contains(RecoveryAction.retryLibrary)) {
      return "La reprise de lecture n'a pas pu etre chargee.";
    }
    if (notice.actions.contains(RecoveryAction.resyncSource)) {
      return "Les sections IPTV sont indisponibles.";
    }
    return "Une section de l'accueil n'a pas pu etre chargee.";
  }

  String _labelFor(RecoveryAction action) {
    return switch (action) {
      RecoveryAction.retryLibrary => 'Recharger la reprise',
      RecoveryAction.resyncSource => 'Resynchroniser',
      RecoveryAction.retryHomeSections => 'Recharger',
      _ => 'Reessayer',
    };
  }
}
