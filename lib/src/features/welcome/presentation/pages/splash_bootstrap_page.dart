// lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/router/router.dart' as routes;
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/widgets/widgets.dart';

import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';

class SplashBootstrapPage extends ConsumerStatefulWidget {
  const SplashBootstrapPage({super.key});

  @override
  ConsumerState<SplashBootstrapPage> createState() =>
      _SplashBootstrapPageState();
}

class _SplashBootstrapPageState extends ConsumerState<SplashBootstrapPage> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final preload = ref.watch(appPreloadProvider);

    if (preload.isLoading) {
      return const Scaffold(
        body: OverlaySplash(message: 'Préparation de l\'accueil…'),
      );
    }

    if (preload.hasError) {
      final message = 'Impossible de préparer la page d\'accueil';
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              MoviPrimaryButton(
                label: 'Réessayer',
                onPressed: () => ref.refresh(appPreloadProvider),
              ),
            ],
          ),
        ),
      );
    }

    if (!_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        GoRouter.of(context).go(routes.AppRouteNames.home);
      });
      return const Scaffold(
        body: OverlaySplash(message: 'Ouverture de l\'accueil…'),
      );
    }

    return const SizedBox.shrink();
  }
}
