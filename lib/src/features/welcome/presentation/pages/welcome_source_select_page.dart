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
import 'package:movi/src/core/router/app_route_names.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/startup/presentation/boot_action_executor.dart';
import 'package:movi/src/core/startup/presentation/boot_action_handler.dart';
import 'package:movi/src/core/startup/entry_boot_state_repository.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_form_tokens.dart';
import 'package:movi/src/core/startup/presentation/widgets/launch_recovery_banner.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
import 'package:movi/src/features/iptv/presentation/providers/iptv_accounts_providers.dart';
import 'package:movi/src/features/settings/presentation/widgets/settings_content_width.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_header.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';

class WelcomeSourceSelectPage extends ConsumerStatefulWidget {
  const WelcomeSourceSelectPage({super.key});

  @override
  ConsumerState<WelcomeSourceSelectPage> createState() =>
      _WelcomeSourceSelectPageState();
}

class _WelcomeSourceSelectPageState
    extends ConsumerState<WelcomeSourceSelectPage> {
  final FocusNode _retryFocusNode = FocusNode(
    debugLabel: 'WelcomeSourceSelectRetry',
  );
  final FocusNode _addSourceFocusNode = FocusNode(
    debugLabel: 'WelcomeSourceSelectAddSource',
  );
  final List<FocusNode> _accountFocusNodes = <FocusNode>[];
  bool _isHandlingBack = false;

  @override
  void dispose() {
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
        FocusNode(
          debugLabel: 'WelcomeSourceSelectItem${_accountFocusNodes.length}',
        ),
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

  Future<void> _runBootAction(
    BuildContext context,
    BootActionIntent intent,
    String reasonCode, {
    String? destinationOverride,
  }) {
    return executeBootAction(
      context,
      ref,
      BootActionRequest(
        intent: intent,
        reasonCode: reasonCode,
        destinationOverride: destinationOverride,
      ),
    );
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

    final initialFocusNode = asyncAccounts.maybeWhen(
      data: (accounts) {
        if (accounts.isEmpty) {
          return _addSourceFocusNode;
        }
        _syncAccountFocusNodes(accounts.length);
        return _accountFocusNodes.first;
      },
      orElse: () => _addSourceFocusNode,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: FocusRegionScope(
        regionId: AppFocusRegionId.welcomeSourceSelectPrimary,
        binding: FocusRegionBinding(
          resolvePrimaryEntryNode: () => initialFocusNode,
          resolveFallbackEntryNode: () => _addSourceFocusNode,
        ),
        requestFocusOnMount: true,
        handleDirectionalExits: false,
        debugLabel: 'WelcomeSourceSelectRegion',
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: (_, event) => _handleRouteBackKey(event, context),
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: SafeArea(
              child: SettingsContentWidth(
                child: Column(
                  children: [
                    if (launchRecovery?.isRetryable ?? false) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: MoviEnsureVisibleOnFocus(
                          verticalAlignment: 0.18,
                          child: Focus(
                            canRequestFocus: false,
                            onKeyEvent: (_, event) => _handleDirectionalKey(
                              event,
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
                              onRetry: () => unawaited(
                                _runBootAction(
                                  context,
                                  BootActionIntent.retry,
                                  launchRecovery.reasonCode,
                                ),
                              ),
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
                            l10n.errorLoadingPlaylistsWithMessage(e.toString()),
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
                                              up:
                                                  launchRecovery?.isRetryable ??
                                                      false
                                                  ? _retryFocusNode
                                                  : null,
                                              blockLeft: true,
                                              blockRight: true,
                                              blockDown: true,
                                            ),
                                        child: ElevatedButton(
                                          focusNode: _addSourceFocusNode,
                                          onPressed: () => context.go(
                                            '${AppRouteNames.welcomeSources}?mode=add',
                                          ),
                                          child: Text(l10n.welcomeSourceAdd),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final sourceSelectionButtonStyle =
                              BootFormTokens.bootPrimaryButtonStyle(
                                Theme.of(context),
                              ).copyWith(
                                backgroundColor: const WidgetStatePropertyAll(
                                  Color(0xFF333333),
                                ),
                              );

                          Future<void> selectAccount(AnyIptvAccount account) async {
                            final prefs = locator<SelectedIptvSourcePreferences>();
                            await prefs.setSelectedSourceId(account.id);

                            final appStateController = ref.read(
                              appStateControllerProvider,
                            );
                            appStateController.setActiveIptvSources({
                              account.id,
                            });
                            if (locator.isRegistered<EntryBootStateRepository>()) {
                              await locator<EntryBootStateRepository>()
                                  .confirmSourceSelected(sourceId: account.id);
                            }

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

                            await Future.delayed(const Duration(milliseconds: 100));

                            if (!context.mounted) return;
                            await _runBootAction(
                              context,
                              BootActionIntent.retry,
                              'source_selected',
                              destinationOverride: AppRoutePaths.welcomeSourceLoading,
                            );
                          }

                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: BootFormTokens.textFieldMaxWidth,
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.xl,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    WelcomeHeader(
                                      title: l10n.bootActionSourceSelectionTitle,
                                      subtitle:
                                          l10n.bootActionSourceSelectionMessage,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    for (final account in accounts) ...[
                                      BootFormTokens.constrainPrimaryAction(
                                        MoviPrimaryButton(
                                          label: account.alias,
                                          onPressed: () async {
                                            await selectAccount(account);
                                          },
                                          buttonStyle: sourceSelectionButtonStyle,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.s),
                                    ],
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      l10n.welcomeSourceAddPrompt,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    BootFormTokens.constrainPrimaryAction(
                                      MoviPrimaryButton(
                                        label: l10n.welcomeSourceAddNewAction,
                                        focusNode: _addSourceFocusNode,
                                        onPressed: () => context.go(
                                          '${AppRouteNames.welcomeSources}?mode=add',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
      ),
    );
  }
}
