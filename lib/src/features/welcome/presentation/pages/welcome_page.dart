// lib/src/features/welcome/presentation/pages/welcome_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/logging/logging.dart';

import 'package:movi/src/features/welcome/presentation/widgets/welcome_header.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_form.dart';
import 'package:movi/src/features/welcome/presentation/widgets/welcome_faq_row.dart';
import 'package:movi/src/features/settings/presentation/providers/iptv_connect_providers.dart';

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  Future<void> _onConnect(
    BuildContext context,
    WidgetRef ref, {
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final controller = ref.read(iptvConnectControllerProvider.notifier);
    unawaited(
      LoggingService.log(
        'Welcome: connect attempt url=$serverUrl user=$username',
      ),
    );
    final success = await controller.connect(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );

    if (success && context.mounted) {
      unawaited(LoggingService.log('Welcome: connect success, go bootstrap'));
      // ✅ Navigation immédiate vers la page d’accueil
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.snackbarSourceAddedBackground,
          ),
        ),
      );
      context.go('/bootstrap'); // Aller d'abord au splash de préparation
    } else if (!success && context.mounted) {
      final error =
          ref.read(iptvConnectControllerProvider).error ??
          AppLocalizations.of(context)!.errorUnknown;
      unawaited(LoggingService.log('Welcome: connect failed error=$error'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorConnectionFailed(error),
          ),
        ),
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
                    onConnect: (serverUrl, username, password) {
                      // ⬅️ Corrigé : on RETOURNE le Future pour éviter l’avertissement
                      return _onConnect(
                        context,
                        ref,
                        serverUrl: serverUrl,
                        username: username,
                        password: password,
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
