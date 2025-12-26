import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/supabase/supabase_providers.dart';

/// État d'auth Supabase côté app (pour distinguer "pas loggé" vs "0 profil").
enum SupabaseAuthStatus {
  uninitialized,
  unauthenticated,
  authenticated,
}

/// Notifier qui écoute les changements de session Supabase et met à jour l'état d'auth.
class SupabaseAuthStatusNotifier extends Notifier<SupabaseAuthStatus> {
  StreamSubscription? _subscription;

  @override
  SupabaseAuthStatus build() {
    final client = ref.watch(supabaseClientProvider);
    if (client == null) {
      _subscription?.cancel();
      _subscription = null;
      return SupabaseAuthStatus.uninitialized;
    }

    // Écouter les changements de session
    _subscription?.cancel();
    _subscription = client.auth.onAuthStateChange.listen((event) {
      final session = event.session;
      final newStatus = session == null
          ? SupabaseAuthStatus.unauthenticated
          : SupabaseAuthStatus.authenticated;
      if (state != newStatus) {
        state = newStatus;
      }
    });

    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
    });

    // État initial
    final session = client.auth.currentSession;
    if (session == null) {
      return SupabaseAuthStatus.unauthenticated;
    }
    return SupabaseAuthStatus.authenticated;
  }
}

/// Provider qui détermine l'état d'auth Supabase en écoutant les changements de session.
final supabaseAuthStatusProvider =
    NotifierProvider<SupabaseAuthStatusNotifier, SupabaseAuthStatus>(
  SupabaseAuthStatusNotifier.new,
);
