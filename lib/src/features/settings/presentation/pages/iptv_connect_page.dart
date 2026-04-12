import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/directional_edge.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/domain/focus_region_exit_map.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/widgets/movi_subpage_back_title_header.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_connect_providers.dart';
import 'package:movi/src/features/settings/presentation/widgets/settings_content_width.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';
import 'package:movi/src/features/welcome/presentation/widgets/labeled_field.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_header.dart';

class IptvConnectPage extends ConsumerStatefulWidget {
  const IptvConnectPage({super.key});

  @override
  ConsumerState<IptvConnectPage> createState() => _IptvConnectPageState();
}

class _IptvConnectPageState extends ConsumerState<IptvConnectPage> {
  final _formKey = GlobalKey<FormState>();
  final _serverCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _aliasCtrl = TextEditingController();
  final _serverFocusNode = FocusNode(debugLabel: 'ConnectSourceServer');
  final _userFocusNode = FocusNode(debugLabel: 'ConnectSourceUser');
  final _passFocusNode = FocusNode(debugLabel: 'ConnectSourcePassword');
  final _submitFocusNode = FocusNode(debugLabel: 'ConnectSourceSubmit');
  final _backFocusNode = FocusNode(debugLabel: 'ConnectSourceBack');
  bool _obscurePassword = true;

  KeyEventResult _handleRouteBackKey(KeyEvent event, BuildContext context) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (!mounted || !context.mounted) return KeyEventResult.ignored;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRouteNames.home);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _serverCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _aliasCtrl.dispose();
    _serverFocusNode.dispose();
    _userFocusNode.dispose();
    _passFocusNode.dispose();
    _submitFocusNode.dispose();
    _backFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final notifier = ref.read(iptvConnectControllerProvider.notifier);
    final ok = await notifier.connect(
      sourceType: IptvSourceType.xtream,
      serverUrl: _serverCtrl.text.trim(),
      username: _userCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.snackbarSourceAddedSynced,
          ),
        ),
      );
      if (context.canPop()) {
        context.pop(); // cas: ouvert depuis Settings (push)
      } else {
        ref.read(appLaunchOrchestratorProvider.notifier).reset();
        context.go(AppRouteNames.bootstrap); // pipeline strict de bootstrap
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(iptvConnectControllerProvider);

    return FocusRegionScope(
      regionId: AppFocusRegionId.settingsIptvConnectPrimary,
      binding: FocusRegionBinding(
        resolvePrimaryEntryNode: () => _serverFocusNode,
        resolveFallbackEntryNode: () => _backFocusNode,
      ),
      exitMap: FocusRegionExitMap({
        DirectionalEdge.left: AppFocusRegionId.shellSidebar,
      }),
      requestFocusOnMount: true,
      debugLabel: 'IptvConnectRegion',
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (_, event) => _handleRouteBackKey(event, context),
        child: Scaffold(
          body: SafeArea(
            child: SettingsContentWidth(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        MoviSubpageBackTitleHeader(
                          title: AppLocalizations.of(context)!.actionConnect,
                          focusNode: _backFocusNode,
                          onBack: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(AppRouteNames.home);
                            }
                          },
                        ),
                        WelcomeHeader(
                          title: AppLocalizations.of(context)!.welcomeTitle,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.welcomeSubtitle,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LabeledField(
                                label: AppLocalizations.of(
                                  context,
                                )!.iptvServerUrlLabel,
                                child: TextFormField(
                                  controller: _serverCtrl,
                                  focusNode: _serverFocusNode,
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(
                                      context,
                                    )!.iptvServerUrlHint,
                                    border: OutlineInputBorder(),
                                  ),
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) =>
                                      _userFocusNode.requestFocus(),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return AppLocalizations.of(
                                        context,
                                      )!.validationRequired;
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.url,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              LabeledField(
                                label: AppLocalizations.of(
                                  context,
                                )!.labelUsername,
                                child: TextFormField(
                                  controller: _userCtrl,
                                  focusNode: _userFocusNode,
                                  decoration: const InputDecoration(
                                    hintText: 'Nom d’utilisateur Xtream',
                                    border: OutlineInputBorder(),
                                  ),
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) =>
                                      _passFocusNode.requestFocus(),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? AppLocalizations.of(
                                          context,
                                        )!.validationRequired
                                      : null,
                                  autofillHints: const [AutofillHints.username],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              LabeledField(
                                label: AppLocalizations.of(
                                  context,
                                )!.iptvPasswordLabel,
                                child: TextFormField(
                                  controller: _passCtrl,
                                  focusNode: _passFocusNode,
                                  decoration: InputDecoration(
                                    hintText: AppLocalizations.of(
                                      context,
                                    )!.iptvPasswordHint,
                                    border: OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                    ),
                                  ),
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) =>
                                      _submitFocusNode.requestFocus(),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? AppLocalizations.of(
                                          context,
                                        )!.validationRequired
                                      : null,
                                  obscureText: _obscurePassword,
                                  autofillHints: const [AutofillHints.password],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: MoviPrimaryButton(
                                    label: AppLocalizations.of(
                                      context,
                                    )!.actionConnect,
                                    focusNode: _submitFocusNode,
                                    onPressed: state.isLoading ? null : _submit,
                                    loading: state.isLoading,
                                  ),
                                ),
                              ),
                              if (state.error != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  state.error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
