// lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/router/router.dart' as routes;
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/l10n/app_localizations.dart';

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
      return Scaffold(
        body: OverlaySplash(
          message: AppLocalizations.of(context)!.overlayPreparingHome,
        ),
      );
    }

    if (preload.hasError) {
      final message = AppLocalizations.of(context)!.errorPrepareHome;
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              MoviPrimaryButton(
                label: AppLocalizations.of(context)!.actionRetry,
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
      return Scaffold(
        body: OverlaySplash(
          message: AppLocalizations.of(context)!.overlayOpeningHome,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
