# Subscription target snapshot

Root analyzed: C:\Users\matte\Documents\DEV\Flutter\movi-app

## Requested files

~~~text
lib/src/features/settings/presentation/pages/settings_page.dart
lib/src/features/library/presentation/pages/library_page.dart
lib/src/core/router/app_routes.dart
lib/src/core/router/app_router.dart
lib/src/features/auth/presentation/auth_otp_page.dart
lib/src/features/home/presentation/widgets/home_continue_watching_section.dart
lib/src/features/person/presentation/pages/person_detail_page.dart
lib/src/features/saga/presentation/pages/saga_detail_page.dart
lib/src/core/profile/presentation/ui/dialogs/create_profile_dialog.dart
lib/src/core/profile/presentation/ui/dialogs/manage_profile_dialog.dart
lib/src/core/parental/presentation/providers/parental_providers.dart
lib/src/core/parental/presentation/providers/parental_access_providers.dart
~~~

## File snapshots
## lib/src/features/settings/presentation/pages/settings_page.dart

- Absolute path: C:\Users\matte\Documents\DEV\Flutter\movi-app\lib\src\features\settings\presentation\pages\settings_page.dart
- Size: 55934 bytes

~~~text
// lib/src/features/settings/presentation/pages/settings_page.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:movi/src/core/preferences/player_preferences.dart';
import 'package:movi/src/core/preferences/selected_iptv_source_preferences.dart';
import 'package:movi/src/core/preferences/selected_profile_preferences.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
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
import 'package:movi/src/core/supabase/supabase_providers.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/iptv/application/services/xtream_sync_service.dart';
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
import 'package:movi/src/features/player/domain/value_objects/preferred_playback_quality.dart';
import 'package:movi/src/features/player/domain/utils/language_formatter.dart';
import 'package:movi/src/features/shell/presentation/navigation/shell_destinations.dart';
import 'package:movi/src/features/shell/presentation/layouts/app_shell_mobile_layout.dart';
import 'package:movi/src/features/shell/presentation/providers/shell_providers.dart';
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
  final _firstProfileFocusNode = FocusNode(debugLabel: 'SettingsFirstProfile');
  late final ShellFocusCoordinator _shellFocusCoordinator;

  static const List<(String code, String label)> _availableLanguages = [
    ('en', 'English'),
    ('es', 'Español'),
    ('fr', 'Français'),
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

  static const List<String> _playbackLanguageCodes = [
    'fr',
    'en',
    'es',
    'de',
    'it',
    'nl',
    'pl',
    'pt',
  ];

  static const double _sectionTitleGap = 16;
  static const double _sectionItemGap = 12;
  static const double _sectionGap = 32;

  @override
  void initState() {
    super.initState();
    _shellFocusCoordinator = ref.read(shellFocusCoordinatorProvider);
    _shellFocusCoordinator.registerPreferredNode(
      ShellTab.settings,
      _firstProfileFocusNode,
    );

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
    _shellFocusCoordinator.unregisterPreferredNode(
      ShellTab.settings,
      _firstProfileFocusNode,
    );
    _firstProfileFocusNode.dispose();
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
    final normalized = code.toLowerCase().split('-').first;

    final entry = _availableLanguages.firstWhere(
      (e) => e.$1.toLowerCase() == normalized,
      orElse: () => (code, code),
    );
    return entry.$2;
  }

  bool _isCurrentLanguage(String currentCode, String code) {
    final current = currentCode.toLowerCase();
    final option = code.toLowerCase();
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
          child: Text(l10n.actionCancel, style: TextStyle(fontSize: 16)),
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
                      fontWeight:
                          _isCurrentSyncInterval(currentInterval, interval)
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
          child: Text(l10n.actionCancel, style: TextStyle(fontSize: 16)),
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
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
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
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            color: _isCurrentAccentColor(currentColor, color)
                                ? currentColor
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (_isCurrentAccentColor(currentColor, color))
                      PositionedDirectional(
                        end: 0,
                        child: Icon(Icons.check, color: currentColor, size: 20),
                      ),
                  ],
                ),
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.actionCancel, style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  Future<void> _showPreferredAudioLanguageSelector(
    BuildContext context,
    String? currentCode,
  ) async {
    final prefs = ref.read(slProvider)<PlayerPreferences>();
    await _showPlaybackLanguageSelector(
      context: context,
      title: 'Langue audio préférée',
      currentCode: currentCode,
      nullOptionLabel: 'Automatique',
      onSelected: prefs.setPreferredAudioLanguage,
    );
  }

  Future<void> _showPreferredSubtitleLanguageSelector(
    BuildContext context,
    String? currentCode,
  ) async {
    final prefs = ref.read(slProvider)<PlayerPreferences>();
    await _showPlaybackLanguageSelector(
      context: context,
      title: 'Langue des sous-titres',
      currentCode: currentCode,
      nullOptionLabel: 'Désactivés',
      onSelected: prefs.setPreferredSubtitleLanguage,
    );
  }

  Future<void> _showPreferredPlaybackQualitySelector(
    BuildContext context,
    PreferredPlaybackQuality? currentQuality,
  ) async {
    final prefs = ref.read(slProvider)<PlayerPreferences>();
    final accentColor = ref.read(asp.currentAccentColorProvider);
    final l10n = AppLocalizations.of(context)!;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Qualité préférée'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              unawaited(() async {
                await prefs.setPreferredPlaybackQuality(null);
                _lockSessionIfUnlocked();
              }());
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Auto',
                  style: TextStyle(
                    color: currentQuality == null ? accentColor : null,
                    fontWeight: currentQuality == null
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                if (currentQuality == null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check, color: accentColor, size: 18),
                ],
              ],
            ),
          ),
          for (final quality in PreferredPlaybackQuality.values)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                unawaited(() async {
                  await prefs.setPreferredPlaybackQuality(quality);
                  _lockSessionIfUnlocked();
                }());
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _preferredPlaybackQualityLabel(quality),
                    style: TextStyle(
                      color: currentQuality == quality ? accentColor : null,
                      fontWeight: currentQuality == quality
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  if (currentQuality == quality) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check, color: accentColor, size: 18),
                  ],
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.actionCancel, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  String _preferredPlaybackQualityLabel(PreferredPlaybackQuality quality) {
    switch (quality) {
      case PreferredPlaybackQuality.sd:
        return 'SD';
      case PreferredPlaybackQuality.hd:
        return 'HD';
      case PreferredPlaybackQuality.fullHd:
        return 'Full HD';
      case PreferredPlaybackQuality.ultraHd4k:
        return '4K';
    }
  }

  Future<void> _showPlaybackLanguageSelector({
    required BuildContext context,
    required String title,
    required String? currentCode,
    required String nullOptionLabel,
    required Future<void> Function(String? code) onSelected,
  }) async {
    final accentColor = ref.read(asp.currentAccentColorProvider);
    final l10n = AppLocalizations.of(context)!;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(title),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              unawaited(() async {
                await onSelected(null);
                _lockSessionIfUnlocked();
              }());
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  nullOptionLabel,
                  style: TextStyle(
                    fontSize: 16,
                    color: currentCode == null ? accentColor : Colors.white,
                    fontWeight: currentCode == null
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
                if (currentCode == null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check, color: accentColor, size: 20),
                ],
              ],
            ),
          ),
          for (final code in _playbackLanguageCodes)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                unawaited(() async {
                  await onSelected(code);
                  _lockSessionIfUnlocked();
                }());
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    LanguageFormatter.formatLanguageCode(code),
                    style: TextStyle(
                      fontSize: 16,
                      color: currentCode == code ? accentColor : Colors.white,
                      fontWeight: currentCode == code
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  if (currentCode == code) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check, color: accentColor, size: 20),
                  ],
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.actionCancel, style: const TextStyle(fontSize: 16)),
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.homeNoIptvSources),
          ),
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1C1C1E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: accent.withValues(alpha: 0.25),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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

  KeyEventResult _handleSettingsHorizontalBoundary(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      ref.read(shellFocusCoordinatorProvider).focusSidebar();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildSettingItem({
    required String title,
    String? value,
    Color? valueColor,
    VoidCallback? onTap,
    Widget? trailing,
    bool showChevronDown = false,
  }) {
    final accentColor = ref.watch(asp.currentAccentColorProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxValueWidth = screenWidth < 420 ? 112.0 : 168.0;

    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) => _handleSettingsHorizontalBoundary(event),
      child: InkWell(
        onTap: onTap,
        focusColor: accentColor.withValues(alpha: 0.18),
        hoverColor: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxValueWidth),
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? accentColor,
                    ),
                  ),
                ),
              ],
              if (trailing != null) ...[const SizedBox(width: 8), trailing],
              if (showChevronDown) ...[
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down, color: accentColor, size: 20),
              ] else if (onTap != null && trailing == null) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(
    List<Widget> items, {
    double gap = _sectionItemGap,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          items[i],
        ],
      ],
    );
  }

  Widget _buildProfilesSection() {
    final l10n = AppLocalizations.of(context)!;
    final profilesAsync = ref.watch(profilesControllerProvider);
    final selectedProfileId = ref.watch(selectedProfileIdProvider);

    return profilesAsync.when(
      loading: () => const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (error, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildProfileCircle(
                  name: l10n.errorUnknown,
                  color: const Color.fromARGB(20, 255, 255, 255),
                  icon: Icons.error_outline,
                  onTap: () => _guard(
                    () =>
                        ref.read(profilesControllerProvider.notifier).refresh(),
                  ),
                ),
                const SizedBox(width: 24),
                _buildProfileCircle(
                  name: l10n.playlistAddButton,
                  color: const Color.fromARGB(20, 255, 255, 255),
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
                  focusNode: profiles.first.id == profile.id
                      ? _firstProfileFocusNode
                      : null,
                  onTap: () => unawaited(_onSelectProfile(profile)),
                  onLongPress: () => unawaited(_onManageProfile(profile)),
                ),
              ),
            ),
            _buildProfileCircle(
              name: l10n.playlistAddButton,
              color: const Color.fromARGB(20, 255, 255, 255),
              icon: Icons.add,
              onTap: _onAddProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudAccountSection(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final client = ref.watch(supabaseClientProvider);

    final hasCloudSession = authState.userId?.trim().isNotEmpty == true;
    final accountEmail = client?.auth.currentUser?.email?.trim();

    late final String accountValue;
    late final Color accountValueColor;

    if (hasCloudSession) {
      accountValue = (accountEmail?.isNotEmpty ?? false)
          ? accountEmail!
          : 'Connecté';
      accountValueColor = ref.watch(asp.currentAccentColorProvider);
    } else if (client != null) {
      accountValue = 'Mode local';
      accountValueColor = Colors.white70;
    } else {
      accountValue = 'Cloud indisponible';
      accountValueColor = theme.colorScheme.error;
    }

    return _buildSettingsGroup([
      _buildSettingItem(
        title: 'Compte cloud',
        value: accountValue,
        valueColor: accountValueColor,
      ),
      if (!hasCloudSession && client != null)
        _buildSettingItem(
          title: 'Se connecter',
          onTap: () => _guard(
            () => context.push('${AppRoutePaths.authOtp}?return_to=previous'),
          ),
        ),
      SizedBox(height: 8),
      if (hasCloudSession) _buildSignOutButton(context),
    ]);
  }

  // ignore: unused_element
  Widget _buildPlaybackSettingsSection(BuildContext context) {
    final preferredAudioLanguage = ref.watch(
      asp.currentPreferredAudioLanguageProvider,
    );
    final preferredSubtitleLanguage = ref.watch(
      asp.currentPreferredSubtitleLanguageProvider,
    );
    final preferredPlaybackQuality = ref.watch(
      asp.currentPreferredPlaybackQualityProvider,
    );

    return _buildSettingsGroup([
      _buildSettingItem(
        title: 'Langue audio',
        value: preferredAudioLanguage == null
            ? 'Automatique'
            : LanguageFormatter.formatLanguageCode(preferredAudioLanguage),
        showChevronDown: true,
        onTap: () => _guard(
          () => _showPreferredAudioLanguageSelector(
            context,
            preferredAudioLanguage,
          ),
        ),
      ),
      _buildSettingItem(
        title: 'Sous-titres',
        value: preferredSubtitleLanguage == null
            ? 'Désactivés'
            : LanguageFormatter.formatLanguageCode(preferredSubtitleLanguage),
        showChevronDown: true,
        onTap: () => _guard(
          () => _showPreferredSubtitleLanguageSelector(
            context,
            preferredSubtitleLanguage,
          ),
        ),
      ),
      _buildSettingItem(
        title: 'Qualité préférée',
        value: preferredPlaybackQuality == null
            ? 'Auto'
            : _preferredPlaybackQualityLabel(preferredPlaybackQuality),
        showChevronDown: true,
        onTap: () => _guard(
          () => _showPreferredPlaybackQualitySelector(
            context,
            preferredPlaybackQuality,
          ),
        ),
      ),
    ]);
  }

  Widget _buildProfileCircle({
    required String name,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    FocusNode? focusNode,
    bool isSelected = false,
  }) {
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) {
        if (!identical(focusNode, _firstProfileFocusNode)) {
          return KeyEventResult.ignored;
        }
        return _handleSettingsHorizontalBoundary(event);
      },
      child: MoviFocusableAction(
        onPressed: onTap,
        onLongPress: onLongPress,
        focusNode: focusNode,
        semanticLabel: name,
        builder: (context, state) {
          final focused = state.focused;
          return MoviFocusFrame(
            scale: focused ? 1.04 : 1,
            borderRadius: BorderRadius.circular(999),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: focused
                        ? Border.all(color: Colors.white, width: 3)
                        : isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: isSelected || focused
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
        },
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

    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) => _handleSettingsHorizontalBoundary(event),
      child: OutlinedButton(
        onPressed: () => _guard(() async {
          final confirmed = await showCupertinoDialog<bool>(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Déconnexion'),
              content: const Text(
                'Êtes-vous sûr de vouloir vous déconnecter ?',
              ),
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
          backgroundColor: Colors.red.withValues(alpha: 0.18),
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
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
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
    final cloudSyncController = ref.read(
      libraryCloudSyncControllerProvider.notifier,
    );

    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth > 800
              ? 800.0
              : constraints.maxWidth;
          final isMobileShell = MediaQuery.sizeOf(context).width < 900;
          final bottomPadding = isMobileShell
              ? 24 + moviNavBarHeight() + moviNavBarBottomOffset(context)
              : 24.0;

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPadding),
                children: [
                  Text(
                    l10n.settingsTitle,
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                    style:
                        Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: _sectionTitleGap),
                  _buildProfilesSection(),

                  const SizedBox(height: _sectionGap),

                  // --- IPTV
                  Text(
                    l10n.settingsIptvSection,
                    style:
                        Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: _sectionTitleGap),
                  _buildSettingsGroup([
                    _buildSettingItem(
                      title: l10n.settingsSourcesManagement,
                      onTap: () =>
                          _guard(() => context.push(AppRoutePaths.iptvSources)),
                    ),
                    _buildSettingItem(
                      title: l10n.settingsSyncFrequency,
                      value: _formatSyncInterval(currentSyncInterval),
                      showChevronDown: true,
                      onTap: () => _guard(
                        () => _showSyncIntervalSelector(
                          context,
                          currentSyncInterval,
                        ),
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
                      onTap: _refreshingIptv
                          ? null
                          : () => _guard(_refreshIptv),
                    ),
                  ]),

                  const SizedBox(height: _sectionGap),

                  // Text(
                  //   'Lecture',
                  //   style:
                  //       Theme.of(context).textTheme.titleLarge?.copyWith(
                  //         color: Colors.white,
                  //         fontWeight: FontWeight.w600,
                  //       ) ??
                  //       const TextStyle(
                  //         fontSize: 20,
                  //         fontWeight: FontWeight.w600,
                  //         color: Colors.white,
                  //       ),
                  // ),
                  // const SizedBox(height: _sectionTitleGap),
                  // _buildPlaybackSettingsSection(context),

                  // const SizedBox(height: _sectionGap),

                  // --- App settings
                  Text(
                    l10n.settingsAppSection,
                    style:
                        Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: _sectionTitleGap),

                  // ✅ FIX: pas de l10n.navAbout / pas de AppRouteNames.about
                  _buildSettingsGroup([
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
                        () => _showAccentColorSelector(
                          context,
                          currentAccentColor,
                        ),
                      ),
                    ),
                    _buildSettingItem(
                      title: 'À propos',
                      onTap: () => context.push(AppRoutePaths.about),
                    ),
                  ]),

                  const SizedBox(height: _sectionGap),

                  // --- Cloud sync (Library)
                  Text(
                    l10n.settingsCloudSyncSection,
                    style:
                        Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: _sectionTitleGap),
                  _buildSettingsGroup([
                    _buildSettingItem(
                      title: l10n.settingsCloudSyncAuto,
                      trailing: Switch.adaptive(
                        value: cloudSync.autoSyncEnabled,
                        activeThumbColor: currentAccentColor,
                        onChanged: (value) => _guard(
                          () => cloudSyncController.setAutoSyncEnabled(value),
                        ),
                      ),
                    ),
                    _buildSettingItem(
                      title: l10n.settingsCloudSyncNow,
                      value: cloudSync.isSyncing
                          ? l10n.settingsCloudSyncInProgress
                          : _formatCloudSyncLast(
                              context,
                              cloudSync.lastSuccessAtUtc,
                            ),
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
                        cloudSync.lastError!.trim().isNotEmpty)
                      Text(
                        l10n.settingsCloudSyncError(cloudSync.lastError!),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    _buildCloudAccountSection(context),
                  ]),

                  const SizedBox(height: _sectionGap),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

~~~

## lib/src/features/library/presentation/pages/library_page.dart

- Absolute path: C:\Users\matte\Documents\DEV\Flutter\movi-app\lib\src\features\library\presentation\pages\library_page.dart
- Size: 38896 bytes

~~~text
// lib/src/features/library/presentation/pages/library_page.dart
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/features/library/library_constants.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/library/presentation/widgets/library_filter_pills.dart';
import 'package:movi/src/features/library/presentation/widgets/library_playlist_card.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/features/shell/presentation/navigation/shell_destinations.dart';
import 'package:movi/src/features/shell/presentation/providers/shell_providers.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

/// LibraryPage (version "content-only" pour être hostée par le Shell).
///
/// ✅ Changements clés:
/// - Pas de Scaffold/SafeArea/SwipeBackWrapper ici (le Shell s’en charge).
/// - Pas de bottomInset MoviBottomNavBar (le Shell gère ses insets).
/// - Champ de recherche avec FocusNode réel + animation propre.
/// - UI stable avec la retention du Shell.
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _firstPlaylistFocusNode = FocusNode(debugLabel: 'LibraryFirstPlaylist');
  final List<FocusNode> _playlistFocusNodes = [];
  late final ShellFocusCoordinator _shellFocusCoordinator;

  late final AnimationController _anim;
  late final Animation<double> _opacity;
  late final Animation<double> _slideY;

  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _shellFocusCoordinator = ref.read(shellFocusCoordinatorProvider);
    _shellFocusCoordinator.registerPreferredNode(
      ShellTab.library,
      _firstPlaylistFocusNode,
    );

    _anim = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );

    _opacity = CurvedAnimation(parent: _anim, curve: Curves.easeOut);

    _slideY = Tween<double>(
      begin: -12.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _shellFocusCoordinator.unregisterPreferredNode(
      ShellTab.library,
      _firstPlaylistFocusNode,
    );
    _disposePlaylistFocusNodes();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _firstPlaylistFocusNode.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _syncPlaylistFocusNodes(int count) {
    if (_playlistFocusNodes.length == count) return;

    if (_playlistFocusNodes.isEmpty && count > 0) {
      _playlistFocusNodes.add(_firstPlaylistFocusNode);
    }

    while (_playlistFocusNodes.length < count) {
      final index = _playlistFocusNodes.length;
      _playlistFocusNodes.add(
        index == 0
            ? _firstPlaylistFocusNode
            : FocusNode(debugLabel: 'LibraryPlaylist-$index'),
      );
    }

    while (_playlistFocusNodes.length > count) {
      final removed = _playlistFocusNodes.removeLast();
      if (!identical(removed, _firstPlaylistFocusNode)) {
        removed.dispose();
      }
    }
  }

  void _disposePlaylistFocusNodes() {
    for (final node in _playlistFocusNodes) {
      if (!identical(node, _firstPlaylistFocusNode)) {
        node.dispose();
      }
    }
    _playlistFocusNodes.clear();
  }

  KeyEventResult _handlePlaylistListDirection(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    int? targetIndex;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      targetIndex = index + 1 < _playlistFocusNodes.length ? index + 1 : null;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      targetIndex = index > 0 ? index - 1 : null;
    }

    if (targetIndex == null) return KeyEventResult.ignored;
    _playlistFocusNodes[targetIndex].requestFocus();
    return KeyEventResult.handled;
  }

  KeyEventResult _handlePlaylistGridDirection(
    int index,
    int columns,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    int? targetIndex;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      targetIndex = index % columns == 0 ? null : index - 1;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      final nextIndex = index + 1;
      targetIndex =
          (index % columns == columns - 1 ||
              nextIndex >= _playlistFocusNodes.length)
          ? null
          : nextIndex;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      targetIndex = index - columns >= 0 ? index - columns : null;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final nextIndex = index + columns;
      targetIndex = nextIndex < _playlistFocusNodes.length ? nextIndex : null;
    }

    if (targetIndex == null) return KeyEventResult.ignored;
    _playlistFocusNodes[targetIndex].requestFocus();
    return KeyEventResult.handled;
  }

  void _toggleSearch() {
    setState(() => _isSearchVisible = !_isSearchVisible);

    if (_isSearchVisible) {
      _anim.forward();
      // Focus après l’animation (meilleure sensation)
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        _searchFocusNode.requestFocus();
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length),
        );
      });
    } else {
      _anim.reverse();
      _searchController.clear();
      ref.read(librarySearchQueryProvider.notifier).setQuery('');
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  void _showCreatePlaylistDialog() {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final nameFocusNode = FocusNode(debugLabel: 'CreatePlaylistName');
    final cancelFocusNode = FocusNode(debugLabel: 'CreatePlaylistCancel');
    final submitFocusNode = FocusNode(debugLabel: 'CreatePlaylistSubmit');

    Future<void> submitCreate(BuildContext dialogContext) async {
      final name = nameController.text.trim();
      Navigator.of(dialogContext).pop();

      if (name.isEmpty) return;

      try {
        final userId = ref.read(currentUserIdProvider);
        final playlistId = PlaylistId(
          '${LibraryConstants.userPlaylistPrefix}${DateTime.now().millisecondsSinceEpoch}',
        );
        final createPlaylist = ref.read(createPlaylistUseCaseProvider);

        await createPlaylist(
          id: playlistId,
          title: MediaTitle(name),
          owner: userId,
          isPublic: false,
        );

        ref.invalidate(libraryPlaylistsProvider);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.playlistCreatedSuccess(name))),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.playlistCreateError(e.toString()))),
        );
      }
    }

    if (_screenType(context) == ScreenType.desktop) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: AlertDialog(
              title: Text(l10n.createPlaylistTitle),
              content: SizedBox(
                width: 420,
                child: FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: TextFormField(
                    controller: nameController,
                    focusNode: nameFocusNode,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => submitFocusNode.requestFocus(),
                    decoration: InputDecoration(
                      hintText: l10n.playlistName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              buttonPadding: EdgeInsets.zero,
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: FocusTraversalOrder(
                          order: const NumericFocusOrder(2),
                          child: Focus(
                            canRequestFocus: false,
                            onKeyEvent: (_, event) {
                              if (event is! KeyDownEvent) {
                                return KeyEventResult.ignored;
                              }

                              if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowUp) {
                                nameFocusNode.requestFocus();
                                return KeyEventResult.handled;
                              }

                              if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowRight) {
                                submitFocusNode.requestFocus();
                                return KeyEventResult.handled;
                              }

                              return KeyEventResult.ignored;
                            },
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  focusNode: cancelFocusNode,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Theme.of(
                                      dialogContext,
                                    ).colorScheme.onSurface,
                                    side: BorderSide(
                                      color: Theme.of(
                                        dialogContext,
                                      ).colorScheme.outlineVariant,
                                    ),
                                    textStyle: Theme.of(dialogContext)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 15,
                                    ),
                                    shape: const StadiumBorder(),
                                    overlayColor: Colors.transparent,
                                  ),
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    child: Text(l10n.actionCancel),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FocusTraversalOrder(
                          order: const NumericFocusOrder(3),
                          child: Focus(
                            canRequestFocus: false,
                            onKeyEvent: (_, event) {
                              if (event is! KeyDownEvent) {
                                return KeyEventResult.ignored;
                              }

                              if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowUp) {
                                nameFocusNode.requestFocus();
                                return KeyEventResult.handled;
                              }

                              if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowLeft) {
                                cancelFocusNode.requestFocus();
                                return KeyEventResult.handled;
                              }

                              return KeyEventResult.ignored;
                            },
                            child: MoviPrimaryButton(
                              label: l10n.actionConfirm,
                              focusNode: submitFocusNode,
                              onPressed: () => submitCreate(dialogContext),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ).whenComplete(() {
        nameController.dispose();
        nameFocusNode.dispose();
        cancelFocusNode.dispose();
        submitFocusNode.dispose();
      });
      return;
    }

    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.createPlaylistTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: nameController,
            placeholder: l10n.playlistName,
            autofocus: true,
            padding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.actionCancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => submitCreate(dialogContext),
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    ).whenComplete(() {
      nameController.dispose();
      nameFocusNode.dispose();
      cancelFocusNode.dispose();
      submitFocusNode.dispose();
    });
  }

  void _showPlaylistMenu(
    BuildContext context,
    WidgetRef ref,
    LibraryPlaylistItem playlist,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (playlist.playlistId == null) return;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(playlist.title),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final setPinned = ref.read(setPlaylistPinnedUseCaseProvider);
                await setPinned.call(
                  id: PlaylistId(playlist.playlistId!),
                  isPinned: !playlist.isPinned,
                );
                ref.invalidate(libraryPlaylistsProvider);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      !playlist.isPinned
                          ? l10n.playlistPinned
                          : l10n.playlistUnpinned,
                    ),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.push_pin,
                  size: 18,
                  color: playlist.isPinned ? Colors.white70 : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(playlist.isPinned ? l10n.unpinPlaylist : l10n.pinPlaylist),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showRenameDialog(context, ref, playlist);
            },
            child: Text(l10n.renamePlaylist),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              _showDeleteDialog(context, ref, playlist);
            },
            child: Text(l10n.deletePlaylist),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.actionCancel),
        ),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    LibraryPlaylistItem playlist,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (playlist.playlistId == null) return;

    final nameController = TextEditingController(text: playlist.title);

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.playlistRenameTitle),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: nameController,
            placeholder: l10n.playlistNamePlaceholder,
            autofocus: true,
            padding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.actionCancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final name = nameController.text.trim();
              Navigator.of(ctx).pop();
              if (name.isEmpty) return;

              try {
                final renamePlaylist = ref.read(renamePlaylistUseCaseProvider);
                await renamePlaylist.call(
                  id: PlaylistId(playlist.playlistId!),
                  title: MediaTitle(name),
                );

                ref.invalidate(libraryPlaylistsProvider);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Playlist renommée en "$name"')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
              }
            },
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    LibraryPlaylistItem playlist,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (playlist.playlistId == null) return;

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.deletePlaylist),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${playlist.title}" ?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.actionCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();

              try {
                final deletePlaylist = ref.read(deletePlaylistUseCaseProvider);
                await deletePlaylist.call(PlaylistId(playlist.playlistId!));

                ref.invalidate(libraryPlaylistsProvider);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Playlist supprimée')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
              }
            },
            child: Text(l10n.deletePlaylist),
          ),
        ],
      ),
    );
  }

  void _navigateToPlaylist(LibraryPlaylistItem playlist) {
    if (playlist.type == LibraryPlaylistType.actor) {
      final personId = playlist.id.replaceFirst(
        LibraryConstants.actorPrefix,
        '',
      );
      context.push(
        AppRouteNames.person,
        extra: PersonSummary(id: PersonId(personId), name: playlist.title),
      );
      return;
    }

    if (playlist.id.startsWith(LibraryConstants.sagaPrefix)) {
      final sagaId = playlist.id.replaceFirst(LibraryConstants.sagaPrefix, '');
      context.push(AppRouteNames.sagaDetail, extra: sagaId);
      return;
    }

    context.push(AppRouteNames.libraryPlaylist, extra: playlist);
  }

  ScreenType _screenType(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ScreenTypeResolver.instance.resolve(size.width, size.height);
  }

  bool _isLargeScreen(BuildContext context) {
    final screenType = _screenType(context);
    return screenType == ScreenType.desktop || screenType == ScreenType.tv;
  }

  double _horizontalPadding(BuildContext context) {
    return switch (_screenType(context)) {
      ScreenType.mobile => 20,
      ScreenType.tablet => 24,
      ScreenType.desktop => 40,
      ScreenType.tv => 56,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isLargeScreen = _isLargeScreen(context);
    final horizontalPadding = _horizontalPadding(context);

    final filter = ref.watch(libraryFilterProvider);
    final playlistsAsync = ref.watch(filteredLibraryPlaylistsProvider);
    final searchQuery = ref.watch(librarySearchQueryProvider);
    final searchField = _LibrarySearchField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      hintText: l10n.librarySearchPlaceholder,
      clearTooltip: l10n.clear,
      onChanged: (text) {
        ref.read(librarySearchQueryProvider.notifier).setQuery(text);
      },
      onClear: () {
        _searchController.clear();
        ref.read(librarySearchQueryProvider.notifier).setQuery('');
        _searchFocusNode.requestFocus();
      },
    );

    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.navLibrary,
                    style:
                        theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ) ??
                        const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (isLargeScreen && (_isSearchVisible || _anim.value > 0)) ...[
                  const SizedBox(width: 12),
                  AnimatedBuilder(
                    animation: _anim,
                    builder: (context, _) {
                      final width = 420 * _opacity.value;
                      if (width <= 1) {
                        return const SizedBox.shrink();
                      }
                      return ClipRect(
                        child: SizedBox(
                          width: width,
                          child: Opacity(
                            opacity: _opacity.value,
                            child: Transform.translate(
                              offset: Offset(18 * (1 - _opacity.value), 0),
                              child: searchField,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: _isSearchVisible
                        ? theme.colorScheme.primary.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.08),
                    padding: const EdgeInsets.all(10),
                    shape: const CircleBorder(),
                  ),
                  icon: MoviAssetIcon(
                    AppAssets.iconSearch,
                    width: 24,
                    height: 24,
                    color: _isSearchVisible
                        ? theme.colorScheme.primary
                        : Colors.white,
                  ),
                  onPressed: _toggleSearch,
                  tooltip: l10n.searchTitle,
                ),
                const SizedBox(width: 6),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    padding: const EdgeInsets.all(10),
                    shape: const CircleBorder(),
                  ),
                  icon: const MoviAssetIcon(
                    AppAssets.iconPlus,
                    width: 24,
                    height: 24,
                    color: Colors.white,
                  ),
                  onPressed: _showCreatePlaylistDialog,
                  tooltip: l10n.createPlaylistTitle,
                ),
              ],
            ),
          ),

          if (!isLargeScreen)
            AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                if (!_isSearchVisible && _anim.value == 0) {
                  return const SizedBox.shrink();
                }

                return Opacity(
                  opacity: _opacity.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideY.value),
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 8,
                        left: horizontalPadding,
                        right: horizontalPadding,
                      ),
                      child: searchField,
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 12),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: LibraryFilterPills(
              activeFilter: filter,
              onFilterChanged: (newFilter) {
                ref.read(libraryFilterProvider.notifier).setFilter(newFilter);
              },
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: SyncableRefreshIndicator(
              onRefresh: () async {
                ref.invalidate(libraryPlaylistsProvider);
              },
              child: playlistsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    'Erreur: $error',
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
                data: (playlists) {
                  _syncPlaylistFocusNodes(playlists.length);

                  if (playlists.isEmpty) {
                    if (searchQuery.isNotEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Aucun résultat pour "$searchQuery"',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    return ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.35,
                          child: Center(
                            child: Text(
                              l10n.libraryEmpty,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  if (!isLargeScreen) {
                    return ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      itemCount: playlists.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return Focus(
                          canRequestFocus: false,
                          onKeyEvent: (_, event) =>
                              _handlePlaylistListDirection(index, event),
                          child: LibraryPlaylistCard(
                            title: playlist.title,
                            itemCount: playlist.itemCount,
                            type: playlist.type,
                            isPinned: playlist.isPinned,
                            photo: playlist.photo,
                            showItemCount: !playlist.id.startsWith(
                              LibraryConstants.sagaPrefix,
                            ),
                            focusNode: _playlistFocusNodes[index],
                            onTap: () => _navigateToPlaylist(playlist),
                            onLongPress:
                                playlist.type ==
                                        LibraryPlaylistType.userPlaylist &&
                                    playlist.playlistId != null
                                ? () =>
                                      _showPlaylistMenu(context, ref, playlist)
                                : null,
                          ),
                        );
                      },
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final width =
                          constraints.maxWidth - (horizontalPadding * 2);
                      const spacing = 8.0;
                      const maxCardWidth = 300.0;
                      final columns = (width / maxCardWidth).floor().clamp(
                        1,
                        8,
                      );
                      final gridMaxExtent =
                          (width - (spacing * (columns - 1))) / columns;

                      return GridView.builder(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          100,
                        ),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: gridMaxExtent,
                          mainAxisExtent: 276,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          return Focus(
                            canRequestFocus: false,
                            onKeyEvent: (_, event) =>
                                _handlePlaylistGridDirection(
                                  index,
                                  columns,
                                  event,
                                ),
                            child: LibraryPlaylistCard(
                              title: playlist.title,
                              itemCount: playlist.itemCount,
                              type: playlist.type,
                              isPinned: playlist.isPinned,
                              photo: playlist.photo,
                              layout: LibraryPlaylistCardLayout.vertical,
                              showItemCount: !playlist.id.startsWith(
                                LibraryConstants.sagaPrefix,
                              ),
                              focusNode: _playlistFocusNodes[index],
                              onTap: () => _navigateToPlaylist(playlist),
                              onLongPress:
                                  playlist.type ==
                                          LibraryPlaylistType.userPlaylist &&
                                      playlist.playlistId != null
                                  ? () => _showPlaylistMenu(
                                      context,
                                      ref,
                                      playlist,
                                    )
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibrarySearchField extends StatelessWidget {
  const _LibrarySearchField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.clearTooltip,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final String clearTooltip;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: const MoviAssetIcon(
                AppAssets.iconSearch,
                width: 25,
                height: 25,
                color: Colors.white70,
              ),
            ),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: const MoviAssetIcon(
                      AppAssets.iconDelete,
                      width: 25,
                      height: 25,
                      color: Colors.white,
                    ),
                    onPressed: onClear,
                    tooltip: clearTooltip,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 16,
            ),
          ),
        );
      },
    );
  }
}

~~~

## lib/src/core/router/app_routes.dart

- Absolute path: C:\Users\matte\Documents\DEV\Flutter\movi-app\lib\src\core\router\app_routes.dart
- Size: 22799 bytes

~~~text
// lib/src/core/router/app_routes.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/auth/presentation/widgets/auth_gate.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/router/app_route_ids.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/router/launch_redirect_guard.dart';
import 'package:movi/src/core/router/not_found_page.dart';
import 'package:movi/src/core/widgets/overlay_splash.dart';
import 'package:movi/src/core/parental/presentation/pages/pin_recovery_page.dart';
import 'package:movi/src/features/auth/presentation/auth_otp_page.dart';
import 'package:movi/src/features/category_browser/presentation/models/category_args.dart';
import 'package:movi/src/features/category_browser/presentation/pages/category_page.dart';
import 'package:movi/src/features/home/presentation/pages/home_hero_overlay_debug_page.dart';
import 'package:movi/src/features/library/presentation/pages/library_playlist_detail_page.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/movie/presentation/pages/movie_detail_page.dart';
import 'package:movi/src/features/person/presentation/pages/person_detail_page.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/player/presentation/pages/video_player_page.dart';
import 'package:movi/src/features/saga/presentation/pages/saga_detail_page.dart';
import 'package:movi/src/features/search/presentation/models/genre_all_results_args.dart';
import 'package:movi/src/features/search/presentation/models/genre_results_args.dart';
import 'package:movi/src/features/search/presentation/models/provider_all_results_args.dart';
import 'package:movi/src/features/search/presentation/models/provider_results_args.dart';
import 'package:movi/src/features/search/presentation/models/search_results_args.dart';
import 'package:movi/src/features/search/presentation/pages/genre_all_results_page.dart';
import 'package:movi/src/features/search/presentation/pages/genre_results_page.dart';
import 'package:movi/src/features/search/presentation/pages/provider_all_results_page.dart';
import 'package:movi/src/features/search/presentation/pages/provider_results_page.dart';
import 'package:movi/src/features/search/presentation/pages/search_results_page.dart';
import 'package:movi/src/features/settings/presentation/pages/about_page.dart';
import 'package:movi/src/features/settings/presentation/pages/iptv_connect_page.dart';
import 'package:movi/src/features/settings/presentation/pages/iptv_source_add_page.dart';
import 'package:movi/src/features/settings/presentation/pages/iptv_source_edit_page.dart';
import 'package:movi/src/features/settings/presentation/pages/iptv_source_organize_page.dart';
import 'package:movi/src/features/settings/presentation/pages/iptv_source_select_page.dart';
import 'package:movi/src/features/settings/presentation/pages/iptv_sources_page.dart';
import 'package:movi/src/features/tv/presentation/pages/tv_detail_page.dart';
import 'package:movi/src/features/welcome/presentation/pages/splash_bootstrap_page.dart';
import 'package:movi/src/features/welcome/presentation/pages/welcome_source_page.dart';
import 'package:movi/src/features/welcome/presentation/pages/welcome_source_select_page.dart';
import 'package:movi/src/features/welcome/presentation/pages/welcome_source_loading_page.dart';
import 'package:movi/src/features/welcome/presentation/pages/welcome_user_page.dart';
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';
import 'package:movi/src/core/router/route_args/player_route_args.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/shell/presentation/pages/app_shell_page.dart';

/// Construit la liste des routes de l'application.
///
/// Le [launchGuard] est pour l’instant uniquement utilisé comme
/// [refreshListenable] et dans la logique de redirection globale au
/// niveau du [GoRouter]. Il est néanmoins passé ici pour garder la
/// possibilité d'ajouter des redirections spécifiques par route à l’avenir.
List<RouteBase> buildAppRoutes(LaunchRedirectGuard launchGuard) {
  return [
    if (kDebugMode)
      GoRoute(
        path: AppRoutePaths.debug,
        name: AppRouteIds.debug,
        redirect: (context, state) => AppRoutePaths.debugHeroOverlays,
        pageBuilder: (context, state) =>
            const MaterialPage(child: SizedBox.shrink()),
      ),
    if (kDebugMode)
      GoRoute(
        path: AppRoutePaths.debugHeroOverlays,
        name: AppRouteIds.debugHeroOverlays,
        pageBuilder: (context, state) =>
            const MaterialPage(child: HomeHeroOverlayDebugPage()),
      ),

    // --- Launch / welcome / bootstrap --------------------------------------
    GoRoute(
      path: AppRoutePaths.launch,
      name: AppRouteIds.launch,
      pageBuilder: (context, state) => const MaterialPage(child: _LaunchGate()),
    ),

    // Compat: /welcome -> /welcome/user
    GoRoute(
      path: AppRoutePaths.welcome,
      name: AppRouteIds.welcome,
      redirect: (context, state) => AppRoutePaths.welcomeUser,
      pageBuilder: (context, state) =>
          const MaterialPage(child: SizedBox.shrink()),
    ),

    // Étape 1: profil utilisateur
    GoRoute(
      path: AppRoutePaths.welcomeUser,
      name: AppRouteIds.welcomeUser,
      pageBuilder: (context, state) =>
          const MaterialPage(child: WelcomeUserPage()),
    ),

    // Étape 2: ajout/connexion des sources
    GoRoute(
      path: AppRoutePaths.welcomeSources,
      name: AppRouteIds.welcomeSources,
      pageBuilder: (context, state) =>
          const MaterialPage(child: WelcomeSourcePage()),
    ),

    // Étape 2bis: choix d'une source quand il y en a plusieurs (sans redemander le mot de passe).
    GoRoute(
      path: AppRoutePaths.welcomeSourceSelect,
      name: AppRouteIds.welcomeSourceSelect,
      pageBuilder: (context, state) =>
          const MaterialPage(child: WelcomeSourceSelectPage()),
    ),

    // Étape 2ter: chargement initial des playlists IPTV
    GoRoute(
      path: AppRoutePaths.welcomeSourceLoading,
      name: AppRouteIds.welcomeSourceLoading,
      pageBuilder: (context, state) =>
          const MaterialPage(child: WelcomeSourceLoadingPage()),
    ),

    GoRoute(
      path: AppRoutePaths.authOtp,
      name: AppRouteIds.authOtp,
      pageBuilder: (context, state) {
        final returnOnSuccess =
            state.uri.queryParameters['return_to'] == 'previous';

        return MaterialPage(
          child: AuthOtpPage(returnOnSuccess: returnOnSuccess),
        );
      },
    ),

    GoRoute(
      path: AppRoutePaths.bootstrap,
      name: AppRouteIds.bootstrap,
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: SplashBootstrapPage(),
        transitionsBuilder: _fadeTransition,
      ),
    ),

    // --- Home (Shell) ------------------------------------------------------
    GoRoute(
      path: AppRoutePaths.home,
      name: AppRouteIds.home,
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: AuthGate(child: AppShellPage()),
        transitionsBuilder: _fadeTransition,
      ),
    ),

    // --- Recherche ---------------------------------------------------------
    GoRoute(
      path: AppRoutePaths.search,
      name: AppRouteIds.search,
      redirect: (context, state) => AppRoutePaths.home,
      pageBuilder: (context, state) =>
          const MaterialPage(child: SizedBox.shrink()),
    ),
    GoRoute(
      path: AppRoutePaths.searchResults,
      name: AppRouteIds.searchResults,
      pageBuilder: (context, state) {
        final args = state.extra is SearchResultsPageArgs
            ? state.extra as SearchResultsPageArgs
            : null;
        return MaterialPage(child: SearchResultsPage(args: args));
      },
    ),
    GoRoute(
      path: AppRoutePaths.providerResults,
      name: AppRouteIds.providerResults,
      pageBuilder: (context, state) {
        final args = state.extra is ProviderResultsArgs
            ? state.extra as ProviderResultsArgs
            : null;
        return MaterialPage(child: ProviderResultsPage(args: args));
      },
    ),
    GoRoute(
      path: AppRoutePaths.providerAllResults,
      name: AppRouteIds.providerAllResults,
      pageBuilder: (context, state) {
        final args = state.extra is ProviderAllResultsArgs
            ? state.extra as ProviderAllResultsArgs
            : null;

        if (args == null) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(
              message: l10n.notFoundWithEntity(l10n.entityProvider),
            ),
          );
        }

        return MaterialPage(
          child: ProviderAllResultsPage(args: args, type: args.type),
        );
      },
    ),
    GoRoute(
      path: AppRoutePaths.genreResults,
      name: AppRouteIds.genreResults,
      pageBuilder: (context, state) {
        final args = state.extra is GenreResultsArgs
            ? state.extra as GenreResultsArgs
            : null;
        return MaterialPage(child: GenreResultsPage(args: args));
      },
    ),
    GoRoute(
      path: AppRoutePaths.genreAllResults,
      name: AppRouteIds.genreAllResults,
      pageBuilder: (context, state) {
        final args = state.extra is GenreAllResultsArgs
            ? state.extra as GenreAllResultsArgs
            : null;

        if (args == null) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(
              message: l10n.notFoundWithEntity(l10n.entityGenre),
            ),
          );
        }

        return MaterialPage(
          child: GenreAllResultsPage(args: args, type: args.type),
        );
      },
    ),

    // --- Bibliothèque ------------------------------------------------------
    GoRoute(
      path: AppRoutePaths.library,
      name: AppRouteIds.library,
      redirect: (context, state) => AppRoutePaths.home,
      pageBuilder: (context, state) =>
          const MaterialPage(child: SizedBox.shrink()),
    ),
    GoRoute(
      path: AppRoutePaths.libraryPlaylist,
      name: AppRouteIds.libraryPlaylist,
      pageBuilder: (context, state) {
        final playlist = state.extra is LibraryPlaylistItem
            ? state.extra as LibraryPlaylistItem
            : null;

        if (playlist == null) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(
              message: l10n.notFoundWithEntity(l10n.entityPlaylist),
            ),
          );
        }

        return MaterialPage(
          child: LibraryPlaylistDetailPage(playlist: playlist),
        );
      },
    ),

    GoRoute(
      path: AppRoutePaths.pinRecovery,
      name: AppRouteIds.pinRecovery,
      pageBuilder: (context, state) {
        final profileId = state.extra is String ? state.extra as String : null;
        return MaterialPage(child: PinRecoveryPage(profileId: profileId));
      },
    ),

    // --- Paramètres --------------------------------------------------------
    GoRoute(
      path: AppRoutePaths.settings,
      name: AppRouteIds.settings,
      redirect: (context, state) => AppRoutePaths.home,
      pageBuilder: (context, state) =>
          const MaterialPage(child: SizedBox.shrink()),
    ),
    GoRoute(
      path: AppRoutePaths.about,
      name: AppRouteIds.about,
      pageBuilder: (context, state) => const MaterialPage(child: AboutPage()),
    ),
    GoRoute(
      path: AppRoutePaths.iptvConnect,
      name: AppRouteIds.iptvConnect,
      pageBuilder: (context, state) =>
          const MaterialPage(child: IptvConnectPage()),
    ),
    GoRoute(
      path: AppRoutePaths.iptvSources,
      name: AppRouteIds.iptvSources,
      pageBuilder: (context, state) =>
          const MaterialPage(child: IptvSourcesPage()),
    ),
    GoRoute(
      path: AppRoutePaths.iptvSourceSelect,
      name: AppRouteIds.iptvSourceSelect,
      pageBuilder: (context, state) =>
          const MaterialPage(child: IptvSourceSelectPage()),
    ),
    GoRoute(
      path: AppRoutePaths.iptvSourceAdd,
      name: AppRouteIds.iptvSourceAdd,
      pageBuilder: (context, state) =>
          const MaterialPage(child: IptvSourceAddPage()),
    ),
    GoRoute(
      path: AppRoutePaths.iptvSourceEdit,
      name: AppRouteIds.iptvSourceEdit,
      pageBuilder: (context, state) {
        final accountId = state.extra is String ? state.extra as String : null;
        if (accountId == null || accountId.trim().isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(
              message: l10n.notFoundWithEntity(l10n.entitySource),
            ),
          );
        }
        return MaterialPage(child: IptvSourceEditPage(accountId: accountId));
      },
    ),
    GoRoute(
      path: AppRoutePaths.iptvSourceOrganize,
      name: AppRouteIds.iptvSourceOrganize,
      pageBuilder: (context, state) {
        final accountId = state.extra is String ? state.extra as String : null;
        if (accountId == null || accountId.trim().isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(
              message: l10n.notFoundWithEntity(l10n.entitySource),
            ),
          );
        }
        return MaterialPage(
          child: IptvSourceOrganizePage(accountId: accountId),
        );
      },
    ),

    // --- Détails contenus (films, séries, personnes, sagas, catégories) ----
    GoRoute(
      path: AppRoutePaths.movie,
      name: AppRouteIds.movie,
      pageBuilder: (context, state) {
        final extra = state.extra;
        final movieId = extra is ContentRouteArgs
            ? extra.id
            : extra is MoviMedia
            ? extra.id
            : null;

        if (movieId == null || movieId.trim().isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(
              message: l10n.notFoundWithEntity(l10n.entityMovie),
            ),
          );
        }

        return CustomTransitionPage(
          child: MovieDetailPage(movieId: movieId),
          transitionsBuilder: _fadeTransition,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
      },
    ),
    GoRoute(
      path: AppRoutePaths.movieById,
      name: AppRouteIds.movieById,
      pageBuilder: (context, state) {
        final movieId = state.pathParameters['id'];
        if (movieId == null || movieId.trim().isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(
              message: l10n.notFoundWithEntity(l10n.entityMovie),
            ),
          );
        }

        return CustomTransitionPage(
          child: MovieDetailPage(movieId: movieId),
          transitionsBuilder: _fadeTransition,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
      },
    ),
    GoRoute(
      path: AppRoutePaths.tv,
      name: AppRouteIds.tv,
      pageBuilder: (context, state) {
        final extra = state.extra;
        final seriesId = extra is ContentRouteArgs
            ? extra.id
            : extra is MoviMedia
            ? extra.id
            : null;

        if (seriesId == null || seriesId.trim().isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(
              message: l10n.notFoundWithEntity(l10n.entitySeries),
            ),
          );
        }

        return CustomTransitionPage(
          child: TvDetailPage(seriesId: seriesId),
          transitionsBuilder: _fadeTransition,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
      },
    ),
    GoRoute(
      path: AppRoutePaths.tvById,
      name: AppRouteIds.tvById,
      pageBuilder: (context, state) {
        final seriesId = state.pathParameters['id'];
        if (seriesId == null || seriesId.trim().isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(
              message: l10n.notFoundWithEntity(l10n.entitySeries),
            ),
          );
        }

        return CustomTransitionPage(
          child: TvDetailPage(seriesId: seriesId),
          transitionsBuilder: _fadeTransition,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
      },
    ),
    GoRoute(
      path: AppRoutePaths.person,
      name: AppRouteIds.person,
      pageBuilder: (context, state) {
        final personSummary = state.extra is PersonSummary
            ? state.extra as PersonSummary
            : null;

        if (personSummary == null) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(
              message: l10n.notFoundWithEntity(l10n.entityPerson),
            ),
          );
        }

        return MaterialPage(
          child: PersonDetailPage(personSummary: personSummary),
        );
      },
    ),
    GoRoute(
      path: AppRoutePaths.personById,
      name: AppRouteIds.personById,
      pageBuilder: (context, state) {
        final personId = state.pathParameters['id'];
        if (personId == null || personId.trim().isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(
              message: l10n.notFoundWithEntity(l10n.entityPerson),
            ),
          );
        }
        return MaterialPage(child: PersonDetailPage(personId: personId));
      },
    ),
    GoRoute(
      path: AppRoutePaths.category,
      name: AppRouteIds.category,
      pageBuilder: (context, state) {
        final args = state.extra is CategoryPageArgs
            ? state.extra as CategoryPageArgs
            : null;

        return MaterialPage(child: CategoryPage(args: args));
      },
    ),
    GoRoute(
      path: AppRoutePaths.sagaDetail,
      name: AppRouteIds.sagaDetail,
      pageBuilder: (context, state) {
        final sagaId = state.extra is String ? state.extra as String : null;

        if (sagaId == null || sagaId.trim().isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(
              message: l10n.notFoundWithEntity(l10n.entitySaga),
            ),
          );
        }

        return MaterialPage(child: SagaDetailPage(sagaId: sagaId));
      },
    ),
    GoRoute(
      path: AppRoutePaths.sagaDetailById,
      name: AppRouteIds.sagaDetailById,
      pageBuilder: (context, state) {
        final sagaId = state.pathParameters['id'];

        if (sagaId == null || sagaId.trim().isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(
              message: l10n.notFoundWithEntity(l10n.entitySaga),
            ),
          );
        }

        return MaterialPage(child: SagaDetailPage(sagaId: sagaId));
      },
    ),

    // --- Player ------------------------------------------------------------
    GoRoute(
      path: AppRoutePaths.player,
      name: AppRouteIds.player,
      pageBuilder: (context, state) {
        VideoSource? videoSource;
        final extra = state.extra;
        if (extra is VideoSource) {
          videoSource = extra;
        } else if (extra is PlayerRouteArgs) {
          videoSource = extra.toVideoSource();
        } else {
          final qp = state.uri.queryParameters;
          final url = qp['url']?.trim();
          if (url != null && url.isNotEmpty) {
            final resume = int.tryParse(qp['resumeSeconds'] ?? '');
            final season = int.tryParse(qp['season'] ?? '');
            final episode = int.tryParse(qp['episode'] ?? '');
            final poster = Uri.tryParse(qp['poster'] ?? '');
            final contentTypeRaw = (qp['contentType'] ?? '').trim();
            final contentType = switch (contentTypeRaw) {
              'movie' => ContentType.movie,
              'series' => ContentType.series,
              _ => null,
            };

            videoSource = PlayerRouteArgs(
              url: url,
              title: qp['title'],
              subtitle: qp['subtitle'],
              contentId: qp['contentId'],
              contentType: contentType,
              poster: poster?.toString().isEmpty == true ? null : poster,
              season: season,
              episode: episode,
              resumeSeconds: resume,
            ).toVideoSource();
          }
        }

        if (videoSource == null) {
          final l10n = AppLocalizations.of(context)!;
          return MaterialPage(
            child: NotFoundPage(
              message: l10n.notFoundWithEntity(l10n.entityVideo),
            ),
          );
        }

        return MaterialPage(child: VideoPlayerPage(videoSource: videoSource));
      },
    ),
  ];
}

/// Transition simple en fondu réutilisée par plusieurs pages.
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

/// Page de lancement minimaliste utilisée le temps que le guard
/// décide où envoyer l'utilisateur.
class _LaunchGate extends ConsumerStatefulWidget {
  const _LaunchGate();

  @override
  ConsumerState<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends ConsumerState<_LaunchGate> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(appLaunchRunnerProvider)('startup'));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: OverlaySplash());
  }
}

~~~

## lib/src/core/router/app_router.dart

- Absolute path: C:\Users\matte\Documents\DEV\Flutter\movi-app\lib\src\core\router\app_router.dart
- Size: 4119 bytes

~~~text
// lib/src/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/auth/domain/repositories/auth_repository.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/router/app_routes.dart';
import 'package:movi/src/core/router/launch_redirect_guard.dart';
import 'package:movi/src/core/router/not_found_page.dart';
import 'package:movi/src/core/startup/app_launch_orchestrator.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/core/state/app_state_provider.dart';

typedef RouterBundle = ({GoRouter router, LaunchRedirectGuard guard});

class RouterHandle {
  const RouterHandle({required this.router, required this.guard});

  final GoRouter router;
  final LaunchRedirectGuard guard;

  void dispose() {
    router.dispose();
    guard.dispose();
  }
}

RouterBundle createRouterBundle({
  required AppStateController appStateController,
  required AppLogger logger,
  required AuthRepository authRepository,
  required AppLaunchStateRegistry launchRegistry,
}) {
  final guard = LaunchRedirectGuard(
    logger: logger,
    appStateController: appStateController,
    authRepository: authRepository,
    launchRegistry: launchRegistry,
  );

  final router = GoRouter(
    initialLocation: const String.fromEnvironment(
      'MOVI_INITIAL_ROUTE',
      defaultValue: AppRoutePaths.launch,
    ),
    refreshListenable: guard,
    redirect: guard.handle,
    routes: buildAppRoutes(guard),
    errorPageBuilder: (context, state) {
      final l10n = AppLocalizations.of(context)!;
      return MaterialPage(
        child: NotFoundPage(
          message: l10n.notFoundWithEntityAndError(
            l10n.entityRoute,
            state.error.toString(),
          ),
        ),
      );
    },
  );

  return (router: router, guard: guard);
}

/// Factory permettant de créer un [GoRouter] en dehors de Riverpod.
///
/// ⚠️ Attention : cette méthode ne permet pas de disposer le [LaunchRedirectGuard]
/// (subscriptions auth + listeners). Préfère [createRouterHandle] (ou
/// [createRouterBundle]) et dispose explicitement `router` + `guard`.
@Deprecated(
  'Use createRouterHandle(...) and dispose it, or createRouterBundle(...).',
)
GoRouter createRouter({
  required AppStateController appStateController,
  required AppLogger logger,
  required AuthRepository authRepository,
}) {
  return createRouterBundle(
    appStateController: appStateController,
    logger: logger,
    authRepository: authRepository,
    launchRegistry: sl<AppLaunchStateRegistry>(),
  ).router;
}

RouterHandle createRouterHandle({
  required AppStateController appStateController,
  required AppLogger logger,
  required AuthRepository authRepository,
}) {
  final bundle = createRouterBundle(
    appStateController: appStateController,
    logger: logger,
    authRepository: authRepository,
    launchRegistry: sl<AppLaunchStateRegistry>(),
  );
  return RouterHandle(router: bundle.router, guard: bundle.guard);
}

/// Provider global du routeur.
///
/// Gère également le cycle de vie du [GoRouter] et du [LaunchRedirectGuard].
final appRouterProvider = Provider<GoRouter>((ref) {
  final appStateController = ref.watch(appStateControllerProvider);
  final sl = ref.watch(slProvider);

  final logger = sl<AppLogger>();
  final authRepository = sl<AuthRepository>();
  final launchRegistry = sl<AppLaunchStateRegistry>();

  final bundle = createRouterBundle(
    appStateController: appStateController,
    logger: logger,
    authRepository: authRepository,
    launchRegistry: launchRegistry,
  );

  ref.onDispose(() {
    bundle.router.dispose();
    bundle.guard.dispose();
  });

  return bundle.router;
});

~~~

## lib/src/features/auth/presentation/auth_otp_page.dart

- Absolute path: C:\Users\matte\Documents\DEV\Flutter\movi-app\lib\src\features\auth\presentation\auth_otp_page.dart
- Size: 14354 bytes

~~~text
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/features/auth/presentation/auth_otp_controller.dart';
import 'package:movi/src/features/welcome/presentation/widgets/labeled_field.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_header.dart';

class AuthOtpPage extends ConsumerStatefulWidget {
  const AuthOtpPage({super.key, this.returnOnSuccess = false});

  final bool returnOnSuccess;

  @override
  ConsumerState<AuthOtpPage> createState() => _AuthOtpPageState();
}

class _AuthOtpPageState extends ConsumerState<AuthOtpPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _codeFocusNode = FocusNode();
  bool _handledSuccessfulAuth = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _emailFocusNode.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(authOtpControllerProvider);
    final authStatus = ref.watch(authStatusProvider);

    final emailErrorText = switch (state.emailError) {
      AuthOtpEmailError.invalid => l10n.errorFillFields,
      null => null,
    };

    final globalErrorText =
        state.globalError ??
        switch (state.globalErrorKey) {
          AuthOtpGlobalError.supabaseUnavailable => l10n.errorConnectionGeneric,
          null => null,
        };

    // Réagir à l'auth globale : dès que l'utilisateur est authentifié,
    // on le redirige vers l'écran Welcome (création / sélection de profil).
    ref.listen<AuthStatus>(authStatusProvider, (previous, next) {
      if (previous != AuthStatus.authenticated &&
          next == AuthStatus.authenticated &&
          mounted) {
        _handleSuccessfulAuthentication();
      }
    });

    if (widget.returnOnSuccess &&
        authStatus == AuthStatus.authenticated &&
        !_handledSuccessfulAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleSuccessfulAuthentication();
      });
    }

    final isSending = state.status == AuthOtpStatus.sendingCode;
    final isVerifying = state.status == AuthOtpStatus.verifyingCode;
    final isBusy = isSending || isVerifying;
    final isCodeStepVisible =
        state.status == AuthOtpStatus.codeSent ||
        isVerifying ||
        state.cooldownRemaining > 0;

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
                    title: l10n.authOtpTitle,
                    subtitle: l10n.authOtpSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step 1 — Email
                      LabeledField(
                        label: l10n.authOtpEmailLabel,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              enabled: !isBusy,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              onChanged: (value) {
                                ref
                                    .read(authOtpControllerProvider.notifier)
                                    .setEmail(value);
                              },
                              onFieldSubmitted: (_) {
                                if (!isCodeStepVisible) {
                                  _onSendCode();
                                } else {
                                  _codeFocusNode.requestFocus();
                                }
                              },
                              decoration: InputDecoration(
                                hintText: l10n.authOtpEmailHint,
                                errorText: emailErrorText,
                              ),
                            ),
                            if (emailErrorText == null) ...[
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 12,
                                  right: 12,
                                ),
                                child: Text(
                                  l10n.authOtpEmailHelp,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                  softWrap: true,
                                  maxLines: 3,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Step 2 — Code OTP
                      if (isCodeStepVisible) ...[
                        LabeledField(
                          label: l10n.authOtpCodeLabel,
                          child: TextFormField(
                            controller: _codeController,
                            focusNode: _codeFocusNode,
                            enabled: !isBusy,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            maxLength: 8,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              ref
                                  .read(authOtpControllerProvider.notifier)
                                  .setCode(value);
                            },
                            onFieldSubmitted: (_) => _onVerifyCode(),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: l10n.authOtpCodeHint,
                              helperText: l10n.authOtpCodeHelp,
                              errorText: state.codeError,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      if (globalErrorText != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Text(
                            globalErrorText,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // 32px d'espacement entre le champ email et le bouton
                      const SizedBox(height: 32),

                      // Primary action button
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: MoviPrimaryButton(
                            label: isCodeStepVisible
                                ? l10n.authOtpPrimarySubmit
                                : l10n.authOtpPrimarySend,
                            loading: isBusy,
                            onPressed: isBusy
                                ? null
                                : () {
                                    if (isCodeStepVisible) {
                                      _onVerifyCode();
                                    } else {
                                      _onSendCode();
                                    }
                                  },
                          ),
                        ),
                      ),

                      if (isCodeStepVisible) ...[
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final bool isNarrow = constraints.maxWidth < 360;

                              final resendButton = SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed:
                                      state.cooldownRemaining == 0 && !isBusy
                                      ? _onResendCode
                                      : null,
                                  child: Text(
                                    state.cooldownRemaining > 0
                                        ? l10n.authOtpResendDisabled(
                                            state.cooldownRemaining,
                                          )
                                        : l10n.authOtpResend,
                                  ),
                                ),
                              );

                              final changeEmailButton = SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: isBusy ? null : _onChangeEmail,
                                  child: Text(l10n.authOtpChangeEmail),
                                ),
                              );

                              if (isNarrow) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    resendButton,
                                    const SizedBox(height: AppSpacing.xs),
                                    changeEmailButton,
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: resendButton),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(child: changeEmailButton),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSendCode() {
    final controller = ref.read(authOtpControllerProvider.notifier);
    controller.sendCode().then((success) {
      if (success && mounted) {
        FocusScope.of(context).requestFocus(_codeFocusNode);
      }
    });
  }

  void _onVerifyCode() {
    ref.read(authOtpControllerProvider.notifier).verifyCode();
  }

  void _onResendCode() {
    ref.read(authOtpControllerProvider.notifier).resendCode();
  }

  void _onChangeEmail() {
    _codeController.clear();
    ref.read(authOtpControllerProvider.notifier).resetToEmailStep();
    FocusScope.of(context).requestFocus(_emailFocusNode);
  }

  void _handleSuccessfulAuthentication() {
    if (_handledSuccessfulAuth || !mounted) return;
    _handledSuccessfulAuth = true;

    final router = GoRouter.of(context);
    if (widget.returnOnSuccess && router.canPop()) {
      router.pop(true);
      return;
    }

    if (widget.returnOnSuccess) {
      context.go(AppRoutePaths.bootstrap);
      return;
    }

    context.go(AppRouteNames.welcome);
  }
}

~~~

## lib/src/features/home/presentation/widgets/home_continue_watching_section.dart

- Absolute path: C:\Users\matte\Documents\DEV\Flutter\movi-app\lib\src\features\home\presentation\widgets\home_continue_watching_section.dart
- Size: 6517 bytes

~~~text
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/core/widgets/movi_items_list.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/home/domain/entities/in_progress_media.dart'
    as domain;
import 'package:movi/src/features/home/presentation/widgets/continue_watching_card.dart';
import 'package:movi/src/features/home/presentation/widgets/home_first_section_transition.dart';
import 'package:movi/src/features/home/presentation/widgets/home_layout_constants.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/services/iptv_content_resolver.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';

/// Section affichant les médias en cours de lecture.
class HomeContinueWatchingSection extends ConsumerWidget {
  const HomeContinueWatchingSection({
    super.key,
    required this.onMarkAsUnwatched,
    this.applyHeroTransition = false,
  });

  final void Function(
    BuildContext context,
    WidgetRef ref,
    String contentId,
    ContentType type,
  )
  onMarkAsUnwatched;
  final bool applyHeroTransition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inProgressAsync = ref.watch(hp.homeInProgressProvider);
    final screenType = ScreenTypeResolver.instance.resolve(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
    );
    final itemLimit = switch (screenType) {
      ScreenType.mobile => HomeLayoutConstants.continueWatchingMobileLimit,
      ScreenType.tablet => HomeLayoutConstants.continueWatchingTabletLimit,
      ScreenType.desktop ||
      ScreenType.tv => HomeLayoutConstants.continueWatchingDesktopLimit,
    };

    return inProgressAsync.when(
      data: (List<domain.InProgressMedia> inProgress) {
        if (inProgress.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final section = MoviItemsList(
          title: AppLocalizations.of(context)!.homeContinueWatching,
          itemSpacing: HomeLayoutConstants.itemSpacing,
          estimatedItemWidth: HomeLayoutConstants.continueWatchingCardWidth,
          estimatedItemHeight: HomeLayoutConstants.continueWatchingCardHeight,
          items: inProgress
              .take(itemLimit)
              .map((media) => _buildCard(context, ref, media))
              .toList(),
        );

        return SliverToBoxAdapter(
          child: HomeFirstSectionTransition(
            enabled: applyHeroTransition,
            child: section,
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref,
    domain.InProgressMedia media,
  ) {
    if (media.type == ContentType.movie) {
      return ContinueWatchingCard.movie(
        title: media.title,
        backdrop: media.backdrop?.toString(),
        progress: media.progress,
        year: media.year,
        duration: media.duration,
        rating: media.rating,
        onTap: () => unawaited(_openMedia(context, ref, media)),
        onLongPress: () =>
            onMarkAsUnwatched(context, ref, media.contentId, media.type),
      );
    } else {
      final seasonEpisode = media.season != null && media.episode != null
          ? 'S${media.season!.toString().padLeft(2, '0')} E${media.episode!.toString().padLeft(2, '0')}'
          : '';
      return ContinueWatchingCard.episode(
        title: media.episodeTitle ?? media.title,
        backdrop: media.backdrop?.toString(),
        seriesTitle: media.seriesTitle,
        seasonEpisode: seasonEpisode,
        duration: media.duration,
        progress: media.progress,
        onTap: () => unawaited(_openMedia(context, ref, media)),
        onLongPress: () =>
            onMarkAsUnwatched(context, ref, media.contentId, media.type),
      );
    }
  }

  Future<void> _openMedia(
    BuildContext context,
    WidgetRef ref,
    domain.InProgressMedia media,
  ) async {
    final locator = ref.read(slProvider);
    final resolver = locator<IptvContentResolver>();
    final activeSourceIds = ref
        .read(asp.appStateControllerProvider)
        .preferredIptvSourceIds;
    final resolution = await resolver.resolve(
      contentId: media.contentId,
      type: media.type,
      activeSourceIds: activeSourceIds,
    );
    if (!context.mounted) return;
    if (!resolution.isAvailable || resolution.resolvedContentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pas disponible sur cette source')),
      );
      return;
    }

    final resolvedId = resolution.resolvedContentId!;
    if (media.type == ContentType.movie) {
      navigateToMovieDetail(context, ref, ContentRouteArgs.movie(resolvedId));
    } else {
      navigateToTvDetail(context, ref, ContentRouteArgs.series(resolvedId));
    }
  }
}

/// Widget pour l'espacement après la section "En cours" si elle est visible.
class HomeContinueWatchingSpacer extends ConsumerWidget {
  const HomeContinueWatchingSpacer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inProgressAsync = ref.watch(hp.homeInProgressProvider);

    return inProgressAsync.when(
      data: (inProgress) {
        if (inProgress.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return const SliverToBoxAdapter(
          child: SizedBox(height: HomeLayoutConstants.sectionGap),
        );
      },
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }
}

~~~

## lib/src/features/person/presentation/pages/person_detail_page.dart

- Absolute path: C:\Users\matte\Documents\DEV\Flutter\movi-app\lib\src\features\person\presentation\pages\person_detail_page.dart
- Size: 15668 bytes

~~~text
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/person/presentation/providers/person_detail_providers.dart';
import 'package:movi/src/features/person/presentation/models/person_detail_view_model.dart';
import 'package:movi/src/features/person/presentation/widgets/person_detail_hero_section.dart';
import 'package:movi/src/features/person/presentation/widgets/person_detail_actions_row.dart';
import 'package:movi/src/features/person/presentation/widgets/person_biography_section.dart';
import 'package:movi/src/features/person/presentation/widgets/person_filmography_section.dart';
import 'package:movi/src/shared/domain/entities/person_summary.dart';

class PersonDetailPage extends ConsumerStatefulWidget {
  const PersonDetailPage({super.key, this.personSummary, this.personId});

  final PersonSummary? personSummary;
  final String? personId;

  @override
  ConsumerState<PersonDetailPage> createState() => _PersonDetailPageState();
}

class _PersonDetailPageState extends ConsumerState<PersonDetailPage> {
  Timer? _autoRefreshTimer;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _loadingTimeout = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _startAutoRefreshTimer();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer(_loadingTimeout, () {
      final personId = _resolvePersonId(context);
      if (mounted && personId != null && _retryCount < _maxRetries) {
        final vmAsync = ref.read(personDetailControllerProvider(personId));
        // Si toujours en chargement après le timeout, relancer
        if (vmAsync.isLoading) {
          _retryCount++;
          ref.invalidate(personDetailControllerProvider(personId));
          _startAutoRefreshTimer();
        }
      }
    });
  }

  String? _resolvePersonId(BuildContext context) {
    if (widget.personSummary != null) return widget.personSummary!.id.value;
    if (widget.personId != null && widget.personId!.trim().isNotEmpty) {
      return widget.personId!.trim();
    }
    final extra = GoRouterState.of(context).extra;
    if (extra is PersonSummary) return extra.id.value;
    if (extra is String) return extra.trim().isEmpty ? null : extra.trim();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final personId = _resolvePersonId(context);
    if (personId == null) {
      final l10n = AppLocalizations.of(context)!;
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Text(
            l10n.personNoData,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final vmAsync = ref.watch(personDetailControllerProvider(personId));

    // Détecter les erreurs et relancer automatiquement
    vmAsync.whenOrNull(
      error: (e, st) {
        if (mounted && _retryCount < _maxRetries) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _retryCount++;
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  ref.invalidate(personDetailControllerProvider(personId));
                  _startAutoRefreshTimer();
                }
              });
            }
          });
        }
      },
      data: (_) {
        // Le chargement a réussi, annuler le timer et réinitialiser
        _autoRefreshTimer?.cancel();
        _retryCount = 0;
      },
    );

    return vmAsync.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const OverlaySplash(),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.personGenericError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              MoviPrimaryButton(
                label: AppLocalizations.of(context)!.actionRetry,
                onPressed: () {
                  final personId = _resolvePersonId(context);
                  if (personId == null) return;
                  ref.invalidate(personDetailControllerProvider(personId));
                  _startAutoRefreshTimer();
                },
              ),
            ],
          ),
        ),
      ),
      data: (vm) => _PersonDetailContent(vm: vm, personId: personId),
    );
  }
}

class _PersonDetailContent extends StatefulWidget {
  const _PersonDetailContent({required this.vm, required this.personId});

  final PersonDetailViewModel vm;
  final String personId;

  @override
  State<_PersonDetailContent> createState() => _PersonDetailContentState();
}

class _PersonDetailContentState extends State<_PersonDetailContent> {
  bool _isTransitioningFromLoading = true;

  ScreenType _screenTypeFor(BuildContext context) {
    final mq = MediaQuery.of(context);
    return ScreenTypeResolver.instance.resolve(
      mq.size.width,
      mq.size.height == 0 ? 1 : mq.size.height,
    );
  }

  bool _useDesktopLayout(BuildContext context) {
    final screenType = _screenTypeFor(context);
    return screenType == ScreenType.desktop || screenType == ScreenType.tv;
  }

  double _horizontalPadding(BuildContext context) {
    return _useDesktopLayout(context) ? 36 : 20;
  }

  @override
  void initState() {
    super.initState();
    _isTransitioningFromLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            setState(() {
              _isTransitioningFromLoading = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const heroHeight = 500.0;
    final cs = Theme.of(context).colorScheme;
    final isWideLayout = _useDesktopLayout(context);
    final horizontalPadding = _horizontalPadding(context);
    final movies = widget.vm.movies
        .map(
          (m) => MoviMedia(
            id: m.id.value,
            title: m.title.display,
            poster: m.poster,
            year: m.releaseYear,
            type: MoviMediaType.movie,
          ),
        )
        .toList(growable: false);
    final shows = widget.vm.shows
        .map(
          (s) => MoviMedia(
            id: s.id.value,
            title: s.title.display,
            poster: s.poster,
            type: MoviMediaType.series,
          ),
        )
        .toList(growable: false);

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          top: true,
          bottom: true,
          child: AnimatedOpacity(
            opacity: _isTransitioningFromLoading ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isWideLayout)
                          _buildDesktopHeader(
                            context,
                            horizontalPadding: horizontalPadding,
                            movies: movies,
                            shows: shows,
                          )
                        else
                          PersonDetailHeroSection(
                            photo: widget.vm.photo,
                            name: widget.vm.name,
                            moviesCount: widget.vm.moviesCount,
                            showsCount: widget.vm.showsCount,
                            height: heroHeight,
                          ),
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: horizontalPadding,
                            end: horizontalPadding,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 16),
                              if (!isWideLayout) ...[
                                PersonDetailActionsRow(
                                  personId: widget.personId,
                                  movies: movies,
                                  shows: shows,
                                ),
                                const SizedBox(height: 32),
                              ],
                              if (widget.vm.biography != null &&
                                  widget.vm.biography!.isNotEmpty) ...[
                                PersonBiographySection(
                                  biography: widget.vm.biography!,
                                ),
                                const SizedBox(height: 32),
                              ],
                              PersonFilmographySection(
                                movies: movies,
                                shows: shows,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(
    BuildContext context, {
    required double horizontalPadding,
    required List<MoviMedia> movies,
    required List<MoviMedia> shows,
  }) {
    final cs = Theme.of(context).colorScheme;
    final photo = widget.vm.photo;
    final countLabel = AppLocalizations.of(
      context,
    )!.personMoviesCount(widget.vm.moviesCount, widget.vm.showsCount);

    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.only(
        start: horizontalPadding,
        end: horizontalPadding,
        top: 20,
        bottom: 28,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerHighest.withValues(alpha: 0.9),
            cs.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 47,
              height: 47,
              child: MoviFocusableAction(
                onPressed: () => context.pop(),
                semanticLabel: 'Retour',
                builder: (context, state) {
                  return MoviFocusFrame(
                    scale: state.focused ? 1.04 : 1,
                    padding: const EdgeInsets.all(6),
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: state.focused
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.transparent,
                    child: const SizedBox(
                      width: 35,
                      height: 35,
                      child: MoviAssetIcon(
                        AppAssets.iconBack,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildDesktopPhoto(photo),
              const SizedBox(width: 32),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.vm.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                              height: 1.05,
                            ) ??
                            TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                              height: 1.05,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          MoviPill(
                            countLabel,
                            large: true,
                            color: cs.surfaceContainer,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 376,
                        child: PersonDetailActionsRow(
                          personId: widget.personId,
                          movies: movies,
                          shows: shows,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopPhoto(Uri? photo) {
    const size = 220.0;

    Widget child;
    if (photo == null) {
      child = const MoviPlaceholderCard(
        type: PlaceholderType.person,
        fit: BoxFit.cover,
        alignment: Alignment(0.0, 0.1),
        borderRadius: BorderRadius.zero,
      );
    } else {
      child = Image.network(
        photo.toString(),
        fit: BoxFit.cover,
        cacheWidth: 880,
        filterQuality: FilterQuality.high,
        alignment: const Alignment(0.0, 0.1),
        errorBuilder: (_, __, ___) => const MoviPlaceholderCard(
          type: PlaceholderType.person,
          fit: BoxFit.cover,
          alignment: Alignment(0.0, 0.1),
          borderRadius: BorderRadius.zero,
        ),
      );
    }

    return ClipOval(
      child: SizedBox(width: size, height: size, child: child),
    );
  }

  // Biography and hero image are now handled by dedicated widgets:
  // - PersonDetailHeroSection
  // - PersonBiographySection
}

~~~

## lib/src/features/saga/presentation/pages/saga_detail_page.dart

- Absolute path: C:\Users\matte\Documents\DEV\Flutter\movi-app\lib\src\features\saga\presentation\pages\saga_detail_page.dart
- Size: 24495 bytes

~~~text
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/utils/navigation_helpers.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/features/saga/presentation/providers/saga_detail_providers.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/presentation/router/content_route_args.dart';

class SagaDetailPage extends ConsumerWidget {
  const SagaDetailPage({super.key, required this.sagaId});

  final String sagaId;

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    }
    return '${minutes}m';
  }

  Future<void> _playMovie(
    BuildContext context,
    WidgetRef ref,
    String movieId,
  ) async {
    // Pour l'instant, ouvrir la page de détail du film
    navigateToMovieDetail(context, ref, ContentRouteArgs.movie(movieId));
  }

  Future<void> _startSaga(
    BuildContext context,
    WidgetRef ref,
    SagaDetailViewModel viewModel,
  ) async {
    // Trouver le premier film non visionné ou reprendre le film en cours
    final inProgressMovieId = await ref.read(
      sagaInProgressMovieProvider(sagaId).future,
    );
    if (!context.mounted) return;

    if (inProgressMovieId != null) {
      // Reprendre le film en cours
      if (!context.mounted) return;
      await _playMovie(context, ref, inProgressMovieId);
    } else {
      // Commencer par le premier film
      if (!context.mounted) return;
      final movies = viewModel.saga.timeline
          .where((entry) => entry.reference.type == ContentType.movie)
          .toList();
      if (movies.isNotEmpty && context.mounted) {
        await _playMovie(context, ref, movies.first.reference.id);
      }
    }
  }

  ScreenType _screenTypeFor(BuildContext context) {
    final mq = MediaQuery.of(context);
    return ScreenTypeResolver.instance.resolve(
      mq.size.width,
      mq.size.height == 0 ? 1 : mq.size.height,
    );
  }

  bool _useDesktopDetailLayout(BuildContext context) {
    final screenType = _screenTypeFor(context);
    return screenType == ScreenType.desktop || screenType == ScreenType.tv;
  }

  double _sectionHorizontalPadding(BuildContext context) {
    return _useDesktopDetailLayout(context) ? 36 : 20;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sagaDetailAsync = ref.watch(sagaDetailProvider(sagaId));
    final inProgressMovieAsync = ref.watch(sagaInProgressMovieProvider(sagaId));
    final isFavoriteAsync = ref.watch(sagaIsFavoriteProvider(sagaId));

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          top: true,
          bottom: true,
          child: sagaDetailAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.errorWithMessage(error.toString()),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.refresh(sagaDetailProvider(sagaId)),
                    child: Text(AppLocalizations.of(context)!.actionRetry),
                  ),
                ],
              ),
            ),
            data: (viewModel) {
              final movies = viewModel.saga.timeline
                  .where((entry) => entry.reference.type == ContentType.movie)
                  .map((entry) {
                    final ref = entry.reference;
                    return MoviMedia(
                      id: ref.id,
                      title: ref.title.display,
                      poster: ref.poster,
                      year: entry.timelineYear,
                      type: MoviMediaType.movie,
                    );
                  })
                  .toList();

              // Trier par année
              movies.sort((a, b) {
                final yearA = a.year ?? 0;
                final yearB = b.year ?? 0;
                return yearA.compareTo(yearB);
              });

              final isWideLayout = _useDesktopDetailLayout(context);
              final horizontalPadding = _sectionHorizontalPadding(context);
              final synopsisText = viewModel.saga.synopsis?.value ?? '';
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MoviDetailHeroScene(
                      isWideLayout: isWideLayout,
                      background: _buildHeroImage(
                        context,
                        poster: viewModel.poster,
                        backdrop: viewModel.backdrop,
                      ),
                      children: [
                        if (isWideLayout)
                          _buildDesktopHeroOverlay(
                            context,
                            ref,
                            viewModel,
                            inProgressMovieAsync,
                            isFavoriteAsync,
                            synopsisText: synopsisText,
                          ),
                        _buildHeroTopBar(
                          context,
                          isWideLayout: isWideLayout,
                          horizontalPadding: horizontalPadding,
                        ),
                      ],
                    ),
                    if (!isWideLayout)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 20,
                          end: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              viewModel.saga.title.display,
                              style:
                                  Theme.of(
                                    context,
                                  ).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ) ??
                                  const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${AppLocalizations.of(context)!.sagaMovieCount(viewModel.movieCount)} - ${_formatDuration(viewModel.totalDuration)}',
                              style:
                                  Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(color: Colors.white70) ??
                                  const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: inProgressMovieAsync.when(
                                    data: (inProgressMovieId) {
                                      return MoviPrimaryButton(
                                        label: inProgressMovieId != null
                                            ? AppLocalizations.of(
                                                context,
                                              )!.sagaContinue
                                            : AppLocalizations.of(
                                                context,
                                              )!.sagaStartNow,
                                        assetIcon: AppAssets.iconPlay,
                                        onPressed: () =>
                                            _startSaga(context, ref, viewModel),
                                      );
                                    },
                                    loading: () => MoviPrimaryButton(
                                      label: AppLocalizations.of(
                                        context,
                                      )!.sagaStartNow,
                                      assetIcon: AppAssets.iconPlay,
                                      onPressed: () {},
                                    ),
                                    error: (_, __) => MoviPrimaryButton(
                                      label: AppLocalizations.of(
                                        context,
                                      )!.sagaStartNow,
                                      assetIcon: AppAssets.iconPlay,
                                      onPressed: () =>
                                          _startSaga(context, ref, viewModel),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: isFavoriteAsync.when(
                                    data: (isFavorite) => MoviFavoriteButton(
                                      isFavorite: isFavorite,
                                      onPressed: () async {
                                        await ref
                                            .read(
                                              sagaToggleFavoriteProvider
                                                  .notifier,
                                            )
                                            .toggle(
                                              sagaId,
                                              SagaSummary(
                                                id: viewModel.saga.id,
                                                tmdbId: viewModel.saga.tmdbId,
                                                title: viewModel.saga.title,
                                                cover: viewModel.poster,
                                              ),
                                            );
                                      },
                                    ),
                                    loading: () => MoviFavoriteButton(
                                      isFavorite: true,
                                      onPressed: () {},
                                    ),
                                    error: (_, __) => MoviFavoriteButton(
                                      isFavorite: true,
                                      onPressed: () {},
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),
                    // Liste des films
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: horizontalPadding,
                        end: horizontalPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.sagaMoviesList,
                            style:
                                Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: Colors.white) ??
                                const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 16),
                          // Liste horizontale des films
                          Consumer(
                            builder: (context, ref, _) {
                              final availabilityAsync = ref.watch(
                                sagaMoviesAvailabilityProvider(sagaId),
                              );
                              return availabilityAsync.when(
                                data: (availability) {
                                  return SizedBox(
                                    height: MoviMediaCard.listHeight,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      padding: EdgeInsets.zero,
                                      itemCount: movies.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 16),
                                      itemBuilder: (context, index) {
                                        final movie = movies[index];
                                        final movieId = int.tryParse(movie.id);
                                        final isAvailable =
                                            movieId != null &&
                                            (availability[movieId] ?? false);
                                        return _SagaMovieCard(
                                          media: movie,
                                          isAvailable: isAvailable,
                                        );
                                      },
                                    ),
                                  );
                                },
                                loading: () => const SizedBox(
                                  height: MoviMediaCard.listHeight,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                error: (_, __) => SizedBox(
                                  height: MoviMediaCard.listHeight,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: EdgeInsets.zero,
                                    itemCount: movies.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 16),
                                    itemBuilder: (context, index) {
                                      final movie = movies[index];
                                      return MoviMediaCard(
                                        media: movie,
                                        heroTag: 'saga_movie_${movie.id}',
                                        onTap: (m) => context.push(
                                          AppRouteNames.movie,
                                          extra: m,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(
    BuildContext context, {
    required Uri? poster,
    required Uri? backdrop,
  }) {
    return MoviHeroBackground(
      posterBackground: poster?.toString(),
      poster: poster?.toString(),
      backdrop: backdrop?.toString(),
      placeholderType: PlaceholderType.movie,
      imageStrategy: MoviHeroImageStrategy.backdropFirst,
    );
  }

  Widget _buildHeroTopBar(
    BuildContext context, {
    required bool isWideLayout,
    required double horizontalPadding,
  }) {
    return MoviDetailHeroTopBar(
      isWideLayout: isWideLayout,
      horizontalPadding: horizontalPadding,
      leading: MoviDetailHeroActionButton(
        iconAsset: AppAssets.iconBack,
        semanticLabel: 'Retour',
        onPressed: () => context.pop(),
        isWideLayout: isWideLayout,
      ),
    );
  }

  Widget _buildDesktopHeroOverlay(
    BuildContext context,
    WidgetRef ref,
    SagaDetailViewModel viewModel,
    AsyncValue<String?> inProgressMovieAsync,
    AsyncValue<bool> isFavoriteAsync, {
    required String synopsisText,
  }) {
    return MoviDetailHeroDesktopOverlay(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            viewModel.saga.title.display,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ) ??
                const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.05,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MoviPill(
                AppLocalizations.of(
                  context,
                )!.sagaMovieCount(viewModel.movieCount),
                large: true,
              ),
              MoviPill(_formatDuration(viewModel.totalDuration), large: true),
            ],
          ),
          if (synopsisText.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 72,
              child: Text(
                synopsisText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style:
                    Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ) ??
                    const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 320,
                child: inProgressMovieAsync.when(
                  data: (inProgressMovieId) {
                    return MoviPrimaryButton(
                      label: inProgressMovieId != null
                          ? AppLocalizations.of(context)!.sagaContinue
                          : AppLocalizations.of(context)!.sagaStartNow,
                      assetIcon: AppAssets.iconPlay,
                      onPressed: () => _startSaga(context, ref, viewModel),
                    );
                  },
                  loading: () => MoviPrimaryButton(
                    label: AppLocalizations.of(context)!.sagaStartNow,
                    assetIcon: AppAssets.iconPlay,
                    onPressed: () {},
                  ),
                  error: (_, __) => MoviPrimaryButton(
                    label: AppLocalizations.of(context)!.sagaStartNow,
                    assetIcon: AppAssets.iconPlay,
                    onPressed: () => _startSaga(context, ref, viewModel),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 40,
                height: 40,
                child: isFavoriteAsync.when(
                  data: (isFavorite) => MoviFavoriteButton(
                    isFavorite: isFavorite,
                    onPressed: () async {
                      await ref
                          .read(sagaToggleFavoriteProvider.notifier)
                          .toggle(
                            sagaId,
                            SagaSummary(
                              id: viewModel.saga.id,
                              tmdbId: viewModel.saga.tmdbId,
                              title: viewModel.saga.title,
                              cover: viewModel.poster,
                            ),
                          );
                    },
                  ),
                  loading: () =>
                      MoviFavoriteButton(isFavorite: true, onPressed: () {}),
                  error: (_, __) =>
                      MoviFavoriteButton(isFavorite: true, onPressed: () {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SagaMovieCard extends ConsumerWidget {
  const _SagaMovieCard({required this.media, required this.isAvailable});

  final MoviMedia media;
  final bool isAvailable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Opacity(
      opacity: isAvailable ? 1.0 : 0.5,
      child: ColorFiltered(
        colorFilter: isAvailable
            ? const ColorFilter.mode(Colors.transparent, BlendMode.color)
            : const ColorFilter.matrix([
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0.2126,
                0.7152,
                0.0722,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
              ]),
        child: MoviMediaCard(
          media: media,
          heroTag: 'saga_movie_${media.id}',
          onTap: isAvailable
              ? (mm) => navigateToMovieDetail(
                  context,
                  ref,
                  ContentRouteArgs.movie(mm.id),
                )
              : null,
        ),
      ),
    );
  }
}

~~~

## lib/src/core/profile/presentation/ui/dialogs/create_profile_dialog.dart

- Absolute path: C:\Users\matte\Documents\DEV\Flutter\movi-app\lib\src\core\profile\presentation\ui\dialogs\create_profile_dialog.dart
- Size: 19633 bytes

~~~text
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/presentation/providers/profiles_providers.dart';
import 'package:movi/src/core/profile/presentation/ui/dialogs/restart_required_dialog.dart';
import 'package:movi/src/core/widgets/modal_content_width.dart';

/// Modal dialog pour crÃƒÆ’Ã‚Â©er un nouveau profil.
class CreateProfileDialog extends ConsumerStatefulWidget {
  const CreateProfileDialog({super.key});

  /// Affiche la modal et retourne true si un profil a ÃƒÆ’Ã‚Â©tÃƒÆ’Ã‚Â© crÃƒÆ’Ã‚Â©ÃƒÆ’Ã‚Â©.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const CreateProfileDialog(),
    );
    return result ?? false;
  }

  @override
  ConsumerState<CreateProfileDialog> createState() =>
      _CreateProfileDialogState();
}

class _CreateProfileDialogState extends ConsumerState<CreateProfileDialog> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _isKid = false;
  int _pegiLimit = 12;
  String? _pin;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createProfile() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = l10n.errorFillFields);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Utiliser la couleur accent du thème
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final color = accentColor.toARGB32();

    final Profile? created = await ref
        .read(profilesControllerProvider.notifier)
        .createProfile(name: name, color: color);

    if (!mounted) return;

    if (created == null) {
      setState(() {
        _isLoading = false;
        _error = l10n.errorUnknown;
      });
      return;
    }

    // If kid profile: require PIN + set restrictions.
    if (_isKid) {
      final pin = _pin?.trim();
      if (pin == null || !RegExp(r'^\d{4,6}$').hasMatch(pin)) {
        setState(() {
          _isLoading = false;
          _error = 'PIN requis (4-6 chiffres)';
        });
        return;
      }

      try {
        final pinSvc = ref.read(parental.profilePinEdgeServiceProvider);
        await pinSvc.setPin(profileId: created.id, pin: pin);

        final ok = await ref
            .read(profilesControllerProvider.notifier)
            .updateProfile(
              profileId: created.id,
              isKid: true,
              pegiLimit: _pegiLimit,
            );

        if (!ok) {
          // Keep invariant: no "kid profile" without proper config.
          await ref
              .read(profilesControllerProvider.notifier)
              .deleteProfile(created.id);
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _error = 'Impossible d\'appliquer le contrôle parental';
          });
          return;
        }

        await ref.read(profilesControllerProvider.notifier).refresh();
      } catch (e) {
        // Best-effort rollback: delete the profile if PIN setup fails.
        await ref
            .read(profilesControllerProvider.notifier)
            .deleteProfile(created.id);
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'Erreur PIN: $e';
        });
        return;
      }

      // Afficher la modal de redémarrage pour les profils enfants
      if (!mounted) return;
      final shouldRestart = await RestartRequiredDialog.show(context);
      if (shouldRestart) {
        // Le redémarrage est géré dans le dialog
        return;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    final bool canCreate =
        !_isLoading &&
        _nameController.text.trim().isNotEmpty &&
        (!_isKid ||
            (_pin != null && RegExp(r'^\d{4,6}$').hasMatch(_pin!.trim())));

    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ModalContentWidth(
        maxWidth: 560,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.settingsProfileInfoTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section Pseudo
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pseudo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    enabled: !_isLoading,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: l10n.hintUsername,
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section Profil enfant
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profil enfant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 6,
                        child: const Text(
                          'Oblige un PIN et active le filtre PEGI.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _isKid,
                        onChanged: _isLoading
                            ? null
                            : (v) {
                                setState(() {
                                  _isKid = v;
                                  if (!v) {
                                    _pin = null;
                                  } else {
                                    _pegiLimit = 12;
                                  }
                                });
                              },
                      ),
                    ],
                  ),
                ],
              ),

              if (_isKid) ...[
                const SizedBox(height: 24),
                // Section Limite d'âge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Limite d\'âge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      children: [3, 7, 12, 16, 18]
                          .map((v) {
                            final selected = _pegiLimit == v;
                            return ChoiceChip(
                              label: Text('PEGI $v'),
                              selected: selected,
                              onSelected: _isLoading
                                  ? null
                                  : (_) => setState(() => _pegiLimit = v),
                              selectedColor: accentColor,
                              backgroundColor: const Color(0xFF2C2C2E),
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : Colors.white70,
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Section Code pin
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Code pin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (!mounted) return;
                                final pin = await showDialog<String>(
                                  context: context,
                                  builder: (ctx) => const _PinPromptDialog(
                                    title: 'Définir un PIN',
                                    confirmLabel: 'Valider',
                                  ),
                                );
                                if (!mounted) return;
                                final trimmed = pin?.trim();
                                if (trimmed == null || trimmed.isEmpty) return;
                                setState(() => _pin = trimmed);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Définir code PIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 24),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ],

              const SizedBox(height: 24),

              // Section Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accentColor),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        l10n.actionCancel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canCreate ? _createProfile : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.actionConfirm,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinPromptDialog extends StatefulWidget {
  const _PinPromptDialog({required this.title, required this.confirmLabel});

  final String title;
  final String confirmLabel;

  @override
  State<_PinPromptDialog> createState() => _PinPromptDialogState();
}

class _PinPromptDialogState extends State<_PinPromptDialog> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ModalContentWidth(
        maxWidth: 420,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'PIN (4-6 chiffres)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accentColor),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(controller.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.confirmLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

~~~

## lib/src/core/profile/presentation/ui/dialogs/manage_profile_dialog.dart

- Absolute path: C:\Users\matte\Documents\DEV\Flutter\movi-app\lib\src\core\profile\presentation\ui\dialogs\manage_profile_dialog.dart
- Size: 32528 bytes

~~~text
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/domain/repositories/profile_repository.dart';
import 'package:movi/src/core/profile/presentation/providers/profiles_providers.dart';
import 'package:movi/src/core/widgets/modal_content_width.dart';

/// Dialog pour gÃƒÆ’Ã‚Â©rer un profil (rename / delete).
///
/// Clean rules respectÃƒÆ’Ã‚Â©es :
/// - UI dans `presentation/ui/dialogs/`
/// - Aucun import depuis `features/*`
/// - Utilise l'entity domain `Profile` (pas de "SupabaseProfile")
class ManageProfileDialog extends ConsumerStatefulWidget {
  const ManageProfileDialog({super.key, required this.profile});

  final Profile profile;

  static Future<void> show(
    BuildContext context, {
    required Profile profile,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ManageProfileDialog(profile: profile),
    );
  }

  @override
  ConsumerState<ManageProfileDialog> createState() =>
      _ManageProfileDialogState();
}

class _ManageProfileDialogState extends ConsumerState<ManageProfileDialog> {
  late final TextEditingController _nameController;
  late bool _isKid;
  int? _pegiLimit;
  late bool _hasPin;

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _isKid = widget.profile.isKid;
    _pegiLimit = widget.profile.pegiLimit;
    _hasPin = widget.profile.hasPin;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = l10n.errorFillFields);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final bool parentalChanged =
        _isKid != widget.profile.isKid ||
        _pegiLimit != widget.profile.pegiLimit;

    if (parentalChanged && _hasPin) {
      final ok = await _verifyPin();
      if (!ok) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = 'PIN incorrect';
        });
        return;
      }
    }

    final Object? pegiLimitArg = (_pegiLimit != widget.profile.pegiLimit)
        ? _pegiLimit
        : ProfileRepository.noChange;

    final ok = await ref
        .read(profilesControllerProvider.notifier)
        .updateProfile(
          profileId: widget.profile.id,
          name: name,
          isKid: _isKid != widget.profile.isKid ? _isKid : null,
          pegiLimit: pegiLimitArg,
        );

    if (!mounted) return;

    if (ok) {
      // Si on a modifié les paramètres parentaux, réinitialiser la session de déverrouillage
      if (parentalChanged) {
        try {
          final sessionSvc = ref.read(parental.parentalSessionServiceProvider);
          await sessionSvc.lock(widget.profile.id);
        } catch (_) {
          // Best-effort: ne pas bloquer la fermeture du dialog si ça échoue
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _error = l10n.errorUnknown;
      });
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: size.width - 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.playlistDeleteTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.playlistDeleteConfirm(widget.profile.name),
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(ctx).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          l10n.actionCancel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          l10n.delete,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    if (_hasPin) {
      final ok = await _verifyPin();
      if (!ok) {
        if (!mounted) return;
        setState(() => _error = 'PIN incorrect');
        return;
      }
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final ok = await ref
        .read(profilesControllerProvider.notifier)
        .deleteProfile(widget.profile.id);

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _error = l10n.errorUnknown;
      });
    }
  }

  Future<bool> _verifyPin({bool isDeleteAction = false}) async {
    if (!mounted) return false;

    final pin = await showDialog<String>(
      context: context,
      builder: (ctx) => _PinPromptDialog(
        title: 'Vérification PIN',
        confirmLabel: isDeleteAction ? 'Supprimer' : 'Vérifier',
        isDeleteAction: isDeleteAction,
      ),
    );
    final trimmed = pin?.trim();
    if (trimmed == null || trimmed.isEmpty) return false;

    try {
      final svc = ref.read(parental.profilePinEdgeServiceProvider);
      return await svc.verifyPin(profileId: widget.profile.id, pin: trimmed);
    } catch (_) {
      return false;
    }
  }

  Future<void> _setOrChangePin() async {
    if (_busy) return;

    if (_hasPin) {
      final ok = await _verifyPin();
      if (!ok) {
        if (!mounted) return;
        setState(() => _error = 'PIN incorrect');
        return;
      }
    }

    if (!mounted) return;
    final newPin = await showDialog<String>(
      context: context,
      builder: (ctx) => _PinPromptDialog(
        title: widget.profile.hasPin ? 'Nouveau PIN' : 'Définir un PIN',
        confirmLabel: 'Enregistrer',
      ),
    );
    final trimmed = newPin?.trim();
    if (trimmed == null || trimmed.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final svc = ref.read(parental.profilePinEdgeServiceProvider);
      await svc.setPin(profileId: widget.profile.id, pin: trimmed);
      await ref.read(profilesControllerProvider.notifier).refresh();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _hasPin = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Erreur: $e';
      });
    }
  }

  Future<void> _removePin() async {
    if (_busy || !_hasPin) return;

    final pin = await showDialog<String>(
      context: context,
      builder: (ctx) => const _RemovePinDialog(),
    );
    final trimmed = pin?.trim();
    if (trimmed == null || trimmed.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final svc = ref.read(parental.profilePinEdgeServiceProvider);
      final cleared = await svc.clearPin(
        profileId: widget.profile.id,
        pin: trimmed,
      );
      if (!cleared) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = 'PIN incorrect';
        });
        return;
      }
      await ref.read(profilesControllerProvider.notifier).refresh();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _hasPin = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Erreur: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ModalContentWidth(
        maxWidth: 560,
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.settingsProfileInfoTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section Pseudo
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pseudo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    enabled: !_busy,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: l10n.hintUsername,
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section Profil enfant
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profil enfant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 6,
                        child: const Text(
                          'Active le contrôle parental (PEGI + PIN).',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _isKid,
                        onChanged: _busy
                            ? null
                            : (v) {
                                setState(() {
                                  _isKid = v;
                                  if (!v) _pegiLimit = null;
                                  _error = null;
                                });
                              },
                      ),
                    ],
                  ),
                ],
              ),

              if (_isKid) ...[
                const SizedBox(height: 24),
                // Section Limite d'âge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Limite d\'âge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      children: [3, 7, 12, 16, 18]
                          .map((v) {
                            final selected = _pegiLimit == v;
                            return ChoiceChip(
                              label: Text('PEGI $v'),
                              selected: selected,
                              onSelected: _busy
                                  ? null
                                  : (_) => setState(() {
                                      _pegiLimit = v;
                                      _error = null;
                                    }),
                              selectedColor: accentColor,
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : Colors.white70,
                              ),
                              backgroundColor: const Color(0xFF2C2C2E),
                            );
                          })
                          .toList(growable: false),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Section Code pin
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Code pin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_hasPin) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _setOrChangePin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Définir code PIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _busy ? null : _setOrChangePin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Changer le code PIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: (_busy || !_hasPin) ? null : _removePin,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Supprimer le code PIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              if (_error != null) ...[
                const SizedBox(height: 24),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ],

              const SizedBox(height: 24),

              // Section Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : _delete,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        l10n.delete,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.actionConfirm,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinPromptDialog extends StatefulWidget {
  const _PinPromptDialog({
    required this.title,
    required this.confirmLabel,
    this.isDeleteAction = false,
  });

  final String title;
  final String confirmLabel;
  final bool isDeleteAction;

  @override
  State<_PinPromptDialog> createState() => _PinPromptDialogState();
}

class _PinPromptDialogState extends State<_PinPromptDialog> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ModalContentWidth(
        maxWidth: 420,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'PIN (4-6 chiffres)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: widget.isDeleteAction
                        ? ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(null),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Annuler',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(null),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: accentColor),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Annuler',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: widget.isDeleteAction
                        ? OutlinedButton(
                            onPressed: () =>
                                Navigator.of(context).pop(controller.text),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              widget.confirmLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () =>
                                Navigator.of(context).pop(controller.text),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              widget.confirmLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemovePinDialog extends StatefulWidget {
  const _RemovePinDialog();

  @override
  State<_RemovePinDialog> createState() => _RemovePinDialogState();
}

class _RemovePinDialogState extends State<_RemovePinDialog> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ModalContentWidth(
        maxWidth: 420,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Supprimer le PIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'PIN (4-6 chiffres)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accentColor),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(controller.text),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Supprimer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

~~~

## lib/src/core/parental/presentation/providers/parental_providers.dart

- Absolute path: C:\Users\matte\Documents\DEV\Flutter\movi-app\lib\src\core\parental\presentation\providers\parental_providers.dart
- Size: 3372 bytes

~~~text
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/parental/application/services/child_profile_rating_preload_service.dart';
import 'package:movi/src/core/parental/data/repositories/iptv_parental_content_candidate_repository.dart';
import 'package:movi/src/core/parental/data/services/content_rating_repository_warmup_gateway.dart';
import 'package:movi/src/core/parental/data/services/noop_content_metadata_resolvers.dart';
import 'package:movi/src/core/parental/domain/repositories/content_rating_repository.dart';
import 'package:movi/src/core/parental/domain/repositories/parental_content_candidate_repository.dart';
import 'package:movi/src/core/parental/domain/services/age_policy.dart';
import 'package:movi/src/core/parental/domain/services/content_rating_warmup_gateway.dart';
import 'package:movi/src/core/parental/domain/services/movie_metadata_resolver.dart';
import 'package:movi/src/core/parental/domain/services/series_metadata_resolver.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/storage/storage.dart';

final contentRatingRepositoryProvider = Provider<ContentRatingRepository>((
  ref,
) {
  return ref.watch(slProvider)<ContentRatingRepository>();
});

final agePolicyProvider = Provider<AgePolicy>((ref) {
  return ref.watch(slProvider)<AgePolicy>();
});

final childProfileRatingPreloadServiceProvider =
    Provider<ChildProfileRatingPreloadService>((ref) {
      final sl = ref.watch(slProvider);
      final ratingRepository = ref.watch(contentRatingRepositoryProvider);

      final candidateRepository =
          sl.isRegistered<ParentalContentCandidateRepository>()
          ? sl<ParentalContentCandidateRepository>()
          : IptvParentalContentCandidateRepository(sl<IptvLocalRepository>());

      final movieMetadataResolver = sl.isRegistered<MovieMetadataResolver>()
          ? sl<MovieMetadataResolver>()
          : const NoopMovieMetadataResolver();

      final seriesMetadataResolver = sl.isRegistered<SeriesMetadataResolver>()
          ? sl<SeriesMetadataResolver>()
          : const NoopSeriesMetadataResolver();

      final languageCode = ref.watch(currentLanguageCodeProvider);
      final preferredRegions = _preferredRegionsForLanguage(languageCode);

      final ratingWarmupGateway = sl.isRegistered<ContentRatingWarmupGateway>()
          ? sl<ContentRatingWarmupGateway>()
          : ContentRatingRepositoryWarmupGateway(
              ratingRepository,
              preferredRegions: preferredRegions,
            );

      return ChildProfileRatingPreloadService(
        candidateRepository: candidateRepository,
        movieMetadataResolver: movieMetadataResolver,
        seriesMetadataResolver: seriesMetadataResolver,
        ratingWarmupGateway: ratingWarmupGateway,
      );
    });

List<String> _preferredRegionsForLanguage(String languageCode) {
  final normalized = languageCode.trim().toLowerCase();

  switch (normalized) {
    case 'nl':
    case 'nl-be':
    case 'nl-nl':
      return const <String>['BE', 'NL', 'US'];
    case 'fr':
    case 'fr-be':
    case 'fr-fr':
      return const <String>['BE', 'FR', 'US'];
    default:
      return const <String>['BE', 'FR', 'US'];
  }
}

~~~

## lib/src/core/parental/presentation/providers/parental_access_providers.dart

- Absolute path: C:\Users\matte\Documents\DEV\Flutter\movi-app\lib\src\core\parental\presentation\providers\parental_access_providers.dart
- Size: 2187 bytes

~~~text
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/parental/application/services/parental_session_service.dart';
import 'package:movi/src/core/parental/data/services/profile_pin_edge_service.dart';
import 'package:movi/src/core/parental/domain/entities/age_decision.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/core/parental/presentation/providers/parental_providers.dart';

final parentalSessionServiceProvider = Provider<ParentalSessionService>((ref) {
  return ref.watch(slProvider)<ParentalSessionService>();
});

final profilePinEdgeServiceProvider = Provider<ProfilePinEdgeService>((ref) {
  return ref.watch(slProvider)<ProfilePinEdgeService>();
});

/// Computes the age decision for a given content for the current selected profile.
///
/// If an unlock session is active for the profile, this returns allowed.
final contentAgeDecisionProvider =
    FutureProvider.family<AgeDecision, ContentReference>((ref, content) async {
      // Only guard TMDB IDs.
      if (content.type != ContentType.movie &&
          content.type != ContentType.series) {
        return AgeDecision.allowed(reason: 'non_media_type');
      }

      final Profile? profile = ref.watch(currentProfileProvider);
      if (profile == null) {
        return AgeDecision.allowed(reason: 'no_profile');
      }

      final sessionSvc = ref.read(parentalSessionServiceProvider);
      if (await sessionSvc.isUnlocked(profile.id)) {
        return AgeDecision.allowed(reason: 'unlocked_session');
      }

      final policy = ref.read(agePolicyProvider);
      return policy.evaluate(content, profile);
    });

ContentReference contentRefFromId({
  required ContentType type,
  required String id,
}) {
  return ContentReference(id: id, type: type, title: MediaTitle(id));
}

~~~

