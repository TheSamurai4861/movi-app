import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_header.dart';

class WelcomeSourcePage extends StatelessWidget {
  const WelcomeSourcePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                        'Ajoute une source pour personnaliser ton expérience dans Movi.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: MoviPrimaryButton(
                        label: 'Ajouter une source',
                        onPressed: () {
                          if (!context.mounted) return;
                          GoRouter.of(context).go('/settings/iptv/connect');
                        },
                      ),
                    ),
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
