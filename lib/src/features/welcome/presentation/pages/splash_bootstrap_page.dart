// lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/router/app_router.dart' as routes;
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/logging/logging_service.dart';

import '../providers/bootstrap_providers.dart';

class SplashBootstrapPage extends ConsumerStatefulWidget {
  const SplashBootstrapPage({super.key});

  @override
  ConsumerState<SplashBootstrapPage> createState() => _SplashBootstrapPageState();
}

class _SplashBootstrapPageState extends ConsumerState<SplashBootstrapPage> {
  @override
  void initState() {
    super.initState();
    // Démarre la préparation au montage.
    ref.read(bootstrapControllerProvider.notifier).start();
    unawaited(LoggingService.log('Bootstrap: start initiated'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(bootstrapControllerProvider);

    // Quand prêt: navigue vers Home.
    if (state.phase == BootPhase.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Utilise GoRouter pour naviguer vers la route Home (fade transition configurée).
        unawaited(LoggingService.log('Bootstrap: ready → navigating to Home; message="${state.message}"'));
        GoRouter.of(context).go(routes.AppRouteNames.home);
      });
    }

    final media = MediaQuery.of(context);
    final bottom = 30.0 + media.padding.bottom;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          // Logo centré
          Center(
            child: Image.asset(
              'assets/icons/app_logo.png',
              height: 120,
              fit: BoxFit.contain,
            ),
          ),

          // Message d’état 30 px du bas
          Positioned(
            left: 0,
            right: 0,
            bottom: bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}