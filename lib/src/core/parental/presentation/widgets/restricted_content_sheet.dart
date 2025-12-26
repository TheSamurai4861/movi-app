import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/parental/presentation/providers/parental_access_providers.dart';
import 'package:movi/src/core/parental/presentation/utils/parental_reason_localizer.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';

class RestrictedContentSheet extends ConsumerStatefulWidget {
  const RestrictedContentSheet({
    super.key,
    required this.profile,
    this.title,
    this.reason,
  });

  final Profile profile;
  final String? title;
  final String? reason;

  static Future<bool> show(
    BuildContext context,
    WidgetRef ref, {
    required Profile profile,
    String? title,
    String? reason,
  }) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => RestrictedContentSheet(
        profile: profile,
        title: title,
        reason: reason,
      ),
    );
    return ok ?? false;
  }

  @override
  ConsumerState<RestrictedContentSheet> createState() =>
      _RestrictedContentSheetState();
}

class _RestrictedContentSheetState extends ConsumerState<RestrictedContentSheet> {
  final _pinController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final l10n = AppLocalizations.of(context)!;
    final accentColor = Theme.of(context).colorScheme.primary;
    
    // Convert technical reason to localized message
    final localizedReason = getLocalizedParentalReason(context, widget.reason);
    final displayReason = localizedReason ?? l10n.parentalContentRestrictedDefault;
    final displayTitle = widget.title ?? l10n.parentalContentRestricted;

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  displayTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            displayReason,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          TextField(
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
            alignment: Alignment.centerLeft,
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
                style: const TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 16),
          MoviPrimaryButton(
            label: l10n.parentalUnlockButton,
            onPressed: _busy ? null : _unlock,
            loading: _busy,
          ),
        ],
      ),
    );
  }
}
