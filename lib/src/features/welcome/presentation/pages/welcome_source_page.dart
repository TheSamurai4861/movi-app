import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/presentation/focus_directional_navigation.dart';
import 'package:movi/src/core/focus/presentation/focus_orchestrator_provider.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';
import 'package:movi/src/core/logging/logging.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/startup/presentation/widgets/launch_recovery_banner.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
import 'package:movi/src/features/iptv/data/services/iptv_credentials_edge_service.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_connect_providers.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_faq_row.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_header.dart';

/// Écran "Welcome Sources".
///
/// L'écran supporte désormais le mode local-first:
/// - la liste remote est optionnelle
/// - l'ajout manuel d'une source reste possible sans session cloud
/// - la persistance Supabase devient best-effort
class WelcomeSourcePage extends ConsumerStatefulWidget {
  const WelcomeSourcePage({super.key});

  @override
  ConsumerState<WelcomeSourcePage> createState() => _WelcomeSourcePageState();
}

class _WelcomeSourcePageState extends ConsumerState<WelcomeSourcePage>
    with TickerProviderStateMixin {
  final _retryFocusNode = FocusNode(debugLabel: 'WelcomeSourceRetry');
  String? _selectedSourceId;

  final _nameCtrl = TextEditingController();
  final _serverCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _refreshFocusNode = FocusNode(debugLabel: 'WelcomeSourceRefresh');
  final _sourcesErrorRetryFocusNode = FocusNode(
    debugLabel: 'WelcomeSourceErrorRetry',
  );
  final _nameFocusNode = FocusNode(debugLabel: 'WelcomeSourceName');
  final _serverFocusNode = FocusNode(debugLabel: 'WelcomeSourceServer');
  final _userFocusNode = FocusNode(debugLabel: 'WelcomeSourceUser');
  final _passFocusNode = FocusNode(debugLabel: 'WelcomeSourcePassword');
  final _passwordToggleFocusNode = FocusNode(
    debugLabel: 'WelcomeSourcePasswordToggle',
  );
  final _submitFocusNode = FocusNode(debugLabel: 'WelcomeSourceSubmit');
  final List<FocusNode> _savedSourceFocusNodes = <FocusNode>[];

  bool _loadingSources = false;
  String? _sourcesError;
  bool _obscurePassword = true;
  bool _isHandlingBack = false;
  List<SupabaseIptvSourceEntity> _sources = const <SupabaseIptvSourceEntity>[];

  // Animation pour le bouton refresh
  late AnimationController _refreshAnimationController;
  late Animation<double> _refreshAnimation;

  bool _hasSupabaseAccess = false;

  bool get _shouldDisplaySavedSourcesSection {
    return _hasSupabaseAccess &&
        (_sources.isNotEmpty || _sourcesError != null || _loadingSources);
  }

  SupabaseIptvSourcesRepository? get _supaRepo {
    final locator = ref.read(slProvider);
    if (!locator.isRegistered<SupabaseIptvSourcesRepository>()) {
      return null;
    }
    return locator<SupabaseIptvSourcesRepository>();
  }

  @override
  void initState() {
    super.initState();

    // Initialisation de l'animation du bouton refresh
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _refreshAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_refreshAnimationController);

    unawaited(_loadSupabaseSources());
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    _retryFocusNode.dispose();
    _refreshFocusNode.dispose();
    _sourcesErrorRetryFocusNode.dispose();
    _nameCtrl.dispose();
    _serverCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _nameFocusNode.dispose();
    _serverFocusNode.dispose();
    _userFocusNode.dispose();
    _passFocusNode.dispose();
    _passwordToggleFocusNode.dispose();
    _submitFocusNode.dispose();
    for (final node in _savedSourceFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncSavedSourceFocusNodes(int count) {
    while (_savedSourceFocusNodes.length < count) {
      _savedSourceFocusNodes.add(
        FocusNode(
          debugLabel: 'WelcomeSourceSaved${_savedSourceFocusNodes.length}',
        ),
      );
    }
    while (_savedSourceFocusNodes.length > count) {
      _savedSourceFocusNodes.removeLast().dispose();
    }
  }

  bool _enterFocusRegion(AppFocusRegionId regionId) {
    return ref
        .read(focusOrchestratorProvider)
        .enterRegion(regionId, restoreLastFocused: false);
  }

  KeyEventResult _handleRouteBackKey(KeyEvent event, BuildContext context) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      return _handleBack(context)
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  String? _determineFallbackRoute(BuildContext context) {
    if (context.canPop()) {
      return null;
    }

    final currentLocation = GoRouterState.of(context).uri.toString();
    if (currentLocation.startsWith(AppRoutePaths.welcome)) {
      return AppRouteNames.welcomeUser;
    }
    return AppRouteNames.iptvSources;
  }

  bool _handleBack(BuildContext context) {
    if (!context.mounted || _isHandlingBack) {
      return false;
    }
    _isHandlingBack = true;
    final fallbackRoute = _determineFallbackRoute(context);
    if (fallbackRoute == null) {
      context.pop();
    } else {
      context.go(fallbackRoute);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _isHandlingBack = false;
      }
    });
    return true;
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

  Future<void> _loadSupabaseSources({bool animateRefreshButton = false}) async {
    if (animateRefreshButton) {
      _refreshAnimationController.forward(from: 0.0);
    }

    setState(() {
      _loadingSources = true;
      _sourcesError = null;
    });

    final repo = _supaRepo;
    final accountId = _resolveAccountIdOrNull();
    if (repo == null || accountId == null) {
      if (!mounted) return;
      setState(() {
        _loadingSources = false;
        _sources = const <SupabaseIptvSourceEntity>[];
        _sourcesError = null;
        _hasSupabaseAccess = false;
      });
      unawaited(
        LoggingService.log(
          'WelcomeSources: remote sources unavailable -> local mode',
        ),
      );
      return;
    }

    try {
      unawaited(
        LoggingService.log('WelcomeSources: load sources (uid=$accountId)'),
      );

      // IMPORTANT: accountId explicite (évite auth.currentUser null).
      final rows = await repo.getSources(accountId: accountId);

      if (!mounted) return;
      setState(() {
        _sources = rows;
        _loadingSources = false;
        _hasSupabaseAccess = true;
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
        _sources = const <SupabaseIptvSourceEntity>[];
        _hasSupabaseAccess = true;
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

    final policy =
        (_selectedSourceId != null ||
            _matchesSupabaseSource(serverUrl: serverUrl, username: username))
        ? IptvConnectSupabasePolicy.localOnly
        : IptvConnectSupabasePolicy.bestEffortSupabase;
    controller.setSupabasePolicy(policy);

    unawaited(
      LoggingService.log(
        'WelcomeSources: activate attempt uid=${_resolveAccountIdOrNull() ?? "local"} selected=$_selectedSourceId policy=${policy.name}',
      ),
    );

    final success = await controller.connect(
      sourceType: IptvSourceType.xtream,
      serverUrl: serverUrl,
      username: username,
      password: password,
      alias: alias,
      runCatalogSyncInBackground: false,
    );

    if (!mounted) return;

    if (success) {
      unawaited(
        LoggingService.log(
          'WelcomeSources: activate success - redirecting to loading page',
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.snackbarSourceAddedBackground)),
      );
      if (mounted) {
        GoRouter.of(context).goNamed(
          AppRouteIds.welcomeSourceLoading,
          queryParameters: const <String, String>{'force_reload': '1'},
        );
      }
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
    final launchRecovery = ref.watch(appLaunchStateProvider).recovery;

    final isBusy = _loadingSources || connectState.isLoading;
    final hasSavedSources =
        _shouldDisplaySavedSourcesSection && _sources.isNotEmpty;
    if (hasSavedSources) {
      _syncSavedSourceFocusNodes(_sources.length);
    } else {
      _syncSavedSourceFocusNodes(0);
    }
    final initialFocusNode = hasSavedSources
        ? _savedSourceFocusNodes.first
        : _nameFocusNode;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: FocusRegionScope(
        regionId: AppFocusRegionId.welcomePrimary,
        binding: FocusRegionBinding(
          resolvePrimaryEntryNode: () => initialFocusNode,
          resolveFallbackEntryNode: () => _submitFocusNode,
        ),
        requestFocusOnMount: true,
        handleDirectionalExits: false,
        debugLabel: 'WelcomeSourcePrimaryRegion',
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: (_, event) => _handleRouteBackKey(event, context),
          child: Scaffold(
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
                        if (launchRecovery?.isRetryable ?? false) ...[
                          const SizedBox(height: AppSpacing.md),
                          MoviEnsureVisibleOnFocus(
                            verticalAlignment: 0.18,
                            child: Focus(
                              canRequestFocus: false,
                              onKeyEvent: (_, event) => FocusDirectionalNavigation.handleDirectionalKey(
                                event,
                                down: _shouldDisplaySavedSourcesSection
                                    ? (_sourcesError != null
                                          ? _sourcesErrorRetryFocusNode
                                          : hasSavedSources
                                          ? _savedSourceFocusNodes.first
                                          : _refreshFocusNode)
                                    : _nameFocusNode,
                                blockLeft: true,
                                blockRight: true,
                                blockUp: true,
                              ),
                              child: LaunchRecoveryBanner(
                                message: launchRecovery!.message,
                                retryFocusNode: _retryFocusNode,
                                onRetry: () {
                                  ref
                                      .read(
                                        appLaunchOrchestratorProvider.notifier,
                                      )
                                      .reset();
                                  context.go(AppRouteNames.launch);
                                },
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),

                        // ---------------- Sources Supabase ----------------
                        // Afficher seulement si Supabase est disponible
                        if (_shouldDisplaySavedSourcesSection) ...[
                          _SectionHeader(
                            title: 'Sources sauvegardées',
                            forceRow: true,
                            trailing: AnimatedBuilder(
                              animation: _refreshAnimation,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle:
                                      _refreshAnimation.value *
                                      2 *
                                      3.14159, // Rotation complète
                                  child: Focus(
                                    canRequestFocus: false,
                                    onKeyEvent: (_, event) =>
                                        FocusDirectionalNavigation.handleDirectionalKey(
                                          event,
                                          up:
                                              launchRecovery?.isRetryable ??
                                                  false
                                              ? _retryFocusNode
                                              : null,
                                          down: hasSavedSources
                                              ? _savedSourceFocusNodes.first
                                              : _nameFocusNode,
                                          blockLeft: true,
                                          blockRight: true,
                                        ),
                                    child: IconButton(
                                      focusNode: _refreshFocusNode,
                                      tooltip: 'Rafraîchir',
                                      onPressed: isBusy
                                          ? null
                                          : () => unawaited(
                                              _loadSupabaseSources(
                                                animateRefreshButton: true,
                                              ),
                                            ),
                                      icon: Icon(
                                        Icons.refresh,
                                        color: accentColor,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          if (_loadingSources)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: CircularProgressIndicator(),
                            )
                          else if (_sourcesError != null)
                            MoviEnsureVisibleOnFocus(
                              verticalAlignment: 0.22,
                              child: Focus(
                                canRequestFocus: false,
                                onKeyEvent: (_, event) => FocusDirectionalNavigation.handleDirectionalKey(
                                  event,
                                  up: launchRecovery?.isRetryable ?? false
                                      ? _retryFocusNode
                                      : _refreshFocusNode,
                                  down: _nameFocusNode,
                                  blockLeft: true,
                                  blockRight: true,
                                ),
                                child: _ErrorBox(
                                  message: _sourcesError!,
                                  retryFocusNode: _sourcesErrorRetryFocusNode,
                                  onRetry: () =>
                                      unawaited(_loadSupabaseSources()),
                                ),
                              ),
                            )
                          else if (_sources.isEmpty)
                            const _InfoBox(
                              message:
                                  'Aucune source trouvée sur Supabase. Ajoute/active une source ci-dessous.',
                            )
                          else
                            FocusRegionScope(
                              regionId: AppFocusRegionId.welcomeSavedSources,
                              binding: FocusRegionBinding(
                                resolvePrimaryEntryNode: () =>
                                    _savedSourceFocusNodes.isNotEmpty
                                    ? _savedSourceFocusNodes.first
                                    : _sourcesErrorRetryFocusNode,
                                resolveFallbackEntryNode: () =>
                                    _refreshFocusNode,
                              ),
                              handleDirectionalExits: false,
                              debugLabel: 'WelcomeSavedSourcesRegion',
                              child: _SourcesList(
                                sources: _sources,
                                selectedId: _selectedSourceId,
                                focusNodes: _savedSourceFocusNodes,
                                focusVerticalAlignment: 0.22,
                                onFirstItemUp: () => FocusDirectionalNavigation.requestFocus(
                                  launchRecovery?.isRetryable ?? false
                                      ? _retryFocusNode
                                      : _refreshFocusNode,
                                ),
                                onLastItemDown: () => _enterFocusRegion(
                                  AppFocusRegionId.welcomeSourceForm,
                                ),
                                onSelect: _selectSource,
                              ),
                            ),

                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // ---------------- Activation ----------------
                        FocusRegionScope(
                          regionId: AppFocusRegionId.welcomeSourceForm,
                          binding: FocusRegionBinding(
                            resolvePrimaryEntryNode: () => _nameFocusNode,
                            resolveFallbackEntryNode: () => _submitFocusNode,
                          ),
                          handleDirectionalExits: false,
                          debugLabel: 'WelcomeSourceFormRegion',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SectionHeader(title: 'Activer une source'),
                              const SizedBox(height: AppSpacing.sm),
                              MoviEnsureVisibleOnFocus(
                                verticalAlignment: 0.22,
                                child: Focus(
                                  canRequestFocus: false,
                                  onKeyEvent: (_, event) =>
                                      FocusDirectionalNavigation.handleDirectionalKey(
                                        event,
                                        up: _shouldDisplaySavedSourcesSection
                                            ? (_sourcesError != null
                                                  ? _sourcesErrorRetryFocusNode
                                                  : hasSavedSources
                                                  ? _savedSourceFocusNodes.last
                                                  : _refreshFocusNode)
                                            : launchRecovery?.isRetryable ??
                                                  false
                                            ? _retryFocusNode
                                            : null,
                                        down: _serverFocusNode,
                                        blockLeft: true,
                                        blockRight: true,
                                      ),
                                  child: CallbackShortcuts(
                                    bindings: <ShortcutActivator, VoidCallback>{
                                      const SingleActivator(
                                        LogicalKeyboardKey.arrowDown,
                                      ): () =>
                                          FocusDirectionalNavigation.requestFocus(_serverFocusNode),
                                    },
                                    child: TextField(
                                      controller: _nameCtrl,
                                      focusNode: _nameFocusNode,
                                      enabled: !isBusy,
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: (_) =>
                                          _serverFocusNode.requestFocus(),
                                      decoration: const InputDecoration(
                                        labelText: 'Nom de la source',
                                        hintText: 'Mon IPTV',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              MoviEnsureVisibleOnFocus(
                                verticalAlignment: 0.22,
                                child: Focus(
                                  canRequestFocus: false,
                                  onKeyEvent: (_, event) =>
                                      FocusDirectionalNavigation.handleDirectionalKey(
                                        event,
                                        up: _nameFocusNode,
                                        down: _userFocusNode,
                                        blockLeft: true,
                                        blockRight: true,
                                      ),
                                  child: CallbackShortcuts(
                                    bindings: <ShortcutActivator, VoidCallback>{
                                      const SingleActivator(
                                        LogicalKeyboardKey.arrowUp,
                                      ): () =>
                                          FocusDirectionalNavigation.requestFocus(_nameFocusNode),
                                      const SingleActivator(
                                        LogicalKeyboardKey.arrowDown,
                                      ): () =>
                                          FocusDirectionalNavigation.requestFocus(_userFocusNode),
                                    },
                                    child: TextField(
                                      controller: _serverCtrl,
                                      focusNode: _serverFocusNode,
                                      enabled: !isBusy,
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: (_) =>
                                          _userFocusNode.requestFocus(),
                                      decoration: const InputDecoration(
                                        labelText: 'Server URL',
                                        hintText: 'https://example.com:port',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              MoviEnsureVisibleOnFocus(
                                verticalAlignment: 0.22,
                                child: Focus(
                                  canRequestFocus: false,
                                  onKeyEvent: (_, event) =>
                                      FocusDirectionalNavigation.handleDirectionalKey(
                                        event,
                                        up: _serverFocusNode,
                                        down: _passFocusNode,
                                        blockLeft: true,
                                        blockRight: true,
                                      ),
                                  child: CallbackShortcuts(
                                    bindings: <ShortcutActivator, VoidCallback>{
                                      const SingleActivator(
                                        LogicalKeyboardKey.arrowUp,
                                      ): () =>
                                          FocusDirectionalNavigation.requestFocus(_serverFocusNode),
                                      const SingleActivator(
                                        LogicalKeyboardKey.arrowDown,
                                      ): () =>
                                          FocusDirectionalNavigation.requestFocus(_passFocusNode),
                                    },
                                    child: TextField(
                                      controller: _userCtrl,
                                      focusNode: _userFocusNode,
                                      enabled: !isBusy,
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: (_) =>
                                          _passFocusNode.requestFocus(),
                                      decoration: const InputDecoration(
                                        labelText: 'Username',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              MoviEnsureVisibleOnFocus(
                                verticalAlignment: 0.22,
                                child: Focus(
                                  canRequestFocus: false,
                                  onKeyEvent: (_, event) =>
                                      FocusDirectionalNavigation.handleDirectionalKey(
                                        event,
                                        up: _userFocusNode,
                                        right: _passwordToggleFocusNode,
                                        down: _submitFocusNode,
                                        blockLeft: true,
                                      ),
                                  child: CallbackShortcuts(
                                    bindings: <ShortcutActivator, VoidCallback>{
                                      const SingleActivator(
                                        LogicalKeyboardKey.arrowUp,
                                      ): () =>
                                          FocusDirectionalNavigation.requestFocus(_userFocusNode),
                                      const SingleActivator(
                                        LogicalKeyboardKey.arrowRight,
                                      ): () => FocusDirectionalNavigation.requestFocus(
                                        _passwordToggleFocusNode,
                                      ),
                                      const SingleActivator(
                                        LogicalKeyboardKey.arrowDown,
                                      ): () =>
                                          FocusDirectionalNavigation.requestFocus(_submitFocusNode),
                                    },
                                    child: TextField(
                                      controller: _passCtrl,
                                      focusNode: _passFocusNode,
                                      enabled: !isBusy,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) =>
                                          _submitFocusNode.requestFocus(),
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        border: const OutlineInputBorder(),
                                        suffixIcon: Padding(
                                          padding: const EdgeInsets.only(
                                            right: 12,
                                          ),
                                          child: Focus(
                                            canRequestFocus: false,
                                            onKeyEvent: (_, event) =>
                                                FocusDirectionalNavigation.handleDirectionalKey(
                                                  event,
                                                  left: _passFocusNode,
                                                  down: _submitFocusNode,
                                                  up: _userFocusNode,
                                                  blockRight: true,
                                                ),
                                            child: IconButton(
                                              focusNode:
                                                  _passwordToggleFocusNode,
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                              ),
                                              onPressed: () => setState(
                                                () => _obscurePassword =
                                                    !_obscurePassword,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
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
                              MoviEnsureVisibleOnFocus(
                                verticalAlignment: 0.22,
                                child: Focus(
                                  canRequestFocus: false,
                                  onKeyEvent: (_, event) =>
                                      FocusDirectionalNavigation.handleDirectionalKey(
                                        event,
                                        up: _passFocusNode,
                                        blockLeft: true,
                                        blockRight: true,
                                        blockDown: true,
                                      ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: MoviPrimaryButton(
                                      label: 'Activer',
                                      focusNode: _submitFocusNode,
                                      onPressed: isBusy ? null : _activate,
                                      loading: connectState.isLoading,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              const WelcomeFaqRow(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
    required this.focusNodes,
    required this.focusVerticalAlignment,
    required this.onSelect,
    this.onFirstItemUp,
    this.onLastItemDown,
  });

  final List<SupabaseIptvSourceEntity> sources;
  final String? selectedId;
  final List<FocusNode> focusNodes;
  final double focusVerticalAlignment;
  final void Function(SupabaseIptvSourceEntity source) onSelect;
  final VoidCallback? onFirstItemUp;
  final VoidCallback? onLastItemDown;

  String _formatDateOnly(BuildContext context, DateTime value) {
    final local = value.toLocal();
    return MaterialLocalizations.of(context).formatCompactDate(local);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (var index = 0; index < sources.length; index++)
            Focus(
              canRequestFocus: false,
              onKeyEvent: (_, event) {
                if (event is! KeyDownEvent) {
                  return KeyEventResult.ignored;
                }
                switch (event.logicalKey) {
                  case LogicalKeyboardKey.arrowUp:
                    if (index == 0) {
                      onFirstItemUp?.call();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  case LogicalKeyboardKey.arrowDown:
                    if (index == sources.length - 1) {
                      onLastItemDown?.call();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  case LogicalKeyboardKey.arrowLeft:
                  case LogicalKeyboardKey.arrowRight:
                    return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: MoviEnsureVisibleOnFocus(
                verticalAlignment: focusVerticalAlignment,
                child: MoviFocusableAction(
                  focusNode: index < focusNodes.length
                      ? focusNodes[index]
                      : null,
                  onPressed: () => onSelect(sources[index]),
                  semanticLabel: sources[index].name,
                  builder: (context, state) {
                    return MoviFocusFrame(
                      scale: state.focused ? 1.01 : 1,
                      borderRadius: BorderRadius.circular(18),
                      child: ListTile(
                        onTap: () => onSelect(sources[index]),
                        title: Text(
                          sources[index].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          sources[index].expiresAt != null
                              ? 'Expire: ${_formatDateOnly(context, sources[index].expiresAt!)}'
                              : 'Aucune date d’expiration',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: selectedId == sources[index].id
                            ? const Icon(Icons.check_circle)
                            : const Icon(Icons.circle_outlined),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({
    required this.message,
    required this.onRetry,
    this.retryFocusNode,
  });

  final String message;
  final VoidCallback onRetry;
  final FocusNode? retryFocusNode;

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
                focusNode: retryFocusNode,
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
