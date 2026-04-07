import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/router/app_route_names.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_stalker_catalog.dart';
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_sources_providers.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';
import 'package:movi/src/features/settings/presentation/services/iptv_source_remote_delete_service.dart';
import 'package:movi/src/features/settings/presentation/widgets/settings_content_width.dart';

class IptvSourcesPage extends ConsumerStatefulWidget {
  const IptvSourcesPage({super.key});

  @override
  ConsumerState<IptvSourcesPage> createState() => _IptvSourcesPageState();
}

class _IptvSourcesPageState extends ConsumerState<IptvSourcesPage> {
  String? _selectedAccountId;
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  bool _refreshing = false;
  StreamSubscription<AppEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _eventSub = ref.read(appEventBusProvider).stream.listen((event) {
      if (event.type != AppEventType.iptvSynced) return;
      ref.invalidate(allIptvAccountsProvider);
      ref.invalidate(iptvAccountsProvider);
      ref.invalidate(stalkerAccountsProvider);
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _ensureDefaultSelection(
    List<AnyIptvAccount> accounts,
    Set<String> activeIds,
  ) {
    if (_selectedAccountId != null &&
        !accounts.any((a) => a.id == _selectedAccountId)) {
      setState(() => _selectedAccountId = null);
    }
    final preferredId = accounts
        .map((a) => a.id)
        .firstWhere((id) => activeIds.contains(id), orElse: () => '');
    if (preferredId.isNotEmpty && _selectedAccountId != preferredId) {
      setState(() => _selectedAccountId = preferredId);
      return;
    }
    if (_selectedAccountId != null) return;
    if (accounts.isEmpty) return;

    setState(() {
      _selectedAccountId = (preferredId.isNotEmpty)
          ? preferredId
          : accounts.first.id;
    });
  }

  String _formatExpiration(DateTime? date, Locale locale) {
    if (date == null) return '—';
    return DateFormat('dd/MM/yy', locale.toString()).format(date);
  }

  bool _isAccountActive(AnyIptvAccount account) {
    return account.isActive();
  }

  Future<RemoteIptvDeleteStatus> _deleteRemoteSourceBestEffort({
    required String localSourceId,
  }) async {
    final locator = ref.read(slProvider);
    if (!locator.isRegistered<SupabaseIptvSourcesRepository>()) {
      return RemoteIptvDeleteStatus.skippedRepositoryUnavailable;
    }

    final service = IptvSourceRemoteDeleteService(
      loadSources: ({required accountId}) => locator
          .get<SupabaseIptvSourcesRepository>()
          .getSources(accountId: accountId),
      deleteSource: ({required id, required accountId}) => locator
          .get<SupabaseIptvSourcesRepository>()
          .deleteSource(id: id, accountId: accountId),
    );

    final userId = ref.read(authUserIdProvider);
    return service.deleteByLocalIdBestEffort(
      localId: localSourceId,
      userId: userId,
    );
  }

  Future<void> _confirmAndDelete(
    AnyIptvAccount account,
    List<AnyIptvAccount> accounts,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final local = ref.read(slProvider)<IptvLocalRepository>();
    final vault = ref.read(slProvider)<CredentialsVault>();
    final appState = ref.read(asp.appStateControllerProvider);
    final selectedPrefs = ref.read(slProvider)<SelectedIptvSourcePreferences>();

    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.actionConfirm),
        content: Text('Supprimer la source "${account.alias}" ?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final wasActive = ref
        .read(asp.activeIptvSourcesProvider)
        .contains(account.id);
    final wasSelected = selectedPrefs.selectedSourceId == account.id;
    final remainingAccounts = accounts
        .where((candidate) => candidate.id != account.id)
        .toList(growable: false);

    if (account.isStalker) {
      await local.removeStalkerAccount(account.id);
    } else {
      await local.removeAccount(account.id);
    }
    await vault.removePassword(account.id);
    appState.removeIptvSource(account.id);

    if (_selectedAccountId == account.id) {
      setState(() => _selectedAccountId = null);
    }

    if (remainingAccounts.isEmpty) {
      await selectedPrefs.clear();
      appState.setActiveIptvSources(<String>{});
    } else if (wasActive || wasSelected) {
      final fallback = remainingAccounts.first;
      await selectedPrefs.setSelectedSourceId(fallback.id);
      appState.setActiveIptvSources({fallback.id});
      setState(() => _selectedAccountId = fallback.id);
    }

    final remoteDeleteStatus = await _deleteRemoteSourceBestEffort(
      localSourceId: account.id,
    );
    if (remoteDeleteStatus == RemoteIptvDeleteStatus.failed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Source supprimée localement, mais suppression cloud impossible.',
          ),
        ),
      );
    }
    if (kDebugMode &&
        remoteDeleteStatus != RemoteIptvDeleteStatus.deleted &&
        remoteDeleteStatus != RemoteIptvDeleteStatus.skippedNotFound) {
      debugPrint(
        '[IptvSourcesPage] remote delete status=$remoteDeleteStatus sourceId=${account.id}',
      );
    }

    ref.invalidate(allIptvAccountsProvider);
    ref.invalidate(iptvAccountsProvider);
    ref.invalidate(stalkerAccountsProvider);

    ref.read(appEventBusProvider).emit(const AppEvent(AppEventType.iptvSynced));

    if (remainingAccounts.isEmpty) {
      ref
          .read(appLaunchOrchestratorProvider.notifier)
          .markWelcomeSourcesRequiredFromCurrentContext();
      if (mounted) {
        context.go(AppRouteNames.welcomeSources);
      }
      return;
    }

    await ref.read(hp.homeControllerProvider.notifier).refresh();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Source supprimée')));
    }
  }

  Future<void> _refreshSelected(AnyIptvAccount account) async {
    if (_refreshing) return;

    if (account.isStalker) {
      setState(() => _refreshing = true);
      try {
        final refresh = ref.read(slProvider)<RefreshStalkerCatalog>();
        final res = await refresh(account.id);
        var ok = false;
        res.fold(
          ok: (_) => ok = true,
          err: (f) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(f.message)));
            }
          },
        );

        ref.invalidate(iptvSourceStatsProvider(account.id));
        if (ok) {
          ref
              .read(appEventBusProvider)
              .emit(const AppEvent(AppEventType.iptvSynced));
          await ref.read(hp.homeControllerProvider.notifier).refresh();
        }
      } finally {
        if (mounted) {
          setState(() => _refreshing = false);
        }
      }
      return;
    }

    setState(() => _refreshing = true);
    try {
      final refresh = ref.read(slProvider)<RefreshXtreamCatalog>();
      final res = await refresh(account.id);

      var ok = false;
      res.fold(
        ok: (_) => ok = true,
        err: (f) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(f.message)));
          }
        },
      );

      ref.invalidate(iptvAccountsProvider);
      ref.invalidate(iptvSourceStatsProvider(account.id));

      if (ok) {
        ref
            .read(appEventBusProvider)
            .emit(const AppEvent(AppEventType.iptvSynced));
        await ref.read(hp.homeControllerProvider.notifier).refresh();
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _openAddSource() async {
    final updated = await context.push<bool>(AppRouteNames.iptvSourceAdd);
    if (!mounted) return;
    if (updated == true) {
      setState(() => _selectedAccountId = null);
    }
    ref.invalidate(allIptvAccountsProvider);
    ref.invalidate(iptvAccountsProvider);
    ref.invalidate(stalkerAccountsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final accent = ref.watch(asp.currentAccentColorProvider);
    final activeIds = ref.watch(asp.activeIptvSourcesProvider);
    final accountsAsync = ref.watch(allIptvAccountsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        top: true,
        bottom: true,
        child: SettingsContentWidth(
          child: accountsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                e.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            data: (accounts) {
              _ensureDefaultSelection(accounts, activeIds);

              final selectedId = _selectedAccountId;
              final activeAccount = (selectedId == null)
                  ? null
                  : accounts.where((a) => a.id == selectedId).firstOrNull;

              final query = _searchController.text.trim().toLowerCase();
              final otherAccounts = accounts
                  .where((a) => a.id != selectedId)
                  .where(
                    (a) =>
                        query.isEmpty ||
                        a.alias.toLowerCase().contains(query) ||
                        a.getUsername().toLowerCase().contains(query) ||
                        a.getHost().toLowerCase().contains(query),
                  )
                  .toList(growable: false);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: _HeaderBar(
                      title: 'Sources',
                      accent: accent,
                      searchActive: _isSearchVisible,
                      onBack: () => context.pop(),
                      onSearch: () {
                        setState(() {
                          _isSearchVisible = !_isSearchVisible;
                          if (!_isSearchVisible) {
                            _searchController.clear();
                          }
                        });
                      },
                      onAdd: _openAddSource,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      children: [
                        SizedBox(
                          height: 48,
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                context.push(AppRouteNames.iptvSourceSelect),
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Changer de source active'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent.withAlpha(51),
                              foregroundColor: accent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                            ),
                          ),
                        ),
                        if (_isSearchVisible) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Rechercher une source…',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: const Color(0xFF1C1C1E),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12),
                                child: const MoviAssetIcon(
                                  AppAssets.iconSearch,
                                  width: 20,
                                  height: 20,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        const Text(
                          'Source active',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (activeAccount == null)
                          Text(
                            AppLocalizations.of(context)!.statusNoActiveSource,
                            style: const TextStyle(color: Colors.white70),
                          )
                        else
                          _SourceCard(
                            account: activeAccount,
                            accent: accent,
                            locale: locale,
                            isActive: _isAccountActive(activeAccount),
                            expirationText: _formatExpiration(
                              activeAccount.getExpiration(),
                              locale,
                            ),
                            onDelete: () =>
                                _confirmAndDelete(activeAccount, accounts),
                            onSelect: null,
                          ),
                        const SizedBox(height: 16),
                        if (activeAccount != null) ...[
                          MoviPrimaryButton(
                            label: _refreshing
                                ? 'Rafraîchissement…'
                                : 'Rafraîchir',
                            onPressed: _refreshing
                                ? null
                                : () => _refreshSelected(activeAccount),
                            loading: _refreshing,
                          ),
                          const SizedBox(height: 16),
                          if (!activeAccount.isStalker)
                            MoviPrimaryButton(
                              label: 'Modifier',
                              onPressed: () async {
                                final updated = await context.push<bool>(
                                  AppRouteNames.iptvSourceEdit,
                                  extra: activeAccount.id,
                                );

                                if (updated == true) {
                                  ref.invalidate(allIptvAccountsProvider);
                                  ref.invalidate(iptvAccountsProvider);
                                  ref.invalidate(
                                    iptvSourceStatsProvider(activeAccount.id),
                                  );
                                }
                              },
                            ),
                          const SizedBox(height: 16),
                          MoviPrimaryButton(
                            label: 'Organiser les catégories',
                            onPressed: () => context.push(
                              AppRouteNames.iptvSourceOrganize,
                              extra: activeAccount.id,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        Container(height: 1, color: const Color(0xFF262626)),
                        const SizedBox(height: 32),
                        const Text(
                          'Autres sources',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final account in otherAccounts) ...[
                          _SourceCard(
                            account: account,
                            accent: accent,
                            locale: locale,
                            isActive: _isAccountActive(account),
                            expirationText: _formatExpiration(
                              account.getExpiration(),
                              locale,
                            ),
                            onDelete: () =>
                                _confirmAndDelete(account, accounts),
                            onSelect: null,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (otherAccounts.isNotEmpty)
                          const SizedBox(height: 16),
                        MoviPrimaryButton(
                          label: 'Ajouter une source',
                          onPressed: _openAddSource,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.title,
    required this.accent,
    required this.searchActive,
    required this.onBack,
    required this.onSearch,
    required this.onAdd,
  });

  final String title;
  final Color accent;
  final bool searchActive;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MoviFocusableAction(
                  onPressed: onSearch,
                  semanticLabel: 'Rechercher',
                  builder: (context, state) {
                    return MoviFocusFrame(
                      scale: state.focused ? 1.04 : 1,
                      padding: const EdgeInsets.all(8),
                      borderRadius: BorderRadius.circular(999),
                      backgroundColor: state.focused
                          ? Colors.white.withValues(alpha: 0.14)
                          : Colors.transparent,
                      child: MoviAssetIcon(
                        AppAssets.iconSearch,
                        width: 30,
                        height: 30,
                        color: searchActive ? accent : Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                MoviFocusableAction(
                  onPressed: onAdd,
                  semanticLabel: 'Ajouter',
                  builder: (context, state) {
                    return MoviFocusFrame(
                      scale: state.focused ? 1.04 : 1,
                      padding: const EdgeInsets.all(8),
                      borderRadius: BorderRadius.circular(999),
                      backgroundColor: state.focused
                          ? Colors.white.withValues(alpha: 0.14)
                          : Colors.transparent,
                      child: const MoviAssetIcon(
                        AppAssets.iconPlus,
                        width: 25,
                        height: 25,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends ConsumerWidget {
  const _SourceCard({
    required this.account,
    required this.accent,
    required this.locale,
    required this.isActive,
    required this.expirationText,
    required this.onDelete,
    required this.onSelect,
  });

  final AnyIptvAccount account;
  final Color accent;
  final Locale locale;
  final bool isActive;
  final String expirationText;
  final VoidCallback onDelete;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // Stats seulement pour Xtream
    final statsAsync = account.isStalker
        ? null
        : ref.watch(iptvSourceStatsProvider(account.id));

    final pillColor = isActive
        ? const Color(0xFF339936)
        : const Color(0xFF555555);

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF262626),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF404040), width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    account.alias,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDelete,
                  child: const MoviAssetIcon(
                    AppAssets.iconTrash,
                    width: 28,
                    height: 28,
                    color: Color(0xFFFF3B30),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _KeyValueRow(
              label: 'Statut',
              valueWidget: Container(
                width: 100,
                height: 30,
                decoration: BoxDecoration(
                  color: pillColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  isActive ? l10n.statusActive : 'Inactif',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _KeyValueRow(label: 'Date d\'expiration', value: expirationText),
            if (account.isStalker) ...[
              const SizedBox(height: 16),
              _KeyValueRow(label: 'Type', value: 'Stalker Portal'),
              const SizedBox(height: 16),
              _KeyValueRow(label: 'MAC', value: account.getUsername()),
            ],
            if (!account.isStalker && statsAsync != null) ...[
              const SizedBox(height: 16),
              statsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) => Column(
                  children: [
                    _KeyValueRow(
                      label: 'Films',
                      value:
                          '${stats.movieCount} (${stats.movieIndexedCount} recensés)',
                    ),
                    const SizedBox(height: 16),
                    _KeyValueRow(
                      label: 'Séries',
                      value:
                          '${stats.seriesCount} (${stats.seriesIndexedCount} recensés)',
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, this.value, this.valueWidget});

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child:
                valueWidget ??
                Text(
                  value ?? '—',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
          ),
        ),
      ],
    );
  }
}
