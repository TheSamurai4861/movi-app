import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/di/injector.dart';
import 'package:movi/src/core/state/app_state_controller.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/features/settings/domain/entities/user_profile.dart';
import 'package:movi/src/features/settings/domain/value_objects/first_name.dart';
import 'package:movi/src/features/settings/domain/value_objects/language_code.dart';
import 'package:movi/src/features/settings/domain/value_objects/metadata_preference.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_header.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/features/welcome/presentation/widgets/labeled_field.dart';

class WelcomeUserPage extends ConsumerStatefulWidget {
  const WelcomeUserPage({super.key});

  @override
  ConsumerState<WelcomeUserPage> createState() => _WelcomeUserPageState();
}

class _WelcomeUserPageState extends ConsumerState<WelcomeUserPage> {
  final _nameCtrl = TextEditingController();
  String _lang = 'fr-FR';
  String _meta = 'tmdb';

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userSettingsControllerProvider);

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
                  const WelcomeHeader(
                    title: 'Bienvenue !',
                    subtitle: 'Renseigne ton prénom et tes préférences pour personnaliser Movi.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabeledField(
                        label: 'Prénom',
                        child: TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Ton prénom',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LabeledField(
                        label: 'Langue TMDB préférée',
                        child: DropdownButtonFormField<String>(
                          initialValue: _lang,
                          items: const [
                            DropdownMenuItem(value: 'en-US', child: Text('English (US)')),
                            DropdownMenuItem(value: 'fr-FR', child: Text('Français (FR)')),
                            DropdownMenuItem(value: 'es-ES', child: Text('Español (ES)')),
                            DropdownMenuItem(value: 'de-DE', child: Text('Deutsch (DE)')),
                            DropdownMenuItem(value: 'it-IT', child: Text('Italiano (IT)')),
                            DropdownMenuItem(value: 'pt-BR', child: Text('Português (BR)')),
                            DropdownMenuItem(value: 'ja-JP', child: Text('日本語 (JP)')),
                            DropdownMenuItem(value: 'ko-KR', child: Text('한국어 (KR)')),
                            DropdownMenuItem(value: 'zh-CN', child: Text('中文 (CN)')),
                            DropdownMenuItem(value: 'ru-RU', child: Text('Русский (RU)')),
                            DropdownMenuItem(value: 'ar-SA', child: Text('العربية (SA)')),
                          ],
                          onChanged: (v) => setState(() => _lang = v ?? 'fr-FR'),
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LabeledField(
                        label: 'Préférences métadonnées',
                        child: DropdownButtonFormField<String>(
                          initialValue: _meta,
                          items: const [
                            DropdownMenuItem(value: 'tmdb', child: Text('TMDB')),
                            DropdownMenuItem(value: 'none', child: Text('Aucune')),
                          ],
                          onChanged: (v) => setState(() => _meta = v ?? 'tmdb'),
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: SizedBox(
                          width: double.infinity,
                          child: MoviPrimaryButton(
                            label: 'Continuer',
                            onPressed: state.isSaving ? null : () async {
                              final fn = FirstName.tryParse(_nameCtrl.text);
                              final lc = LanguageCode.tryParse(_lang);
                              final mp = MetadataPreference.tryParse(_meta);
                              if (fn == null || lc == null || mp == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Merci de remplir correctement les champs.')),
                                );
                                return;
                              }
                              // Sauvegarde du profil
                              final ok = await ref
                                  .read(userSettingsControllerProvider.notifier)
                                  .save(UserProfile(firstName: fn, languageCode: lc, metadataPreference: mp));
                              if (!context.mounted) return;
                              if (ok) {
                                await sl<AppStateController>().setPreferredLocale(_lang);
                                if (!context.mounted) return;
                                GoRouter.of(context).go('/settings/iptv/connect');
                              }
                            },
                            loading: state.isSaving,
                          ),
                        ),
                      ),
                      if (state.error != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(state.error!, style: const TextStyle(color: Colors.red)),
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