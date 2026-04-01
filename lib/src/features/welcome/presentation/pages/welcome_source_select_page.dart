import 'dart:async';

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
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
import 'package:movi/src/features/iptv/presentation/providers/iptv_accounts_providers.dart';
import 'package:movi/src/features/iptv/presentation/widgets/iptv_source_selection_list.dart';
import 'package:movi/src/features/settings/presentation/widgets/settings_content_width.dart';

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
    final asyncAccounts = ref.watch(allIptvAccountsProvider);

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
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: SettingsContentWidth(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _WelcomeSourceSelectHeader(
                  title: l10n.activeSourceTitle,
                  onBack: () => _handleBack(context),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: asyncAccounts.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(
                        '${l10n.errorUnknown}: $e',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    data: (accounts) {
                      if (accounts.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.welcomeSourceSubtitle,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () =>
                                      context.go(AppRouteNames.welcomeSources),
                                  child: const Text('Ajouter une source'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return IptvSourceSelectionList(
                        accounts: accounts,
                        selectedId: selectedId,
                        onSelected: (account) async {
                          final prefs =
                              locator<SelectedIptvSourcePreferences>();

                          await prefs.setSelectedSourceId(account.id);

                          final appStateController = ref.read(
                            appStateControllerProvider,
                          );
                          appStateController.setActiveIptvSources({account.id});
                          ref
                              .read(appEventBusProvider)
                              .emit(const AppEvent(AppEventType.iptvSynced));

                          try {
                            await pushUserPreferencesIfSignedIn(
                              ref,
                              logContext: 'WelcomeSourceSelectPage',
                            ).timeout(const Duration(seconds: 18));
                          } on TimeoutException {
                            assert(() {
                              debugPrint(
                                '[WelcomeSourceSelectPage] pushUserPreferences timeout',
                              );
                              return true;
                            }());
                          } catch (_) {}

                          await Future.delayed(
                            const Duration(milliseconds: 100),
                          );

                          if (!context.mounted) return;
                          context.go(AppRouteNames.welcomeSourceLoading);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeSourceSelectHeader extends StatelessWidget {
  const _WelcomeSourceSelectHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 44,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 35,
                height: 35,
                child: MoviFocusableAction(
                  onPressed: onBack,
                  semanticLabel: 'Retour',
                  builder: (context, state) {
                    return MoviFocusFrame(
                      scale: state.focused ? 1.04 : 1,
                      borderRadius: BorderRadius.circular(999),
                      backgroundColor: state.focused
                          ? Colors.white.withValues(alpha: 0.14)
                          : Colors.transparent,
                      child: const SizedBox(
                        width: 35,
                        height: 35,
                        child: MoviAssetIcon(
                          AppAssets.iconBack,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
