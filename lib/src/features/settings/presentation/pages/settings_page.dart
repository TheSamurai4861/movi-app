import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/l10n/app_localizations.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const List<(String code, String label)> _languages = <(String, String)>[
    ('en-US', 'English (United States)'),
    ('fr-FR', 'Français (France)'),
    ('es-ES', 'Español (España)'),
    ('nl-NL', 'Nederlands (Nederland)'),
    ('it-IT', 'Italiano (Italia)'),
  ];

  String _labelFor(String code) {
    final entry = _languages.firstWhere(
      (e) => e.$1.toLowerCase() == code.toLowerCase(),
      orElse: () => (code, code),
    );
    return entry.$2;
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
            Text(AppLocalizations.of(context)!.settingsGeneralTitle, style: context.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              value: ref.watch(currentThemeModeProvider) == ThemeMode.dark,
              title: Text(AppLocalizations.of(context)!.settingsDarkModeTitle),
              subtitle: Text(AppLocalizations.of(context)!.settingsDarkModeSubtitle),
              onChanged: (enabled) {
                final mode = enabled ? ThemeMode.dark : ThemeMode.light;
                unawaited(ref.read(appStateControllerProvider).setThemeMode(mode));
              },
            ),
            SwitchListTile(
              value: false,
              title: Text(AppLocalizations.of(context)!.settingsNotificationsTitle),
              subtitle: Text(AppLocalizations.of(context)!.settingsNotificationsSubtitle),
              onChanged: (_) {},
            ),
            const Divider(height: AppSpacing.sectionGap),
            Text(AppLocalizations.of(context)!.settingsAccountTitle, style: context.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text(AppLocalizations.of(context)!.settingsProfileInfoTitle),
              subtitle: Text(AppLocalizations.of(context)!.settingsProfileInfoSubtitle),
              trailing: Icon(Icons.chevron_right),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(AppLocalizations.of(context)!.settingsLanguageLabel),
              subtitle: Text(_labelFor(currentCode)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickLanguage(context, currentCode),
            ),
            const Divider(height: AppSpacing.sectionGap),
            Text(AppLocalizations.of(context)!.settingsAboutTitle, style: context.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text(AppLocalizations.of(context)!.settingsLegalMentionsTitle),
              trailing: Icon(Icons.chevron_right),
            ),
            ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text(AppLocalizations.of(context)!.settingsPrivacyPolicyTitle),
              trailing: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
