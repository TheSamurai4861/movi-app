import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/parental/presentation/providers/parental_access_providers.dart';
import 'package:movi/src/core/parental/presentation/utils/parental_reason_localizer.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/movi_overlay_focus_scope.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';

class RestrictedContentSheet extends ConsumerStatefulWidget {
  const RestrictedContentSheet({
    super.key,
    required this.profile,
    this.title,
    this.reason,
    this.triggerFocusNode,
    this.originRegionId,
    this.fallbackRegionId,
    this.overlayRegionId = AppFocusRegionId.dialogPrimary,
  });

  final Profile profile;
  final String? title;
  final String? reason;
  final FocusNode? triggerFocusNode;
  final AppFocusRegionId? originRegionId;
  final AppFocusRegionId? fallbackRegionId;
  final AppFocusRegionId overlayRegionId;

  static Future<bool> show(
    BuildContext context,
    WidgetRef ref, {
    required Profile profile,
    String? title,
    String? reason,
    FocusNode? triggerFocusNode,
    AppFocusRegionId? originRegionId,
    AppFocusRegionId? fallbackRegionId,
    AppFocusRegionId overlayRegionId = AppFocusRegionId.dialogPrimary,
  }) {
    final effectiveTriggerFocusNode =
        triggerFocusNode ?? FocusManager.instance.primaryFocus;
    final size = MediaQuery.sizeOf(context);
    final screenType = ScreenTypeResolver.instance.resolve(
      size.width,
      size.height,
    );
    final isDesktopLike =
        screenType == ScreenType.desktop || screenType == ScreenType.tv;
    final dialog = RestrictedContentSheet(
      profile: profile,
      title: title,
      reason: reason,
      triggerFocusNode: effectiveTriggerFocusNode,
      originRegionId: originRegionId,
      fallbackRegionId: fallbackRegionId,
      overlayRegionId: overlayRegionId,
    );
    final future = isDesktopLike
        ? showDialog<bool>(
            context: context,
            barrierDismissible: true,
            builder: (ctx) => dialog,
          )
        : showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => dialog,
          );
    return future.then((ok) => ok ?? false);
  }

  @override
  ConsumerState<RestrictedContentSheet> createState() =>
      _RestrictedContentSheetState();
}

class _RestrictedContentSheetState
    extends ConsumerState<RestrictedContentSheet> {
  static const double _sheetHorizontalPadding = 20;
  static const double _sheetVerticalPadding = 20;
  static const double _sheetMaxWidth = 520;

  final _pinController = TextEditingController();
  late final FocusNode _pinFocusNode = FocusNode(
    debugLabel: 'restricted_pin_field',
  );
  late final FocusNode _closeFocusNode = FocusNode(
    debugLabel: 'restricted_close_button',
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    _closeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_busy) return;
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() => _error = 'PIN invalide');
      return;
    }

    if (!widget.profile.hasPin) {
      setState(() => _error = 'Aucun PIN défini pour ce profil');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final svc = ref.read(profilePinEdgeServiceProvider);
      final valid = await svc.verifyPin(profileId: widget.profile.id, pin: pin);
      if (!mounted) return;
      if (!valid) {
        setState(() {
          _busy = false;
          _error = 'PIN incorrect';
        });
        return;
      }

      final sessionSvc = ref.read(parentalSessionServiceProvider);
      await sessionSvc.unlock(profileId: widget.profile.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Erreur: $e';
      });
    }
  }

  void _openPinRecovery() {
    final router = GoRouter.of(context);
    Navigator.of(context).pop(false);
    router.push(AppRoutePaths.pinRecovery, extra: widget.profile.id);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = colorScheme.primary;
    final size = MediaQuery.sizeOf(context);
    final screenType = ScreenTypeResolver.instance.resolve(
      size.width,
      size.height,
    );
    final isDesktopLike =
        screenType == ScreenType.desktop || screenType == ScreenType.tv;

    final localizedReason = getLocalizedParentalReason(context, widget.reason);
    final displayReason =
        localizedReason ?? l10n.parentalContentRestrictedDefault;
    final displayTitle = widget.title ?? l10n.parentalContentRestricted;

    final sheetCard = DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: isDesktopLike
            ? Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
              )
            : null,
        boxShadow: isDesktopLike
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ScrollConfiguration(
          behavior: const _RestrictedContentSheetScrollBehavior(),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayTitle,
                        textAlign: isDesktopLike
                            ? TextAlign.center
                            : TextAlign.start,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      focusNode: _closeFocusNode,
                      autofocus: false,
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  displayReason,
                  textAlign: isDesktopLike ? TextAlign.center : TextAlign.start,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                TextField(
                  focusNode: _pinFocusNode,
                  autofocus: false,
                  controller: _pinController,
                  enabled: !_busy,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'PIN',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF2C2C2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _unlock(),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: isDesktopLike
                      ? Alignment.center
                      : Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _busy ? null : _openPinRecovery,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: accentColor,
                    ),
                    child: Text(
                      l10n.pinRecoveryLink,
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 16),
                MoviPrimaryButton(
                  label: l10n.parentalUnlockButton,
                  onPressed: _busy ? null : _unlock,
                  loading: _busy,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return MoviOverlayFocusScope(
      triggerFocusNode: widget.triggerFocusNode,
      initialFocusNode: _pinFocusNode,
      fallbackFocusNode: _closeFocusNode,
      originRegionId: widget.originRegionId,
      overlayRegionId: widget.overlayRegionId,
      fallbackRegionId: widget.fallbackRegionId,
      debugLabel: 'RestrictedContentSheet',
      child: isDesktopLike
          ? Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _sheetMaxWidth),
                child: sheetCard,
              ),
            )
          : SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  _sheetHorizontalPadding,
                  _sheetVerticalPadding,
                  _sheetHorizontalPadding,
                  bottomInset + _sheetVerticalPadding,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _sheetMaxWidth),
                  child: sheetCard,
                ),
              ),
            ),
    );
  }
}

class _RestrictedContentSheetScrollBehavior extends MaterialScrollBehavior {
  const _RestrictedContentSheetScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
