import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/iptv/application/usecases/refresh_stalker_catalog.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
import 'package:movi/src/features/iptv/presentation/widgets/iptv_source_selection_list.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_sources_providers.dart';
import 'package:movi/src/features/settings/presentation/widgets/settings_content_width.dart';

/// Sélecteur de source active dédié au contexte Réglages.
///
/// Contrairement au flow `welcome/*`, cette page ne dépend pas du bootstrap
/// et revient simplement vers l'écran précédent une fois la source activée.
class IptvSourceSelectPage extends ConsumerStatefulWidget {
  const IptvSourceSelectPage({super.key});

  @override
  ConsumerState<IptvSourceSelectPage> createState() =>
      _IptvSourceSelectPageState();
}

class _IptvSourceSelectPageState extends ConsumerState<IptvSourceSelectPage> {
  String? _switchingAccountId;

  bool get _isSwitching => _switchingAccountId != null;

  Future<void> _activateSource(AnyIptvAccount account) async {
    if (_isSwitching) return;

    final locator = ref.read(slProvider);
    final prefs = locator<SelectedIptvSourcePreferences>();
    final appStateController = ref.read(asp.appStateControllerProvider);
    final local = locator<IptvLocalRepository>();
    final previousSelectedId = prefs.selectedSourceId;
    final previousActiveIds = appStateController.activeIptvSourceIds;

    if (previousSelectedId == account.id &&
        previousActiveIds.length == 1 &&
        previousActiveIds.contains(account.id)) {
      if (!mounted) return;
      context.pop(false);
      return;
    }

    setState(() => _switchingAccountId = account.id);

    try {
      await prefs.setSelectedSourceId(account.id);
      appStateController.setActiveIptvSources({account.id});

      if (account.isStalker) {
        final refresh = locator<RefreshStalkerCatalog>();
        final result = await refresh(account.id);
        result.fold(
          ok: (_) {},
          err: (failure) => throw StateError(failure.message),
        );
      } else {
        final refresh = locator<RefreshXtreamCatalog>();
        final result = await refresh(account.id);
        result.fold(
          ok: (_) {},
          err: (failure) => throw StateError(failure.message),
        );
      }

      final hasItemsAfterRefresh = await local.hasAnyPlaylistItems(
        accountIds: {account.id},
      );
      if (!hasItemsAfterRefresh) {
        throw StateError(
          'Aucun media charge pour cette source apres actualisation.',
        );
      }

      ref.invalidate(iptvSourceStatsProvider(account.id));
      ref
          .read(appEventBusProvider)
          .emit(const AppEvent(AppEventType.iptvSynced));
      await ref.read(hp.homeControllerProvider.notifier).refresh();

      try {
        await pushUserPreferencesIfSignedIn(
          ref,
          logContext: 'IptvSourceSelectPage',
        ).timeout(const Duration(seconds: 18));
      } on TimeoutException {
        assert(() {
          debugPrint('[IptvSourceSelectPage] pushUserPreferences timeout');
          return true;
        }());
      } catch (_) {}

      if (!mounted) return;
      context.pop(true);
    } catch (error) {
      await prefs.setSelectedSourceId(previousSelectedId);
      appStateController.setActiveIptvSources(previousActiveIds);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _switchingAccountId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeIds = ref.watch(asp.activeIptvSourcesProvider);
    final accountsAsync = ref.watch(allIptvAccountsProvider);
    final selectedId = activeIds.isEmpty ? null : activeIds.first;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          SafeArea(
            child: SettingsContentWidth(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  IptvSourceSelectHeader(
                    title: l10n.activeSourceTitle,
                    onBack: _isSwitching ? null : () => context.pop(),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: accountsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(
                        child: Text(
                          '${l10n.errorUnknown}: $error',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      data: (accounts) {
                        if (accounts.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Text(
                                l10n.welcomeSourceSubtitle,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        return IptvSourceSelectionList(
                          accounts: accounts,
                          selectedId: selectedId,
                          onSelected: _activateSource,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isSwitching)
            Positioned.fill(
              child: ColoredBox(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.82),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class IptvSourceSelectHeader extends StatelessWidget {
  const IptvSourceSelectHeader({
    super.key,
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback? onBack;

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
