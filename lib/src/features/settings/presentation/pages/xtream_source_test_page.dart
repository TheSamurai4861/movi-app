import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/features/iptv/domain/entities/source_probe_models.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_network_profile_providers.dart';
import 'package:movi/src/features/settings/presentation/widgets/settings_content_width.dart';

class XtreamSourceTestPageArgs {
  const XtreamSourceTestPageArgs({
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.preferredRouteProfileId,
    required this.fallbackRouteProfileIds,
    this.accountId,
  });

  final String serverUrl;
  final String username;
  final String password;
  final String preferredRouteProfileId;
  final List<String> fallbackRouteProfileIds;
  final String? accountId;
}

class XtreamSourceTestPage extends ConsumerStatefulWidget {
  const XtreamSourceTestPage({super.key, required this.args});

  final XtreamSourceTestPageArgs args;

  @override
  ConsumerState<XtreamSourceTestPage> createState() =>
      _XtreamSourceTestPageState();
}

class _XtreamSourceTestPageState extends ConsumerState<XtreamSourceTestPage> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    Future<void>.microtask(_runProbe);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(xtreamSourceProbeControllerProvider);
    final result = state.result;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SettingsContentWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Test de source Xtream',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: state.isLoading ? null : _runProbe,
                      child: state.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Relancer'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SummaryCard(
                  serverUrl: widget.args.serverUrl,
                  username: widget.args.username,
                  result: result,
                  error: state.error,
                ),
                if (result != null &&
                    result.isValid &&
                    widget.args.accountId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton(
                        onPressed: () => _saveWorkingProfile(result),
                        child: const Text('Enregistrer ce profil'),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: result == null
                      ? const Center(
                          child: Text(
                            'Aucun diagnostic disponible.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView(
                          children: [
                            ...result.attempts.map(_AttemptCard.new),
                            const SizedBox(height: 16),
                            _RawResponseCard(result: result),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _runProbe() async {
    await ref
        .read(xtreamSourceProbeControllerProvider.notifier)
        .probeXtream(
          serverUrl: widget.args.serverUrl,
          username: widget.args.username,
          password: widget.args.password,
          preferredRouteProfileId: widget.args.preferredRouteProfileId,
          fallbackRouteProfileIds: widget.args.fallbackRouteProfileIds,
          accountId: widget.args.accountId,
        );
  }

  Future<void> _saveWorkingProfile(SourceProbeResult result) async {
    final fallbackIds = <String>[
      if (widget.args.preferredRouteProfileId != result.routeProfileId)
        widget.args.preferredRouteProfileId,
      ...widget.args.fallbackRouteProfileIds.where(
        (id) =>
            id != result.routeProfileId &&
            id != widget.args.preferredRouteProfileId,
      ),
    ];
    await ref
        .read(networkProfileEditControllerProvider.notifier)
        .saveSourcePolicy(
          accountId: widget.args.accountId!,
          preferredRouteProfileId: result.routeProfileId,
          fallbackRouteProfileIds: fallbackIds,
          lastWorkingRouteProfileId: result.routeProfileId,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profil prefere enregistre')));
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.serverUrl,
    required this.username,
    required this.result,
    required this.error,
  });

  final String serverUrl;
  final String username;
  final SourceProbeResult? result;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final isValid = result?.isValid == true;
    final statusLabel = error != null
        ? 'Erreur'
        : isValid
        ? 'Valide'
        : result == null
        ? 'En attente'
        : 'Echec';
    final statusColor = error != null
        ? Colors.redAccent
        : isValid
        ? Colors.green
        : Colors.orangeAccent;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF404040)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  serverUrl,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(statusLabel, style: TextStyle(color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Utilisateur: $username',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            'IP publique: ${result?.publicIp ?? 'unavailable'}',
            style: const TextStyle(color: Colors.white70),
          ),
          if (result != null) ...[
            const SizedBox(height: 6),
            Text(
              'Profil utilise: ${result!.routeProfileId}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!, style: const TextStyle(color: Colors.redAccent)),
          ] else if (result?.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              result!.errorMessage!,
              style: const TextStyle(color: Colors.orangeAccent),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttemptCard extends StatelessWidget {
  const _AttemptCard(this.attempt);

  final ProbeAttemptResult attempt;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (attempt.status) {
      ProbeAttemptStatus.success => Colors.green,
      ProbeAttemptStatus.failed => Colors.redAccent,
      ProbeAttemptStatus.notApplicable => Colors.white54,
      ProbeAttemptStatus.skipped => Colors.orangeAccent,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF404040)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${attempt.stage.name} - ${attempt.routeProfileId}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(attempt.status.name, style: TextStyle(color: statusColor)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'latency=${attempt.latencyMs}ms'
            '${attempt.httpStatusCode == null ? '' : ' http=${attempt.httpStatusCode}'}'
            '${attempt.contentType == null ? '' : ' content-type=${attempt.contentType}'}',
            style: const TextStyle(color: Colors.white70),
          ),
          if (attempt.proxyLabel != null) ...[
            const SizedBox(height: 6),
            Text(
              'route=${attempt.proxyLabel}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          if (attempt.errorKind != null) ...[
            const SizedBox(height: 6),
            Text(
              'error=${attempt.errorKind!.name}',
              style: const TextStyle(color: Colors.orangeAccent),
            ),
          ],
          if (attempt.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              attempt.errorMessage!,
              style: const TextStyle(color: Colors.white),
            ),
          ],
          if (attempt.responseSnippet != null &&
              attempt.responseSnippet!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                attempt.responseSnippet!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RawResponseCard extends StatelessWidget {
  const _RawResponseCard({required this.result});

  final SourceProbeResult result;

  @override
  Widget build(BuildContext context) {
    String? rawSnippet;
    for (final attempt in result.attempts) {
      final snippet = attempt.responseSnippet;
      if (snippet != null && snippet.trim().isNotEmpty) {
        rawSnippet = snippet;
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF404040)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reponse brute redacted',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SelectableText(
            rawSnippet ?? 'Aucune reponse brute capturee.',
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
