import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: unnecessary_import
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/presentation/focus_directional_navigation.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';
import 'package:movi/src/core/router/app_route_names.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/startup/presentation/widgets/launch_recovery_banner.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/core/widgets/overlay_splash.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/parental/presentation/widgets/restricted_content_sheet.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
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
import 'package:movi/src/core/supabase/supabase_providers.dart';

class WelcomeUserPage extends ConsumerStatefulWidget {
  const WelcomeUserPage({super.key});

  @override
  ConsumerState<WelcomeUserPage> createState() => _WelcomeUserPageState();
}

class _WelcomeUserPageState extends ConsumerState<WelcomeUserPage> {
  final _nameCtrl = TextEditingController();
  final _retryFocusNode = FocusNode(debugLabel: 'WelcomeUserRetry');
  final _nameFocusNode = FocusNode(debugLabel: 'WelcomeUserName');
  final _submitFocusNode = FocusNode(debugLabel: 'WelcomeUserSubmit');
  final List<FocusNode> _profileFocusNodes = <FocusNode>[];
  bool _hasInvalidatedOnAuth = false;
  bool _autoOpenedOtp = false;
  ProviderSubscription<SupabaseAuthStatus>? _authStatusSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Robustesse: si Supabase est dispo mais l'utilisateur n'est pas encore
      // authentifié, on priorise l'écran email/OTP et on évite de toucher aux
      // providers "local mode" (DI) tant que l'auth n'est pas faite.
      final client = ref.read(supabaseClientProvider);
      final authStatus = ref.read(supabaseAuthStatusProvider);
      final launchRecovery = ref.read(appLaunchStateProvider).recovery;
      final shouldSuppressEmailAuth = launchRecovery?.isRetryable ?? false;
      final shouldPrioritizeEmailAuth =
          client != null &&
          authStatus == SupabaseAuthStatus.unauthenticated &&
          !shouldSuppressEmailAuth;
      if (shouldPrioritizeEmailAuth) return;

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
    _retryFocusNode.dispose();
    _nameFocusNode.dispose();
    _submitFocusNode.dispose();
    for (final node in _profileFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncProfileFocusNodes(int count) {
    while (_profileFocusNodes.length < count) {
      _profileFocusNodes.add(
        FocusNode(debugLabel: 'WelcomeUserProfile${_profileFocusNodes.length}'),
      );
    }
    while (_profileFocusNodes.length > count) {
      _profileFocusNodes.removeLast().dispose();
    }
  }

  FocusNode _continueUpFocusNode(List<Profile> profiles, String? selectedId) {
    final selectedIndex = profiles.indexWhere(
      (profile) => profile.id == selectedId,
    );
    if (selectedIndex >= 0 && selectedIndex < _profileFocusNodes.length) {
      return _profileFocusNodes[selectedIndex];
    }
    return _profileFocusNodes.first;
  }

  bool _handleBack(BuildContext context) {
    if (!context.canPop()) {
      return false;
    }
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

  Widget _buildWelcomeProfileChip({
    required Profile profile,
    required bool isSelected,
    required FocusNode focusNode,
    required VoidCallback onTap,
  }) {
    return MoviEnsureVisibleOnFocus(
      verticalAlignment: 0.22,
      child: MoviFocusableAction(
        focusNode: focusNode,
        onPressed: onTap,
        semanticLabel: profile.name,
        builder: (context, state) {
          return MoviFocusFrame(
            scale: state.focused ? 1.04 : 1,
            borderRadius: BorderRadius.circular(999),
            child: ProfileAvatarChip(
              color: Theme.of(context).colorScheme.primary,
              label: profile.name,
              size: 72,
              selected: isSelected || state.focused,
            ),
          );
        },
      ),
    );
  }

  Future<void> _createFirstProfile({
    required String profileName,
    required int profileColor,
  }) async {
    final created = await ref
        .read(profilesControllerProvider.notifier)
        .createProfile(name: profileName, color: profileColor);
    if (created == null) return;
  }

  bool _isRestrictedProfile(Profile profile) {
    return profile.isKid || profile.pegiLimit != null;
  }

  Future<bool> _ensureProfileUnlocked(Profile profile) async {
    final sessionSvc = ref.read(parental.parentalSessionServiceProvider);
    if (await sessionSvc.isUnlocked(profile.id)) {
      return true;
    }

    if (!mounted) return false;
    return RestrictedContentSheet.show(
      context,
      ref,
      profile: profile,
      title: 'Profil verrouillé',
      reason: 'Saisis le PIN pour changer de profil.',
      originRegionId: AppFocusRegionId.welcomeUserForm,
      fallbackRegionId: AppFocusRegionId.welcomeUserForm,
    );
  }

  Profile? _findProfileById(List<Profile> profiles, String? profileId) {
    if (profileId == null || profileId.trim().isEmpty) return null;
    for (final profile in profiles) {
      if (profile.id == profileId) return profile;
    }
    return null;
  }

  Future<bool> _selectProfileWithGuard(
    List<Profile> profiles,
    String? selectedProfileId,
    Profile targetProfile,
  ) async {
    final currentProfile = _findProfileById(profiles, selectedProfileId);
    if (currentProfile?.id == targetProfile.id) {
      return true;
    }

    if (_isRestrictedProfile(targetProfile)) {
      final unlocked = await _ensureProfileUnlocked(targetProfile);
      if (!unlocked) return false;
    } else if (currentProfile != null && _isRestrictedProfile(currentProfile)) {
      final unlocked = await _ensureProfileUnlocked(currentProfile);
      if (!unlocked) return false;
    }

    await ref
        .read(profilesControllerProvider.notifier)
        .selectProfile(targetProfile.id);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = ref.watch(asp.currentAccentColorProvider);
    final l10n = AppLocalizations.of(context)!;
    final supabaseClient = ref.watch(supabaseClientProvider);
    final supabaseAuthStatus = ref.watch(supabaseAuthStatusProvider);
    final launchRecovery = ref.watch(appLaunchStateProvider).recovery;
    final shouldSuppressEmailAuth = launchRecovery?.isRetryable ?? false;
    final shouldPrioritizeEmailAuth =
        supabaseClient != null &&
        supabaseAuthStatus == SupabaseAuthStatus.unauthenticated &&
        !shouldSuppressEmailAuth;

    // Robustesse: si on priorise l'auth, ne pas "watch" les providers de profil/settings
    // pour éviter de dépendre d'une DI complète avant la connexion.
    if (shouldPrioritizeEmailAuth) {
      if (!_autoOpenedOtp) {
        _autoOpenedOtp = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaited(
            context.push<bool>('${AppRoutePaths.authOtp}?return_to=previous'),
          );
        });
      }
      return Scaffold(body: OverlaySplash(message: l10n.authPasswordTitle));
    }

    final state = ref.watch(userSettingsControllerProvider);
    final profilesAsync = ref.watch(profilesControllerProvider);
    final selectedProfileId = ref.watch(selectedProfileControllerProvider);
    final initialFocusNode = profilesAsync.maybeWhen(
      data: (profiles) {
        if (profiles.isEmpty) {
          return _nameFocusNode;
        }
        _syncProfileFocusNodes(profiles.length);
        final selectedIndex = profiles.indexWhere(
          (profile) => profile.id == selectedProfileId,
        );
        if (selectedIndex >= 0 && selectedIndex < _profileFocusNodes.length) {
          return _profileFocusNodes[selectedIndex];
        }
        return _profileFocusNodes.first;
      },
      orElse: () => _nameFocusNode,
    );

    final errorText = switch (state.errorKey) {
      UserSettingsError.loadFailed ||
      UserSettingsError.saveFailed => l10n.errorUnknown,
      null => null,
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: FocusRegionScope(
        regionId: AppFocusRegionId.welcomePrimary,
        binding: FocusRegionBinding(
          resolvePrimaryEntryNode: () => initialFocusNode,
          resolveFallbackEntryNode: () => _submitFocusNode,
        ),
        requestFocusOnMount: true,
        handleDirectionalExits: false,
        debugLabel: 'WelcomeUserPrimaryRegion',
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: (_, event) => _handleRouteBackKey(event, context),
          child: Scaffold(
            body: SafeArea(
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
                        WelcomeHeader(
                          title: l10n.welcomeTitle,
                          subtitle: l10n.welcomeSubtitle,
                        ),
                        if (launchRecovery?.isRetryable ?? false) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child: MoviEnsureVisibleOnFocus(
                              verticalAlignment: 0.18,
                              child: Focus(
                                canRequestFocus: false,
                                onKeyEvent: (_, event) =>
                                    FocusDirectionalNavigation.handleDirectionalKey(
                                      event,
                                      down: profilesAsync.maybeWhen(
                                        data: (profiles) {
                                          if (profiles.isEmpty) {
                                            return _nameFocusNode;
                                          }
                                          _syncProfileFocusNodes(
                                            profiles.length,
                                          );
                                          return _profileFocusNodes.first;
                                        },
                                        orElse: () => null,
                                      ),
                                      blockLeft: true,
                                      blockRight: true,
                                      blockUp: true,
                                    ),
                                child: LaunchRecoveryBanner(
                                  message: launchRecovery!.message,
                                  retryFocusNode: _retryFocusNode,
                                  onRetry: () {
                                    ref
                                        .read(
                                          appLaunchOrchestratorProvider
                                              .notifier,
                                        )
                                        .reset();
                                    context.go(AppRouteNames.launch);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        FocusRegionScope(
                          regionId: AppFocusRegionId.welcomeUserForm,
                          binding: FocusRegionBinding(
                            resolvePrimaryEntryNode: () => initialFocusNode,
                            resolveFallbackEntryNode: () => _submitFocusNode,
                          ),
                          handleDirectionalExits: false,
                          debugLabel: 'WelcomeUserFormRegion',
                          child: profilesAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.only(top: AppSpacing.lg),
                              child: CircularProgressIndicator(),
                            ),
                            error: (err, stackTrace) {
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
                              _syncProfileFocusNodes(profiles.length);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Si des profils existent, on affiche un picker (pas de champ texte).
                                  if (profiles.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg,
                                      ),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            for (
                                              var index = 0;
                                              index < profiles.length;
                                              index++
                                            ) ...[
                                              Focus(
                                                canRequestFocus: false,
                                                onKeyEvent: (_, event) =>
                                                    FocusDirectionalNavigation.handleDirectionalKey(
                                                      event,
                                                      left: index > 0
                                                          ? _profileFocusNodes[index -
                                                                1]
                                                          : null,
                                                      right:
                                                          index + 1 <
                                                              profiles.length
                                                          ? _profileFocusNodes[index +
                                                                1]
                                                          : null,
                                                      up:
                                                          launchRecovery
                                                                  ?.isRetryable ??
                                                              false
                                                          ? _retryFocusNode
                                                          : null,
                                                      down: _submitFocusNode,
                                                      blockLeft: index == 0,
                                                      blockRight:
                                                          index ==
                                                          profiles.length - 1,
                                                    ),
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                    right:
                                                        index ==
                                                            profiles.length - 1
                                                        ? 0
                                                        : AppSpacing.lg,
                                                  ),
                                                  child: _buildWelcomeProfileChip(
                                                    profile: profiles[index],
                                                    isSelected:
                                                        profiles[index].id ==
                                                        selectedProfileId,
                                                    focusNode:
                                                        _profileFocusNodes[index],
                                                    onTap: () => unawaited(
                                                      _selectProfileWithGuard(
                                                        profiles,
                                                        selectedProfileId,
                                                        profiles[index],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg,
                                      ),
                                      child: MoviEnsureVisibleOnFocus(
                                        verticalAlignment: 0.22,
                                        child: Focus(
                                          canRequestFocus: false,
                                          onKeyEvent: (_, event) =>
                                              FocusDirectionalNavigation.handleDirectionalKey(
                                                event,
                                                up: _continueUpFocusNode(
                                                  profiles,
                                                  selectedProfileId,
                                                ),
                                                blockLeft: true,
                                                blockRight: true,
                                                blockDown: true,
                                              ),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: MoviPrimaryButton(
                                              label: l10n.actionContinue,
                                              focusNode: _submitFocusNode,
                                              onPressed: () async {
                                                if (profiles.isNotEmpty &&
                                                    selectedProfileId == null) {
                                                  final selected =
                                                      await _selectProfileWithGuard(
                                                        profiles,
                                                        selectedProfileId,
                                                        profiles.first,
                                                      );
                                                  if (!selected) {
                                                    return;
                                                  }
                                                }
                                                if (!context.mounted) return;
                                                ref
                                                    .read(
                                                      appLaunchOrchestratorProvider
                                                          .notifier,
                                                    )
                                                    .reset();
                                                context.go(
                                                  AppRouteNames.bootstrap,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    // Aucun profil: on affiche l'input (création du premier profil)
                                    LabeledField(
                                      label: l10n.labelUsername,
                                      child: MoviEnsureVisibleOnFocus(
                                        verticalAlignment: 0.22,
                                        child: Focus(
                                          canRequestFocus: false,
                                          onKeyEvent: (_, event) =>
                                              FocusDirectionalNavigation.handleDirectionalKey(
                                                event,
                                                up:
                                                    launchRecovery
                                                            ?.isRetryable ??
                                                        false
                                                    ? _retryFocusNode
                                                    : null,
                                                down: _submitFocusNode,
                                                blockLeft: true,
                                                blockRight: true,
                                              ),
                                          child: CallbackShortcuts(
                                            bindings: <ShortcutActivator, VoidCallback>{
                                              const SingleActivator(
                                                LogicalKeyboardKey.arrowDown,
                                              ): () =>
                                                  FocusDirectionalNavigation.requestFocus(
                                                    _submitFocusNode,
                                                  ),
                                              if (launchRecovery?.isRetryable ??
                                                  false)
                                                const SingleActivator(
                                                  LogicalKeyboardKey.arrowUp,
                                                ): () =>
                                                    FocusDirectionalNavigation.requestFocus(
                                                      _retryFocusNode,
                                                    ),
                                            },
                                            child: TextFormField(
                                              controller: _nameCtrl,
                                              focusNode: _nameFocusNode,
                                              textInputAction:
                                                  TextInputAction.done,
                                              onFieldSubmitted: (_) =>
                                                  _submitFocusNode
                                                      .requestFocus(),
                                              decoration: InputDecoration(
                                                hintText: l10n.hintUsername,
                                                border:
                                                    const OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg,
                                      ),
                                      child: MoviEnsureVisibleOnFocus(
                                        verticalAlignment: 0.22,
                                        child: Focus(
                                          canRequestFocus: false,
                                          onKeyEvent: (_, event) =>
                                              FocusDirectionalNavigation.handleDirectionalKey(
                                                event,
                                                up: _nameFocusNode,
                                                blockLeft: true,
                                                blockRight: true,
                                                blockDown: true,
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
                                                      final router =
                                                          GoRouter.of(context);
                                                      final messenger =
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          );

                                                      final fn =
                                                          FirstName.tryParse(
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
                                                      final currentLangCode =
                                                          ref.read(
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
                                                          AppRouteNames
                                                              .bootstrap,
                                                        );
                                                      }
                                                    },
                                            ),
                                          ),
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
