import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/widgets/movi_subpage_back_title_header.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/iptv/application/usecases/refresh_stalker_catalog.dart';
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
import 'package:movi/src/features/iptv/presentation/widgets/iptv_source_selection_list.dart';
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_sources_providers.dart';
import 'package:movi/src/features/settings/presentation/widgets/settings_content_width.dart';

class IptvSourceSelectPage extends ConsumerStatefulWidget {
  const IptvSourceSelectPage({super.key});

  @override
  ConsumerState<IptvSourceSelectPage> createState() =>
      _IptvSourceSelectPageState();
}

class _IptvSourceSelectPageState extends ConsumerState<IptvSourceSelectPage> {
  String? _switchingAccountId;
  final FocusNode _backFocusNode = FocusNode(
    debugLabel: 'IptvSourceSelectBack',
  );
  final List<FocusNode> _accountFocusNodes = <FocusNode>[];

  bool get _isSwitching => _switchingAccountId != null;

  @override
  void dispose() {
    _backFocusNode.dispose();
    for (final node in _accountFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncAccountFocusNodes(int count) {
    while (_accountFocusNodes.length < count) {
      _accountFocusNodes.add(
        FocusNode(
          debugLabel: 'IptvSourceSelectItem${_accountFocusNodes.length}',
        ),
      );
    }
    while (_accountFocusNodes.length > count) {
      _accountFocusNodes.removeLast().dispose();
    }
  }

  bool _requestFocus(FocusNode node) {
    if (!node.canRequestFocus || node.context == null) {
      return false;
    }
    node.requestFocus();
    return true;
  }

  KeyEventResult _handleDirectionalKey(
    KeyEvent event, {
    FocusNode? up,
    FocusNode? down,
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
        return blockLeft ? KeyEventResult.handled : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowRight:
        return blockRight ? KeyEventResult.handled : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowUp:
        if (moveTo(up)) return KeyEventResult.handled;
        return blockUp ? KeyEventResult.handled : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowDown:
        if (moveTo(down)) return KeyEventResult.handled;
        return blockDown ? KeyEventResult.handled : KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }

  bool _handleBack(BuildContext context) {
    if (!context.mounted || _isSwitching) return false;
    if (!context.canPop()) return false;
    context.pop();
    return true;
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
      ScaffoldMessenger.of(context).showSnackBar(
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

    final initialFocusNode = accountsAsync.maybeWhen(
      data: (accounts) {
        if (accounts.isEmpty) {
          return _backFocusNode;
        }
        _syncAccountFocusNodes(accounts.length);
        return _accountFocusNodes.first;
      },
      orElse: () => _backFocusNode,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: FocusRegionScope(
        regionId: AppFocusRegionId.settingsIptvSourceSelectPrimary,
        binding: FocusRegionBinding(
          resolvePrimaryEntryNode: () => initialFocusNode,
          resolveFallbackEntryNode: () => _backFocusNode,
        ),
        requestFocusOnMount: true,
        handleDirectionalExits: false,
        debugLabel: 'IptvSourceSelectRegion',
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: (_, event) => _handleRouteBackKey(event, context),
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Stack(
              children: [
            SafeArea(
              child: SettingsContentWidth(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Focus(
                      canRequestFocus: false,
                      onKeyEvent: (_, event) => _handleDirectionalKey(
                        event,
                        down: accountsAsync.maybeWhen(
                          data: (accounts) {
                            if (accounts.isEmpty) {
                              return null;
                            }
                            _syncAccountFocusNodes(accounts.length);
                            return _accountFocusNodes.first;
                          },
                          orElse: () => null,
                        ),
                        blockLeft: true,
                        blockRight: true,
                        blockUp: true,
                      ),
                      child: MoviSubpageBackTitleHeader(
                        title: l10n.activeSourceTitle,
                        focusNode: _backFocusNode,
                        onBack: _isSwitching ? null : () => _handleBack(context),
                      ),
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
                          _syncAccountFocusNodes(accounts.length);
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
                            itemFocusNodes: _accountFocusNodes,
                            onFirstItemUp: () => _requestFocus(_backFocusNode),
                            onLastItemDown: () {},
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
          ),
        ),
      ),
    );
  }
}
