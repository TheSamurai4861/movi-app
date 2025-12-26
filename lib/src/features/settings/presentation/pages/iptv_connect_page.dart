import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_connect_providers.dart';
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

  @override
  void dispose() {
    _serverCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _aliasCtrl.dispose();
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
        context.go(AppRouteNames.home); // cas: arrivé depuis LaunchGate (go)
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(iptvConnectControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  WelcomeHeader(
                    title: AppLocalizations.of(context)!.welcomeTitle,
                    subtitle: AppLocalizations.of(context)!.welcomeSubtitle,
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
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(
                                context,
                              )!.iptvServerUrlHint,
                              border: OutlineInputBorder(),
                            ),
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
                          label: AppLocalizations.of(context)!.labelUsername,
                          child: TextFormField(
                            controller: _userCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Nom d’utilisateur Xtream',
                              border: OutlineInputBorder(),
                            ),
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
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(
                                context,
                              )!.iptvPasswordHint,
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? AppLocalizations.of(
                                    context,
                                  )!.validationRequired
                                : null,
                            obscureText: true,
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
    );
  }
}
