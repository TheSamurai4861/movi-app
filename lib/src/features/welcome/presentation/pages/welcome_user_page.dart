import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
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
  String _lang = 'fr-FR';

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(userSettingsControllerProvider.notifier).load());
  }

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
                    subtitle:
                        'Renseigne tes préférences pour personnaliser Movi.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabeledField(
                        label: 'Pseudo',
                        child: TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Ton pseudo',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LabeledField(
                        label: 'Langue préférée',
                        child: DropdownButtonFormField<String>(
                          initialValue: _lang,
                          items: const [
                            DropdownMenuItem(
                              value: 'en-US',
                              child: Text(
                                'English',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'fr-FR',
                              child: Text(
                                'Français',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'es-ES',
                              child: Text(
                                'Español',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'de-DE',
                              child: Text(
                                'Deutsch',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'it-IT',
                              child: Text(
                                'Italiano',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'pt-BR',
                              child: Text(
                                'Português',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'ja-JP',
                              child: Text(
                                '日本語',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'ko-KR',
                              child: Text(
                                '한국어',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'zh-CN',
                              child: Text(
                                '中文',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'ru-RU',
                              child: Text(
                                'Русский',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'ar-SA',
                              child: Text(
                                'العربية',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _lang = v ?? 'fr-FR'),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
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
                            label: 'Continuer',
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
                                        const SnackBar(
                                          content: Text(
                                            'Merci de remplir correctement les champs.',
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
                                      await ref
                                          .read(appStateControllerProvider)
                                          .setPreferredLocale(_lang);
                                      if (!context.mounted) return;
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
