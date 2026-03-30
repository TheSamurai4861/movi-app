import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/router/app_route_names.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/core/profile/presentation/ui/widgets/profile_avatar_chip.dart';
import 'package:movi/src/features/settings/domain/entities/user_settings.dart';
import 'package:movi/src/features/settings/domain/value_objects/first_name.dart';
import 'package:movi/src/features/settings/domain/value_objects/language_code.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/features/welcome/presentation/widgets/labeled_field.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_header.dart';
import 'package:movi/src/core/profile/presentation/providers/profiles_providers.dart';
import 'package:movi/src/core/profile/presentation/providers/selected_profile_providers.dart';
import 'package:movi/src/core/profile/presentation/providers/profile_auth_providers.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';

class WelcomeUserPage extends ConsumerStatefulWidget {
  const WelcomeUserPage({super.key});

  @override
  ConsumerState<WelcomeUserPage> createState() => _WelcomeUserPageState();
}

class _WelcomeUserPageState extends ConsumerState<WelcomeUserPage> {
  final _nameCtrl = TextEditingController();
  final _nameFocusNode = FocusNode(debugLabel: 'WelcomeUserName');
  final _submitFocusNode = FocusNode(debugLabel: 'WelcomeUserSubmit');
  bool _hasInvalidatedOnAuth = false;
  ProviderSubscription<SupabaseAuthStatus>? _authStatusSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(userSettingsControllerProvider.notifier).load());
    });

    // Utiliser listenManual au lieu de listen car on est dans initState
    _authStatusSub = ref.listenManual(supabaseAuthStatusProvider, (
      previous,
      next,
    ) {
      if (previous == next || !mounted) return;

      if (next == SupabaseAuthStatus.authenticated) {
        if (!_hasInvalidatedOnAuth) {
          _hasInvalidatedOnAuth = true;
          ref.invalidate(profilesControllerProvider);
        }
      }
    }, fireImmediately: false);
  }

  @override
  void dispose() {
    _authStatusSub?.close();
    _nameCtrl.dispose();
    _nameFocusNode.dispose();
    _submitFocusNode.dispose();
    super.dispose();
  }

  Future<void> _createFirstProfile({
    required String profileName,
    required int profileColor,
  }) async {
    final created = await ref
        .read(profilesControllerProvider.notifier)
        .createProfile(name: profileName, color: profileColor);
    if (created == null) {
      debugPrint('[WelcomeUserPage] createProfile failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userSettingsControllerProvider);
    final accentColor = ref.watch(asp.currentAccentColorProvider);
    final l10n = AppLocalizations.of(context)!;
    final profilesAsync = ref.watch(profilesControllerProvider);
    final selectedProfileId = ref.watch(selectedProfileControllerProvider);

    final errorText = switch (state.errorKey) {
      UserSettingsError.loadFailed ||
      UserSettingsError.saveFailed => l10n.errorUnknown,
      null => null,
    };

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
                    title: l10n.welcomeTitle,
                    subtitle: l10n.welcomeSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  profilesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.lg),
                      child: CircularProgressIndicator(),
                    ),
                    error: (err, stackTrace) {
                      final errString = err.toString();
                      if (kDebugMode) {
                        debugPrint('[WelcomeUserPage] Error: $errString');
                      }

                      // Pour les autres erreurs, afficher un message localisé
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.errorUnknown,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (kDebugMode) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                err.toString(),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.error.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    data: (profiles) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Si des profils existent, on affiche un picker (pas de champ texte).
                          if (profiles.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: Wrap(
                                spacing: AppSpacing.lg,
                                runSpacing: AppSpacing.lg,
                                alignment: WrapAlignment.center,
                                children: [
                                  for (final p in profiles)
                                    GestureDetector(
                                      onTap: () async {
                                        await ref
                                            .read(
                                              profilesControllerProvider
                                                  .notifier,
                                            )
                                            .selectProfile(p.id);
                                      },
                                      child: ProfileAvatarChip(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        label: p.name,
                                        size: 72,
                                        selected: p.id == selectedProfileId,
                                      ),
                                    ),
                                ],
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
                                  label: l10n.actionContinue,
                                  onPressed: () async {
                                    if (profiles.isNotEmpty &&
                                        selectedProfileId == null) {
                                      await ref
                                          .read(
                                            profilesControllerProvider.notifier,
                                          )
                                          .selectProfile(profiles.first.id);
                                    }
                                    if (!context.mounted) return;
                                    // Reset orchestrator pour relancer le bootstrap.
                                    ref
                                        .read(
                                          appLaunchOrchestratorProvider
                                              .notifier,
                                        )
                                        .reset();
                                    context.go(AppRouteNames.bootstrap);
                                  },
                                ),
                              ),
                            ),
                          ] else ...[
                            // Aucun profil: on affiche l'input (création du premier profil)
                            LabeledField(
                              label: l10n.labelUsername,
                              child: TextFormField(
                                controller: _nameCtrl,
                                focusNode: _nameFocusNode,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) =>
                                    _submitFocusNode.requestFocus(),
                                decoration: InputDecoration(
                                  hintText: l10n.hintUsername,
                                  border: const OutlineInputBorder(),
                                ),
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
                                  label: l10n.actionContinue,
                                  focusNode: _submitFocusNode,
                                  loading: state.isSaving,
                                  onPressed: state.isSaving
                                      ? null
                                      : () async {
                                          final router = GoRouter.of(context);
                                          final messenger =
                                              ScaffoldMessenger.of(context);

                                          final fn = FirstName.tryParse(
                                            _nameCtrl.text,
                                          );

                                          if (fn == null) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  l10n.errorFillFields,
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          // La langue est déjà définie par l'appareil, pas besoin de la sauvegarder ici
                                          final currentLangCode = ref.read(
                                            asp.currentLanguageCodeProvider,
                                          );
                                          final lc =
                                              LanguageCode.tryParse(
                                                currentLangCode,
                                              ) ??
                                              LanguageCode.tryParse('en')!;

                                          final ok = await ref
                                              .read(
                                                userSettingsControllerProvider
                                                    .notifier,
                                              )
                                              .save(
                                                UserSettings(
                                                  firstName: fn,
                                                  languageCode: lc,
                                                ),
                                              );

                                          if (!mounted) return;

                                          if (ok) {
                                            await _createFirstProfile(
                                              profileName: fn.value,
                                              profileColor:
                                                  (accentColor.toARGB32() |
                                                  0xFF000000),
                                            );
                                            ref.invalidate(
                                              profilesControllerProvider,
                                            );
                                            // Reset orchestrator pour relancer le bootstrap.
                                            ref
                                                .read(
                                                  appLaunchOrchestratorProvider
                                                      .notifier,
                                                )
                                                .reset();
                                            router.go(AppRouteNames.bootstrap);
                                          }
                                        },
                                ),
                              ),
                            ),
                            if (errorText != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                                child: Text(
                                  errorText,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ],
                        ],
                      );
                    },
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
