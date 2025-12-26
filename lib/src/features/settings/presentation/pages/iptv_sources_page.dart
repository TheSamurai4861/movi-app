import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/router/app_route_names.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_stalker_catalog.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_sources_providers.dart';

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

    final wasActive = ref.read(asp.activeIptvSourcesProvider).contains(account.id);

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

    if (wasActive) {
      final fallback = accounts.firstWhere(
        (a) => a.id != account.id,
        orElse: () => account,
      );
      if (fallback.id != account.id) {
        await selectedPrefs.setSelectedSourceId(fallback.id);
        appState.setActiveIptvSources({fallback.id});
        setState(() => _selectedAccountId = fallback.id);
      } else {
        await selectedPrefs.clear();
      }
    }

    ref.invalidate(allIptvAccountsProvider);
    ref.invalidate(iptvAccountsProvider);
    ref.invalidate(stalkerAccountsProvider);

    ref.read(appEventBusProvider).emit(const AppEvent(AppEventType.iptvSynced));
    await ref.read(hp.homeControllerProvider.notifier).refresh();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Source supprimée')),
      );
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(f.message)),
              );
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(f.message)),
            );
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

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                _HeaderBar(
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
                const SizedBox(height: 16),
                // 🔵 Bouton pour changer de source active
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(AppRouteNames.welcomeSourceSelect),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Changer de source active'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent.withAlpha(51),
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        child: Image.asset(
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
                    onDelete: () => _confirmAndDelete(activeAccount, accounts),
                    onSelect: null,
                  ),
                const SizedBox(height: 16),
                if (activeAccount != null) ...[
                  MoviPrimaryButton(
                    label: _refreshing ? 'Rafraîchissement…' : 'Rafraîchir',
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
                          ref.invalidate(iptvSourceStatsProvider(activeAccount.id));
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
                    expirationText: _formatExpiration(account.getExpiration(), locale),
                    onDelete: () => _confirmAndDelete(account, accounts),
                    onSelect: null,
                  ),
                  const SizedBox(height: 16),
                ],
                if (otherAccounts.isNotEmpty) const SizedBox(height: 16),
                MoviPrimaryButton(
                  label: 'Ajouter une source',
                  onPressed: _openAddSource,
                ),
              ],
            );
          },
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
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: const SizedBox(
                width: 35,
                height: 35,
                child: Image(image: AssetImage(AppAssets.iconBack)),
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
                IconButton(
                  icon: Image.asset(
                    AppAssets.iconSearch,
                    width: 30,
                    height: 30,
                    color: searchActive ? accent : Colors.white,
                  ),
                  onPressed: onSearch,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Image.asset(
                    AppAssets.iconPlus,
                    width: 25,
                    height: 25,
                    color: Colors.white,
                  ),
                  onPressed: onAdd,
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

    final pillColor = isActive ? const Color(0xFF339936) : const Color(0xFF555555);

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
                Row(
                  children: [
                    Icon(
                      account.isStalker ? Icons.router : Icons.live_tv,
                      color: account.isStalker ? Colors.orange : Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      account.alias,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDelete,
                  child: Image.asset(
                    AppAssets.iconTrash,
                    width: 28,
                    height: 28,
                    color: Colors.white,
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
                      value: '${stats.movieCount} (${stats.movieIndexedCount} recensés)',
                    ),
                    const SizedBox(height: 16),
                    _KeyValueRow(
                      label: 'Séries',
                      value: '${stats.seriesCount} (${stats.seriesIndexedCount} recensés)',
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
