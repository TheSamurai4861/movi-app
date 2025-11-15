import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/startup/app_startup_provider.dart';

class AppStartupGate extends ConsumerWidget {
  const AppStartupGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStartupProvider);
    if (state.isLoading) {
      debugPrint('[Startup] loading...');
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color.fromRGBO(20, 20, 20, 1),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (state.hasError) {
      final details = state.error.toString();
      final showDetails = !kReleaseMode;
      debugPrint('[Startup] error: $details');
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color.fromRGBO(20, 20, 20, 1),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Erreur au démarrage (config ou réseau)'),
                if (showDetails) ...[
                  const SizedBox(height: 12),
                  Text(details, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.refresh(appStartupProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    debugPrint('[Startup] success, navigate to Home');
    return child;
  }
}