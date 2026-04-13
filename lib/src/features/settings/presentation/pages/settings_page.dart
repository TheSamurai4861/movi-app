// lib/src/features/settings/presentation/pages/settings_page.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/directional_edge.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/domain/focus_region_exit_map.dart';
import 'package:movi/src/core/focus/presentation/focus_directional_navigation.dart';
import 'package:movi/src/core/focus/presentation/focus_orchestrator_provider.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/parental/presentation/widgets/restricted_content_sheet.dart';
import 'package:movi/src/core/preferences/accent_color_preferences.dart';
import 'package:movi/src/core/preferences/iptv_sync_preferences.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/preferences/player_preferences.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/core/profile/presentation/providers/profile_auth_providers.dart';
import 'package:movi/src/core/profile/presentation/providers/profiles_providers.dart';
import 'package:movi/src/core/profile/presentation/providers/selected_profile_providers.dart';
import 'package:movi/src/core/profile/presentation/ui/dialogs/create_profile_dialog.dart';
import 'package:movi/src/core/profile/presentation/ui/dialogs/manage_profile_dialog.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';
import 'package:movi/src/core/router/app_route_paths.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/subscription/domain/entities/premium_feature.dart';
import 'package:movi/src/core/subscription/presentation/providers/subscription_providers.dart';
import 'package:movi/src/core/supabase/supabase_providers.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/core/widgets/movi_tv_action_menu.dart';
import 'package:movi/src/features/iptv/application/services/xtream_sync_service.dart';
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
import 'package:movi/src/features/player/domain/value_objects/preferred_playback_quality.dart';
import 'package:movi/src/features/player/domain/utils/language_formatter.dart';
import 'package:movi/src/features/shell/presentation/layouts/app_shell_mobile_layout.dart';
import 'package:movi/src/features/settings/presentation/widgets/movi_premium_settings_tile.dart';
import 'package:movi/src/features/settings/presentation/widgets/premium_feature_locked_sheet.dart';
import 'package:movi/src/features/settings/presentation/widgets/export_diagnostics_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

/// SettingsPage (content-only): pas de Scaffold ici.
/// Le Shell (Home layout) gère le Scaffold/SafeArea/Bottombar.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const double _settingsFocusVerticalAlignment = 0.22;
  static final Uri _privacyPolicyUrl = Uri.parse(
    'https://thesamurai4861.github.io/movi-privacy/privacy.html',
  );
  static final Uri _termsOfUseUrl = Uri.parse(
    'https://thesamurai4861.github.io/movi-privacy/terms.html',
  );

  bool _unlocking = false;
  bool _wasUnlockedForSettings = false;
  String? _unlockedProfileId;
  ProviderSubscription<SupabaseAuthStatus>? _authStatusSub;
  final _firstProfileFocusNode = FocusNode(debugLabel: 'SettingsFirstProfile');
  final _addProfileFocusNode = FocusNode(debugLabel: 'SettingsAddProfile');
  final _premiumTileFocusNode = FocusNode(debugLabel: 'SettingsPremiumTile');
  final _languageSelectorFocusNode = FocusNode(
    debugLabel: 'SettingsLanguageSelector',
  );
  final _cloudSyncAutoFocusNode = FocusNode(
    debugLabel: 'SettingsCloudSyncAuto',
  );
  late List<FocusNode> _profileFocusNodes;

  static const Map<String, String> _languageNativeNames = {
    'ar': 'العربية',
    'de': 'Deutsch',
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'it': 'Italiano',
    'ja': '日本語',
    'ko': '한국어',
    'nl': 'Nederlands',
    'pl': 'Polski',
    'pt': 'Português',
    'ru': 'Русский',
    'tr': 'Türkçe',
    'uk': 'Українська',
    'zh': '中文',
  };

  static List<(String code, String label)> _availableLanguages() {
    final out = <(String, String)>[];
    final seen = <String>{};

    for (final locale in AppLocalizations.supportedLocales) {
      final lang = locale.languageCode.toLowerCase();
      if (seen.contains(lang)) continue;
      seen.add(lang);
      out.add((lang, _languageNativeNames[lang] ?? lang.toUpperCase()));
    }

    out.sort((a, b) => a.$2.compareTo(b.$2));
    return out;
  }

  Future<void> _showCupertinoLanguageSelector(
    BuildContext context,
    String currentCode,
  ) async {
    final localePrefs = ref.read(slProvider)<LocalePreferences>();
    final l10n = AppLocalizations.of(context)!;
    final items = _availableLanguages();
    final currentLang = currentCode.toLowerCase().split('-').first;
    final initialIndex = items.indexWhere(
      (e) => e.$1.toLowerCase().split('-').first == currentLang,
    );
    var pickedIndex = initialIndex >= 0 ? initialIndex : 0;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.settingsLanguageLabel),
        actions: [
          SizedBox(
            height: 44.0 * 5,
            child: CupertinoPicker(
              itemExtent: 44,
              scrollController: FixedExtentScrollController(
                initialItem: pickedIndex,
              ),
              onSelectedItemChanged: (i) => pickedIndex = i,
              children: [
                for (final (_, label) in items) Center(child: Text(label)),
              ],
            ),
          ),
        ],
        cancelButton: Row(
          children: [
            Expanded(
              child: CupertinoActionSheetAction(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  l10n.actionCancel,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            Expanded(
              child: CupertinoActionSheetAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  final code = items[pickedIndex].$1;
                  unawaited(() async {
                    await localePrefs.setLanguageCode(code);
                    _lockSessionIfUnlocked();
                  }());
                },
                child: const Text('OK', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTvLanguageSelector(
    BuildContext context,
    String currentCode,
  ) async {
    final localePrefs = ref.read(slProvider)<LocalePreferences>();
    final l10n = AppLocalizations.of(context)!;
    final items = _availableLanguages();
    final currentLang = currentCode.toLowerCase().split('-').first;

    await showMoviTvActionMenu(
      context: context,
      title: l10n.settingsLanguageLabel,
      focusScale: 1,
      focusVerticalAlignment: 0.22,
      actions: items
          .map(
            (entry) => MoviTvActionMenuAction(
              label:
                  '${entry.$1.toLowerCase().split('-').first == currentLang ? '✓ ' : ''}${entry.$2}',
              onPressed: () {
                _guard(() => localePrefs.setLanguageCode(entry.$1));
              },
            ),
          )
          .toList(growable: false),
      cancelLabel: l10n.actionCancel,
    );
  }

  bool _useSettingsActionMenuLayout(BuildContext context) {
    final screenType = _screenTypeFor(context);
    return screenType == ScreenType.desktop || screenType == ScreenType.tv;
  }

  Future<void> _openExternalLink(Uri url) async {
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (ok) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.settingsUnableToOpenLink),
      ),
    );
  }

  static const List<Duration?> _syncIntervalOptions = [
    null,
    Duration(minutes: 60),
    Duration(minutes: 120),
    Duration(minutes: 240),
    Duration(minutes: 360),
    Duration(minutes: 1440),
    Duration(minutes: 2880),
  ];

  static const List<Color> _accentColorOptions = [
    Color(0xFF2160AB),
    Color(0xFFF48FB1),
    Color(0xFF81C784),
    Color(0xFFBA68C8),
    Color(0xFFFFB74D),
    Color(0xFF4DB6AC),
    Color(0xFFFFE082),
    Color(0xFF7986CB),
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
    _profileFocusNodes = <FocusNode>[_firstProfileFocusNode];

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
    _disposeOwnedProfileFocusNodes();
    _firstProfileFocusNode.dispose();
    _addProfileFocusNode.dispose();
    _premiumTileFocusNode.dispose();
    _languageSelectorFocusNode.dispose();
    _cloudSyncAutoFocusNode.dispose();
    _lockSessionIfUnlocked();
    super.dispose();
  }

  void _syncProfileFocusNodes(int profileCount) {
    if (_profileFocusNodes.length == profileCount) return;
    if (_profileFocusNodes.isEmpty && profileCount > 0) {
      _profileFocusNodes.add(_firstProfileFocusNode);
    }
    while (_profileFocusNodes.length < profileCount) {
      final index = _profileFocusNodes.length;
      _profileFocusNodes.add(
        index == 0
            ? _firstProfileFocusNode
            : FocusNode(debugLabel: 'SettingsProfile-$index'),
      );
    }
    while (_profileFocusNodes.length > profileCount) {
      final removed = _profileFocusNodes.removeLast();
      if (!identical(removed, _firstProfileFocusNode)) {
        removed.dispose();
      }
    }
  }

  void _disposeOwnedProfileFocusNodes() {
    for (final node in _profileFocusNodes) {
      if (!identical(node, _firstProfileFocusNode)) {
        node.dispose();
      }
    }
    _profileFocusNodes.clear();
  }

  // -------------------- Parental guard --------------------

  Future<bool> _ensureSettingsUnlocked({FocusNode? triggerFocusNode}) async {
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
        triggerFocusNode: triggerFocusNode,
        originRegionId: AppFocusRegionId.settingsPrimary,
        fallbackRegionId: AppFocusRegionId.settingsPrimary,
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

  Future<bool> _ensureProfileUnlocked(
    Profile profile, {
    FocusNode? triggerFocusNode,
  }) async {
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
        triggerFocusNode: triggerFocusNode,
        originRegionId: AppFocusRegionId.settingsPrimary,
        fallbackRegionId: AppFocusRegionId.settingsPrimary,
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

  bool _isCurrentLanguage(String currentCode, String code) {
    final current = currentCode.toLowerCase();
    final option = code.toLowerCase();
    return current.split('-').first == option.split('-').first;
  }

  String _formatSyncInterval(Duration interval) {
    final l10n = AppLocalizations.of(context)!;
    if (interval.inDays >= 365) return l10n.settingsSyncDisabled;

    final minutes = interval.inMinutes;
    if (minutes == 60) return l10n.settingsSyncEveryHour;
    if (minutes == 120) return l10n.settingsSyncEvery2Hours;
    if (minutes == 240) return l10n.settingsSyncEvery4Hours;
    if (minutes == 360) return l10n.settingsSyncEvery6Hours;
    if (minutes == 1440) return l10n.settingsSyncEveryDay;
    if (minutes == 2880) return l10n.settingsSyncEvery2Days;
    return '${interval.inHours}h';
  }

  bool _isCurrentSyncInterval(Duration current, Duration? option) {
    if (option == null) return current.inDays >= 365;
    if (current.inDays >= 365) return false;
    return current.inMinutes == option.inMinutes;
  }

  String _getAccentColorName(Color color) {
    final l10n = AppLocalizations.of(context)!;
    // ignore: deprecated_member_use
    final v = color.value;
    // ignore: deprecated_member_use
    if (v == const Color(0xFF2160AB).value) return l10n.settingsColorBlue;
    // ignore: deprecated_member_use
    if (v == const Color(0xFFF48FB1).value) return l10n.settingsColorPink;
    // ignore: deprecated_member_use
    if (v == const Color(0xFF81C784).value) return l10n.settingsColorGreen;
    // ignore: deprecated_member_use
    if (v == const Color(0xFFBA68C8).value) return l10n.settingsColorPurple;
    // ignore: deprecated_member_use
    if (v == const Color(0xFFFFB74D).value) return l10n.settingsColorOrange;
    // ignore: deprecated_member_use
    if (v == const Color(0xFF4DB6AC).value) return l10n.settingsColorTurquoise;
    // ignore: deprecated_member_use
    if (v == const Color(0xFFFFE082).value) return l10n.settingsColorYellow;
    // ignore: deprecated_member_use
    if (v == const Color(0xFF7986CB).value) return l10n.settingsColorIndigo;
    return l10n.settingsColorCustom;
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

  Future<void> _showSyncIntervalSelector(
    BuildContext context,
    Duration currentInterval,
  ) async {
    final iptvSyncPrefs = ref.read(slProvider)<IptvSyncPreferences>();
    final syncService = ref.read(slProvider)<XtreamSyncService>();
    final accentColor = ref.read(asp.currentAccentColorProvider);
    final l10n = AppLocalizations.of(context)!;

    if (_useSettingsActionMenuLayout(context)) {
      await showMoviTvActionMenu(
        context: context,
        title: l10n.settingsSyncFrequency,
        focusScale: 1,
        actions: _syncIntervalOptions
            .map(
              (interval) => MoviTvActionMenuAction(
                label:
                    '${_isCurrentSyncInterval(currentInterval, interval) ? '✓ ' : ''}'
                    '${interval == null ? l10n.settingsSyncDisabled : _formatSyncInterval(interval)}',
                onPressed: () {
                  _guard(() async {
                    if (interval == null) {
                      const disabled = Duration(days: 365);
                      await iptvSyncPrefs.setSyncInterval(disabled);
                      syncService.setInterval(disabled);
                    } else {
                      await iptvSyncPrefs.setSyncInterval(interval);
                      syncService.setInterval(interval);
                    }
                    _lockSessionIfUnlocked();
                  });
                },
              ),
            )
            .toList(growable: false),
        cancelLabel: l10n.actionCancel,
      );
      return;
    }

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.settingsSyncFrequency),
        actions: [
          for (final interval in _syncIntervalOptions)
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
                    interval == null
                        ? l10n.settingsSyncDisabled
                        : _formatSyncInterval(interval),
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

    if (_useSettingsActionMenuLayout(context)) {
      await showMoviTvActionMenu(
        context: context,
        title: l10n.settingsAccentColor,
        focusScale: 1,
        actions: _accentColorOptions
            .map(
              (color) => MoviTvActionMenuAction(
                leadingColor: color,
                label:
                    '${_isCurrentAccentColor(currentColor, color) ? '✓ ' : ''}'
                    '${_getAccentColorName(color)}',
                onPressed: () {
                  _guard(() async {
                    await accentColorPrefs.setAccentColor(color);
                    ref.invalidate(asp.accentColorStreamProvider);
                    ref.invalidate(asp.currentAccentColorProvider);
                    _lockSessionIfUnlocked();
                  });
                },
              ),
            )
            .toList(growable: false),
        cancelLabel: l10n.actionCancel,
      );
      return;
    }

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.settingsAccentColor),
        actions: [
          for (final color in _accentColorOptions)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                unawaited(() async {
                  await accentColorPrefs.setAccentColor(color);
                  ref.invalidate(asp.accentColorStreamProvider);
                  ref.invalidate(asp.currentAccentColorProvider);
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
                          _getAccentColorName(color),
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
    final l10n = AppLocalizations.of(context)!;
    await _showPlaybackLanguageSelector(
      context: context,
      title: l10n.settingsPreferredAudioLanguage,
      currentCode: currentCode,
      nullOptionLabel: l10n.settingsAutomaticOption,
      onSelected: prefs.setPreferredAudioLanguage,
    );
  }

  Future<void> _showPreferredSubtitleLanguageSelector(
    BuildContext context,
    String? currentCode,
  ) async {
    final prefs = ref.read(slProvider)<PlayerPreferences>();
    final l10n = AppLocalizations.of(context)!;
    await _showPlaybackLanguageSelector(
      context: context,
      title: l10n.settingsPreferredSubtitleLanguage,
      currentCode: currentCode,
      nullOptionLabel: l10n.settingsSyncDisabled,
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

  // -------------------- UI parts --------------------

  ScreenType _screenTypeFor(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ScreenTypeResolver.instance.resolve(size.width, size.height);
  }

  bool _focusSidebarFromRegionExit() {
    return ref
        .read(focusOrchestratorProvider)
        .resolveExit(AppFocusRegionId.settingsPrimary, DirectionalEdge.left);
  }

  KeyEventResult _handleSettingsHorizontalBoundary(
    KeyEvent event, {
    bool blockDown = false,
  }) {
    if (blockDown &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.handled;
    }

    return FocusDirectionalNavigation.handleDirectionalTransition(
      event,
      onLeft: _focusSidebarFromRegionExit,
      blockRight: true,
      blockDown: blockDown,
    );
  }

  bool _focusProfileNodeAt(int index) {
    if (index < 0 || index >= _profileFocusNodes.length) {
      return false;
    }
    return FocusDirectionalNavigation.requestFocus(_profileFocusNodes[index]);
  }

  KeyEventResult _handleProfileKey({
    required KeyEvent event,
    required int index,
    required int profileCount,
    VoidCallback? onLongPress,
  }) {
    final isLongPressKey =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA;

    if (event is KeyRepeatEvent && isLongPressKey && onLongPress != null) {
      onLongPress();
      return KeyEventResult.handled;
    }

    return FocusDirectionalNavigation.handleDirectionalTransition(
      event,
      onLeft: () => index == 0 ? _focusSidebarFromRegionExit() : _focusProfileNodeAt(index - 1),
      onRight: () => index + 1 < profileCount
          ? _focusProfileNodeAt(index + 1)
          : FocusDirectionalNavigation.requestFocus(_addProfileFocusNode),
      blockUp: true,
      blockDown: false,
    );
  }

  KeyEventResult _handleAddProfileKey({
    required KeyEvent event,
    required int profileCount,
  }) {
    return FocusDirectionalNavigation.handleDirectionalKey(
      event,
      left: profileCount > 0 ? _profileFocusNodes[profileCount - 1] : _firstProfileFocusNode,
      blockUp: true,
      blockRight: true,
      blockDown: false,
    );
  }

  KeyEventResult _handlePremiumTileKey(KeyEvent event) {
    final directionalResult = FocusDirectionalNavigation.handleDirectionalKey(
      event,
      up: _firstProfileFocusNode,
      blockLeft: false,
      blockRight: false,
      blockDown: false,
    );
    if (directionalResult != KeyEventResult.ignored) {
      return directionalResult;
    }
    return _handleSettingsHorizontalBoundary(event);
  }

  Widget _buildSettingItem({
    required String title,
    String? value,
    Color? valueColor,
    VoidCallback? onTap,
    Widget? trailing,
    bool showChevronDown = false,
    bool blockArrowDown = false,
  }) {
    final accentColor = ref.watch(asp.currentAccentColorProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxValueWidth = screenWidth < 420 ? 112.0 : 168.0;

    return MoviEnsureVisibleOnFocus(
      verticalAlignment: _settingsFocusVerticalAlignment,
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (_, event) =>
            _handleSettingsHorizontalBoundary(event, blockDown: blockArrowDown),
        child: InkWell(
          onTap: onTap,
          focusColor: accentColor.withValues(alpha: 0.18),
          hoverColor: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          child: ClipRect(
            clipBehavior: Clip.none,
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
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: accentColor,
                      size: 20,
                    ),
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
                Focus(
                  canRequestFocus: false,
                  onKeyEvent: (_, event) => _handleProfileKey(
                    event: event,
                    index: 0,
                    profileCount: 1,
                    onLongPress: () => _guard(
                      () => ref
                          .read(profilesControllerProvider.notifier)
                          .refresh(),
                    ),
                  ),
                  child: _buildProfileCircle(
                    name: l10n.errorUnknown,
                    color: const Color.fromARGB(20, 255, 255, 255),
                    icon: AppAssets.iconDelete,
                    focusNode: _firstProfileFocusNode,
                    onTap: () => _guard(
                      () => ref
                          .read(profilesControllerProvider.notifier)
                          .refresh(),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Focus(
                  canRequestFocus: false,
                  onKeyEvent: (_, event) =>
                      _handleAddProfileKey(event: event, profileCount: 1),
                  child: _buildProfileCircle(
                    name: l10n.playlistAddButton,
                    color: const Color.fromARGB(20, 255, 255, 255),
                    icon: AppAssets.iconPlus,
                    focusNode: _addProfileFocusNode,
                    onTap: () => _onAddProfile(
                      triggerFocusNode: _addProfileFocusNode,
                    ),
                  ),
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
      data: (profiles) {
        _syncProfileFocusNodes(profiles.length);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < profiles.length; index++)
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Focus(
                    canRequestFocus: false,
                    onKeyEvent: (_, event) => _handleProfileKey(
                      event: event,
                      index: index,
                      profileCount: profiles.length,
                      onLongPress: () =>
                          unawaited(
                            _onManageProfile(
                              profiles[index],
                              triggerFocusNode: _profileFocusNodes[index],
                            ),
                          ),
                    ),
                    child: _buildProfileCircle(
                      name: profiles[index].name,
                      color: Theme.of(context).colorScheme.primary,
                      icon: AppAssets.iconUser,
                      isSelected: profiles[index].id == selectedProfileId,
                      focusNode: _profileFocusNodes[index],
                      onTap: () => unawaited(_onSelectProfile(profiles[index])),
                      onLongPress: () =>
                          unawaited(
                            _onManageProfile(
                              profiles[index],
                              triggerFocusNode: _profileFocusNodes[index],
                            ),
                          ),
                    ),
                  ),
                ),
              Focus(
                canRequestFocus: false,
                onKeyEvent: (_, event) => _handleAddProfileKey(
                  event: event,
                  profileCount: profiles.length,
                ),
                child: _buildProfileCircle(
                  name: l10n.playlistAddButton,
                  color: const Color.fromARGB(20, 255, 255, 255),
                  icon: AppAssets.iconPlus,
                  focusNode: _addProfileFocusNode,
                  onTap: () => _onAddProfile(
                    triggerFocusNode: _addProfileFocusNode,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
          : AppLocalizations.of(context)!.settingsAccountConnected;
      accountValueColor = ref.watch(asp.currentAccentColorProvider);
    } else if (client != null) {
      accountValue = AppLocalizations.of(context)!.settingsAccountLocalMode;
      accountValueColor = Colors.white70;
    } else {
      accountValue = AppLocalizations.of(
        context,
      )!.settingsAccountCloudUnavailable;
      accountValueColor = theme.colorScheme.error;
    }

    return _buildSettingsGroup([
      _buildSettingItem(
        title: AppLocalizations.of(context)!.settingsCloudAccountTitle,
        value: accountValue,
        valueColor: accountValueColor,
        blockArrowDown: !hasCloudSession && !(client != null),
      ),
      if (!hasCloudSession && client != null)
        _buildSettingItem(
          title: AppLocalizations.of(context)!.authOtpPrimarySubmit,
          onTap: () => _guard(
            () => context.push('${AppRoutePaths.authOtp}?return_to=previous'),
          ),
          blockArrowDown: true,
        ),
      SizedBox(height: 8),
      if (hasCloudSession) _buildSignOutButton(context, blockArrowDown: true),
    ]);
  }

  // ignore: unused_element
  Widget _buildPlaybackSettingsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
        title: l10n.settingsPreferredAudioLanguage,
        value: preferredAudioLanguage == null
            ? l10n.settingsAutomaticOption
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
        title: l10n.settingsPreferredSubtitleLanguage,
        value: preferredSubtitleLanguage == null
            ? l10n.settingsSyncDisabled
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
        title: l10n.settingsPreferredPlaybackQuality,
        value: preferredPlaybackQuality == null
            ? l10n.settingsAutomaticOption
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
    required String icon,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    FocusNode? focusNode,
    bool isSelected = false,
    KeyEventResult Function(KeyEvent event)? onKeyEvent,
  }) {
    return Focus(
      canRequestFocus: false,
      onKeyEvent: onKeyEvent == null ? null : (_, event) => onKeyEvent(event),
      child: MoviEnsureVisibleOnFocus(
        verticalAlignment: _settingsFocusVerticalAlignment,
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
                    child: Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: SvgPicture.asset(
                          icon,
                          fit: BoxFit.contain,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<bool> _ensurePremiumFeature(
    PremiumFeature feature, {
    FocusNode? triggerFocusNode,
  }) async {
    final hasPremium = await ref.read(
      canAccessPremiumFeatureProvider(feature).future,
    );

    if (hasPremium) {
      return true;
    }

    if (!mounted) {
      return false;
    }

    await showPremiumFeatureLockedSheet(
      context,
      triggerFocusNode: triggerFocusNode,
      originRegionId: AppFocusRegionId.settingsPrimary,
      fallbackRegionId: AppFocusRegionId.settingsPrimary,
    );
    return false;
  }

  Future<void> _onAddProfile({FocusNode? triggerFocusNode}) async {
    final hasPremium = await _ensurePremiumFeature(
      PremiumFeature.localProfiles,
      triggerFocusNode: triggerFocusNode ?? _addProfileFocusNode,
    );
    if (!hasPremium) return;

    final ok = await _ensureSettingsUnlocked(
      triggerFocusNode: triggerFocusNode,
    );
    if (!ok || !mounted) return;
    await CreateProfileDialog.show(
      context,
      triggerFocusNode: triggerFocusNode ?? _addProfileFocusNode,
    );
    _lockSessionIfUnlocked();
  }

  Future<void> _onSelectProfile(Profile profile) async {
    final currentSelectedId = ref.read(selectedProfileIdProvider);
    final isChangingProfile =
        currentSelectedId != null &&
        currentSelectedId.isNotEmpty &&
        currentSelectedId != profile.id;
    if (isChangingProfile) {
      final hasPremium = await _ensurePremiumFeature(
        PremiumFeature.localProfiles,
        triggerFocusNode: _profileFocusNodes.firstWhere(
          (node) => node.hasFocus,
          orElse: () => _firstProfileFocusNode,
        ),
      );
      if (!hasPremium) return;
    }

    final isTargetChild = profile.isKid || profile.pegiLimit != null;

    if (isTargetChild) {
      final ok = await _ensureProfileUnlocked(
        profile,
        triggerFocusNode: _profileFocusNodes.firstWhere(
          (node) => node.hasFocus,
          orElse: () => _firstProfileFocusNode,
        ),
      );
      if (!ok) return;
    } else {
      final ok = await _ensureSettingsUnlocked(
        triggerFocusNode: _profileFocusNodes.firstWhere(
          (node) => node.hasFocus,
          orElse: () => _firstProfileFocusNode,
        ),
      );
      if (!ok) return;
    }

    await ref
        .read(profilesControllerProvider.notifier)
        .selectProfile(profile.id);
    _lockSessionIfUnlocked();
  }

  Future<void> _onManageProfile(
    Profile profile, {
    FocusNode? triggerFocusNode,
  }) async {
    final hasPremium = await _ensurePremiumFeature(
      PremiumFeature.localProfiles,
      triggerFocusNode: triggerFocusNode,
    );
    if (!hasPremium) return;

    final ok = await _ensureSettingsUnlocked(
      triggerFocusNode: triggerFocusNode,
    );
    if (!ok || !mounted) return;
    await ManageProfileDialog.show(
      context,
      profile: profile,
      triggerFocusNode: triggerFocusNode,
    );
    _lockSessionIfUnlocked();
  }

  Widget _buildSignOutButton(
    BuildContext context, {
    bool blockArrowDown = false,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return MoviEnsureVisibleOnFocus(
      verticalAlignment: _settingsFocusVerticalAlignment,
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (_, event) =>
            _handleSettingsHorizontalBoundary(event, blockDown: blockArrowDown),
        child: OutlinedButton(
          onPressed: () => _guard(() async {
            final confirmed = await showCupertinoDialog<bool>(
              context: context,
              builder: (ctx) => CupertinoAlertDialog(
                title: Text(l10n.actionSignOut),
                content: Text(l10n.dialogSignOutBody),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(l10n.actionCancel),
                  ),
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(l10n.actionSignOut),
                  ),
                ],
              ),
            );

            if (confirmed != true) return;
            if (!mounted) return;

            // Capture context before async gap
            final navigatorContext = context;

            try {
              await ref.read(authControllerProvider.notifier).signOut();

              if (!mounted) return;
              // ✅ utilise un path existant (pas AppRouteNames.about)
              navigatorContext.go(AppRoutePaths.authOtp);
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(navigatorContext).showSnackBar(
                SnackBar(
                  content: Text(l10n.settingsSignOutError(e.toString())),
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
                  l10n.actionSignOut,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------- Build --------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final currentLangCode = ref.watch(asp.currentLanguageCodeProvider);
    final currentSyncInterval = ref.watch(asp.currentIptvSyncIntervalProvider);
    final currentAccentColor = ref.watch(asp.currentAccentColorProvider);
    final isTvLayout = _screenTypeFor(context) == ScreenType.tv;
    final hasCloudSyncPremium = ref
        .watch(canAccessPremiumFeatureProvider(PremiumFeature.cloudLibrarySync))
        .maybeWhen(data: (value) => value, orElse: () => false);

    final cloudSync = ref.watch(libraryCloudSyncControllerProvider);
    final cloudSyncController = ref.read(
      libraryCloudSyncControllerProvider.notifier,
    );

    return FocusRegionScope(
      regionId: AppFocusRegionId.settingsPrimary,
      binding: FocusRegionBinding(
        resolvePrimaryEntryNode: () => _firstProfileFocusNode,
        resolveFallbackEntryNode: () => _firstProfileFocusNode,
      ),
      exitMap: FocusRegionExitMap({
        DirectionalEdge.left: AppFocusRegionId.shellSidebar,
      }),
      debugLabel: 'SettingsFocusRegion',
      child: Material(
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
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ) ??
                          const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
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
                    const SizedBox(height: _sectionItemGap),
                    MoviEnsureVisibleOnFocus(
                      verticalAlignment: _settingsFocusVerticalAlignment,
                      child: MoviPremiumSettingsTile(
                        focusNode: _premiumTileFocusNode,
                        onKeyEvent: _handlePremiumTileKey,
                      ),
                    ),

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
                        onTap: () => _guard(
                          () => context.push(AppRoutePaths.iptvSources),
                        ),
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
                    ]),

                    const SizedBox(height: _sectionGap),

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
                    _buildSettingsGroup([
                      _buildSettingItem(
                        title: l10n.settingsSubtitlesTitle,
                        onTap: () => _guard(
                          () => context.push(AppRoutePaths.settingsSubtitles),
                        ),
                      ),
                      _buildSettingItem(
                        title: l10n.settingsLanguageLabel,
                        trailing: Builder(
                          builder: (context) {
                            final localePrefs = ref.read(
                              slProvider,
                            )<LocalePreferences>();
                            final items = _availableLanguages();
                            final selected = items
                                .where(
                                  (e) =>
                                      _isCurrentLanguage(currentLangCode, e.$1),
                                )
                                .map((e) => e.$1)
                                .cast<String?>()
                                .firstWhere(
                                  (_) => true,
                                  orElse: () => items.first.$1,
                                );

                            final platform = Theme.of(context).platform;
                            final isCupertinoPlatform =
                                platform == TargetPlatform.iOS ||
                                platform == TargetPlatform.macOS;
                            final useActionMenuLayout =
                                _useSettingsActionMenuLayout(context);

                            if (isCupertinoPlatform) {
                              return CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => _guard(
                                  () => _showCupertinoLanguageSelector(
                                    context,
                                    currentLangCode,
                                  ),
                                ),
                                child: Text(
                                  items.firstWhere((e) => e.$1 == selected).$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: currentAccentColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }

                            if (useActionMenuLayout) {
                              final selectedLabel = items
                                  .firstWhere((e) => e.$1 == selected)
                                  .$2;
                              return ConstrainedBox(
                                constraints: BoxConstraints(minHeight: 44),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: MoviEnsureVisibleOnFocus(
                                    verticalAlignment:
                                        _settingsFocusVerticalAlignment,
                                    child: MoviFocusableAction(
                                      focusNode: _languageSelectorFocusNode,
                                      onPressed: () => _guard(
                                        () => _showTvLanguageSelector(
                                          context,
                                          currentLangCode,
                                        ),
                                      ),
                                      semanticLabel: l10n.settingsLanguageLabel,
                                      builder: (context, state) {
                                        return MoviFocusFrame(
                                          scale: state.focused ? 1.02 : 1,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  selectedLabel,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: currentAccentColor,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.keyboard_arrow_down,
                                                size: 18,
                                                color: currentAccentColor,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }

                            return DropdownButtonHideUnderline(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.10),
                                    width: 1,
                                  ),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final screenW = MediaQuery.sizeOf(
                                      context,
                                    ).width;
                                    final maxW = math.min(
                                      220.0,
                                      screenW * 0.45,
                                    );

                                    return ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: maxW,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        child: DropdownButton<String>(
                                          value: selected,
                                          isDense: true,
                                          menuMaxHeight: 48.0 * 5,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          dropdownColor: const Color(
                                            0xFF1E1E1E,
                                          ),
                                          style: TextStyle(
                                            color: currentAccentColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          selectedItemBuilder: (context) => [
                                            for (final (_, label) in items)
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  label,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: currentAccentColor,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                          ],
                                          icon: Transform.rotate(
                                            angle: -math.pi / 2,
                                            child: SvgPicture.asset(
                                              'assets/icons/actions/back.svg',
                                              width: 18,
                                              height: 18,
                                              colorFilter: ColorFilter.mode(
                                                currentAccentColor,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ),
                                          items: [
                                            for (final (code, label) in items)
                                              DropdownMenuItem<String>(
                                                value: code,
                                                child: Text(
                                                  label,
                                                  style: TextStyle(
                                                    color: code == selected
                                                        ? currentAccentColor
                                                        : Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                          ],
                                          onChanged: (value) {
                                            if (value == null) return;
                                            _guard(() async {
                                              await localePrefs.setLanguageCode(
                                                value,
                                              );
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
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
                        title: l10n.settingsPrivacyPolicyTitle,
                        onTap: () => _openExternalLink(_privacyPolicyUrl),
                      ),
                      _buildSettingItem(
                        title: l10n.settingsTermsOfUseTitle,
                        onTap: () => _openExternalLink(_termsOfUseUrl),
                      ),
                      _buildSettingItem(
                        title: l10n.settingsAboutTitle,
                        onTap: () => context.push(AppRoutePaths.about),
                      ),
                    ]),

                    const SizedBox(height: _sectionGap),

                    if (!isTvLayout) ...[
                      // --- Aide & diagnostic
                      Text(
                        l10n.settingsHelpDiagnosticsSection,
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
                          title: l10n.settingsExportErrorLogs,
                          onTap: () => _guard(
                            () => ExportDiagnosticsSheet.show(context, ref),
                          ),
                        ),
                      ]),
                      const SizedBox(height: _sectionGap),
                    ],

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
                        trailing: ListenableBuilder(
                          listenable: _cloudSyncAutoFocusNode,
                          builder: (context, _) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: _cloudSyncAutoFocusNode.hasFocus
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Switch.adaptive(
                                focusNode: _cloudSyncAutoFocusNode,
                                value: cloudSync.autoSyncEnabled,
                                activeThumbColor: currentAccentColor,
                                onChanged: (value) => unawaited(() async {
                                  if (!value) {
                                    _guard(
                                      () => cloudSyncController
                                          .setAutoSyncEnabled(false),
                                    );
                                    return;
                                  }

                                  final hasPremium =
                                      await _ensurePremiumFeature(
                                        PremiumFeature.cloudLibrarySync,
                                      );
                                  if (!hasPremium) return;
                                  _guard(
                                    () => cloudSyncController
                                        .setAutoSyncEnabled(true),
                                  );
                                }()),
                              ),
                            );
                          },
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
                            : () => unawaited(() async {
                                final hasPremium = await _ensurePremiumFeature(
                                  PremiumFeature.cloudLibrarySync,
                                );
                                if (!hasPremium) return;
                                _guard(() => cloudSyncController.syncNow());
                              }()),
                      ),
                      if (!hasCloudSyncPremium)
                        Text(
                          l10n.settingsCloudSyncPremiumRequiredMessage,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
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
      ),
    );
  }
}
