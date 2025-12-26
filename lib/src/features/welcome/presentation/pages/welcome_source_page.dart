// FILE #448
// lib/src/features/welcome/presentation/pages/welcome_source_page.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
import 'package:movi/src/core/logging/logging.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/features/iptv/data/services/iptv_credentials_edge_service.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_connect_providers.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_faq_row.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_header.dart';

/// Écran "Welcome Sources".
///
/// Corrections appliquées:
/// 1) Chargement des sources Supabase avec la même stratégie que bootstrap:
///    - userId explicite via AuthRepository.currentSession.userId
///    - pas de dépendance à `supabase.auth.currentUser` (peut être temporairement null)
/// 2) Après connect() (si succès), on ne redirige vers bootstrap QUE si la source
///    est garantie côté Supabase.
///
/// Contrat choisi (Variante B - recommandée avec ton code actuel):
/// - connect() = "local + Supabase (garantie)" via policy requireSupabase
/// - la page ne fait PAS d'upsert Supabase (sinon double responsabilité + besoin du localId).
class WelcomeSourcePage extends ConsumerStatefulWidget {
  const WelcomeSourcePage({super.key});

  @override
  ConsumerState<WelcomeSourcePage> createState() => _WelcomeSourcePageState();
}

class _WelcomeSourcePageState extends ConsumerState<WelcomeSourcePage> {
  String? _selectedSourceId;

  final _nameCtrl = TextEditingController();
  final _serverCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loadingSources = false;
  String? _sourcesError;
  bool _obscurePassword = true;
  List<SupabaseIptvSourceEntity> _sources = const <SupabaseIptvSourceEntity>[];

  SupabaseIptvSourcesRepository get _supaRepo {
    final locator = ref.read(slProvider);
    return locator<SupabaseIptvSourcesRepository>();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadSupabaseSources());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _serverCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _resolveAccountIdOrNull() {
    // Même stratégie que bootstrap: on lit l'ID via AuthRepository (session).
    final auth = ref.read(authRepositoryProvider);
    final session = auth.currentSession;
    final id = session?.userId.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  bool _matchesSupabaseSource({
    required String serverUrl,
    required String username,
  }) {
    final needleUrl = serverUrl.trim().toLowerCase();
    final needleUser = username.trim().toLowerCase();
    if (needleUrl.isEmpty || needleUser.isEmpty) return false;

    for (final source in _sources) {
      final String? url = source.serverUrl;
      final String? user = source.username;
      if (url == null || user == null) continue;
      if (url.trim().toLowerCase() == needleUrl &&
          user.trim().toLowerCase() == needleUser) {
        return true;
      }
    }
    return false;
  }

  Future<void> _loadSupabaseSources() async {
    setState(() {
      _loadingSources = true;
      _sourcesError = null;
    });

    final accountId = _resolveAccountIdOrNull();
    if (accountId == null) {
      if (!mounted) return;
      setState(() {
        _loadingSources = false;
        _sources = const <SupabaseIptvSourceEntity>[];
        _sourcesError = 'Not authenticated (no session).';
      });
      unawaited(
        LoggingService.log('WelcomeSources: cannot load sources (no session)'),
      );
      return;
    }

    try {
      unawaited(
        LoggingService.log('WelcomeSources: load sources (uid=$accountId)'),
      );

      // IMPORTANT: accountId explicite (évite auth.currentUser null).
      final rows = await _supaRepo.getSources(accountId: accountId);

      if (!mounted) return;
      setState(() {
        _sources = rows;
        _loadingSources = false;
      });

      // Auto-sélection + pré-remplissage si possible
      if (_sources.isNotEmpty && _selectedSourceId == null) {
        _selectSource(_sources.first);
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _loadingSources = false;
        _sourcesError = e.toString();
      });

      if (kDebugMode) {
        debugPrint('[WelcomeSourcePage] getSources failed: $e\n$st');
      }
      unawaited(LoggingService.log('WelcomeSources: getSources failed: $e'));
    }
  }

  void _selectSource(SupabaseIptvSourceEntity source) {
    setState(() {
      _selectedSourceId = source.id;

      // Pré-remplissage si l'entity expose serverUrl/username.
      var serverUrl = source.serverUrl?.trim();
      final String? username = source.username?.trim();

      // Détecter et ignorer les URLs invalides stockées avec toString() au lieu de toRawUrl()
      if (serverUrl != null && serverUrl.isNotEmpty) {
        // Si l'URL contient "XtreamEndpoint" ou "Instance of", c'est invalide
        if (serverUrl.contains('XtreamEndpoint') ||
            serverUrl.startsWith('Instance of')) {
          if (kDebugMode) {
            debugPrint(
              '[WelcomeSourcePage] Invalid serverUrl format detected: "$serverUrl". '
              'Clearing field for manual entry.',
            );
          }
          // Ne pas pré-remplir si l'URL est invalide
          serverUrl = null;
        }
      }

      if (serverUrl != null && serverUrl.isNotEmpty) {
        _serverCtrl.text = serverUrl;
      }
      if (username != null && username.isNotEmpty) {
        _userCtrl.text = username;
      }
      _nameCtrl.text = source.name.trim();
    });

    // Best-effort: if the source has encrypted credentials (Edge Function),
    // auto-prefill the password so the user doesn't need to retype it.
    unawaited(_maybePrefillPassword(source));
  }

  Future<void> _maybePrefillPassword(SupabaseIptvSourceEntity source) async {
    if (!mounted) return;
    if (_passCtrl.text.trim().isNotEmpty) return;

    final ciphertext = source.encryptedCredentials?.trim();
    if (ciphertext == null || ciphertext.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[WelcomeSourcePage] No encrypted credentials for source ${source.id}',
        );
      }
      return;
    }

    // Vérifier que le ciphertext est au format attendu par l'Edge Function
    // Formats supportés :
    // - v1.<iv>.<data>
    // - v1:<base64(iv||data)>
    if (!ciphertext.startsWith('v1.')) {
      if (!ciphertext.startsWith('v1:')) {
        if (kDebugMode) {
          debugPrint(
            '[WelcomeSourcePage] Ciphertext is not in a supported Edge Function format (expected v1.<iv>.<data> or v1:<base64>, got: ${ciphertext.substring(0, ciphertext.length > 50 ? 50 : ciphertext.length)}...)',
          );
        }
        return;
      }
    }

    // Pour le format v1.<iv>.<data>, vérifier qu'il y a bien 3 parties séparées par des points
    if (ciphertext.contains('.')) {
      final parts = ciphertext.split('.');
      if (parts.length != 3) {
        if (kDebugMode) {
          debugPrint(
            '[WelcomeSourcePage] Invalid ciphertext format: expected 3 parts separated by ".", got ${parts.length}',
          );
        }
        return;
      }
    }

    try {
      final locator = ref.read(slProvider);
      if (!locator.isRegistered<IptvCredentialsEdgeService>()) {
        if (kDebugMode) {
          debugPrint(
            '[WelcomeSourcePage] IptvCredentialsEdgeService not registered',
          );
        }
        // Réessayer après un court délai au cas où le service n'est pas encore enregistré
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        if (!locator.isRegistered<IptvCredentialsEdgeService>()) return;
      }
      final edge = locator<IptvCredentialsEdgeService>();
      final creds = await edge.decrypt(ciphertext: ciphertext);
      if (!mounted) return;
      if (_passCtrl.text.trim().isEmpty && creds.password.isNotEmpty) {
        setState(() {
          _passCtrl.text = creds.password;
        });
        if (kDebugMode) {
          debugPrint(
            '[WelcomeSourcePage] Password prefilled from edge function',
          );
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[WelcomeSourcePage] Failed to decrypt password: $e\n$st');
      }
      // best-effort: ne pas bloquer l'utilisateur
    }
  }

  Future<void> _activate() async {
    final l10n = AppLocalizations.of(context)!;

    final accountId = _resolveAccountIdOrNull();
    if (accountId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorUnknown)));
      GoRouter.of(context).go(AppRouteNames.authOtp);
      return;
    }

    final serverUrl = _serverCtrl.text.trim();
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final alias = _nameCtrl.text.trim();

    if (serverUrl.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorFillFields)));
      return;
    }

    final controller = ref.read(iptvConnectControllerProvider.notifier);

    // IMPORTANT:
    // - Si on active une source déjà présente sur Supabase (sélection dans la liste),
    //   le bootstrap ne dépend pas d’un nouvel upsert => localOnly suffit.
    // - Sinon (ajout manuel), on exige Supabase pour éviter la boucle "0 source -> welcomeSources".
    final policy =
        (_selectedSourceId != null ||
            _matchesSupabaseSource(serverUrl: serverUrl, username: username))
        ? IptvConnectSupabasePolicy.localOnly
        : IptvConnectSupabasePolicy.requireSupabase;
    controller.setSupabasePolicy(policy);

    unawaited(
      LoggingService.log(
        'WelcomeSources: activate attempt uid=$accountId selected=$_selectedSourceId policy=${policy.name}',
      ),
    );

    final success = await controller.connect(
      sourceType: IptvSourceType.xtream,
      serverUrl: serverUrl,
      username: username,
      password: password,
      alias: alias,
    );

    if (!mounted) return;

    if (success) {
      unawaited(LoggingService.log('WelcomeSources: activate success'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.snackbarSourceAddedBackground)),
      );
      // Redirection vers la page de chargement pour attendre le chargement complet des playlists
      GoRouter.of(context).go(AppRouteNames.welcomeSourceLoading);
      return;
    }

    final error =
        ref.read(iptvConnectControllerProvider).error ?? l10n.errorUnknown;

    unawaited(
      LoggingService.log('WelcomeSources: activate failed error=$error'),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.errorConnectionFailed(error))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final connectState = ref.watch(iptvConnectControllerProvider);
    final accentColor = ref.watch(asp.currentAccentColorProvider);

    final isBusy = _loadingSources || connectState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WelcomeHeader(
                    title: l10n.welcomeSourceTitle,
                    subtitle: l10n.welcomeSourceSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ---------------- Sources Supabase ----------------
                  _SectionHeader(
                    title: 'Sources sauvegardées',
                    forceRow: true,
                    trailing: IconButton(
                      tooltip: 'Rafraîchir',
                      onPressed: isBusy
                          ? null
                          : () => unawaited(_loadSupabaseSources()),
                      icon: Icon(Icons.refresh, color: accentColor),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  if (_loadingSources)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(),
                    )
                  else if (_sourcesError != null)
                    _ErrorBox(
                      message: _sourcesError!,
                      onRetry: () => unawaited(_loadSupabaseSources()),
                    )
                  else if (_sources.isEmpty)
                    const _InfoBox(
                      message:
                          'Aucune source trouvée sur Supabase. Ajoute/active une source ci-dessous.',
                    )
                  else
                    _SourcesList(
                      sources: _sources,
                      selectedId: _selectedSourceId,
                      onSelect: _selectSource,
                    ),

                  const SizedBox(height: AppSpacing.lg),

                  // ---------------- Activation ----------------
                  _SectionHeader(title: 'Activer une source'),
                  const SizedBox(height: AppSpacing.sm),

                  TextField(
                    controller: _nameCtrl,
                    enabled: !isBusy,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la source',
                      hintText: 'Mon IPTV',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  TextField(
                    controller: _serverCtrl,
                    enabled: !isBusy,
                    decoration: const InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'https://example.com:port',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  TextField(
                    controller: _userCtrl,
                    enabled: !isBusy,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  TextField(
                    controller: _passCtrl,
                    enabled: !isBusy,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  if (connectState.warning != null &&
                      connectState.supabasePolicy !=
                          IptvConnectSupabasePolicy.localOnly) ...[
                    _InfoBox(message: connectState.warning!),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: MoviPrimaryButton(
                      label: 'Activer',
                      onPressed: isBusy ? null : _activate,
                      loading: connectState.isLoading,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  const WelcomeFaqRow(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
    this.forceRow = false,
  });

  final String title;
  final Widget? trailing;
  final bool forceRow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleWidget = Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );

        if (trailing == null) return titleWidget;

        final isNarrow = constraints.maxWidth < 360;
        if (isNarrow && !forceRow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleWidget,
              Align(alignment: Alignment.centerRight, child: trailing!),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: titleWidget),
            trailing!,
          ],
        );
      },
    );
  }
}

class _SourcesList extends StatelessWidget {
  const _SourcesList({
    required this.sources,
    required this.selectedId,
    required this.onSelect,
  });

  final List<SupabaseIptvSourceEntity> sources;
  final String? selectedId;
  final void Function(SupabaseIptvSourceEntity source) onSelect;

  String _formatDateOnly(BuildContext context, DateTime value) {
    final local = value.toLocal();
    return MaterialLocalizations.of(context).formatCompactDate(local);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (final s in sources)
            ListTile(
              onTap: () => onSelect(s),
              title: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                s.expiresAt != null
                    ? 'Expire: ${_formatDateOnly(context, s.expiresAt!)}'
                    : 'Aucune date d’expiration',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: selectedId == s.id
                  ? const Icon(Icons.check_circle)
                  : const Icon(Icons.circle_outlined),
            ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppLocalizations.of(context)!.errorUnknown}: $message',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRetry,
                child: Text(AppLocalizations.of(context)!.actionRetry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Align(alignment: Alignment.centerLeft, child: Text(message)),
      ),
    );
  }
}
