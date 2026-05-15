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
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/startup/presentation/boot_action_executor.dart';
import 'package:movi/src/core/startup/presentation/boot_action_handler.dart';
import 'package:movi/src/core/startup/presentation/widgets/boot_form_tokens.dart';
import 'package:movi/src/core/startup/presentation/widgets/launch_recovery_banner.dart';
import 'package:movi/src/core/startup/entry_boot_state_repository.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/responsive/presentation/extensions/tv_ui_scale_context.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/core/widgets/overlay_splash.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/parental/presentation/widgets/restricted_content_sheet.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
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

class _WelcomeProfilePickerLayout {
  const _WelcomeProfilePickerLayout({
    required this.crossAxisCount,
    required this.pickerMaxWidth,
    required this.chipWidth,
    required this.avatarSize,
    required this.gridSpacing,
    required this.nameGap,
    required this.nameFontSize,
    required this.chipVerticalPadding,
    required this.mainAxisExtent,
  });

  final int crossAxisCount;
  final double pickerMaxWidth;
  final double chipWidth;
  final double avatarSize;
  final double gridSpacing;
  final double nameGap;
  final double nameFontSize;
  final double chipVerticalPadding;
  final double mainAxisExtent;
}

class _WelcomeUserPageState extends ConsumerState<WelcomeUserPage> {
  static const int _profileGridColumnCount = 3;
  static const double _profilePickerMaxWidthBase = 480;
  static const double _profileChipWidthBase = 112;
  static const double _profileAvatarSizeBase = 75;

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
        event.logicalKey == LogicalKeyboardKey.escape) {
      return _handleBack(context)
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  _WelcomeProfilePickerLayout _profilePickerLayout(BuildContext context) {
    final uiScale = context.tvUiScale;
    final screenWidth = MediaQuery.sizeOf(context).width;
    const crossAxisCount = _profileGridColumnCount;
    final gridSpacing = AppSpacing.lg * uiScale;
    final minPickerWidth =
        _profileChipWidthBase * crossAxisCount +
        gridSpacing * (crossAxisCount - 1);
    final horizontalInsets = AppSpacing.lg * 2;
    final availableWidth = screenWidth - horizontalInsets;
    final pickerMaxWidth =
        (_profilePickerMaxWidthBase * uiScale).clamp(
          minPickerWidth,
          availableWidth > 0 ? availableWidth : _profilePickerMaxWidthBase * uiScale,
        );
    final chipWidth =
        (pickerMaxWidth - gridSpacing * (crossAxisCount - 1)) / crossAxisCount;
    final avatarSize = _profileAvatarSizeBase * uiScale;
    final nameGap = 12 * uiScale;
    final nameFontSize = 16 * uiScale;
    final chipVerticalPadding = 6 * uiScale;
    final estimatedChipHeight =
        chipVerticalPadding * 2 + avatarSize + nameGap + nameFontSize * 2.5 + 8;

    return _WelcomeProfilePickerLayout(
      crossAxisCount: crossAxisCount,
      pickerMaxWidth: pickerMaxWidth,
      chipWidth: chipWidth,
      avatarSize: avatarSize,
      gridSpacing: gridSpacing,
      nameGap: nameGap,
      nameFontSize: nameFontSize,
      chipVerticalPadding: chipVerticalPadding,
      mainAxisExtent: estimatedChipHeight,
    );
  }

  Widget _buildWelcomeProfileChip({
    required Profile profile,
    required bool isSelected,
    required FocusNode focusNode,
    required VoidCallback onTap,
    required _WelcomeProfilePickerLayout layout,
  }) {
    final trimmed = profile.name.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : trimmed.substring(0, 1).toUpperCase();
    return MoviEnsureVisibleOnFocus(
      verticalAlignment: 0.22,
      child: MoviFocusableAction(
        focusNode: focusNode,
        onPressed: onTap,
        semanticLabel: profile.name,
        builder: (context, state) {
          final theme = Theme.of(context);
          final isActive = isSelected || state.focused;
          return MoviFocusFrame(
            scale: state.focused ? 1.04 : 1,
            child: SizedBox(
              width: layout.chipWidth,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: layout.chipVerticalPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: layout.avatarSize,
                      height: layout.avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(profile.color),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: layout.avatarSize * 0.42,
                        ),
                      ),
                    ),
                    SizedBox(height: layout.nameGap),
                    Text(
                      profile.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isActive ? theme.colorScheme.primary : null,
                        fontSize: layout.nameFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
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
    final locator = ref.read(slProvider);
    if (locator.isRegistered<EntryBootStateRepository>()) {
      await locator<EntryBootStateRepository>().confirmProfileSelected(
        profileId: created.id,
      );
    }
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
    final l10n = AppLocalizations.of(context)!;
    return RestrictedContentSheet.show(
      context,
      ref,
      profile: profile,
      title: l10n.welcomeUserProfileLockedTitle,
      reason: l10n.welcomeUserProfileLockedReason,
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

  Future<void> _runBootAction(
    BuildContext context,
    BootActionIntent intent,
    String reasonCode,
  ) {
    return executeBootAction(
      context,
      ref,
      BootActionRequest(intent: intent, reasonCode: reasonCode),
    );
  }

  Future<void> _onProfileSelected(
    BuildContext context,
    List<Profile> profiles,
    String? selectedProfileId,
    Profile profile,
  ) async {
    final selected = await _selectProfileWithGuard(
      profiles,
      selectedProfileId,
      profile,
    );
    if (!selected || !context.mounted) {
      return;
    }
    final locator = ref.read(slProvider);
    if (locator.isRegistered<EntryBootStateRepository>()) {
      await locator<EntryBootStateRepository>().confirmProfileSelected(
        profileId: profile.id,
      );
    }
    if (!context.mounted) {
      return;
    }
    await _runBootAction(context, BootActionIntent.retry, 'profile_selected');
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
    final hasProfiles = profilesAsync.maybeWhen(
      data: (profiles) => profiles.isNotEmpty,
      orElse: () => false,
    );
    final profilePickerLayout = hasProfiles ? _profilePickerLayout(context) : null;
    if (profilesAsync.isLoading) {
      return Scaffold(
        body: OverlaySplash(message: l10n.bootLoadingProfile),
      );
    }
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
      UserSettingsError.saveFailed => l10n.welcomeUserProfilesLoadFailed,
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
          resolveFallbackEntryNode: () => initialFocusNode,
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
                  constraints: BoxConstraints(
                    maxWidth: hasProfiles
                        ? profilePickerLayout!.pickerMaxWidth
                        : BootFormTokens.textFieldMaxWidth,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        WelcomeHeader(
                          title: profilesAsync.maybeWhen(
                            data: (profiles) => profiles.isEmpty
                                ? l10n.welcomeUserCreateTitle
                                : l10n.welcomeUserChooseTitle,
                            orElse: () => l10n.welcomeTitle,
                          ),
                          subtitle: profilesAsync.maybeWhen(
                            data: (profiles) => profiles.isEmpty
                                ? l10n.welcomeUserCreateSubtitle
                                : l10n.welcomeUserChooseSubtitle,
                            orElse: () => l10n.welcomeSubtitle,
                          ),
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
                            loading: () => const SizedBox.shrink(),
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
                                      l10n.welcomeUserProfilesLoadFailed,
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
                              final layout = profiles.isNotEmpty
                                  ? _profilePickerLayout(context)
                                  : null;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Si des profils existent, on affiche un picker (pas de champ texte).
                                  if (profiles.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg,
                                      ),
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: profiles.length,
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: layout!.crossAxisCount,
                                              crossAxisSpacing: layout.gridSpacing,
                                              mainAxisSpacing: layout.gridSpacing,
                                              mainAxisExtent: layout.mainAxisExtent,
                                            ),
                                        itemBuilder: (context, index) {
                                          final leftIndex = index - 1;
                                          final rightIndex = index + 1;
                                          final upIndex =
                                              index - _profileGridColumnCount;
                                          final downIndex =
                                              index + _profileGridColumnCount;
                                          final isFirstColumn =
                                              index % _profileGridColumnCount ==
                                              0;
                                          final isLastColumn =
                                              index % _profileGridColumnCount ==
                                              _profileGridColumnCount - 1;

                                          return Focus(
                                            canRequestFocus: false,
                                            onKeyEvent: (_, event) =>
                                                FocusDirectionalNavigation.handleDirectionalKey(
                                                  event,
                                                  left:
                                                      !isFirstColumn &&
                                                          leftIndex >= 0
                                                      ? _profileFocusNodes[leftIndex]
                                                      : null,
                                                  right:
                                                      !isLastColumn &&
                                                          rightIndex <
                                                              profiles.length
                                                      ? _profileFocusNodes[rightIndex]
                                                      : null,
                                                  down:
                                                      downIndex <
                                                          profiles.length
                                                      ? _profileFocusNodes[downIndex]
                                                      : null,
                                                  up: upIndex >= 0
                                                      ? _profileFocusNodes[upIndex]
                                                      : (launchRecovery
                                                                ?.isRetryable ??
                                                            false)
                                                      ? _retryFocusNode
                                                      : null,
                                                  blockLeft: isFirstColumn,
                                                  blockRight:
                                                      isLastColumn ||
                                                      rightIndex >=
                                                          profiles.length,
                                                ),
                                            child: Center(
                                              child: _buildWelcomeProfileChip(
                                                profile: profiles[index],
                                                isSelected:
                                                    profiles[index].id ==
                                                    selectedProfileId,
                                                layout: layout,
                                                focusNode:
                                                    _profileFocusNodes[index],
                                                onTap: () {
                                                  unawaited(
                                                    _onProfileSelected(
                                                      context,
                                                      profiles,
                                                      selectedProfileId,
                                                      profiles[index],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ] else ...[
                                    // Aucun profil: on affiche l'input (création du premier profil)
                                    LabeledField(
                                      label: l10n.welcomeUserProfileNameLabel,
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
                                            child: BootFormTokens.constrainTextField(
                                              TextFormField(
                                                controller: _nameCtrl,
                                                focusNode: _nameFocusNode,
                                                textInputAction:
                                                    TextInputAction.done,
                                                onFieldSubmitted: (_) =>
                                                    _submitFocusNode
                                                        .requestFocus(),
                                                decoration:
                                                    BootFormTokens.bootTextFieldDecoration(
                                                      Theme.of(context),
                                                    ).copyWith(
                                                      hintText: l10n
                                                          .welcomeUserProfileNameHint,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: BootFormTokens.formElementGap,
                                    ),
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
                                          child: BootFormTokens.constrainPrimaryAction(
                                            MoviPrimaryButton(
                                              label: l10n
                                                  .welcomeUserCreateProfileAction,
                                              focusNode: _submitFocusNode,
                                              loading: state.isSaving,
                                              buttonStyle:
                                                  BootFormTokens.bootPrimaryButtonStyle(
                                                    Theme.of(context),
                                                  ),
                                              onPressed: state.isSaving
                                                  ? null
                                                  : () async {
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
                                                        if (!context.mounted) {
                                                          return;
                                                        }
                                                        ref.invalidate(
                                                          profilesControllerProvider,
                                                        );
                                                        await _runBootAction(
                                                          context,
                                                          BootActionIntent
                                                              .retry,
                                                          'profile_created',
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
