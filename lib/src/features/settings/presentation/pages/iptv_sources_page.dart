import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/focus/movi_focus_restore_policy.dart';
import 'package:movi/src/core/focus/movi_route_focus_boundary.dart';
import 'package:movi/src/core/preferences/suppressed_remote_iptv_sources_preferences.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/router/app_route_names.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/storage/repositories/secure_storage_repository.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/core/widgets/movi_tv_action_menu.dart';
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
  static const double _focusVerticalAlignment = 0.22;
  String? _selectedAccountId;
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _backFocusNode = FocusNode(debugLabel: 'IptvSourcesBack');
  final FocusNode _searchButtonFocusNode = FocusNode(
    debugLabel: 'IptvSourcesSearchButton',
  );
  final FocusNode _headerAddFocusNode = FocusNode(
    debugLabel: 'IptvSourcesHeaderAdd',
  );
  final FocusNode _changeSourceFocusNode = FocusNode(
    debugLabel: 'IptvSourcesChangeActive',
  );
  final FocusNode _searchFieldFocusNode = FocusNode(
    debugLabel: 'IptvSourcesSearchField',
  );
  final FocusNode _activeDeleteFocusNode = FocusNode(
    debugLabel: 'IptvSourcesActiveDelete',
  );
  final FocusNode _refreshFocusNode = FocusNode(debugLabel: 'IptvSourcesRefresh');
  final FocusNode _editFocusNode = FocusNode(debugLabel: 'IptvSourcesEdit');
  final FocusNode _organizeFocusNode = FocusNode(
    debugLabel: 'IptvSourcesOrganize',
  );
  final FocusNode _bottomAddFocusNode = FocusNode(
    debugLabel: 'IptvSourcesBottomAdd',
  );
  final Map<String, FocusNode> _otherDeleteFocusNodes = <String, FocusNode>{};

  bool _refreshing = false;
  StreamSubscription<AppEvent>? _eventSub;
  _PendingSourcesFocusTarget? _pendingFocusTarget;

  @override
  void initState() {
    super.initState();
    _eventSub = ref.read(appEventBusProvider).stream.listen((event) {
      if (event.type != AppEventType.iptvSynced) return;
      ref.invalidate(allIptvAccountsProvider);
      ref.invalidate(iptvAccountsProvider);
      ref.invalidate(stalkerAccountsProvider);
    });
    unawaited(_retrySuppressedRemoteDeletes());
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _searchController.dispose();
    _backFocusNode.dispose();
    _searchButtonFocusNode.dispose();
    _headerAddFocusNode.dispose();
    _changeSourceFocusNode.dispose();
    _searchFieldFocusNode.dispose();
    _activeDeleteFocusNode.dispose();
    _refreshFocusNode.dispose();
    _editFocusNode.dispose();
    _organizeFocusNode.dispose();
    _bottomAddFocusNode.dispose();
    for (final node in _otherDeleteFocusNodes.values) {
      node.dispose();
    }
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

  ScreenType _screenTypeFor(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ScreenTypeResolver.instance.resolve(size.width, size.height);
  }

  bool _useTvModal(BuildContext context) {
    final screenType = _screenTypeFor(context);
    return screenType == ScreenType.desktop || screenType == ScreenType.tv;
  }

  void _syncOtherDeleteFocusNodes(List<AnyIptvAccount> accounts) {
    final activeIds = accounts.map((account) => account.id).toSet();
    final staleIds = _otherDeleteFocusNodes.keys
        .where((id) => !activeIds.contains(id))
        .toList(growable: false);
    for (final id in staleIds) {
      _otherDeleteFocusNodes.remove(id)?.dispose();
    }

    for (final account in accounts) {
      _otherDeleteFocusNodes.putIfAbsent(
        account.id,
        () => FocusNode(debugLabel: 'IptvSourcesDelete_${account.id}'),
      );
    }
  }

  bool _requestFocus(FocusNode node) {
    if (!node.canRequestFocus || node.context == null) {
      return false;
    }
    node.requestFocus();
    return true;
  }

  void _setPendingFocusTarget(_PendingSourcesFocusTarget target) {
    _pendingFocusTarget = target;
  }

  FocusNode? _focusNodeForPendingTarget({
    required _PendingSourcesFocusTarget target,
    required AnyIptvAccount? activeAccount,
  }) {
    switch (target.type) {
      case _PendingSourcesFocusTargetType.searchButton:
        return _searchButtonFocusNode;
      case _PendingSourcesFocusTargetType.searchField:
        return _searchFieldFocusNode;
      case _PendingSourcesFocusTargetType.activeDelete:
        return activeAccount == null ? null : _activeDeleteFocusNode;
      case _PendingSourcesFocusTargetType.refresh:
        return _refreshFocusNode;
      case _PendingSourcesFocusTargetType.bottomAdd:
        return _bottomAddFocusNode;
      case _PendingSourcesFocusTargetType.otherDelete:
        return target.accountId == null
            ? null
            : _otherDeleteFocusNodes[target.accountId!];
    }
  }

  void _applyPendingFocusTarget({required AnyIptvAccount? activeAccount}) {
    final target = _pendingFocusTarget;
    if (target == null) return;
    _pendingFocusTarget = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetNode = _focusNodeForPendingTarget(
        target: target,
        activeAccount: activeAccount,
      );
      if (targetNode != null && _requestFocus(targetNode)) {
        return;
      }
      _requestFocus(_bottomAddFocusNode);
    });
  }

  void _ensureFocusStillVisible({
    required AnyIptvAccount? activeAccount,
    required List<AnyIptvAccount> otherAccounts,
  }) {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null || primaryFocus.context != null) {
      return;
    }

    final managedNodes = <FocusNode>{
      _backFocusNode,
      _searchButtonFocusNode,
      _headerAddFocusNode,
      _changeSourceFocusNode,
      _searchFieldFocusNode,
      _activeDeleteFocusNode,
      _refreshFocusNode,
      _editFocusNode,
      _organizeFocusNode,
      _bottomAddFocusNode,
      ..._otherDeleteFocusNodes.values,
    };
    if (!managedNodes.contains(primaryFocus)) {
      return;
    }

    if (otherAccounts.isNotEmpty) {
      _setPendingFocusTarget(
        _PendingSourcesFocusTarget.otherDelete(otherAccounts.first.id),
      );
    } else if (activeAccount != null) {
      _setPendingFocusTarget(const _PendingSourcesFocusTarget.refresh());
    } else {
      _setPendingFocusTarget(const _PendingSourcesFocusTarget.bottomAdd());
    }
    _applyPendingFocusTarget(activeAccount: activeAccount);
  }

  void _openSearch() {
    setState(() {
      _isSearchVisible = true;
      _setPendingFocusTarget(const _PendingSourcesFocusTarget.searchField());
    });
  }

  void _closeSearch({bool clearText = true, bool focusSearchButton = true}) {
    setState(() {
      if (clearText) {
        _searchController.clear();
      }
      _isSearchVisible = false;
      if (focusSearchButton) {
        _setPendingFocusTarget(
          const _PendingSourcesFocusTarget.searchButton(),
        );
      }
    });
  }

  void _toggleSearch() {
    if (_isSearchVisible) {
      _closeSearch();
      return;
    }
    _openSearch();
  }

  bool _handleRouteBack() {
    if (_isSearchVisible && _searchFieldFocusNode.hasFocus) {
      if (_searchController.text.isNotEmpty) {
        setState(() => _searchController.clear());
      } else {
        _closeSearch();
      }
      return true;
    }
    if (_isSearchVisible && _searchButtonFocusNode.hasFocus) {
      _closeSearch();
      return true;
    }
    if (!context.mounted) return false;
    context.pop();
    return true;
  }

  KeyEventResult _handleDirectionalKey(
    KeyEvent event, {
    FocusNode? left,
    FocusNode? right,
    FocusNode? up,
    FocusNode? down,
    VoidCallback? onLeft,
    VoidCallback? onRight,
    VoidCallback? onUp,
    VoidCallback? onDown,
    bool blockLeft = true,
    bool blockRight = true,
    bool blockUp = true,
    bool blockDown = true,
  }) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    bool moveTo(FocusNode? node) => node != null && _requestFocus(node);

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (onLeft != null) {
          onLeft();
          return KeyEventResult.handled;
        }
        if (moveTo(left)) return KeyEventResult.handled;
        return blockLeft ? KeyEventResult.handled : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowRight:
        if (onRight != null) {
          onRight();
          return KeyEventResult.handled;
        }
        if (moveTo(right)) return KeyEventResult.handled;
        return blockRight ? KeyEventResult.handled : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowUp:
        if (onUp != null) {
          onUp();
          return KeyEventResult.handled;
        }
        if (moveTo(up)) return KeyEventResult.handled;
        return blockUp ? KeyEventResult.handled : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowDown:
        if (onDown != null) {
          onDown();
          return KeyEventResult.handled;
        }
        if (moveTo(down)) return KeyEventResult.handled;
        return blockDown ? KeyEventResult.handled : KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }

  _PendingSourcesFocusTarget _focusTargetAfterDelete({
    required AnyIptvAccount account,
    required List<AnyIptvAccount> accounts,
  }) {
    final selectedId = _selectedAccountId;
    final activeAccount = selectedId == null
        ? null
        : accounts.where((candidate) => candidate.id == selectedId).firstOrNull;
    final query = _searchController.text.trim().toLowerCase();
    final visibleDeleteIds = <String>[
      if (activeAccount != null) activeAccount.id,
      ...accounts
          .where((candidate) => candidate.id != selectedId)
          .where(
            (candidate) =>
                query.isEmpty ||
                candidate.alias.toLowerCase().contains(query) ||
                candidate.getUsername().toLowerCase().contains(query) ||
                candidate.getHost().toLowerCase().contains(query),
          )
          .map((candidate) => candidate.id),
    ];

    final currentIndex = visibleDeleteIds.indexOf(account.id);
    final remainingAccounts = accounts
        .where((candidate) => candidate.id != account.id)
        .toList(growable: false);
    if (remainingAccounts.isEmpty) {
      return const _PendingSourcesFocusTarget.bottomAdd();
    }

    final wasActive = ref
        .read(asp.activeIptvSourcesProvider)
        .contains(account.id);
    final wasSelected = ref.read(slProvider)<SelectedIptvSourcePreferences>().selectedSourceId ==
        account.id;
    final nextSelectedId = (wasActive || wasSelected)
        ? remainingAccounts.first.id
        : _selectedAccountId;

    final remainingVisibleIds = visibleDeleteIds
        .where((candidateId) => candidateId != account.id)
        .toList(growable: false);
    if (remainingVisibleIds.isEmpty) {
      return const _PendingSourcesFocusTarget.bottomAdd();
    }

    final fallbackIndex = currentIndex < 0
        ? 0
        : currentIndex.clamp(0, remainingVisibleIds.length - 1);
    final targetId = remainingVisibleIds[fallbackIndex];
    if (targetId == nextSelectedId) {
      return const _PendingSourcesFocusTarget.activeDelete();
    }
    return _PendingSourcesFocusTarget.otherDelete(targetId);
  }

  Future<RemoteIptvDeleteStatus> _deleteRemoteSourceBestEffort({
    required String localSourceId,
  }) async {
    final service = _remoteDeleteServiceOrNull();
    if (service == null) {
      return RemoteIptvDeleteStatus.skippedRepositoryUnavailable;
    }

    final userId = ref.read(authUserIdProvider);
    return service.deleteByLocalIdBestEffort(
      localId: localSourceId,
      userId: userId,
    );
  }

  IptvSourceRemoteDeleteService? _remoteDeleteServiceOrNull() {
    final locator = ref.read(slProvider);
    if (!locator.isRegistered<SupabaseIptvSourcesRepository>()) {
      return null;
    }

    return IptvSourceRemoteDeleteService(
      loadSources: ({required accountId}) => locator
          .get<SupabaseIptvSourcesRepository>()
          .getSources(accountId: accountId),
      deleteSource: ({required id, required accountId}) => locator
          .get<SupabaseIptvSourcesRepository>()
          .deleteSource(id: id, accountId: accountId),
    );
  }

  SuppressedRemoteIptvSourcesPreferences?
  _suppressedRemoteSourcesPreferencesOrNull() {
    final locator = ref.read(slProvider);
    if (!locator.isRegistered<SecureStorageRepository>()) {
      return null;
    }
    return SuppressedRemoteIptvSourcesPreferences(
      storage: locator<SecureStorageRepository>(),
    );
  }

  Future<void> _syncRemoteHydrationSuppression({
    required String localSourceId,
    required RemoteIptvDeleteStatus remoteDeleteStatus,
  }) async {
    final userId = ref.read(authUserIdProvider)?.trim();
    if (userId == null || userId.isEmpty) {
      return;
    }

    final prefs = _suppressedRemoteSourcesPreferencesOrNull();
    if (prefs == null) {
      return;
    }

    try {
      if (remoteDeleteStatus.remoteDeletionConfirmed) {
        await prefs.clear(accountId: userId, localId: localSourceId);
      } else {
        await prefs.suppress(accountId: userId, localId: localSourceId);
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[IptvSourcesPage] failed to sync remote hydration suppression '
          'status=$remoteDeleteStatus sourceId=$localSourceId error=$error',
        );
      }
    }
  }

  Future<void> _retrySuppressedRemoteDeletes() async {
    final userId = ref.read(authUserIdProvider)?.trim();
    if (userId == null || userId.isEmpty) {
      return;
    }

    final prefs = _suppressedRemoteSourcesPreferencesOrNull();
    final service = _remoteDeleteServiceOrNull();
    if (prefs == null || service == null) {
      return;
    }

    final pendingLocalIds = await prefs.readSuppressedLocalIds(
      accountId: userId,
    );
    if (pendingLocalIds.isEmpty) {
      return;
    }

    final results = await service.deleteByLocalIdsBestEffort(
      localIds: pendingLocalIds,
      userId: userId,
    );
    for (final entry in results.entries) {
      await _syncRemoteHydrationSuppression(
        localSourceId: entry.key,
        remoteDeleteStatus: entry.value,
      );
    }

    if (kDebugMode) {
      debugPrint(
        '[IptvSourcesPage] retried suppressed remote deletes '
        'pending=${pendingLocalIds.length} '
        'confirmed=${results.values.where((status) => status.remoteDeletionConfirmed).length}',
      );
    }
  }

  String? _remoteDeleteFollowUpMessage(RemoteIptvDeleteStatus status) {
    if (!status.mayReappearAfterReconnect) {
      return null;
    }
    return 'Source supprimée localement. Elle peut réapparaître après reconnexion tant que la suppression cloud n’a pas abouti.';
  }

  Future<bool> _showDeleteConfirmation(AnyIptvAccount account) async {
    final l10n = AppLocalizations.of(context)!;
    if (_useTvModal(context)) {
      var confirmed = false;
      await showMoviTvActionMenu(
        context: context,
        title: l10n.actionConfirm,
        actions: [
          MoviTvActionMenuAction(
            label: 'Supprimer',
            destructive: true,
            onPressed: () {
              confirmed = true;
            },
          ),
        ],
        cancelLabel: l10n.actionCancel,
      );
      await WidgetsBinding.instance.endOfFrame;
      return confirmed;
    }

    final confirmed = await showCupertinoDialog<bool>(
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
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _confirmAndDelete(
    AnyIptvAccount account,
    List<AnyIptvAccount> accounts,
  ) async {
    final local = ref.read(slProvider)<IptvLocalRepository>();
    final vault = ref.read(slProvider)<CredentialsVault>();
    final appState = ref.read(asp.appStateControllerProvider);
    final selectedPrefs = ref.read(slProvider)<SelectedIptvSourcePreferences>();
    final focusTargetAfterDelete = _focusTargetAfterDelete(
      account: account,
      accounts: accounts,
    );

    if (!await _showDeleteConfirmation(account)) return;

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

    _setPendingFocusTarget(focusTargetAfterDelete);

    final remoteDeleteStatus = await _deleteRemoteSourceBestEffort(
      localSourceId: account.id,
    );
    await _syncRemoteHydrationSuppression(
      localSourceId: account.id,
      remoteDeleteStatus: remoteDeleteStatus,
    );
    final remoteDeleteFollowUp = _remoteDeleteFollowUpMessage(
      remoteDeleteStatus,
    );
    if (remoteDeleteFollowUp != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(remoteDeleteFollowUp)));
    }
    if (kDebugMode && !remoteDeleteStatus.remoteDeletionConfirmed) {
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

    if (mounted && remoteDeleteFollowUp == null) {
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
    final initialFocusNode = accountsAsync.maybeWhen(
      data: (accounts) => accounts.isEmpty ? _bottomAddFocusNode : _refreshFocusNode,
      orElse: () => _backFocusNode,
    );

    return MoviRouteFocusBoundary(
      restorePolicy: MoviFocusRestorePolicy(
        initialFocusNode: initialFocusNode,
        fallbackFocusNode: _backFocusNode,
      ),
      requestInitialFocusOnMount: true,
      onUnhandledBack: _handleRouteBack,
      debugLabel: 'IptvSourcesRouteFocus',
      child: Scaffold(
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
              final allOtherAccounts = accounts
                  .where((account) => account.id != selectedId)
                  .toList(growable: false);
              _syncOtherDeleteFocusNodes(allOtherAccounts);

              final query = _searchController.text.trim().toLowerCase();
              final otherAccounts = allOtherAccounts
                  .where(
                    (a) =>
                        query.isEmpty ||
                        a.alias.toLowerCase().contains(query) ||
                        a.getUsername().toLowerCase().contains(query) ||
                        a.getHost().toLowerCase().contains(query),
                  )
                  .toList(growable: false);
              final firstOtherDeleteNode = otherAccounts.isNotEmpty
                  ? _otherDeleteFocusNodes[otherAccounts.first.id]
                  : null;
              final lastOtherDeleteNode = otherAccounts.isNotEmpty
                  ? _otherDeleteFocusNodes[otherAccounts.last.id]
                  : null;

              _applyPendingFocusTarget(activeAccount: activeAccount);
              _ensureFocusStillVisible(
                activeAccount: activeAccount,
                otherAccounts: otherAccounts,
              );

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: _HeaderBar(
                      title: 'Sources',
                      accent: accent,
                      searchActive: _isSearchVisible,
                      backFocusNode: _backFocusNode,
                      searchFocusNode: _searchButtonFocusNode,
                      addFocusNode: _headerAddFocusNode,
                      onBack: () => context.pop(),
                      onSearch: _toggleSearch,
                      onAdd: _openAddSource,
                      onBackKeyEvent: (event) => _handleDirectionalKey(
                        event,
                        right: _searchButtonFocusNode,
                        down: _changeSourceFocusNode,
                        blockLeft: true,
                        blockUp: true,
                      ),
                      onSearchKeyEvent: (event) => _handleDirectionalKey(
                        event,
                        left: _backFocusNode,
                        right: _headerAddFocusNode,
                        down: _isSearchVisible
                            ? _searchFieldFocusNode
                            : _changeSourceFocusNode,
                        blockUp: true,
                      ),
                      onAddKeyEvent: (event) => _handleDirectionalKey(
                        event,
                        left: _searchButtonFocusNode,
                        down: _changeSourceFocusNode,
                        blockRight: true,
                        blockUp: true,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      children: [
                        Focus(
                          canRequestFocus: false,
                          onKeyEvent: (_, event) => _handleDirectionalKey(
                            event,
                            up: _isSearchVisible
                                ? _searchFieldFocusNode
                                : _searchButtonFocusNode,
                            down: activeAccount != null
                                ? _activeDeleteFocusNode
                                : firstOtherDeleteNode ?? _bottomAddFocusNode,
                          ),
                          child: MoviEnsureVisibleOnFocus(
                            verticalAlignment: _focusVerticalAlignment,
                            child: MoviPrimaryButton(
                              label: 'Changer de source active',
                              focusNode: _changeSourceFocusNode,
                              leading: const Icon(Icons.swap_horiz),
                              buttonStyle: FilledButton.styleFrom(
                                backgroundColor: accent.withAlpha(51),
                                foregroundColor: accent,
                              ),
                              onPressed: () =>
                                  context.push(AppRouteNames.iptvSourceSelect),
                            ),
                          ),
                        ),
                        if (_isSearchVisible) ...[
                          const SizedBox(height: 12),
                          Focus(
                            canRequestFocus: false,
                            onKeyEvent: (_, event) => _handleDirectionalKey(
                              event,
                              left: _searchButtonFocusNode,
                              up: _searchButtonFocusNode,
                              down: firstOtherDeleteNode ?? _bottomAddFocusNode,
                              blockRight: true,
                            ),
                            child: MoviEnsureVisibleOnFocus(
                              verticalAlignment: _focusVerticalAlignment,
                              child: CallbackShortcuts(
                                bindings: <ShortcutActivator, VoidCallback>{
                                  const SingleActivator(
                                    LogicalKeyboardKey.arrowLeft,
                                  ): () => _requestFocus(_searchButtonFocusNode),
                                  const SingleActivator(
                                    LogicalKeyboardKey.arrowUp,
                                  ): () => _requestFocus(_searchButtonFocusNode),
                                  const SingleActivator(
                                    LogicalKeyboardKey.arrowDown,
                                  ): () => _requestFocus(
                                    firstOtherDeleteNode ?? _bottomAddFocusNode,
                                  ),
                                },
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFieldFocusNode,
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Rechercher une source…',
                                    hintStyle: const TextStyle(
                                      color: Colors.white54,
                                    ),
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
                            deleteFocusNode: _activeDeleteFocusNode,
                            focusVerticalAlignment: _focusVerticalAlignment,
                            onDeleteKeyEvent: (event) => _handleDirectionalKey(
                              event,
                              up: _changeSourceFocusNode,
                              down: _refreshFocusNode,
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (activeAccount != null) ...[
                          Focus(
                            canRequestFocus: false,
                            onKeyEvent: (_, event) => _handleDirectionalKey(
                              event,
                              up: _activeDeleteFocusNode,
                              down: activeAccount.isStalker
                                  ? _organizeFocusNode
                                  : _editFocusNode,
                            ),
                            child: MoviEnsureVisibleOnFocus(
                              verticalAlignment: _focusVerticalAlignment,
                              child: MoviPrimaryButton(
                                label: _refreshing
                                    ? 'Rafraîchissement…'
                                    : 'Rafraîchir',
                                focusNode: _refreshFocusNode,
                                onPressed: _refreshing
                                    ? null
                                    : () => _refreshSelected(activeAccount),
                                loading: _refreshing,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (!activeAccount.isStalker)
                            Focus(
                              canRequestFocus: false,
                              onKeyEvent: (_, event) => _handleDirectionalKey(
                                event,
                                up: _refreshFocusNode,
                                down: _organizeFocusNode,
                              ),
                              child: MoviEnsureVisibleOnFocus(
                                verticalAlignment: _focusVerticalAlignment,
                                child: MoviPrimaryButton(
                                  label: 'Modifier',
                                  focusNode: _editFocusNode,
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
                              ),
                            ),
                          const SizedBox(height: 16),
                          Focus(
                            canRequestFocus: false,
                            onKeyEvent: (_, event) => _handleDirectionalKey(
                              event,
                              up: activeAccount.isStalker
                                  ? _refreshFocusNode
                                  : _editFocusNode,
                              down:
                                  firstOtherDeleteNode ?? _bottomAddFocusNode,
                            ),
                            child: MoviEnsureVisibleOnFocus(
                              verticalAlignment: _focusVerticalAlignment,
                              child: MoviPrimaryButton(
                                label: 'Organiser les catégories',
                                focusNode: _organizeFocusNode,
                                onPressed: () => context.push(
                                  AppRouteNames.iptvSourceOrganize,
                                  extra: activeAccount.id,
                                ),
                              ),
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
                        for (var index = 0; index < otherAccounts.length; index++) ...[
                          _SourceCard(
                            account: otherAccounts[index],
                            accent: accent,
                            locale: locale,
                            isActive: _isAccountActive(otherAccounts[index]),
                            expirationText: _formatExpiration(
                              otherAccounts[index].getExpiration(),
                              locale,
                            ),
                            onDelete: () =>
                                _confirmAndDelete(otherAccounts[index], accounts),
                            deleteFocusNode:
                                _otherDeleteFocusNodes[otherAccounts[index].id],
                            focusVerticalAlignment: _focusVerticalAlignment,
                            onDeleteKeyEvent: (event) => _handleDirectionalKey(
                              event,
                              up: index == 0
                                  ? (activeAccount != null
                                        ? _organizeFocusNode
                                        : (_isSearchVisible
                                              ? _searchFieldFocusNode
                                              : _changeSourceFocusNode))
                                  : _otherDeleteFocusNodes[
                                        otherAccounts[index - 1].id
                                    ],
                              down: index == otherAccounts.length - 1
                                  ? _bottomAddFocusNode
                                  : _otherDeleteFocusNodes[
                                        otherAccounts[index + 1].id
                                    ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (otherAccounts.isNotEmpty)
                          const SizedBox(height: 16),
                        Focus(
                          canRequestFocus: false,
                          onKeyEvent: (_, event) => _handleDirectionalKey(
                            event,
                            up: lastOtherDeleteNode ??
                                (activeAccount != null
                                    ? _organizeFocusNode
                                    : _changeSourceFocusNode),
                            blockDown: true,
                          ),
                          child: MoviEnsureVisibleOnFocus(
                            verticalAlignment: _focusVerticalAlignment,
                            child: MoviPrimaryButton(
                              label: 'Ajouter une source',
                              focusNode: _bottomAddFocusNode,
                              onPressed: _openAddSource,
                            ),
                          ),
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
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.title,
    required this.accent,
    required this.searchActive,
    required this.backFocusNode,
    required this.searchFocusNode,
    required this.addFocusNode,
    required this.onBack,
    required this.onSearch,
    required this.onAdd,
    required this.onBackKeyEvent,
    required this.onSearchKeyEvent,
    required this.onAddKeyEvent,
  });

  final String title;
  final Color accent;
  final bool searchActive;
  final FocusNode backFocusNode;
  final FocusNode searchFocusNode;
  final FocusNode addFocusNode;
  final VoidCallback onBack;
  final VoidCallback onSearch;
  final VoidCallback onAdd;
  final KeyEventResult Function(KeyEvent event) onBackKeyEvent;
  final KeyEventResult Function(KeyEvent event) onSearchKeyEvent;
  final KeyEventResult Function(KeyEvent event) onAddKeyEvent;

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
              child: Focus(
                canRequestFocus: false,
                onKeyEvent: (_, event) => onBackKeyEvent(event),
                child: MoviFocusableAction(
                  focusNode: backFocusNode,
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
                _HeaderActionButton(
                  iconPath: AppAssets.iconSearch,
                  semanticLabel: 'Rechercher',
                  accent: accent,
                  active: searchActive,
                  focusNode: searchFocusNode,
                  onPressed: onSearch,
                  onKeyEvent: onSearchKeyEvent,
                ),
                const SizedBox(width: 8),
                _HeaderActionButton(
                  iconPath: AppAssets.iconPlus,
                  semanticLabel: 'Ajouter',
                  accent: accent,
                  focusNode: addFocusNode,
                  onPressed: onAdd,
                  onKeyEvent: onAddKeyEvent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.iconPath,
    required this.semanticLabel,
    required this.accent,
    required this.focusNode,
    required this.onPressed,
    required this.onKeyEvent,
    this.active = false,
  });

  final String iconPath;
  final String semanticLabel;
  final Color accent;
  final FocusNode focusNode;
  final VoidCallback onPressed;
  final KeyEventResult Function(KeyEvent event) onKeyEvent;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (_, event) => onKeyEvent(event),
        child: MoviFocusableAction(
          focusNode: focusNode,
          onPressed: onPressed,
          semanticLabel: semanticLabel,
          builder: (context, state) {
            final backgroundColor = active
                ? accent.withValues(alpha: state.focused ? 0.28 : 0.20)
                : Colors.white.withValues(alpha: state.focused ? 0.14 : 0.08);
            return MoviFocusFrame(
              scale: state.focused ? 1.04 : 1,
              padding: const EdgeInsets.all(10),
              borderRadius: BorderRadius.circular(999),
              backgroundColor: backgroundColor,
              child: MoviAssetIcon(
                iconPath,
                width: 24,
                height: 24,
                color: active ? accent : Colors.white,
              ),
            );
          },
        ),
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
    required this.deleteFocusNode,
    required this.focusVerticalAlignment,
    required this.onDeleteKeyEvent,
  });

  final AnyIptvAccount account;
  final Color accent;
  final Locale locale;
  final bool isActive;
  final String expirationText;
  final VoidCallback onDelete;
  final FocusNode? deleteFocusNode;
  final double focusVerticalAlignment;
  final KeyEventResult Function(KeyEvent event) onDeleteKeyEvent;

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

    return Container(
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
              Focus(
                canRequestFocus: false,
                onKeyEvent: (_, event) => onDeleteKeyEvent(event),
                child: MoviEnsureVisibleOnFocus(
                  verticalAlignment: focusVerticalAlignment,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: MoviFocusableAction(
                      focusNode: deleteFocusNode,
                      onPressed: onDelete,
                      semanticLabel: 'Supprimer ${account.alias}',
                      builder: (context, state) {
                        return MoviFocusFrame(
                          scale: state.focused ? 1.04 : 1,
                          padding: const EdgeInsets.all(6),
                          borderRadius: BorderRadius.circular(999),
                          backgroundColor: state.focused
                              ? const Color(0xFFFF3B30).withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderColor: state.focused
                              ? const Color(0xFFFF3B30)
                              : Colors.transparent,
                          borderWidth: 2,
                          child: const MoviAssetIcon(
                            AppAssets.iconTrash,
                            width: 28,
                            height: 28,
                            color: Color(0xFFFF3B30),
                          ),
                        );
                      },
                    ),
                  ),
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

enum _PendingSourcesFocusTargetType {
  searchButton,
  searchField,
  activeDelete,
  refresh,
  bottomAdd,
  otherDelete,
}

class _PendingSourcesFocusTarget {
  const _PendingSourcesFocusTarget._(this.type, [this.accountId]);

  const _PendingSourcesFocusTarget.searchButton()
    : this._(_PendingSourcesFocusTargetType.searchButton);

  const _PendingSourcesFocusTarget.searchField()
    : this._(_PendingSourcesFocusTargetType.searchField);

  const _PendingSourcesFocusTarget.activeDelete()
    : this._(_PendingSourcesFocusTargetType.activeDelete);

  const _PendingSourcesFocusTarget.refresh()
    : this._(_PendingSourcesFocusTargetType.refresh);

  const _PendingSourcesFocusTarget.bottomAdd()
    : this._(_PendingSourcesFocusTargetType.bottomAdd);

  const _PendingSourcesFocusTarget.otherDelete(String accountId)
    : this._(_PendingSourcesFocusTargetType.otherDelete, accountId);

  final _PendingSourcesFocusTargetType type;
  final String? accountId;
}

