// lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/router/router.dart' as routes;
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/logging/logging.dart';
import 'package:movi/src/core/widgets/widgets.dart';

import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';

class SplashBootstrapPage extends ConsumerStatefulWidget {
  const SplashBootstrapPage({super.key});

  @override
  ConsumerState<SplashBootstrapPage> createState() =>
      _SplashBootstrapPageState();
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
    final state = ref.watch(bootstrapControllerProvider);

    // Quand prêt: navigue vers Home.
    if (state.phase == BootPhase.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Utilise GoRouter pour naviguer vers la route Home (fade transition configurée).
        unawaited(
          LoggingService.log(
            'Bootstrap: ready → navigating to Home; message="${state.message}"',
          ),
        );
        GoRouter.of(context).go(routes.AppRouteNames.home);
      });
    }

    return Scaffold(body: OverlaySplash(message: state.message));
  }
}
