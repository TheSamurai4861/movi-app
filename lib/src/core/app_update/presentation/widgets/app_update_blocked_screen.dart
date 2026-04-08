import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:movi/src/core/app_update/domain/entities/app_update_decision.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';

class AppUpdateBlockedScreen extends StatefulWidget {
  const AppUpdateBlockedScreen({
    super.key,
    required this.decision,
    required this.onRetry,
  });

  final AppUpdateDecision decision;
  final VoidCallback onRetry;

  @override
  State<AppUpdateBlockedScreen> createState() => _AppUpdateBlockedScreenState();
}

class _AppUpdateBlockedScreenState extends State<AppUpdateBlockedScreen> {
  bool _openingStore = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decision = widget.decision;
    final showStoreButton = decision.updateUrl != null;
    final title = decision.isBlocking
        ? 'Mise à jour requise'
        : 'Mise à jour disponible';
    final description =
        decision.message ??
        'Une version plus récente de Movi est requise pour continuer.';

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.system_update_rounded,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _VersionSummary(decision: decision),
                const SizedBox(height: 24),
                if (showStoreButton)
                  MoviPrimaryButton(
                    label: 'Ouvrir la mise à jour',
                    loading: _openingStore,
                    onPressed: _openingStore ? null : _openStore,
                  ),
                if (showStoreButton) const SizedBox(height: 12),
                TextButton(
                  onPressed: widget.onRetry,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStore() async {
    final url = widget.decision.updateUrl;
    if (url == null) return;

    setState(() => _openingStore = true);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } finally {
      if (mounted) {
        setState(() => _openingStore = false);
      }
    }
  }
}

class _VersionSummary extends StatelessWidget {
  const _VersionSummary({required this.decision});

  final AppUpdateDecision decision;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoRow(label: 'Version installée', value: decision.currentVersion),
            if (decision.minSupportedVersion != null)
              _InfoRow(
                label: 'Version minimale',
                value: decision.minSupportedVersion!,
              ),
            if (decision.latestVersion != null)
              _InfoRow(label: 'Dernière version', value: decision.latestVersion!),
            _InfoRow(label: 'Plateforme', value: decision.platform),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(width: 12),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
