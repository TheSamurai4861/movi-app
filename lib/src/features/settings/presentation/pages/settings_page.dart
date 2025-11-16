import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/state/app_event_bus.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_connect_providers.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/l10n/app_localizations.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const List<(String code, String label)> _languages =
      <(String, String)>[
        ('en-US', 'English (United States)'),
        ('fr-FR', 'Français (France)'),
        ('es-ES', 'Español (España)'),
        ('nl-NL', 'Nederlands (Nederland)'),
        ('it-IT', 'Italiano (Italia)'),
        ('pl-PL', 'Polski (Polska)'),
        ('fr-MM', 'Burgonde'),
      ];

  String _labelFor(String code) {
    final entry = _languages.firstWhere(
      (e) => e.$1.toLowerCase() == code.toLowerCase(),
      orElse: () => (code, code),
    );
    return entry.$2;
  }

  bool _refreshingIptv = false;

  Future<void> _refreshIptv() async {
    if (_refreshingIptv) return;
    var active = ref.read(appStateControllerProvider).activeIptvSourceIds;
    if (active.isEmpty) {
      final locator = ref.read(slProvider);
      final iptvLocal = locator<IptvLocalRepository>();
      final accounts = await iptvLocal.getAccounts();
      if (accounts.isNotEmpty) {
        final ids = accounts.map((a) => a.id).toSet();
        ref.read(appStateControllerProvider).setActiveIptvSources(ids);
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
    ref.read(appEventBusProvider).emit(const AppEvent(AppEventType.iptvSynced));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Playlists IPTV rafraîchies ($ok/${active.length})${ko > 0 ? ' | erreurs: $ko' : ''}',
          ),
        ),
      );
      if (ko > 0 && errors.isNotEmpty) {
        final detail = errors.first;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(detail)));
      }
    }
    if (mounted) setState(() => _refreshingIptv = false);
  }

  Future<void> _pickLanguage(BuildContext context, String current) async {
    final initialIndex = _languages.indexWhere(
      (e) => e.$1.toLowerCase() == current.toLowerCase(),
    );
    int selected = initialIndex >= 0 ? initialIndex : 0;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        return Container(
          height: 250,
          color: Colors.black,
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CupertinoPicker(
                  itemExtent: 44,
                  scrollController: FixedExtentScrollController(
                    initialItem: selected,
                  ),
                  onSelectedItemChanged: (i) => selected = i,
                  children: _languages
                      .map(
                        (e) => Center(
                          child: Text(
                            e.$2,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CupertinoButton(
                      child: Text(AppLocalizations.of(ctx)!.actionCancel),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    CupertinoButton(
                      child: Text(AppLocalizations.of(ctx)!.actionConfirm),
                      onPressed: () async {
                        final code = _languages[selected].$1;
                        Navigator.of(ctx).pop();
                        await ref
                            .read(appStateControllerProvider)
                            .setPreferredLocale(code);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCode = ref.watch(currentLanguageCodeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            Text(
              AppLocalizations.of(context)!.settingsGeneralTitle,
              style: context.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              value: ref.watch(currentThemeModeProvider) == ThemeMode.dark,
              title: Text(AppLocalizations.of(context)!.settingsDarkModeTitle),
              subtitle: Text(
                AppLocalizations.of(context)!.settingsDarkModeSubtitle,
              ),
              onChanged: (enabled) {
                final mode = enabled ? ThemeMode.dark : ThemeMode.light;
                unawaited(
                  ref.read(appStateControllerProvider).setThemeMode(mode),
                );
              },
            ),
            SwitchListTile(
              value: false,
              title: Text(
                AppLocalizations.of(context)!.settingsNotificationsTitle,
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.settingsNotificationsSubtitle,
              ),
              onChanged: (_) {},
            ),
            const Divider(height: AppSpacing.sectionGap),
            Text(
              AppLocalizations.of(context)!.settingsAccountTitle,
              style: context.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text(
                AppLocalizations.of(context)!.settingsProfileInfoTitle,
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.settingsProfileInfoSubtitle,
              ),
              trailing: Icon(Icons.chevron_right),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(AppLocalizations.of(context)!.settingsLanguageLabel),
              subtitle: Text(_labelFor(currentCode)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickLanguage(context, currentCode),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Rafraîchir les playlists IPTV'),
              subtitle: Text(
                ref.watch(appStateControllerProvider).hasActiveIptvSources
                    ? 'Actif'
                    : 'Aucune source active',
              ),
              trailing: _refreshingIptv
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _refreshingIptv ? null : _refreshIptv,
            ),
            const Divider(height: AppSpacing.sectionGap),
            Text(
              AppLocalizations.of(context)!.settingsAboutTitle,
              style: context.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text(
                AppLocalizations.of(context)!.settingsLegalMentionsTitle,
              ),
              trailing: Icon(Icons.chevron_right),
            ),
            ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text(
                AppLocalizations.of(context)!.settingsPrivacyPolicyTitle,
              ),
              trailing: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
