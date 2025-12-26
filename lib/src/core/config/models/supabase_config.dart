// FILE #40
// lib/src/core/config/supabase_config.dart

import 'package:flutter/foundation.dart';

/// Compile-time configuration for Supabase.
///
/// Values are read from `--dart-define` to avoid embedding secrets in assets.
///
/// Expected defines:
/// - `SUPABASE_URL`
/// - `SUPABASE_ANON_KEY`
///
/// Optional (diagnostic):
/// - `SUPABASE_PROJECT_REF` (ex: "xyzcompany") to sanity-check that the app points to the expected project.
///
/// IMPORTANT (Dart const limitation):
/// - On some SDK/analyzer versions, you can't call `.isEmpty` in a const expression.
/// - Therefore `fromEnvironment` cannot conditionally turn empty string into null at compile time.
///   We keep it as a String and normalize at runtime via getters.
@immutable
class SupabaseConfig {
  const SupabaseConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.expectedProjectRef,
  });

  /// Supabase project URL, e.g. `https://xyzcompany.supabase.co`.
  final String supabaseUrl;

  /// Supabase anon key (public by design).
  final String supabaseAnonKey;

  /// Optional expected project ref (first subdomain of supabase.co).
  ///
  /// NOTE: This may be an empty string if not provided via --dart-define.
  final String? expectedProjectRef;

  static const String _defineUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _defineAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // On purpose: keep raw string (may be empty). Avoid `.isEmpty` inside const.
  static const String _defineExpectedProjectRef =
      String.fromEnvironment('SUPABASE_PROJECT_REF');

  /// Builds a config instance from compile-time environment defines.
  static const SupabaseConfig fromEnvironment = SupabaseConfig(
    supabaseUrl: _defineUrl,
    supabaseAnonKey: _defineAnonKey,
    expectedProjectRef: _defineExpectedProjectRef,
  );

  bool get isConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  /// Normalized expected project ref (null if missing/empty).
  String? get expectedProjectRefNormalized {
    final v = expectedProjectRef?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  /// Extracts the project ref from a standard Supabase URL.
  /// Example: https://xyzcompany.supabase.co -> "xyzcompany"
  String? get projectRef {
    final url = supabaseUrl.trim();
    if (url.isEmpty) return null;

    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.trim().isEmpty) return null;

    final host = uri.host.trim();
    // Common: "<ref>.supabase.co"
    final parts = host.split('.');
    if (parts.length >= 3 && parts[1] == 'supabase' && parts[2] == 'co') {
      final ref = parts.first.trim();
      return ref.isEmpty ? null : ref;
    }
    return null;
  }

  /// Throws a [StateError] when configuration is missing/invalid.
  ///
  /// Use this for fail-fast checks in code paths that require Supabase.
  void ensureValid() {
    final url = supabaseUrl.trim();
    final key = supabaseAnonKey.trim();

    if (url.isEmpty) {
      throw StateError(
        'SupabaseConfig.supabaseUrl is empty. '
        'Provide it with --dart-define=SUPABASE_URL=...',
      );
    }
    if (key.isEmpty) {
      throw StateError(
        'SupabaseConfig.supabaseAnonKey is empty. '
        'Provide it with --dart-define=SUPABASE_ANON_KEY=...',
      );
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError(
        'SupabaseConfig.supabaseUrl is invalid: "$url". '
        'Expected something like https://<project-ref>.supabase.co',
      );
    }

    final ref = projectRef;
    final expected = expectedProjectRefNormalized;
    if (expected != null && ref != null && ref != expected) {
      throw StateError(
        'SupabaseConfig points to projectRef="$ref" but expected "$expected". '
        'You are likely using the wrong Supabase project (URL mismatch).',
      );
    }
  }

  /// Debug string WITHOUT exposing the anon key.
  @override
  String toString() {
    final url = supabaseUrl.trim().isEmpty ? '<empty>' : supabaseUrl.trim();
    final ref = projectRef ?? '<unknown>';
    final expected = expectedProjectRefNormalized ?? '<none>';

    // Key is not printed; only a stable hash marker.
    final maskedKey =
        supabaseAnonKey.trim().isEmpty ? '<empty>' : '***${supabaseAnonKey.hashCode}';
    return 'SupabaseConfig(url: $url, projectRef: $ref, expectedRef: $expected, anonKey: $maskedKey)';
  }
}
