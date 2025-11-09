// lib/src/features/welcome/presentation/pages/welcome_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/utils/app_spacing.dart';

import '../widgets/welcome_header.dart';
import '../widgets/welcome_form.dart';
import '../widgets/welcome_faq_row.dart';
import '../../../settings/presentation/providers/iptv_connect_providers.dart';

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  Future<void> _onConnect(
    BuildContext context,
    WidgetRef ref, {
    required String serverUrl,
    required String username,
    required String password,
    required String alias,
  }) async {
    final controller = ref.read(iptvConnectControllerProvider.notifier);
    final success = await controller.connect(
      serverUrl: serverUrl,
      username: username,
      password: password,
      alias: alias,
    );

    if (success && context.mounted) {
      // ✅ Navigation immédiate vers la page d’accueil
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Source IPTV ajoutée. La synchronisation démarre en arrière-plan…',
          ),
        ),
      );
      context.go('/'); // Aller directement à l'accueil
    } else if (!success && context.mounted) {
      final error =
          ref.read(iptvConnectControllerProvider).error ?? 'Erreur inconnue';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de la connexion : $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(iptvConnectControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const WelcomeHeader(),
                  const SizedBox(height: AppSpacing.xl),

                  // 🔸 On passe la fonction _onConnect au formulaire
                  WelcomeForm(
                    onConnect: (serverUrl, username, password, alias) {
                      // ⬅️ Corrigé : on RETOURNE le Future pour éviter l’avertissement
                      return _onConnect(
                        context,
                        ref,
                        serverUrl: serverUrl,
                        username: username,
                        password: password,
                        alias: alias,
                      );
                    },
                    isLoading: state.isLoading,
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  const WelcomeFaqRow(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
