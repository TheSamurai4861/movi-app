import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/router/app_route_names.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';

/// Wrapper pour combiner les comptes Xtream et Stalker
class AnyIptvAccount {
  AnyIptvAccount.xtream(this.xtream) : stalker = null;
  AnyIptvAccount.stalker(this.stalker) : xtream = null;

  final XtreamAccount? xtream;
  final StalkerAccount? stalker;

  String get id => xtream?.id ?? stalker!.id;
  String get alias => xtream?.alias ?? stalker!.alias;
  String get host => xtream?.endpoint.host ?? stalker!.endpoint.host;
  String get subtitle {
    if (xtream != null) {
      return '$host • ${xtream!.username}';
    } else {
      return '$host • ${stalker!.macAddress} (Stalker)';
    }
  }
  bool get isStalker => stalker != null;
}

final _allIptvAccountsProvider = FutureProvider<List<AnyIptvAccount>>((
  ref,
) async {
  final local = ref.watch(slProvider)<IptvLocalRepository>();
  
  final xtreamAccounts = await local.getAccounts();
  final stalkerAccounts = await local.getStalkerAccounts();
  
  return [
    ...xtreamAccounts.map((a) => AnyIptvAccount.xtream(a)),
    ...stalkerAccounts.map((a) => AnyIptvAccount.stalker(a)),
  ];
});

class WelcomeSourceSelectPage extends ConsumerWidget {
  const WelcomeSourceSelectPage({super.key});

  /// Détermine la route de fallback appropriée selon le contexte de navigation.
  /// 
  /// Si `context.canPop()` est `true`, retourne `null` pour utiliser `pop()`.
  /// Sinon, détermine la route de fallback en fonction du contexte :
  /// - Si on est dans le flow welcome, retourne `/welcome/sources`
  /// - Sinon, essaie de retourner vers `/settings/iptv/sources`
  String? _determineFallbackRoute(BuildContext context) {
    if (context.canPop()) {
      return null; // Utiliser pop() si possible
    }

    final routerState = GoRouterState.of(context);
    final currentLocation = routerState.uri.toString();

    // Si on est dans le flow welcome, retourner vers welcome/sources
    if (currentLocation.startsWith(AppRoutePaths.welcome)) {
      return AppRouteNames.welcomeSources;
    }

    // Sinon, essayer de retourner vers les paramètres
    // (cas où on vient des settings mais la stack a été vidée)
    return AppRouteNames.iptvSources;
  }

  /// Gère l'action de retour (bouton retour ou geste système).
  void _handleBack(BuildContext context) {
    final fallbackRoute = _determineFallbackRoute(context);
    
    if (fallbackRoute == null) {
      // On peut pop, donc revenir à la route précédente
      context.pop();
    } else {
      // Navigation vers la route de fallback appropriée
      context.go(fallbackRoute);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncAccounts = ref.watch(_allIptvAccountsProvider);

    final locator = ref.watch(slProvider);
    final selectedPrefs = locator<SelectedIptvSourcePreferences>();
    final selectedId = selectedPrefs.selectedSourceId;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Image(
              image: AssetImage(AppAssets.iconBack),
              width: 24,
              height: 24,
            ),
            onPressed: () => _handleBack(context),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          title: const Text('Choisir une source'),
          actions: [
            TextButton(
              onPressed: () => context.go(AppRouteNames.welcomeSources),
              child: const Text('Ajouter'),
            ),
          ],
        ),
        body: asyncAccounts.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('${l10n.errorUnknown}: $e')),
          data: (accounts) {
          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.welcomeSourceSubtitle),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go(AppRouteNames.welcomeSources),
                    child: const Text('Ajouter une source'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: accounts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final account = accounts[index];
              final isSelected = account.id == selectedId;

              return ListTile(
                title: Text(account.alias),
                subtitle: Text(account.subtitle),
                trailing: isSelected ? const Icon(Icons.check) : null,
                leading: account.isStalker 
                    ? const Icon(Icons.router, color: Colors.orange)
                    : const Icon(Icons.live_tv, color: Colors.blue),
                onTap: () async {
                  final prefs = locator<SelectedIptvSourcePreferences>();
                  
                  await prefs.setSelectedSourceId(account.id);

                  final appStateController = ref.read(
                    appStateControllerProvider,
                  );
                  appStateController.setActiveIptvSources({account.id});
                  ref
                      .read(appEventBusProvider)
                      .emit(const AppEvent(AppEventType.iptvSynced));

                  // Attendre un frame pour s'assurer que l'état est mis à jour
                  await Future.delayed(const Duration(milliseconds: 100));

                  // Redirection vers la page de chargement pour attendre le chargement complet des playlists
                  if (!context.mounted) return;
                  context.go(AppRouteNames.welcomeSourceLoading);
                },
              );
            },
          );
        },
      ),
      ),
    );
  }
}
