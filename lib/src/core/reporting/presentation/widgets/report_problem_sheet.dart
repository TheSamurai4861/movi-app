import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/core/reporting/reporting.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

class ReportProblemSheet extends ConsumerStatefulWidget {
  const ReportProblemSheet({
    super.key,
    required this.contentType,
    required this.tmdbId,
    required this.contentTitle,
  });

  final ContentType contentType;
  final int tmdbId;
  final String contentTitle;

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required ContentType contentType,
    required int tmdbId,
    required String contentTitle,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ReportProblemSheet(
        contentType: contentType,
        tmdbId: tmdbId,
        contentTitle: contentTitle,
      ),
    );
  }

  @override
  ConsumerState<ReportProblemSheet> createState() => _ReportProblemSheetState();
}

class _ReportProblemSheetState extends ConsumerState<ReportProblemSheet> {
  final _messageCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
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
          message: _messageCtrl.text.trim().isEmpty ? null : _messageCtrl.text.trim(),
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
        const SnackBar(content: Text('Signalement envoyé. Merci.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Erreur: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

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
                  'Signaler un problème',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Si ce contenu n’est pas approprié et a été accessible malgré les restrictions, décris rapidement le problème.',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageCtrl,
            enabled: !_busy,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Ex: “Film d’horreur visible alors que PEGI 12”',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2160AB),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Envoyer',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
