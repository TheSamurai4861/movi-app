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
import 'package:movi/src/core/profile/presentation/controllers/profiles_controller.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';

class WelcomeUserPage extends ConsumerStatefulWidget {
  const WelcomeUserPage({super.key});

  @override
  ConsumerState<WelcomeUserPage> createState() => _WelcomeUserPageState();
}

class _WelcomeUserPageState extends ConsumerState<WelcomeUserPage> {
  final _nameCtrl = TextEditingController();
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
    _authStatusSub = ref.listenManual(
      supabaseAuthStatusProvider,
      (previous, next) {
        if (previous == next || !mounted) return;

        if (next == SupabaseAuthStatus.authenticated) {
          if (!_hasInvalidatedOnAuth) {
            _hasInvalidatedOnAuth = true;
            ref.invalidate(profilesControllerProvider);
          }
        }
      },
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _authStatusSub?.close();
    _nameCtrl.dispose();
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
    final authStatus = ref.watch(supabaseAuthStatusProvider);
    final profilesAsync = ref.watch(profilesControllerProvider);
    final selectedProfileId = ref.watch(selectedProfileControllerProvider);

    // Si l'auth n'est pas encore initialisée, afficher un loader
    if (authStatus == SupabaseAuthStatus.uninitialized) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  WelcomeHeader(
                    title: l10n.welcomeTitle,
                    subtitle: l10n.welcomeSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Si l'auth est unauthenticated, laisser le guard rediriger
    if (authStatus == SupabaseAuthStatus.unauthenticated) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: const CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

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
                  // Si l'auth n'est pas encore authentifiée, afficher un loader
                  // au lieu d'essayer de charger les profils (qui échouerait)
                  authStatus != SupabaseAuthStatus.authenticated
                      ? const Padding(
                          padding: EdgeInsets.only(top: AppSpacing.lg),
                          child: CircularProgressIndicator(),
                        )
                      : profilesAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.only(top: AppSpacing.lg),
                            child: CircularProgressIndicator(),
                          ),
                          error: (err, stackTrace) {
                            // Vérifier le type d'exception ET le message pour être sûr de capturer tous les cas
                            final errString = err.toString();
                            final isNotAuthenticated =
                                err is ProfilesNotAuthenticatedException ||
                                errString.contains(
                                  'ProfilesNotAuthenticatedException',
                                ) ||
                                errString.contains('user not logged in');
                            final isNotInitialized =
                                err is ProfilesNotInitializedException ||
                                errString.contains(
                                  'ProfilesNotInitializedException',
                                ) ||
                                errString.contains('not ready');

                            // Debug: afficher le type d'exception en mode debug
                            if (kDebugMode) {
                              debugPrint('[WelcomeUserPage] Error: $errString');
                              debugPrint(
                                '[WelcomeUserPage] Error type: ${err.runtimeType}, isNotAuthenticated: $isNotAuthenticated, isNotInitialized: $isNotInitialized, authStatus: $authStatus',
                              );
                            }

                            // Si c'est une exception d'auth (pas authentifié ou pas initialisé),
                            // toujours afficher un loader et ne jamais afficher l'erreur
                            // Ces exceptions indiquent un problème de timing, pas une vraie erreur
                            if (isNotAuthenticated || isNotInitialized) {
                              // Invalider le provider pour réessayer, mais de manière contrôlée
                              if (!_hasInvalidatedOnAuth && mounted) {
                                _hasInvalidatedOnAuth = true;
                                // Utiliser addPostFrameCallback pour éviter les invalidations pendant le build
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted) {
                                    // Vérifier à nouveau l'état d'auth avant d'invalider
                                    final currentAuthStatus = ref.read(
                                      supabaseAuthStatusProvider,
                                    );
                                    if (currentAuthStatus ==
                                        SupabaseAuthStatus.authenticated) {
                                      // L'auth est prête, invalider pour recharger
                                      ref.invalidate(
                                        profilesControllerProvider,
                                      );
                                    } else {
                                      // L'auth n'est pas encore prête, attendre un peu puis réessayer
                                      Future.delayed(
                                        const Duration(milliseconds: 500),
                                        () {
                                          if (mounted) {
                                            final newAuthStatus = ref.read(
                                              supabaseAuthStatusProvider,
                                            );
                                            if (newAuthStatus ==
                                                SupabaseAuthStatus
                                                    .authenticated) {
                                              ref.invalidate(
                                                profilesControllerProvider,
                                              );
                                            } else {
                                              // Réinitialiser le flag pour permettre un nouveau retry
                                              _hasInvalidatedOnAuth = false;
                                            }
                                          }
                                        },
                                      );
                                    }
                                  }
                                });
                              }

                              // Toujours afficher un loader pour les exceptions d'auth
                              return const Padding(
                                padding: EdgeInsets.only(top: AppSpacing.lg),
                                child: CircularProgressIndicator(),
                              );
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
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error
                                            .withValues(alpha: 0.7),
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
                                              color: Theme.of(context).colorScheme.primary,
                                              label: p.name,
                                              size: 72,
                                              selected:
                                                  p.id == selectedProfileId,
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
                                                  profilesControllerProvider
                                                      .notifier,
                                                )
                                                .selectProfile(
                                                  profiles.first.id,
                                                );
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
                                        loading: state.isSaving,
                                        onPressed: state.isSaving
                                            ? null
                                            : () async {
                                                final router = GoRouter.of(
                                                  context,
                                                );
                                                final messenger =
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    );

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
                                                    LanguageCode.tryParse(
                                                      'en',
                                                    )!;

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
                                                        (accentColor
                                                            .toARGB32() |
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
                                                  router.go(
                                                    AppRouteNames.bootstrap,
                                                  );
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
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
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
