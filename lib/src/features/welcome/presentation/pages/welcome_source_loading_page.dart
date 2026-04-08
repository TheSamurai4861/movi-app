import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logging.dart';
import 'package:movi/src/core/router/app_route_names.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/core/widgets/overlay_splash.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_stalker_catalog.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
import 'package:movi/src/features/shell/presentation/navigation/shell_destinations.dart';
import 'package:movi/src/features/shell/presentation/providers/shell_providers.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_header.dart';

/// Startup page that waits for IPTV playlists to be fully loaded
/// before redirecting to home.
class WelcomeSourceLoadingPage extends ConsumerStatefulWidget {
  const WelcomeSourceLoadingPage({super.key, this.forceCatalogReload = false});

  final bool forceCatalogReload;

  @override
  ConsumerState<WelcomeSourceLoadingPage> createState() =>
      _WelcomeSourceLoadingPageState();
}

class _WelcomeSourceLoadingPageState
    extends ConsumerState<WelcomeSourceLoadingPage> {
  static const Duration _catalogRefreshTimeout = Duration(seconds: 20);
  String? _error;
  bool _isLoading = true;
  bool _showSourceSelectionAction = false;
  String _statusMessage = '';

  void _goToHome() {
    ref.read(shellControllerProvider.notifier).selectTab(ShellTab.home);
    context.go(AppRouteNames.home);
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadCatalog());
  }

  Future<void> _loadCatalog() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _showSourceSelectionAction = false;
      _statusMessage = 'Chargement de votre catalogue...';
    });

    try {
      final appStateController = ref.read(asp.appStateControllerProvider);
      final activeSources = appStateController.activeIptvSourceIds;

      if (activeSources.isEmpty) {
        if (!mounted) return;
        setState(() {
          _error = 'Aucune source active trouvée';
          _isLoading = false;
        });
        return;
      }

      final locator = ref.read(slProvider);
      final iptvLocal = locator<IptvLocalRepository>();
      final selectedSourcePreferences =
          locator<SelectedIptvSourcePreferences>();
      final selectedSourceId = selectedSourcePreferences.selectedSourceId
          ?.trim();

      final xtreamAccounts = await iptvLocal.getAccounts();
      final stalkerAccounts = await iptvLocal.getStalkerAccounts();

      final xtreamIds = xtreamAccounts.map((a) => a.id).toSet();
      final stalkerIds = stalkerAccounts.map((a) => a.id).toSet();
      final knownSourceIds = <String>{...xtreamIds, ...stalkerIds};
      final invalidActiveSources = activeSources.difference(knownSourceIds);

      var mustRefreshCatalog = widget.forceCatalogReload;
      if (!mustRefreshCatalog) {
        final hasAnyItems = await iptvLocal.hasAnyPlaylistItems(
          accountIds: activeSources,
        );
        mustRefreshCatalog = !hasAnyItems;
      }

      _logLoadingContext(
        context: 'welcome_source_loading_inventory',
        selectedSourceId: selectedSourceId,
        activeSourceIds: activeSources,
        mustRefreshCatalog: mustRefreshCatalog,
        detail: 'knownSourceIds=${_formatIds(knownSourceIds)}',
      );

      if (invalidActiveSources.isNotEmpty) {
        _logLoadingContext(
          context: 'welcome_source_loading_invalid_selection',
          selectedSourceId: selectedSourceId,
          activeSourceIds: activeSources,
          mustRefreshCatalog: mustRefreshCatalog,
          detail:
              'invalidActiveSources=${_formatIds(invalidActiveSources)} '
              'knownSourceIds=${_formatIds(knownSourceIds)}',
        );
        if (selectedSourceId != null &&
            invalidActiveSources.contains(selectedSourceId)) {
          await selectedSourcePreferences.clear();
        }
        appStateController.setActiveIptvSources(
          activeSources.difference(invalidActiveSources),
        );
        throw _SelectedSourceOwnershipException(
          invalidSourceIds: invalidActiveSources,
          currentUserId: _currentUserIdOrNull(),
        );
      }

      if (mustRefreshCatalog) {
        setState(() {
          _statusMessage = widget.forceCatalogReload
              ? 'Chargement complet de la source...'
              : 'Téléchargement des playlists...';
        });

        final refreshXtream = locator<RefreshXtreamCatalog>();
        final refreshStalker = locator<RefreshStalkerCatalog>();

        for (final accountId in activeSources) {
          if (xtreamIds.contains(accountId)) {
            setState(() {
              _statusMessage = 'Chargement des films et séries...';
            });

            final result = await refreshXtream(accountId).timeout(
              _catalogRefreshTimeout,
              onTimeout: () {
                throw TimeoutException(
                  'Timeout pendant le chargement du catalogue Xtream',
                  _catalogRefreshTimeout,
                );
              },
            );
            result.fold(
              ok: (_) {
                unawaited(
                  LoggingService.log(
                    'WelcomeSourceLoading: Xtream catalog refreshed for $accountId',
                  ),
                );
              },
              err: (failure) {
                throw Exception(
                  'Erreur lors du chargement du catalogue: ${failure.message}',
                );
              },
            );
          } else if (stalkerIds.contains(accountId)) {
            setState(() {
              _statusMessage = 'Chargement des films et séries...';
            });

            final result = await refreshStalker(accountId).timeout(
              _catalogRefreshTimeout,
              onTimeout: () {
                throw TimeoutException(
                  'Timeout pendant le chargement du catalogue Stalker',
                  _catalogRefreshTimeout,
                );
              },
            );
            result.fold(
              ok: (_) {
                unawaited(
                  LoggingService.log(
                    'WelcomeSourceLoading: Stalker catalog refreshed for $accountId',
                  ),
                );
              },
              err: (failure) {
                throw Exception(
                  'Erreur lors du chargement du catalogue: ${failure.message}',
                );
              },
            );
          } else {
            throw Exception('Type de source inconnu pour $accountId');
          }
        }

        final hasItemsAfterRefresh = await iptvLocal.hasAnyPlaylistItems(
          accountIds: activeSources,
        );

        if (!hasItemsAfterRefresh) {
          throw Exception(
            'Le chargement semble avoir échoué. Aucune playlist trouvée.',
          );
        }
      }

      final hasCatalogReady = await iptvLocal.hasAnyPlaylistItems(
        accountIds: activeSources,
      );
      if (!hasCatalogReady) {
        throw Exception(
          "Le catalogue IPTV n'est pas prêt après le chargement de la source.",
        );
      }

      await selectedSourcePreferences.rereadFromStorage();
      final preferredSourceId = selectedSourcePreferences.selectedSourceId
          ?.trim();
      if ((preferredSourceId == null || preferredSourceId.isEmpty) &&
          activeSources.length == 1) {
        await selectedSourcePreferences.setSelectedSourceId(
          activeSources.first,
        );
      }
      final refreshedPreferredId = selectedSourcePreferences.selectedSourceId
          ?.trim();
      final missingSelection =
          refreshedPreferredId == null || refreshedPreferredId.isEmpty;
      final invalidSelection =
          !missingSelection && !activeSources.contains(refreshedPreferredId);
      if (invalidSelection) {
        _logLoadingContext(
          context: 'welcome_source_loading_selection_invalid_after_refresh',
          selectedSourceId: refreshedPreferredId,
          activeSourceIds: activeSources,
          mustRefreshCatalog: false,
          detail: 'selection_missing_from_active_sources',
        );
        await selectedSourcePreferences.clear();
      }
      if ((missingSelection || invalidSelection) && activeSources.length > 1) {
        if (!mounted) return;
        context.go(AppRouteNames.welcomeSourceSelect);
        return;
      }

      if (!mounted) return;
      setState(() {
        _statusMessage = "Préparation de l'accueil...";
      });

      await ref
          .read(appLaunchOrchestratorProvider.notifier)
          .completeManualSourceLoadingToHome(
            hasIptvCatalogReady: hasCatalogReady,
          );

      if (!mounted) return;
      _goToHome();
    } catch (e, stackTrace) {
      unawaited(
        LoggingService.log(
          'WelcomeSourceLoading: Error loading catalog: $e\n$stackTrace',
          category: 'welcome',
        ),
      );

      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _showSourceSelectionAction = e is _SelectedSourceOwnershipException;
      });
    }
  }

  String? _currentUserIdOrNull() {
    final session = ref.read(authRepositoryProvider).currentSession;
    final id = session?.userId.trim();
    if (id == null || id.isEmpty) {
      return null;
    }
    return id;
  }

  void _logLoadingContext({
    required String context,
    String? selectedSourceId,
    required Set<String> activeSourceIds,
    required bool mustRefreshCatalog,
    String? detail,
  }) {
    final currentUserId = _currentUserIdOrNull();
    final owner = currentUserId ?? 'device_local';
    final selected = (selectedSourceId == null || selectedSourceId.isEmpty)
        ? 'none'
        : selectedSourceId;
    final extra = detail == null || detail.isEmpty ? '' : ' detail=$detail';
    unawaited(
      LoggingService.log(
        '[WelcomeSourceLoading] context=$context '
        'currentUserId=${currentUserId ?? 'none'} '
        'selectedSourceId=$selected '
        'activeSourceIds=${_formatIds(activeSourceIds)} '
        'mustRefreshCatalog=$mustRefreshCatalog '
        'sourceOwner=$owner$extra',
        category: 'welcome',
      ),
    );
  }

  String _formatIds(Iterable<String> ids) {
    final normalized = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false)
      ..sort();
    if (normalized.isEmpty) {
      return 'none';
    }
    return normalized.join(',');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Center(child: WelcomeSourceLoadingLogo()),
          WelcomeSourceLoadingContent(
            isLoading: _isLoading,
            statusMessage: _statusMessage,
            error: _error,
            onRetry: () {
              setState(() {
                _error = null;
              });
              unawaited(_loadCatalog());
            },
            onSelectSource: _showSourceSelectionAction
                ? () => context.go(AppRouteNames.welcomeSourceSelect)
                : null,
            showHeader: false,
            mainAxisAlignment: MainAxisAlignment.end,
            bottomPadding: AppSpacing.lg,
          ),
        ],
      ),
    );
  }
}

class WelcomeSourceLoadingLogo extends ConsumerWidget {
  const WelcomeSourceLoadingLogo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(asp.currentAccentColorProvider);

    return SvgPicture.asset(
      AppAssets.iconAppLogoSvg,
      width: 100,
      height: 100,
      colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
    );
  }
}

class WelcomeSourceLoadingContent extends ConsumerWidget {
  const WelcomeSourceLoadingContent({
    super.key,
    required this.isLoading,
    required this.statusMessage,
    required this.error,
    this.onRetry,
    this.onSelectSource,
    this.onContinueAnyway,
    this.showHeader = true,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.bottomPadding = AppSpacing.xl,
  });

  final bool isLoading;
  final String statusMessage;
  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback? onSelectSource;
  final VoidCallback? onContinueAnyway;
  final bool showHeader;
  final MainAxisAlignment mainAxisAlignment;
  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(asp.currentAccentColorProvider);

    if (isLoading) {
      // Unifier le rendu avec le splash de lancement (logo + spinner + message en bas).
      return OverlaySplash(message: statusMessage);
    }

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              bottomPadding,
            ),
            child: Column(
              mainAxisAlignment: mainAxisAlignment,
              children: [
                if (showHeader) ...[
                  const WelcomeHeader(
                    title: 'Chargement',
                    subtitle: 'Préparation de votre bibliothèque',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                if (error != null) ...[
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    error!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: accentColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (onSelectSource != null)
                    OutlinedButton(
                      onPressed: onSelectSource,
                      child: const Text('Choisir une autre source'),
                    ),
                  if (onSelectSource != null)
                    const SizedBox(height: AppSpacing.md),
                  if (onContinueAnyway != null)
                    OutlinedButton(
                      onPressed: onContinueAnyway,
                      child: const Text('Continuer quand même'),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _SelectedSourceOwnershipException implements Exception {
  const _SelectedSourceOwnershipException({
    required this.invalidSourceIds,
    required this.currentUserId,
  });

  final Set<String> invalidSourceIds;
  final String? currentUserId;

  @override
  String toString() {
    final isPlural = invalidSourceIds.length > 1;
    final userId = currentUserId?.trim();
    final accountLabel = (userId == null || userId.isEmpty)
        ? 'ce mode local'
        : 'ce compte';
    if (isPlural) {
      return 'Les sources sélectionnées ne sont plus disponibles pour $accountLabel. '
          'Choisissez une source liée au compte actif puis relancez le chargement.';
    }
    return 'La source sélectionnée n\'est plus disponible pour $accountLabel. '
        'Choisissez une source liée au compte actif puis relancez le chargement.';
  }
}
