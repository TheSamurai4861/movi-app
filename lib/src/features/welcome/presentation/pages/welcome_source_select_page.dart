import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/focus/movi_focus_restore_policy.dart';
import 'package:movi/src/core/focus/movi_route_focus_boundary.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/router/app_route_ids.dart';
import 'package:movi/src/core/router/app_route_names.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/startup/presentation/widgets/launch_recovery_banner.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/core/widgets/movi_subpage_back_title_header.dart';
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
import 'package:movi/src/features/iptv/presentation/providers/iptv_accounts_providers.dart';
import 'package:movi/src/features/iptv/presentation/widgets/iptv_source_selection_list.dart';
import 'package:movi/src/features/settings/presentation/widgets/settings_content_width.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';

class WelcomeSourceSelectPage extends ConsumerStatefulWidget {
  const WelcomeSourceSelectPage({super.key});

  @override
  ConsumerState<WelcomeSourceSelectPage> createState() =>
      _WelcomeSourceSelectPageState();
}

class _WelcomeSourceSelectPageState
    extends ConsumerState<WelcomeSourceSelectPage> {
  final FocusNode _backFocusNode = FocusNode(
    debugLabel: 'WelcomeSourceSelectBack',
  );
  final FocusNode _retryFocusNode = FocusNode(
    debugLabel: 'WelcomeSourceSelectRetry',
  );
  final FocusNode _addSourceFocusNode = FocusNode(
    debugLabel: 'WelcomeSourceSelectAddSource',
  );
  final List<FocusNode> _accountFocusNodes = <FocusNode>[];

  @override
  void dispose() {
    _backFocusNode.dispose();
    _retryFocusNode.dispose();
    _addSourceFocusNode.dispose();
    for (final node in _accountFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncAccountFocusNodes(int count) {
    while (_accountFocusNodes.length < count) {
      _accountFocusNodes.add(
        FocusNode(debugLabel: 'WelcomeSourceSelectItem${_accountFocusNodes.length}'),
      );
    }
    while (_accountFocusNodes.length > count) {
      _accountFocusNodes.removeLast().dispose();
    }
  }

  String? _determineFallbackRoute(BuildContext context) {
    if (context.canPop()) {
      return null;
    }

    final currentLocation = GoRouterState.of(context).uri.toString();
    if (currentLocation.startsWith(AppRoutePaths.welcome)) {
      return AppRouteNames.welcomeSources;
    }
    return AppRouteNames.iptvSources;
  }

  void _handleBack(BuildContext context) {
    final fallbackRoute = _determineFallbackRoute(context);
    if (fallbackRoute == null) {
      context.pop();
    } else {
      context.go(fallbackRoute);
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
    FocusNode? left,
    FocusNode? right,
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
        if (moveTo(left)) return KeyEventResult.handled;
        return blockLeft ? KeyEventResult.handled : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowRight:
        if (moveTo(right)) return KeyEventResult.handled;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final asyncAccounts = ref.watch(allIptvAccountsProvider);
    final launchRecovery = ref.watch(appLaunchStateProvider).recovery;

    final locator = ref.watch(slProvider);
    final selectedPrefs = locator<SelectedIptvSourcePreferences>();
    final selectedId = selectedPrefs.selectedSourceId;

    final initialFocusNode = asyncAccounts.maybeWhen(
      data: (accounts) {
        if (accounts.isEmpty) {
          return _addSourceFocusNode;
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
      child: MoviRouteFocusBoundary(
        restorePolicy: MoviFocusRestorePolicy(
          initialFocusNode: initialFocusNode,
          fallbackFocusNode: _backFocusNode,
        ),
        requestInitialFocusOnMount: true,
        onUnhandledBack: () {
          if (!context.mounted) return false;
          _handleBack(context);
          return true;
        },
        debugLabel: 'WelcomeSourceSelectRouteFocus',
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: SettingsContentWidth(
              child: Column(
                children: [
                  Focus(
                    canRequestFocus: false,
                    onKeyEvent: (_, event) => _handleDirectionalKey(
                      event,
                      down: launchRecovery?.isRetryable ?? false
                          ? _retryFocusNode
                          : asyncAccounts.maybeWhen(
                              data: (accounts) {
                                if (accounts.isEmpty) {
                                  return _addSourceFocusNode;
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
                      onBack: () => _handleBack(context),
                    ),
                  ),
                  if (launchRecovery?.isRetryable ?? false) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: MoviEnsureVisibleOnFocus(
                        verticalAlignment: 0.18,
                        child: Focus(
                          canRequestFocus: false,
                          onKeyEvent: (_, event) => _handleDirectionalKey(
                            event,
                            up: _backFocusNode,
                            down: asyncAccounts.maybeWhen(
                              data: (accounts) {
                                if (accounts.isEmpty) {
                                  return _addSourceFocusNode;
                                }
                                _syncAccountFocusNodes(accounts.length);
                                return _accountFocusNodes.first;
                              },
                              orElse: () => null,
                            ),
                            blockLeft: true,
                            blockRight: true,
                          ),
                          child: LaunchRecoveryBanner(
                            message: launchRecovery!.message,
                            retryFocusNode: _retryFocusNode,
                            onRetry: () {
                              ref
                                  .read(appLaunchOrchestratorProvider.notifier)
                                  .reset();
                              context.go(AppRouteNames.launch);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
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
                        _syncAccountFocusNodes(accounts.length);
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
                                  MoviEnsureVisibleOnFocus(
                                    verticalAlignment: 0.22,
                                    child: Focus(
                                      canRequestFocus: false,
                                      onKeyEvent: (_, event) =>
                                          _handleDirectionalKey(
                                            event,
                                            up: launchRecovery?.isRetryable ??
                                                    false
                                                ? _retryFocusNode
                                                : _backFocusNode,
                                            blockLeft: true,
                                            blockRight: true,
                                            blockDown: true,
                                          ),
                                      child: ElevatedButton(
                                        focusNode: _addSourceFocusNode,
                                        onPressed: () => context.go(
                                          AppRouteNames.welcomeSources,
                                        ),
                                        child: const Text(
                                          'Ajouter une source',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return IptvSourceSelectionList(
                          accounts: accounts,
                          selectedId: selectedId,
                          itemFocusNodes: _accountFocusNodes,
                          onFirstItemUp: () => _requestFocus(
                            launchRecovery?.isRetryable ?? false
                                ? _retryFocusNode
                                : _backFocusNode,
                          ),
                          focusVerticalAlignment: 0.22,
                          onSelected: (account) async {
                            final prefs =
                                locator<SelectedIptvSourcePreferences>();

                            await prefs.setSelectedSourceId(account.id);

                            final appStateController =
                                ref.read(appStateControllerProvider);
                            appStateController.setActiveIptvSources({account.id});

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
                            context.goNamed(
                              AppRouteIds.welcomeSourceLoading,
                              queryParameters: const <String, String>{
                                'force_reload': '1',
                              },
                            );
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
      ),
    );
  }
}
