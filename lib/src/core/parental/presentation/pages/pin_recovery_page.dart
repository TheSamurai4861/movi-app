import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/focus/movi_focus_restore_policy.dart';
import 'package:movi/src/core/focus/movi_route_focus_boundary.dart';
import 'package:movi/src/core/parental/domain/entities/pin_recovery_result.dart';
import 'package:movi/src/core/parental/presentation/providers/pin_recovery_providers.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/core/widgets/movi_subpage_back_title_header.dart';

class PinRecoveryPage extends ConsumerStatefulWidget {
  const PinRecoveryPage({super.key, this.profileId});

  final String? profileId;

  @override
  ConsumerState<PinRecoveryPage> createState() => _PinRecoveryPageState();
}

class _PinRecoveryPageState extends ConsumerState<PinRecoveryPage> {
  static const double _contentBottomPadding = 24;
  static const double _formMaxWidth = 460;

  final FocusNode _backFocusNode = FocusNode(debugLabel: 'PinRecoveryBack');
  final FocusNode _requestCodeFocusNode = FocusNode(
    debugLabel: 'PinRecoveryRequestCode',
  );
  final FocusNode _codeFocusNode = FocusNode(debugLabel: 'PinRecoveryCode');
  final FocusNode _newPinFocusNode = FocusNode(debugLabel: 'PinRecoveryNewPin');
  final FocusNode _confirmPinFocusNode = FocusNode(
    debugLabel: 'PinRecoveryConfirmPin',
  );
  final FocusNode _verifyFocusNode = FocusNode(debugLabel: 'PinRecoveryVerify');
  final FocusNode _resetFocusNode = FocusNode(debugLabel: 'PinRecoveryReset');
  ProviderSubscription<PinRecoveryUiState>? _pinRecoverySub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pinRecoveryControllerProvider.notifier).resetFlow();
    });
    _pinRecoverySub = ref.listenManual<PinRecoveryUiState>(
      pinRecoveryControllerProvider,
      (previous, next) {
        if (!mounted) return;
        if (previous?.status == PinRecoveryUiStatus.resetSuccess ||
            next.status != PinRecoveryUiStatus.resetSuccess) {
          return;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).maybePop(true);
        });
      },
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _pinRecoverySub?.close();
    _backFocusNode.dispose();
    _requestCodeFocusNode.dispose();
    _codeFocusNode.dispose();
    _newPinFocusNode.dispose();
    _confirmPinFocusNode.dispose();
    _verifyFocusNode.dispose();
    _resetFocusNode.dispose();
    super.dispose();
  }

  String? _statusErrorText(AppLocalizations l10n, PinRecoveryStatus? error) {
    if (error == null) return null;
    return switch (error) {
      PinRecoveryStatus.invalid => l10n.pinRecoveryCodeInvalid,
      PinRecoveryStatus.expired => l10n.pinRecoveryCodeExpired,
      PinRecoveryStatus.tooManyAttempts => l10n.pinRecoveryTooManyAttempts,
      PinRecoveryStatus.notAvailable => l10n.pinRecoveryNotAvailable,
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(pinRecoveryControllerProvider);
    final controller = ref.read(pinRecoveryControllerProvider.notifier);
    final isSending = state.status == PinRecoveryUiStatus.sendingCode;
    final isVerifying = state.status == PinRecoveryUiStatus.verifying;
    final isResetting = state.status == PinRecoveryUiStatus.resetting;
    final isVerified =
        state.status == PinRecoveryUiStatus.verified ||
        state.status == PinRecoveryUiStatus.resetFailure ||
        state.status == PinRecoveryUiStatus.resetSuccess ||
        state.status == PinRecoveryUiStatus.resetting;
    final hasStartedCodeFlow =
        state.status == PinRecoveryUiStatus.sendingCode ||
        state.status == PinRecoveryUiStatus.codeSent ||
        state.status == PinRecoveryUiStatus.verifyFailed ||
        state.status == PinRecoveryUiStatus.verifying ||
        state.code.isNotEmpty;
    final showCodeStep = hasStartedCodeFlow || isVerified;
    final errorText =
        _formErrorText(l10n, state.formError) ??
        _statusErrorText(l10n, state.error);

    final initialFocusNode = showCodeStep
        ? (isVerified ? _newPinFocusNode : _codeFocusNode)
        : _requestCodeFocusNode;
    final fallbackFocusNode = isVerified ? _resetFocusNode : _verifyFocusNode;

    return MoviRouteFocusBoundary(
      restorePolicy: MoviFocusRestorePolicy(
        initialFocusNode: initialFocusNode,
        fallbackFocusNode: fallbackFocusNode,
      ),
      requestInitialFocusOnMount: true,
      onUnhandledBack: () {
        if (!context.mounted) return false;
        Navigator.of(context).maybePop();
        return true;
      },
      debugLabel: 'PinRecoveryRouteFocus',
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: MoviSubpageBackTitleHeader(
                  title: l10n.pinRecoveryTitle,
                  focusNode: _backFocusNode,
                  onBack: () => Navigator.of(context).maybePop(),
                  pageHorizontalPadding: 0,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    _contentBottomPadding,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _formMaxWidth,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                              label: l10n.pinRecoveryRequestCodeButton,
                              focusNode: _requestCodeFocusNode,
                              onPressed: controller.canRequestCode()
                                  ? () => controller.requestCode(
                                      profileId: widget.profileId,
                                    )
                                  : null,
                              loading: isSending,
                            ),
                          if (showCodeStep) ...[
                            if (state.status ==
                                PinRecoveryUiStatus.codeSent) ...[
                              Text(
                                l10n.pinRecoveryCodeSentHint,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            TextField(
                              focusNode: _codeFocusNode,
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
                              focusNode: _newPinFocusNode,
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
                              onSubmitted: (_) =>
                                  _confirmPinFocusNode.requestFocus(),
                              enabled:
                                  !isResetting &&
                                  state.status !=
                                      PinRecoveryUiStatus.resetSuccess,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextField(
                              focusNode: _confirmPinFocusNode,
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
                              enabled:
                                  !isResetting &&
                                  state.status !=
                                      PinRecoveryUiStatus.resetSuccess,
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
                              focusNode: _verifyFocusNode,
                              onPressed: controller.canVerify()
                                  ? controller.verify
                                  : null,
                              loading: isVerifying,
                            ),
                          if (showCodeStep && !isVerified) ...[
                            const SizedBox(height: AppSpacing.xs),
                            TextButton(
                              onPressed:
                                  state.cooldownRemaining == 0 &&
                                      controller.canRequestCode()
                                  ? () => controller.resendCode(
                                      profileId: widget.profileId,
                                    )
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
                              focusNode: _resetFocusNode,
                              onPressed: controller.canReset()
                                  ? controller.resetPin
                                  : null,
                              loading: isResetting,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
