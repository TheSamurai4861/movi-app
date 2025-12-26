// lib/src/features/settings/presentation/pages/settings_page.dart
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/auth/application/services/local_data_cleanup_service.dart';
import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/parental/presentation/widgets/restricted_content_sheet.dart';
import 'package:movi/src/core/preferences/accent_color_preferences.dart';
import 'package:movi/src/core/preferences/iptv_sync_preferences.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/preferences/selected_profile_preferences.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/presentation/controllers/profiles_controller.dart';
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/core/profile/presentation/providers/profile_auth_providers.dart';
import 'package:movi/src/core/profile/presentation/providers/profiles_providers.dart';
import 'package:movi/src/core/profile/presentation/providers/selected_profile_providers.dart';
import 'package:movi/src/core/profile/presentation/ui/dialogs/create_profile_dialog.dart';
import 'package:movi/src/core/profile/presentation/ui/dialogs/manage_profile_dialog.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/iptv/application/services/xtream_sync_service.dart';
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_connect_providers.dart';

/// SettingsPage (content-only): pas de Scaffold ici.
/// Le Shell (Home layout) gère le Scaffold/SafeArea/Bottombar.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _refreshingIptv = false;
  bool _unlocking = false;
  bool _wasUnlockedForSettings = false;
  String? _unlockedProfileId;
  ProviderSubscription<SupabaseAuthStatus>? _authStatusSub;

  static const List<(String code, String label)> _availableLanguages = [
    ('en', 'English'),
    ('es', 'Español'),
    ('fr', 'Français'),
    ('fr-MM', 'Burgonde'),
    ('de', 'Deutsch'),
    ('it', 'Italiano'),
    ('nl', 'Nederlands'),
    ('pl', 'Polski'),
    ('pt', 'Português'),
  ];

  static const List<(Duration? interval, String label)> _syncIntervalOptions = [
    (null, 'Désactivé'),
    (Duration(minutes: 60), 'Toutes les heures'),
    (Duration(minutes: 120), 'Toutes les 2 heures'),
    (Duration(minutes: 240), 'Toutes les 4 heures'),
    (Duration(minutes: 360), 'Toutes les 6 heures'),
    (Duration(minutes: 1440), 'Tous les jours'),
    (Duration(minutes: 2880), 'Tous les 2 jours'),
  ];

  static const List<(Color color, String name)> _accentColorOptions = [
    (Color(0xFF2160AB), 'Bleu'),
    (Color(0xFFF48FB1), 'Rose'),
    (Color(0xFF81C784), 'Vert'),
    (Color(0xFFBA68C8), 'Violet'),
    (Color(0xFFFFB74D), 'Orange'),
    (Color(0xFF4DB6AC), 'Turquoise'),
    (Color(0xFFFFE082), 'Jaune'),
    (Color(0xFF7986CB), 'Indigo'),
  ];

  @override
  void initState() {
    super.initState();

    // Utiliser listenManual dans initState (ref.listen ne peut être utilisé que dans build)
    _authStatusSub = ref.listenManual<SupabaseAuthStatus>(
      supabaseAuthStatusProvider,
      (prev, next) {
        if (prev != next &&
            next == SupabaseAuthStatus.authenticated &&
            mounted) {
          ref.invalidate(profilesControllerProvider);
        }
      },
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _authStatusSub?.close();
    _lockSessionIfUnlocked();
    super.dispose();
  }

  // -------------------- Parental guard --------------------

  Future<bool> _ensureSettingsUnlocked() async {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return true;
    if (!profile.isKid) return true;

    if (_unlocking) return false;
    _unlocking = true;
    try {
      final sessionSvc = ref.read(parental.parentalSessionServiceProvider);

      if (await sessionSvc.isUnlocked(profile.id)) {
        _wasUnlockedForSettings = true;
        _unlockedProfileId = profile.id;
        return true;
      }

      if (!mounted) return false;
      final unlocked = await RestrictedContentSheet.show(
        context,
        ref,
        profile: profile,
        title: 'Paramètres verrouillés',
        reason: 'Saisis le PIN pour accéder aux réglages.',
      );

      if (unlocked) {
        _wasUnlockedForSettings = true;
        _unlockedProfileId = profile.id;
      }
      return unlocked;
    } finally {
      _unlocking = false;
    }
  }

  Future<bool> _ensureProfileUnlocked(Profile profile) async {
    if (!profile.isKid && profile.pegiLimit == null) return true;

    if (_unlocking) return false;
    _unlocking = true;
    try {
      final sessionSvc = ref.read(parental.parentalSessionServiceProvider);

      if (await sessionSvc.isUnlocked(profile.id)) {
        _wasUnlockedForSettings = true;
        _unlockedProfileId = profile.id;
        return true;
      }

      if (!mounted) return false;
      final unlocked = await RestrictedContentSheet.show(
        context,
        ref,
        profile: profile,
        title: 'Paramètres verrouillés',
        reason: 'Saisis le PIN pour accéder aux réglages.',
      );

      if (unlocked) {
        _wasUnlockedForSettings = true;
        _unlockedProfileId = profile.id;
      }
      return unlocked;
    } finally {
      _unlocking = false;
    }
  }

  void _guard(FutureOr<void> Function() action) {
    unawaited(() async {
      final ok = await _ensureSettingsUnlocked();
      if (!ok) return;
      if (!mounted) return;
      await action();
      _lockSessionIfUnlocked();
    }());
  }

  void _lockSessionIfUnlocked() {
    if (_wasUnlockedForSettings && _unlockedProfileId != null) {
      try {
        final sessionSvc = ref.read(parental.parentalSessionServiceProvider);
        sessionSvc.lock(_unlockedProfileId!);
      } catch (_) {
        // best-effort
      }
    }
    _wasUnlockedForSettings = false;
    _unlockedProfileId = null;
  }

  // -------------------- Helpers --------------------

  String _getLanguageLabel(String code) {
    String normalized = code.toLowerCase();

    // special fr-MM
    if (normalized.contains('mm')) {
      return _availableLanguages
          .firstWhere(
            (e) => e.$1 == 'fr-MM',
            orElse: () => ('fr-MM', 'Burgonde'),
          )
          .$2;
    }

    normalized = normalized.split('-').first;

    final entry = _availableLanguages.firstWhere(
      (e) => e.$1.toLowerCase() == normalized,
      orElse: () => (code, code),
    );
    return entry.$2;
  }

  bool _isCurrentLanguage(String currentCode, String code) {
    final current = currentCode.toLowerCase();
    final option = code.toLowerCase();

    if (code == 'fr-MM') return current.contains('mm');
    return current.split('-').first == option.split('-').first;
  }

  String _formatSyncInterval(Duration interval) {
    if (interval.inDays >= 365) return 'Désactivé';

    final minutes = interval.inMinutes;
    if (minutes < 60) {
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    }
    if (minutes < 1440) {
      final hours = minutes ~/ 60;
      if (minutes % 60 == 0) {
        return hours == 1 ? 'Toutes les heures' : 'Toutes les $hours heures';
      }
      return '$hours h ${minutes % 60} min';
    }

    final days = minutes ~/ 1440;
    if (minutes % 1440 == 0) {
      return days == 1 ? 'Tous les jours' : 'Tous les $days jours';
    }
    final hours = (minutes % 1440) ~/ 60;
    return '$days jour${days > 1 ? 's' : ''} ${hours}h';
  }

  bool _isCurrentSyncInterval(Duration current, Duration? option) {
    if (option == null) return current.inDays >= 365;
    if (current.inDays >= 365) return false;
    return current.inMinutes == option.inMinutes;
  }

  String _getAccentColorName(Color color) {
    // ignore: deprecated_member_use
    final option = _accentColorOptions.firstWhere(
      // ignore: deprecated_member_use
      (e) => e.$1.value == color.value,
      orElse: () => (color, 'Personnalisé'),
    );
    return option.$2;
  }

  bool _isCurrentAccentColor(Color current, Color option) {
    // ignore: deprecated_member_use
    return current.value == option.value;
  }

  String _formatCloudSyncLast(BuildContext context, DateTime? lastUtc) {
    final l10n = AppLocalizations.of(context)!;
    if (lastUtc == null) return l10n.settingsCloudSyncNever;

    final local = lastUtc.toLocal();
    final material = MaterialLocalizations.of(context);
    final date = material.formatCompactDate(local);
    final time = material.formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: true,
    );
    return '$date $time';
  }

  // -------------------- Selectors --------------------

  Future<void> _showLanguageSelector(
    BuildContext context,
    String currentCode,
  ) async {
    final localePrefs = ref.read(slProvider)<LocalePreferences>();
    final accentColor = ref.read(asp.currentAccentColorProvider);
    final l10n = AppLocalizations.of(context)!;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.settingsLanguageLabel),
        actions: [
          for (final (code, label) in _availableLanguages)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                unawaited(() async {
                  await localePrefs.setLanguageCode(code);
                  _lockSessionIfUnlocked();
                }());
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: _isCurrentLanguage(currentCode, code)
                          ? accentColor
                          : Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (_isCurrentLanguage(currentCode, code)) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check, color: accentColor, size: 20),
                  ],
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.actionCancel),
        ),
      ),
    );
  }

  Future<void> _showSyncIntervalSelector(
    BuildContext context,
    Duration currentInterval,
  ) async {
    final iptvSyncPrefs = ref.read(slProvider)<IptvSyncPreferences>();
    final syncService = ref.read(slProvider)<XtreamSyncService>();
    final accentColor = ref.read(asp.currentAccentColorProvider);
    final l10n = AppLocalizations.of(context)!;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.settingsSyncFrequency),
        actions: [
          for (final (interval, label) in _syncIntervalOptions)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                unawaited(() async {
                  if (interval == null) {
                    const disabled = Duration(days: 365);
                    await iptvSyncPrefs.setSyncInterval(disabled);
                    syncService.setInterval(disabled);
                  } else {
                    await iptvSyncPrefs.setSyncInterval(interval);
                    syncService.setInterval(interval);
                  }
                  _lockSessionIfUnlocked();
                }());
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: _isCurrentSyncInterval(currentInterval, interval)
                          ? accentColor
                          : Colors.white,
                      fontWeight: _isCurrentSyncInterval(
                        currentInterval,
                        interval,
                      )
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  if (_isCurrentSyncInterval(currentInterval, interval)) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check, color: accentColor, size: 20),
                  ],
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.actionCancel),
        ),
      ),
    );
  }

  Future<void> _showAccentColorSelector(
    BuildContext context,
    Color currentColor,
  ) async {
    final accentColorPrefs = ref.read(slProvider)<AccentColorPreferences>();
    final l10n = AppLocalizations.of(context)!;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.settingsAccentColor),
        actions: [
          for (final (color, name) in _accentColorOptions)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                unawaited(() async {
                  await accentColorPrefs.setAccentColor(color);
                  _lockSessionIfUnlocked();
                }());
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        color: _isCurrentAccentColor(currentColor, color)
                            ? currentColor
                            : Colors.white,
                        fontWeight: _isCurrentAccentColor(currentColor, color)
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_isCurrentAccentColor(currentColor, color)) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check, color: currentColor, size: 20),
                  ],
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.actionCancel),
        ),
      ),
    );
  }

  // -------------------- IPTV --------------------

  Future<void> _refreshIptv() async {
    if (_refreshingIptv) return;

    var active = ref.read(asp.appStateControllerProvider).activeIptvSourceIds;

    if (active.isEmpty) {
      final locator = ref.read(slProvider);
      final iptvLocal = locator<IptvLocalRepository>();
      final accounts = await iptvLocal.getAccounts();

      if (accounts.isNotEmpty) {
        final ids = accounts.map((a) => a.id).toSet();
        ref.read(asp.appStateControllerProvider).setActiveIptvSources(ids);
        active = ids;
      }

      if (active.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.homeNoIptvSources)),
        );
        return;
      }
    }

    if (!mounted) return;
    setState(() => _refreshingIptv = true);

    final refresh = ref.read(refreshXtreamCatalogProvider);
    final logger = ref.read(slProvider)<AppLogger>();

    int ok = 0;
    int ko = 0;
    final errors = <String>[];

    for (final id in active) {
      final res = await refresh(id);
      res.fold(
        ok: (_) => ok += 1,
        err: (f) {
          ko += 1;
          errors.add(f.message);
          logger.error('IPTV refresh failed for $id: ${f.message}');
        },
      );
    }

    unawaited(ref.read(hp.homeControllerProvider.notifier).refresh());
    ref.read(appEventBusProvider).emit(const AppEvent(AppEventType.iptvSynced));

    if (mounted) {
      final accent = ref.read(asp.currentAccentColorProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Playlists IPTV rafraîchies ($ok/${active.length})${ko > 0 ? ' | erreurs: $ko' : ''}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1C1C1E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );

      if (ko > 0 && errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errors.first,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: accent.withValues(alpha: 0.25),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() => _refreshingIptv = false);
    _lockSessionIfUnlocked();
  }

  // -------------------- UI parts --------------------

  Widget _buildSettingItem({
    required String title,
    String? value,
    VoidCallback? onTap,
    Widget? trailing,
    bool showChevronDown = false,
  }) {
    final accentColor = ref.watch(asp.currentAccentColorProvider);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (trailing != null) ...[trailing, const SizedBox(width: 8)],
            if (showChevronDown)
              Icon(Icons.keyboard_arrow_down, color: accentColor, size: 20)
            else if (onTap != null && trailing == null)
              const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilesSection() {
    final l10n = AppLocalizations.of(context)!;
    final authStatus = ref.watch(supabaseAuthStatusProvider);
    final profilesAsync = ref.watch(profilesControllerProvider);
    final selectedProfileId = ref.watch(selectedProfileIdProvider);

    if (authStatus != SupabaseAuthStatus.authenticated) {
      return const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return profilesAsync.when(
      loading: () => const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (error, _) {
        final isNotAuthenticated = error is ProfilesNotAuthenticatedException;
        final isNotInitialized = error is ProfilesNotInitializedException;

        if ((isNotAuthenticated || isNotInitialized) &&
            authStatus == SupabaseAuthStatus.authenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) ref.invalidate(profilesControllerProvider);
          });
          return const SizedBox(
            height: 90,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildProfileCircle(
                  name: l10n.errorUnknown,
                  color: const Color(0xFF8E8E93),
                  icon: Icons.error_outline,
                  onTap: () => _guard(
                    () => ref.read(profilesControllerProvider.notifier).refresh(),
                  ),
                ),
                const SizedBox(width: 24),
                _buildProfileCircle(
                  name: l10n.playlistAddButton,
                  color: const Color(0xFF8E8E93),
                  icon: Icons.add,
                  onTap: _onAddProfile,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.errorWithMessage(error.toString()),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        );
      },
      data: (profiles) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...profiles.map(
              (profile) => Padding(
                padding: const EdgeInsets.only(right: 24),
                child: _buildProfileCircle(
                  name: profile.name,
                  color: Theme.of(context).colorScheme.primary,
                  icon: Icons.person,
                  isSelected: profile.id == selectedProfileId,
                  onTap: () => unawaited(_onSelectProfile(profile)),
                  onLongPress: () => unawaited(_onManageProfile(profile)),
                ),
              ),
            ),
            _buildProfileCircle(
              name: l10n.playlistAddButton,
              color: const Color(0xFF8E8E93),
              icon: Icons.add,
              onTap: _onAddProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCircle({
    required String name,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAddProfile() async {
    final ok = await _ensureSettingsUnlocked();
    if (!ok || !mounted) return;
    await CreateProfileDialog.show(context);
    _lockSessionIfUnlocked();
  }

  Future<void> _onSelectProfile(Profile profile) async {
    final isTargetChild = profile.isKid || profile.pegiLimit != null;

    if (isTargetChild) {
      final ok = await _ensureProfileUnlocked(profile);
      if (!ok) return;
    } else {
      final ok = await _ensureSettingsUnlocked();
      if (!ok) return;
    }

    ref.read(profilesControllerProvider.notifier).selectProfile(profile.id);
    _lockSessionIfUnlocked();
  }

  Future<void> _onManageProfile(Profile profile) async {
    final ok = await _ensureSettingsUnlocked();
    if (!ok || !mounted) return;
    await ManageProfileDialog.show(context, profile: profile);
    _lockSessionIfUnlocked();
  }

  Widget _buildSignOutButton(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: () => _guard(() async {
        final confirmed = await showCupertinoDialog<bool>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Déconnexion'),
            content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Annuler'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Déconnexion'),
              ),
            ],
          ),
        );

        if (confirmed != true) return;
        if (!mounted) return;

        // Capture context before async gap
        final navigatorContext = context;
        
        try {
          final locator = ref.read(slProvider);

          if (locator.isRegistered<LocalDataCleanupService>()) {
            await locator<LocalDataCleanupService>().clearAllLocalData();
          }

          // Clear in-memory selections to avoid stale state after logout.
          ref.read(asp.appStateControllerProvider).setActiveIptvSources({});
          if (locator.isRegistered<SelectedIptvSourcePreferences>()) {
            await locator<SelectedIptvSourcePreferences>().clear();
          }
          if (locator.isRegistered<SelectedProfilePreferences>()) {
            await locator<SelectedProfilePreferences>().clear();
          }

          await ref.read(authControllerProvider.notifier).signOut();

          if (!mounted) return;
          // ✅ utilise un path existant (pas AppRouteNames.about)
          navigatorContext.go(AppRoutePaths.authOtp);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(navigatorContext).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la déconnexion: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.red),
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        minimumSize: const Size(double.infinity, 48),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.logout, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Déconnexion',
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- Build --------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final currentLangCode = ref.watch(asp.currentLanguageCodeProvider);
    final currentLangLabel = _getLanguageLabel(currentLangCode);
    final currentSyncInterval = ref.watch(asp.currentIptvSyncIntervalProvider);
    final currentAccentColor = ref.watch(asp.currentAccentColorProvider);

    final cloudSync = ref.watch(libraryCloudSyncControllerProvider);
    final cloudSyncController =
        ref.read(libraryCloudSyncControllerProvider.notifier);

    return Material(
      color: Colors.transparent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          Text(
            l10n.settingsTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ) ??
                const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),

          const SizedBox(height: 32),

          // --- Comptes
          Text(
            l10n.settingsAccountsSection,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ) ??
                const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 16),
          _buildProfilesSection(),

          const SizedBox(height: 32),

          // --- IPTV
          Text(
            l10n.settingsIptvSection,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ) ??
                const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),
          _buildSettingItem(
            title: l10n.settingsSourcesManagement,
            onTap: () => _guard(() => context.push(AppRoutePaths.iptvSources)),
          ),
          _buildSettingItem(
            title: l10n.settingsSyncFrequency,
            value: _formatSyncInterval(currentSyncInterval),
            showChevronDown: true,
            onTap: () => _guard(
              () => _showSyncIntervalSelector(context, currentSyncInterval),
            ),
          ),
          _buildSettingItem(
            title: l10n.settingsRefreshIptvPlaylistsTitle,
            trailing: _refreshingIptv
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: currentAccentColor,
                    ),
                  )
                : null,
            onTap: _refreshingIptv ? null : () => _guard(_refreshIptv),
          ),

          const SizedBox(height: 32),

          // --- Cloud sync (Library)
          Text(
            l10n.settingsCloudSyncSection,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ) ??
                const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),
          _buildSettingItem(
            title: l10n.settingsCloudSyncAuto,
            trailing: Switch.adaptive(
              value: cloudSync.autoSyncEnabled,
              activeThumbColor: currentAccentColor,
              onChanged: (value) =>
                  _guard(() => cloudSyncController.setAutoSyncEnabled(value)),
            ),
          ),
          _buildSettingItem(
            title: l10n.settingsCloudSyncNow,
            value: cloudSync.isSyncing
                ? l10n.settingsCloudSyncInProgress
                : _formatCloudSyncLast(context, cloudSync.lastSuccessAtUtc),
            trailing: cloudSync.isSyncing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: currentAccentColor,
                    ),
                  )
                : null,
            onTap: cloudSync.isSyncing
                ? null
                : () => _guard(() => cloudSyncController.syncNow()),
          ),
          if (cloudSync.lastError != null &&
              cloudSync.lastError!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.settingsCloudSyncError(cloudSync.lastError!),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],

          const SizedBox(height: 32),

          // --- App settings
          Text(
            l10n.settingsAppSection,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ) ??
                const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),

          // ✅ FIX: pas de l10n.navAbout / pas de AppRouteNames.about
          _buildSettingItem(
            title: 'À propos',
            onTap: () => context.push(AppRoutePaths.about),
          ),

          _buildSettingItem(
            title: l10n.settingsLanguageLabel,
            value: currentLangLabel,
            showChevronDown: true,
            onTap: () => _guard(
              () => _showLanguageSelector(context, currentLangCode),
            ),
          ),
          _buildSettingItem(
            title: l10n.settingsAccentColor,
            value: _getAccentColorName(currentAccentColor),
            showChevronDown: true,
            trailing: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: currentAccentColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            onTap: () => _guard(
              () => _showAccentColorSelector(context, currentAccentColor),
            ),
          ),

          const SizedBox(height: 32),
          _buildSignOutButton(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
