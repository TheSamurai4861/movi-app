import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';

import 'package:movi/src/app.dart';
import 'package:movi/src/core/error/global_error_handler.dart';
import 'package:movi/src/core/network/proxy/http_overrides.dart'
    as http_overrides;
import 'package:movi/src/core/startup/app_startup_gate.dart';
import 'package:movi/src/core/widgets/app_restart.dart';

/// Entry point of the Movi application.
///
/// Sets up:
/// - Flutter engine bindings,
/// - global error handling (Flutter / platform / isolates),
/// - native video engine (MediaKit),
/// then boots the app within a Riverpod [ProviderScope].
Future<void> main(List<String> args) async {
  // Required to interact with the Flutter engine (platform channels, bindings)
  // before calling any plugin or runApp().
  WidgetsFlutterBinding.ensureInitialized();

  if (defaultTargetPlatform == TargetPlatform.android) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  // Prevent runtime font downloads (fonts.gstatic.com) from crashing the app on
  // restricted/offline networks. When disabled, the app falls back to the
  // platform font if the Google font isn't available locally.
  GoogleFonts.config.allowRuntimeFetching = !kReleaseMode;

  if (!kReleaseMode) {
    debugPaintBaselinesEnabled = false;
    debugPaintSizeEnabled = false;
    debugPaintLayerBordersEnabled = false;
    debugRepaintRainbowEnabled = false;
  }

  // Optional: enable proxy support for non-Dio HTTP clients (e.g. Supabase)
  // via compile-time defines (HTTP_PROXY / HTTPS_PROXY / NO_PROXY).
  http_overrides.configureHttpOverridesFromEnvironment();

  // Configure global error handlers as early as possible so that
  // any error during initialization (including plugin init) is captured.
  setupGlobalErrorHandling();

  // Initialize native/video library used throughout the app (MediaKit player).
  // Must be called after Flutter bindings are initialized.
  MediaKit.ensureInitialized();

  // Supabase initialization is handled by SupabaseModule during dependency injection.
  // This keeps the app runnable without Supabase during development while still
  // guaranteeing a single initialization point for SupabaseClient.

  // Root of the dependency graph:
  // - ProviderScope: Riverpod DI / state management.
  // - AppStartupGate: runs bootstrap logic before rendering MyApp.
  runApp(
    AppRestart(
      child: const ProviderScope(child: AppStartupGate(child: MyApp())),
    ),
  );
}
