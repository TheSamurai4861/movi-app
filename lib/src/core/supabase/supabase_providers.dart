import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/di/di.dart';

/// Riverpod access to [SupabaseClient] for widgets/services already using Riverpod.
///
/// Returns null when Supabase is not configured/registered.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  final locator = ref.watch(slProvider);
  if (!locator.isRegistered<SupabaseClient>()) return null;
  try {
    return locator<SupabaseClient>();
  } catch (_) {
    // If Supabase was configured but failed to initialize at startup,
    // accessing `Supabase.instance.client` will throw. We treat it as
    // "Supabase unavailable" to keep the app functional.
    return null;
  }
});
