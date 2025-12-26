import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/parental/domain/entities/pin_recovery_result.dart';
import 'package:movi/src/core/parental/presentation/providers/pin_recovery_providers.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';

class PinRecoveryPage extends ConsumerWidget {
  const PinRecoveryPage({super.key, this.profileId});

  final String? profileId;

  String? _statusErrorText(AppLocalizations l10n, PinRecoveryStatus? error) {
    if (error == null) return null;
    return switch (error) {
      PinRecoveryStatus.invalid => l10n.pinRecoveryCodeInvalid,
      PinRecoveryStatus.expired => l10n.pinRecoveryCodeExpired,
      PinRecoveryStatus.tooManyAttempts => l10n.pinRecoveryTooManyAttempts,
      PinRecoveryStatus.notAvailable => l10n.pinRecoveryComingSoon,
      PinRecoveryStatus.unknown => l10n.pinRecoveryUnknownError,
      PinRecoveryStatus.success => null,
    };
  }

  String? _formErrorText(AppLocalizations l10n, PinRecoveryFormError? error) {
    if (error == null) return null;
    return switch (error) {
      PinRecoveryFormError.invalidCode => l10n.pinRecoveryCodeInvalid,
      PinRecoveryFormError.invalidPin => l10n.pinRecoveryPinInvalid,
      PinRecoveryFormError.pinMismatch => l10n.pinRecoveryPinMismatch,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(pinRecoveryControllerProvider);
    final controller = ref.read(pinRecoveryControllerProvider.notifier);
    final isSending = state.status == PinRecoveryUiStatus.sendingCode;
    final isVerifying = state.status == PinRecoveryUiStatus.verifying;
    final isResetting = state.status == PinRecoveryUiStatus.resetting;
    final isVerified = state.status == PinRecoveryUiStatus.verified ||
        state.status == PinRecoveryUiStatus.resetFailure ||
        state.status == PinRecoveryUiStatus.resetSuccess ||
        state.status == PinRecoveryUiStatus.resetting;
    final showCodeStep =
        state.status == PinRecoveryUiStatus.codeSent ||
        state.status == PinRecoveryUiStatus.verifyFailed ||
        state.status == PinRecoveryUiStatus.verifying ||
        isVerified;
    final errorText =
        _formErrorText(l10n, state.formError) ??
        _statusErrorText(l10n, state.error);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _HeaderBar(
              title: l10n.pinRecoveryTitle,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xl,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.pinRecoveryDescription,
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            if (!showCodeStep)
                              MoviPrimaryButton(
                                label: l10n.authOtpPrimarySend,
                                onPressed: controller.canRequestCode()
                                    ? () => controller.requestCode(
                                          profileId: profileId,
                                        )
                                    : null,
                                loading: isSending,
                              ),
                            if (showCodeStep) ...[
                              TextField(
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(8),
                                ],
                                decoration: InputDecoration(
                                  labelText: l10n.pinRecoveryCodeLabel,
                                  hintText: l10n.pinRecoveryCodeHint,
                                ),
                                onChanged: controller.setCode,
                                onSubmitted: (_) => controller.verify(),
                                enabled: !isVerifying && !isVerified,
                              ),
                            ],
                            if (isVerified) ...[
                              const SizedBox(height: AppSpacing.lg),
                              TextField(
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                decoration: InputDecoration(
                                  labelText: l10n.pinRecoveryNewPinLabel,
                                  hintText: l10n.pinRecoveryNewPinHint,
                                ),
                                onChanged: controller.setNewPin,
                                enabled: !isResetting &&
                                    state.status != PinRecoveryUiStatus.resetSuccess,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextField(
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                decoration: InputDecoration(
                                  labelText: l10n.pinRecoveryConfirmPinLabel,
                                  hintText: l10n.pinRecoveryConfirmPinHint,
                                ),
                                onChanged: controller.setConfirmPin,
                                onSubmitted: (_) => controller.resetPin(),
                                enabled: !isResetting &&
                                    state.status != PinRecoveryUiStatus.resetSuccess,
                              ),
                            ],
                            if (errorText != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                errorText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            if (showCodeStep && !isVerified)
                              MoviPrimaryButton(
                                label: l10n.pinRecoveryVerifyButton,
                                onPressed: controller.canVerify()
                                    ? controller.verify
                                    : null,
                                loading: isVerifying,
                              ),
                            if (showCodeStep && !isVerified) ...[
                              const SizedBox(height: AppSpacing.xs),
                              TextButton(
                                onPressed: state.cooldownRemaining == 0 &&
                                        controller.canRequestCode()
                                    ? () =>
                                        controller.resendCode(profileId: profileId)
                                    : null,
                                child: Text(
                                  state.cooldownRemaining > 0
                                      ? l10n.authOtpResendDisabled(
                                          state.cooldownRemaining,
                                        )
                                      : l10n.authOtpResend,
                                ),
                              ),
                            ],
                            if (isVerified)
                              MoviPrimaryButton(
                                label: l10n.pinRecoveryResetButton,
                                onPressed: controller.canReset()
                                    ? controller.resetPin
                                    : null,
                                loading: isResetting,
                              ),
                            if (state.status == PinRecoveryUiStatus.resetSuccess)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.md,
                                ),
                                child: Text(
                                  l10n.pinRecoveryResetSuccess,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: const SizedBox(
                width: 35,
                height: 35,
                child: Image(image: AssetImage(AppAssets.iconBack)),
              ),
            ),
          ),
          Center(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
