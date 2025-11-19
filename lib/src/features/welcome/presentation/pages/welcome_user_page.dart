import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/utils/unawaited.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/features/settings/domain/entities/user_profile.dart';
import 'package:movi/src/features/settings/domain/value_objects/first_name.dart';
import 'package:movi/src/features/settings/domain/value_objects/language_code.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/features/welcome/presentation/widgets/labeled_field.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_header.dart';

class WelcomeUserPage extends ConsumerStatefulWidget {
  const WelcomeUserPage({super.key});

  @override
  ConsumerState<WelcomeUserPage> createState() => _WelcomeUserPageState();
}

class _WelcomeUserPageState extends ConsumerState<WelcomeUserPage> {
  final _nameCtrl = TextEditingController();
  String _lang = 'fr';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(userSettingsControllerProvider.notifier).load());
      // Initialiser _lang depuis la langue actuelle de l'app
      final currentLang = ref.read(asp.currentLanguageCodeProvider);
      if (mounted) {
        setState(() {
          _lang = currentLang;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _showLanguageSelector(BuildContext context) async {
    final currentLangCode = _lang;
    final accentColor = ref.read(asp.currentAccentColorProvider);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(AppLocalizations.of(context)!.labelPreferredLanguage),
        actions: [
          for (final (code, label) in _availableLanguages)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() => _lang = code);
                unawaited(
                  ref
                      .read(asp.appStateControllerProvider)
                      .setPreferredLocale(code),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: _isCurrentLanguage(currentLangCode, code)
                          ? accentColor
                          : Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (_isCurrentLanguage(currentLangCode, code))
                    const SizedBox(width: 8),
                  if (_isCurrentLanguage(currentLangCode, code))
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userSettingsControllerProvider);
    final accentColor = ref.watch(asp.currentAccentColorProvider);

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
                    title: AppLocalizations.of(context)!.welcomeTitle,
                    subtitle: AppLocalizations.of(context)!.welcomeSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabeledField(
                        label: AppLocalizations.of(context)!.labelUsername,
                        child: TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(
                              context,
                            )!.hintUsername,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LabeledField(
                        label: AppLocalizations.of(
                          context,
                        )!.labelPreferredLanguage,
                        child: InkWell(
                          onTap: () => _showLanguageSelector(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getLanguageLabel(_lang),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: accentColor,
                                  size: 20,
                                ),
                              ],
                            ),
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
                            label: AppLocalizations.of(context)!.actionContinue,
                            onPressed: state.isSaving
                                ? null
                                : () async {
                                    final fn = FirstName.tryParse(
                                      _nameCtrl.text,
                                    );
                                    final lc = LanguageCode.tryParse(_lang);
                                    if (fn == null || lc == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.errorFillFields,
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    // Sauvegarde du profil
                                    final ok = await ref
                                        .read(
                                          userSettingsControllerProvider
                                              .notifier,
                                        )
                                        .save(
                                          UserProfile(
                                            firstName: fn,
                                            languageCode: lc,
                                          ),
                                        );
                                    if (!context.mounted) return;
                                    if (ok) {
                                      GoRouter.of(
                                        context,
                                      ).go('/settings/iptv/connect');
                                    }
                                  },
                            loading: state.isSaving,
                          ),
                        ),
                      ),
                      if (state.error != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          state.error!,
                          style: const TextStyle(color: Colors.red),
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
}
