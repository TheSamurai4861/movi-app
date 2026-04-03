import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/diagnostics/application/usecases/build_diagnostic_bundle.dart';
import 'package:movi/src/core/diagnostics/infrastructure/export/diagnostic_export_repository.dart';
import 'package:movi/src/core/diagnostics/infrastructure/identity/diagnostic_identity_hasher.dart';
import 'package:movi/src/core/diagnostics/infrastructure/logs/log_file_reader.dart';
import 'package:movi/src/core/diagnostics/infrastructure/sanitizer/diagnostic_sanitizer.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/core/supabase/supabase_providers.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';

class ExportDiagnosticsSheet extends ConsumerStatefulWidget {
  const ExportDiagnosticsSheet({super.key});

  static Future<void> show(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ExportDiagnosticsSheet(),
    );
  }

  @override
  ConsumerState<ExportDiagnosticsSheet> createState() =>
      _ExportDiagnosticsSheetState();
}

class _ExportDiagnosticsSheetState extends ConsumerState<ExportDiagnosticsSheet> {
  bool _busy = false;
  String? _error;
  String? _success;
  bool _includeHashedIds = true;

  static const int _maxLogLinesToScan = 2000;

  BuildDiagnosticBundle _buildUseCase(AppMetadata metadata) {
    final locator = ref.read(slProvider);
    final secure = locator<SecurePayloadStore>();
    return BuildDiagnosticBundle(
      metadata,
      const LogFileReader(),
      const DiagnosticSanitizer(),
      DiagnosticIdentityHasher(secure),
    );
  }

  Future<void> _copy() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      final metadata = ref.read(appMetadataProvider);
      final usecase = _buildUseCase(metadata);
      final bundle = await usecase(
        maxLogLinesToScan: _maxLogLinesToScan,
        includeHashedIdentity: _includeHashedIds,
        accountId: ref.read(supabaseClientProvider)?.auth.currentUser?.id,
        profileId: ref.read(currentProfileProvider)?.id,
      );
      await Clipboard.setData(ClipboardData(text: bundle.toPrettyJson()));
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _busy = false;
        _success = l10n.diagnosticsCopiedClipboard;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Erreur: $e';
      });
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      final metadata = ref.read(appMetadataProvider);
      final usecase = _buildUseCase(metadata);
      final bundle = await usecase(
        maxLogLinesToScan: _maxLogLinesToScan,
        includeHashedIdentity: _includeHashedIds,
        accountId: ref.read(supabaseClientProvider)?.auth.currentUser?.id,
        profileId: ref.read(currentProfileProvider)?.id,
      );
      final export = await const DiagnosticExportRepository().saveToDocuments(
        bundle: bundle,
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _busy = false;
        _success = l10n.diagnosticsSavedFile(export.fileName);
      });
      await Clipboard.setData(ClipboardData(text: export.path));
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
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.diagnosticsExportTitle,
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
            l10n.diagnosticsExportDescription,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile.adaptive(
              value: _includeHashedIds,
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _includeHashedIds = v),
              title: Text(
                l10n.diagnosticsIncludeHashedIdsTitle,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                l10n.diagnosticsIncludeHashedIdsSubtitle,
                style: const TextStyle(color: Colors.white70),
              ),
              activeTrackColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          if (_success != null) ...[
            const SizedBox(height: 12),
            Text(_success!, style: const TextStyle(color: Colors.white70)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _busy ? null : _copy,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      shape: const StadiumBorder(),
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
                        : Text(
                            l10n.diagnosticsActionCopy,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MoviPrimaryButton(
                  label: l10n.diagnosticsActionSave,
                  loading: _busy,
                  onPressed: _busy ? null : _save,
                  expand: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

