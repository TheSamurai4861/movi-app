import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/focus/movi_overlay_focus_scope.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/core/reporting/reporting.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class ReportProblemSheet extends ConsumerStatefulWidget {
  const ReportProblemSheet({
    super.key,
    required this.contentType,
    required this.tmdbId,
    required this.contentTitle,
    this.triggerFocusNode,
  });

  final ContentType contentType;
  final int tmdbId;
  final String contentTitle;
  final FocusNode? triggerFocusNode;

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required ContentType contentType,
    required int tmdbId,
    required String contentTitle,
  }) async {
    final triggerFocusNode = FocusManager.instance.primaryFocus;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ReportProblemSheet(
        contentType: contentType,
        tmdbId: tmdbId,
        contentTitle: contentTitle,
        triggerFocusNode: triggerFocusNode,
      ),
    );
  }

  @override
  ConsumerState<ReportProblemSheet> createState() => _ReportProblemSheetState();
}

class _ReportProblemSheetState extends ConsumerState<ReportProblemSheet> {
  final _messageCtrl = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode(
    debugLabel: 'ReportProblemMessageInput',
  );
  final FocusNode _submitFocusNode = FocusNode(
    debugLabel: 'ReportProblemSubmitButton',
  );
  final FocusNode _cancelFocusNode = FocusNode(
    debugLabel: 'ReportProblemCancelButton',
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _messageFocusNode.dispose();
    _submitFocusNode.dispose();
    _cancelFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleInputKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_submitFocusNode.context != null &&
          _submitFocusNode.canRequestFocus) {
        _submitFocusNode.requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleDialogKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _submit() async {
    if (_busy) return;

    final profile = ref.read(currentProfileProvider);
    if (profile == null) {
      setState(() => _error = 'Aucun profil sélectionné.');
      return;
    }

    final client = ref.read(slProvider)<SupabaseClient>();
    final accountId = client.auth.currentUser?.id.trim();
    if (accountId == null || accountId.isEmpty) {
      setState(() => _error = 'Connexion requise.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    parental.AgeDecision? decision;
    try {
      final policy = ref.read(parental.agePolicyProvider);
      decision = await policy.evaluate(
        ContentReference(
          id: widget.tmdbId.toString(),
          type: widget.contentType,
          title: MediaTitle(widget.contentTitle),
        ),
        profile,
      );
    } catch (_) {
      decision = null;
    }

    try {
      final usecase = ref.read(slProvider)<ReportContentProblem>();
      await usecase(
        ContentReport(
          accountId: accountId,
          profileId: profile.id,
          contentType: widget.contentType,
          tmdbId: widget.tmdbId,
          contentTitle: widget.contentTitle,
          reportType: 'bypassed_parental_controls',
          message: _messageCtrl.text.trim().isEmpty
              ? null
              : _messageCtrl.text.trim(),
          profilePegiLimit: profile.pegiLimit,
          requiredPegi: decision?.requiredPegi?.value,
          minAge: decision?.minAge,
          regionUsed: decision?.regionUsed,
          rawRating: decision?.rawRating,
          decisionReason: decision?.reason,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.reportingProblemSentConfirmation,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = AppLocalizations.of(
          context,
        )!.errorGenericWithMessage(e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) => _handleDialogKey(event),
      child: MoviOverlayFocusScope(
        triggerFocusNode: widget.triggerFocusNode,
        initialFocusNode: _messageFocusNode,
        fallbackFocusNode: _cancelFocusNode,
        debugLabel: 'ReportProblemDialog',
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.45),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 20 + bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.actionReportProblem,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.reportingProblemBody,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Focus(
                      canRequestFocus: false,
                      onKeyEvent: (_, event) => _handleInputKey(event),
                      child: TextField(
                        controller: _messageCtrl,
                        focusNode: _messageFocusNode,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _submitFocusNode.requestFocus(),
                        enabled: !_busy,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: l10n.reportingProblemExampleHint,
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: cs.primary, width: 2),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _ReportDialogButton(
                      label: l10n.actionSend,
                      focusNode: _submitFocusNode,
                      previousFocusNode: _messageFocusNode,
                      nextFocusNode: _cancelFocusNode,
                      loading: _busy,
                      onPressed: _busy ? null : _submit,
                    ),
                    const SizedBox(height: 12),
                    _ReportDialogButton(
                      label: l10n.actionCancel,
                      focusNode: _cancelFocusNode,
                      previousFocusNode: _submitFocusNode,
                      isCancel: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportDialogButton extends StatelessWidget {
  const _ReportDialogButton({
    required this.label,
    required this.focusNode,
    required this.onPressed,
    this.previousFocusNode,
    this.nextFocusNode,
    this.isCancel = false,
    this.loading = false,
  });

  final String label;
  final FocusNode focusNode;
  final FocusNode? previousFocusNode;
  final FocusNode? nextFocusNode;
  final VoidCallback? onPressed;
  final bool isCancel;
  final bool loading;

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
        previousFocusNode != null) {
      if (previousFocusNode!.context != null &&
          previousFocusNode!.canRequestFocus) {
        previousFocusNode!.requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
        nextFocusNode != null) {
      if (nextFocusNode!.context != null && nextFocusNode!.canRequestFocus) {
        nextFocusNode!.requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Focus(
      onKeyEvent: (_, event) => _handleKeyEvent(event),
      child: MoviFocusableAction(
        focusNode: focusNode,
        onPressed: onPressed,
        semanticLabel: label,
        builder: (context, state) {
          final foreground = isCancel ? cs.error : cs.onSurface;
          final borderColor = isCancel
              ? cs.error.withValues(alpha: state.focused ? 1 : 0.8)
              : cs.primary.withValues(alpha: state.focused ? 1 : 0.5);
          return MoviFocusFrame(
            scale: state.focused ? 1.02 : 1,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            borderRadius: BorderRadius.circular(20),
            backgroundColor: state.focused
                ? cs.primary.withValues(alpha: 0.16)
                : cs.surfaceContainerHighest.withValues(alpha: 0.2),
            borderColor: borderColor,
            borderWidth: 2,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
