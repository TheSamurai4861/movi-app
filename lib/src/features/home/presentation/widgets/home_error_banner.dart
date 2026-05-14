import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/startup/domain/boot_contracts.dart';
import 'package:movi/src/core/startup/domain/startup_recovery_mapper.dart';
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
      return;
    case RecoveryAction.retryLibrary:
      ref.invalidate(hp.homeInProgressProvider);
      return;
    case RecoveryAction.resyncSource:
      unawaited(_resyncSourceThenRefreshHome(ref, controller));
      return;
    default:
      unawaited(controller.refresh(reason: 'homeDegradationRetry'));
      return;
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

/// Bannière non bloquante pour dégradations Home (sections, bibliothèque, IPTV).
class HomeErrorBanner extends StatelessWidget {
  const HomeErrorBanner({super.key, this.notice, this.onAction});

  final hp.HomeDegradationNotice? notice;
  final ValueChanged<RecoveryAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final currentNotice = notice;
    final primaryAction = currentNotice?.primaryAction;
    final secondaryAction = currentNotice?.secondaryAction;

    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 600;
    final outerH = compact ? AppSpacing.xs : AppSpacing.sm;
    final outerW = compact ? AppSpacing.md : AppSpacing.lg;

    final textStyle = theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onErrorContainer,
          height: compact ? 1.25 : 1.3,
        ) ??
        TextStyle(color: scheme.onErrorContainer, height: 1.3);

    final banner = DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          scheme.errorContainer.withValues(alpha: 0.55),
          scheme.surface,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          vertical: compact ? AppSpacing.xs : AppSpacing.sm,
        ),
        child: compact
            ? _CompactBannerBody(
                textStyle: textStyle,
                scheme: scheme,
                message: homePartialBannerMessage(l10n, currentNotice),
                primaryAction: primaryAction,
                secondaryAction: secondaryAction,
                onAction: onAction,
                labelFor: (a) => homePartialActionLabel(l10n, a),
              )
            : _WideBannerBody(
                textStyle: textStyle,
                scheme: scheme,
                message: homePartialBannerMessage(l10n, currentNotice),
                primaryAction: primaryAction,
                secondaryAction: secondaryAction,
                onAction: onAction,
                labelFor: (a) => homePartialActionLabel(l10n, a),
              ),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(outerW, outerH, outerW, AppSpacing.sm),
      child: banner,
    );
  }
}

/// Texte utilisateur (l10n) à partir des [reasonCodes], sans exposer les codes.
String homePartialBannerMessage(
  AppLocalizations l10n,
  hp.HomeDegradationNotice? notice,
) {
  if (notice == null) {
    return l10n.homeErrorSwipeToRetry;
  }
  final codes = notice.reasonCodes.toSet();
  if (codes.length > 1 ||
      codes.contains(StartupRecoveryReasonCodes.homePartial)) {
    return l10n.homePartialBannerMultiple;
  }
  return switch (notice.primaryReasonCode) {
    StartupRecoveryReasonCodes.homeFeedFailed => l10n.homePartialBannerFeedFailed,
    StartupRecoveryReasonCodes.homeIptvSectionsEmpty =>
      l10n.homePartialBannerIptvEmpty,
    StartupRecoveryReasonCodes.libraryPreloadTimeout ||
    StartupRecoveryReasonCodes.libraryPreloadFailed =>
      l10n.homePartialBannerLibraryUnavailable,
    _ => l10n.homePartialBannerGeneric,
  };
}

String homePartialActionLabel(AppLocalizations l10n, RecoveryAction action) {
  return switch (action) {
    RecoveryAction.retryLibrary => l10n.homePartialActionRetryLibrary,
    RecoveryAction.resyncSource => l10n.homePartialActionResyncSource,
    RecoveryAction.retryHomeSections => l10n.homePartialActionRetrySections,
    _ => l10n.homePartialActionRetryGeneric,
  };
}

class _CompactBannerBody extends StatelessWidget {
  const _CompactBannerBody({
    required this.textStyle,
    required this.scheme,
    required this.message,
    required this.primaryAction,
    required this.secondaryAction,
    required this.onAction,
    required this.labelFor,
  });

  final TextStyle textStyle;
  final ColorScheme scheme;
  final String message;
  final RecoveryAction? primaryAction;
  final RecoveryAction? secondaryAction;
  final ValueChanged<RecoveryAction>? onAction;
  final String Function(RecoveryAction) labelFor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: scheme.onErrorContainer,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(message, style: textStyle)),
          ],
        ),
        if (primaryAction != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.start,
            children: [
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: () => onAction!(primaryAction!),
                child: Text(labelFor(primaryAction!)),
              ),
              if (secondaryAction != null)
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onPressed: () => onAction!(secondaryAction!),
                  child: Text(labelFor(secondaryAction!)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _WideBannerBody extends StatelessWidget {
  const _WideBannerBody({
    required this.textStyle,
    required this.scheme,
    required this.message,
    required this.primaryAction,
    required this.secondaryAction,
    required this.onAction,
    required this.labelFor,
  });

  final TextStyle textStyle;
  final ColorScheme scheme;
  final String message;
  final RecoveryAction? primaryAction;
  final RecoveryAction? secondaryAction;
  final ValueChanged<RecoveryAction>? onAction;
  final String Function(RecoveryAction) labelFor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.warning_amber_rounded,
          size: 22,
          color: scheme.onErrorContainer,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(message, style: textStyle)),
        if (primaryAction != null && onAction != null) ...[
          const SizedBox(width: AppSpacing.sm),
          FilledButton.tonal(
            onPressed: () => onAction!(primaryAction!),
            child: Text(labelFor(primaryAction!)),
          ),
          if (secondaryAction != null) ...[
            const SizedBox(width: AppSpacing.xs),
            TextButton(
              onPressed: () => onAction!(secondaryAction!),
              child: Text(labelFor(secondaryAction!)),
            ),
          ],
        ],
      ],
    );
  }
}
