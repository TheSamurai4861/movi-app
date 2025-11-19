import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/startup/app_startup_provider.dart'
    as app_startup_provider;

class AppStartupGate extends ConsumerWidget {
  const AppStartupGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(app_startup_provider.appStartupProvider);

    // Flag compile-time pour diagnostiquer les IPA dev.
    const bool forceStartupDetails = bool.fromEnvironment(
      'FORCE_STARTUP_DETAILS',
      defaultValue: false,
    );

    if (state.isLoading) {
      debugPrint('[Startup] loading...');
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color.fromRGBO(20, 20, 20, 1),
          body: const SizedBox.shrink(),
        ),
      );
    }

    if (state.hasError) {
      final details = state.error.toString();
      final showDetails = !kReleaseMode || forceStartupDetails;

      // On tronque pour éviter un pavé illisible sur mobile.
      final displayDetails = details.length > 400
          ? '${details.substring(0, 400)}…'
          : details;

      debugPrint('[Startup] error: $details');

      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color.fromRGBO(20, 20, 20, 1),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Erreur au démarrage (config ou réseau)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (showDetails) ...[
                    const SizedBox(height: 12),
                    Text(
                      displayDetails,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () =>
                        ref.refresh(app_startup_provider.appStartupProvider),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    debugPrint('[Startup] success, navigate to Home');
    return child;
  }
}
