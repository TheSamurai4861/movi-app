import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/auth/domain/entities/auth_models.dart';
import 'package:movi/src/core/auth/presentation/providers/auth_providers.dart';
import 'package:movi/src/core/config/config.dart';
import 'package:movi/src/core/widgets/overlay_splash.dart';

/// Simple authentication gate that decides what to render based on
/// the current [AuthStatus].
///
/// Behaviour:
/// - When Supabase is not configured (no defines) → renders [child] directly.
/// - When auth status is [AuthStatus.authenticated] → renders [child].
/// - When status is [AuthStatus.unknown] → shows a minimal loading screen.
/// - When status is [AuthStatus.unauthenticated] → shows the OTP login page.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  bool _isAuthEnabled() {
    const config = SupabaseConfig.fromEnvironment;
    return config.isConfigured;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If Supabase is not configured, we let the app behave as before.
    if (!_isAuthEnabled()) {
      return child;
    }

    final status = ref.watch(authStatusProvider);

    if (status == AuthStatus.authenticated) {
      return child;
    }

    return const Scaffold(body: OverlaySplash());
  }
}
