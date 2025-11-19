import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_connect_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/preferences/iptv_sync_preferences.dart';
import 'package:movi/src/core/preferences/player_preferences.dart';
import 'package:movi/src/core/preferences/accent_color_preferences.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/features/iptv/application/services/xtream_sync_service.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/features/player/domain/utils/language_formatter.dart';
import 'package:movi/l10n/app_localizations.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _refreshingIptv = false;

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

  // Palette de couleurs pastels
  static const List<(Color color, String name)> _accentColorOptions = [
    (Color(0xFF2160AB), 'Bleu'), // Couleur par défaut
    (Color(0xFFF48FB1), 'Rose'),
    (Color(0xFF81C784), 'Vert'),
    (Color(0xFFBA68C8), 'Violet'),
    (Color(0xFFFFB74D), 'Orange'),
    (Color(0xFF4DB6AC), 'Turquoise'),
    (Color(0xFFFFE082), 'Jaune'),
    (Color(0xFF7986CB), 'Indigo'),
  ];

  static const List<(String code, String label)> _playerLanguageOptions = [
    ('', 'Défaut du lecteur'),
    ('fr', 'Français'),
    ('en', 'Anglais'),
    ('es', 'Espagnol'),
    ('de', 'Allemand'),
    ('it', 'Italien'),
    ('pt', 'Portugais'),
    ('ru', 'Russe'),
    ('ja', 'Japonais'),
    ('ko', 'Coréen'),
    ('zh', 'Chinois'),
    ('ar', 'Arabe'),
    ('nl', 'Néerlandais'),
    ('pl', 'Polonais'),
    ('tr', 'Turc'),
    ('sv', 'Suédois'),
    ('da', 'Danois'),
    ('no', 'Norvégien'),
    ('fi', 'Finnois'),
    ('cs', 'Tchèque'),
    ('hu', 'Hongrois'),
    ('ro', 'Roumain'),
    ('el', 'Grec'),
    ('he', 'Hébreu'),
    ('th', 'Thaï'),
    ('vi', 'Vietnamien'),
    ('id', 'Indonésien'),
    ('hi', 'Hindi'),
    ('uk', 'Ukrainien'),
  ];

  String _getLanguageLabel(String code) {
    // Normaliser le code (enlever le pays si présent, sauf pour fr-MM)
    String normalizedCode = code.toLowerCase();
    if (normalizedCode.startsWith('fr-') &&
        !normalizedCode.startsWith('fr-mm')) {
      normalizedCode = 'fr';
    } else if (normalizedCode.startsWith('en-')) {
      normalizedCode = 'en';
    } else if (normalizedCode.startsWith('es-')) {
      normalizedCode = 'es';
    } else if (normalizedCode.startsWith('de-')) {
      normalizedCode = 'de';
    } else if (normalizedCode.startsWith('it-')) {
      normalizedCode = 'it';
    } else if (normalizedCode.startsWith('nl-')) {
      normalizedCode = 'nl';
    } else if (normalizedCode.startsWith('pl-')) {
      normalizedCode = 'pl';
    } else if (normalizedCode.startsWith('pt-')) {
      normalizedCode = 'pt';
    }

    // Vérifier si c'est fr-MM (avec casse flexible)
    if (code.toLowerCase().contains('mm')) {
      return _availableLanguages
          .firstWhere(
            (e) => e.$1 == 'fr-MM',
            orElse: () => ('fr-MM', 'Burgonde'),
          )
          .$2;
    }

    final entry = _availableLanguages.firstWhere(
      (e) => e.$1.toLowerCase() == normalizedCode,
      orElse: () => (code, code),
    );
    return entry.$2;
  }

  Future<void> _showLanguageSelector(
    BuildContext context,
    String currentCode,
  ) async {
    final localePrefs = ref.read(slProvider)<LocalePreferences>();
    final accentColor = ref.read(asp.currentAccentColorProvider);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(AppLocalizations.of(context)!.settingsLanguageLabel),
        actions: [
          for (final (code, label) in _availableLanguages)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                unawaited(localePrefs.setLanguageCode(code));
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
                  if (_isCurrentLanguage(currentCode, code))
                    const SizedBox(width: 8),
                  if (_isCurrentLanguage(currentCode, code))
                    Icon(Icons.check, color: accentColor, size: 20),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppLocalizations.of(context)!.actionCancel),
        ),
      ),
    );
  }

  bool _isCurrentLanguage(String currentCode, String code) {
    // Normaliser les deux codes pour la comparaison
    String normalizedCurrent = currentCode.toLowerCase();
    String normalizedCode = code.toLowerCase();

    // Gérer le cas spécial de fr-MM
    if (code == 'fr-MM') {
      return normalizedCurrent.contains('mm');
    }

    // Pour les autres, extraire juste le code langue
    final currentLang = normalizedCurrent.split('-').first;
    final codeLang = normalizedCode.split('-').first;

    return currentLang == codeLang;
  }

  String _formatSyncInterval(Duration interval) {
    // Si l'intervalle est très long (>= 365 jours), considérer comme désactivé
    if (interval.inDays >= 365) return 'Désactivé';

    final minutes = interval.inMinutes;

    if (minutes < 60) {
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    } else if (minutes < 1440) {
      final hours = minutes ~/ 60;
      if (minutes % 60 == 0) {
        return hours == 1 ? 'Toutes les heures' : 'Toutes les $hours heures';
      } else {
        return '$hours h ${minutes % 60} min';
      }
    } else {
      final days = minutes ~/ 1440;
      if (minutes % 1440 == 0) {
        return days == 1 ? 'Tous les jours' : 'Tous les $days jours';
      } else {
        final hours = (minutes % 1440) ~/ 60;
        return '$days jour${days > 1 ? 's' : ''} ${hours}h';
      }
    }
  }

  Future<void> _showSyncIntervalSelector(
    BuildContext context,
    Duration currentInterval,
  ) async {
    final iptvSyncPrefs = ref.read(slProvider)<IptvSyncPreferences>();
    final syncService = ref.read(slProvider)<XtreamSyncService>();
    final accentColor = ref.read(asp.currentAccentColorProvider);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(AppLocalizations.of(context)!.settingsSyncFrequency),
        actions: [
          for (final (interval, label) in _syncIntervalOptions)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (interval == null) {
                  // Pour désactiver, on utilise une durée très longue (1 an)
                  final disabledInterval = const Duration(days: 365);
                  unawaited(iptvSyncPrefs.setSyncInterval(disabledInterval));
                  syncService.setInterval(disabledInterval);
                } else {
                  unawaited(iptvSyncPrefs.setSyncInterval(interval));
                  syncService.setInterval(interval);
                }
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
                  if (_isCurrentSyncInterval(currentInterval, interval))
                    const SizedBox(width: 8),
                  if (_isCurrentSyncInterval(currentInterval, interval))
                    Icon(Icons.check, color: accentColor, size: 20),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppLocalizations.of(context)!.actionCancel),
        ),
      ),
    );
  }

  bool _isCurrentSyncInterval(Duration current, Duration? option) {
    if (option == null) {
      // Option "Désactivé" - comparer avec une durée très longue
      return current.inDays >= 365;
    }
    // Si current est désactivé (>= 365 jours) et option est null (désactivé)
    if (current.inDays >= 365)
      return false; // option n'est pas null ici, donc différent

    // Comparer les intervalles en minutes
    return current.inMinutes == option.inMinutes;
  }

  String _formatPlayerLanguage(String? code, bool isAudio) {
    if (code == null || code.isEmpty) {
      return isAudio ? 'Défaut du lecteur' : 'Désactivé';
    }
    return LanguageFormatter.formatLanguageCode(code);
  }

  Future<void> _showAudioLanguageSelector(
    BuildContext context,
    String? currentCode,
  ) async {
    final playerPrefs = ref.read(slProvider)<PlayerPreferences>();
    final accentColor = ref.read(asp.currentAccentColorProvider);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(
          AppLocalizations.of(context)!.settingsPreferredAudioLanguage,
        ),
        actions: [
          for (final (code, label) in _playerLanguageOptions)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                final selectedCode = code.isEmpty ? null : code;
                unawaited(playerPrefs.setPreferredAudioLanguage(selectedCode));
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: _isCurrentPlayerLanguage(currentCode, code)
                          ? accentColor
                          : Colors.white,
                      fontWeight: _isCurrentPlayerLanguage(currentCode, code)
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  if (_isCurrentPlayerLanguage(currentCode, code))
                    const SizedBox(width: 8),
                  if (_isCurrentPlayerLanguage(currentCode, code))
                    Icon(Icons.check, color: accentColor, size: 20),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppLocalizations.of(context)!.actionCancel),
        ),
      ),
    );
  }

  Future<void> _showSubtitleLanguageSelector(
    BuildContext context,
    String? currentCode,
  ) async {
    final playerPrefs = ref.read(slProvider)<PlayerPreferences>();
    final accentColor = ref.read(asp.currentAccentColorProvider);

    // Pour les sous-titres, le premier item devrait être "Désactivé" au lieu de "Défaut du lecteur"
    final subtitleOptions = _playerLanguageOptions.map((option) {
      if (option.$1.isEmpty) {
        return ('', 'Désactivé');
      }
      return option;
    }).toList();

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(
          AppLocalizations.of(context)!.settingsPreferredSubtitleLanguage,
        ),
        actions: [
          for (final (code, label) in subtitleOptions)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                final selectedCode = code.isEmpty ? null : code;
                unawaited(
                  playerPrefs.setPreferredSubtitleLanguage(selectedCode),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: _isCurrentPlayerLanguage(currentCode, code)
                          ? accentColor
                          : Colors.white,
                      fontWeight: _isCurrentPlayerLanguage(currentCode, code)
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  if (_isCurrentPlayerLanguage(currentCode, code))
                    const SizedBox(width: 8),
                  if (_isCurrentPlayerLanguage(currentCode, code))
                    Icon(Icons.check, color: accentColor, size: 20),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppLocalizations.of(context)!.actionCancel),
        ),
      ),
    );
  }

  bool _isCurrentPlayerLanguage(String? current, String option) {
    if (current == null || current.isEmpty) {
      return option.isEmpty;
    }
    if (option.isEmpty) {
      return current.isEmpty;
    }
    // Normaliser les deux codes pour la comparaison (insensible à la casse)
    final normalizedCurrent = current.toLowerCase().split('-').first;
    final normalizedOption = option.toLowerCase().split('-').first;
    return normalizedCurrent == normalizedOption;
  }

  String _getAccentColorName(Color color) {
    final option = _accentColorOptions.firstWhere(
      (e) => e.$1.toARGB32() == color.toARGB32(),
      orElse: () => (color, 'Personnalisé'),
    );
    return option.$2;
  }

  Future<void> _showAccentColorSelector(
    BuildContext context,
    Color currentColor,
  ) async {
    final accentColorPrefs = ref.read(slProvider)<AccentColorPreferences>();

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(AppLocalizations.of(context)!.settingsAccentColor),
        actions: [
          for (final (color, name) in _accentColorOptions)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                unawaited(accentColorPrefs.setAccentColor(color));
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
                  if (_isCurrentAccentColor(currentColor, color))
                    const SizedBox(width: 8),
                  if (_isCurrentAccentColor(currentColor, color))
                    Icon(Icons.check, color: currentColor, size: 20),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(AppLocalizations.of(context)!.actionCancel),
        ),
      ),
    );
  }

  bool _isCurrentAccentColor(Color current, Color option) {
    return current.toARGB32() == option.toARGB32();
  }

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.homeNoIptvSources),
            ),
          );
        }
        return;
      }
    }
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
    // Forcer le rafraîchissement de la page d'accueil
    // Appeler refresh() directement pour s'assurer que les données sont rechargées
    unawaited(ref.read(hp.homeControllerProvider.notifier).refresh());
    // Émettre l'événement pour notifier les autres listeners
    ref.read(appEventBusProvider).emit(const AppEvent(AppEventType.iptvSynced));
    if (mounted) {
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
        final detail = errors.first;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    detail,
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
      }
    }
    if (mounted) setState(() => _refreshingIptv = false);
  }

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

  Widget _buildProfileCircle({
    required String name,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLangCode = ref.watch(asp.currentLanguageCodeProvider);
    final currentLangLabel = _getLanguageLabel(currentLangCode);
    final currentSyncInterval = ref.watch(asp.currentIptvSyncIntervalProvider);
    final currentAudioLanguage = ref.watch(
      asp.currentPreferredAudioLanguageProvider,
    );
    final currentSubtitleLanguage = ref.watch(
      asp.currentPreferredSubtitleLanguageProvider,
    );
    final currentAccentColor = ref.watch(asp.currentAccentColorProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // Titre
            Text(
              AppLocalizations.of(context)!.settingsTitle,
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
            // Section Comptes
            Text(
              AppLocalizations.of(context)!.settingsAccountsSection,
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildProfileCircle(
                  name: 'Matt',
                  color: currentAccentColor,
                  icon: Icons.account_circle,
                ),
                const SizedBox(width: 24),
                _buildProfileCircle(
                  name: 'Manu',
                  color: const Color(0xFFFF6B9D),
                  icon: Icons.wb_sunny,
                ),
                const SizedBox(width: 24),
                _buildProfileCircle(
                  name: 'Ber',
                  color: const Color(0xFF34C759),
                  icon: Icons.music_note,
                ),
                const SizedBox(width: 24),
                _buildProfileCircle(
                  name: 'Ajouter',
                  color: const Color(0xFF8E8E93),
                  icon: Icons.add,
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Section Paramètres IPTV
            Text(
              AppLocalizations.of(context)!.settingsIptvSection,
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
            const SizedBox(height: 8),
            _buildSettingItem(
              title: AppLocalizations.of(context)!.settingsSourcesManagement,
              onTap: () {},
            ),
            _buildSettingItem(
              title: AppLocalizations.of(context)!.settingsSyncFrequency,
              value: _formatSyncInterval(currentSyncInterval),
              showChevronDown: true,
              onTap: () =>
                  _showSyncIntervalSelector(context, currentSyncInterval),
            ),
            _buildSettingItem(
              title: AppLocalizations.of(
                context,
              )!.settingsRefreshIptvPlaylistsTitle,
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
              onTap: _refreshingIptv ? null : _refreshIptv,
            ),
            const SizedBox(height: 32),
            // Section Paramètres de l'application
            Text(
              AppLocalizations.of(context)!.settingsAppSection,
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
            const SizedBox(height: 8),
            _buildSettingItem(
              title: AppLocalizations.of(context)!.settingsLanguageLabel,
              value: currentLangLabel,
              showChevronDown: true,
              onTap: () => _showLanguageSelector(context, currentLangCode),
            ),
            _buildSettingItem(
              title: AppLocalizations.of(context)!.settingsAccentColor,
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
              onTap: () =>
                  _showAccentColorSelector(context, currentAccentColor),
            ),
            const SizedBox(height: 32),
            // Section Paramètres de lecture
            Text(
              AppLocalizations.of(context)!.settingsPlaybackSection,
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
            const SizedBox(height: 8),
            _buildSettingItem(
              title: AppLocalizations.of(
                context,
              )!.settingsPreferredAudioLanguage,
              value: _formatPlayerLanguage(currentAudioLanguage, true),
              showChevronDown: true,
              onTap: () =>
                  _showAudioLanguageSelector(context, currentAudioLanguage),
            ),
            _buildSettingItem(
              title: AppLocalizations.of(
                context,
              )!.settingsPreferredSubtitleLanguage,
              value: _formatPlayerLanguage(currentSubtitleLanguage, false),
              showChevronDown: true,
              onTap: () => _showSubtitleLanguageSelector(
                context,
                currentSubtitleLanguage,
              ),
            ),
            const SizedBox(height: 46),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
