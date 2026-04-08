import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:movi/src/core/app_update/domain/entities/app_update_context.dart';
import 'package:movi/src/core/app_update/domain/services/app_runtime_info_provider.dart';

class PackageInfoAppRuntimeInfoProvider implements AppRuntimeInfoProvider {
  const PackageInfoAppRuntimeInfoProvider({
    this.packageInfoLoader = PackageInfo.fromPlatform,
    this.appId = 'movi',
    String environment = '',
  }) : _environment = environment;

  final Future<PackageInfo> Function() packageInfoLoader;
  final String appId;
  final String _environment;

  @override
  Future<AppUpdateContext> loadContext() async {
    final packageInfo = await packageInfoLoader();
    final version = _normalize(packageInfo.version) ?? '0.0.0';
    final buildNumber = _normalize(packageInfo.buildNumber) ?? '0';

    return AppUpdateContext(
      appId: appId,
      environment: _environment.isEmpty ? _resolveEnvironment() : _environment,
      currentVersion: version,
      buildNumber: buildNumber,
      platform: _resolvePlatform(),
      osVersion: _resolveOsVersion(),
    );
  }

  String _resolveEnvironment() {
    const appEnv = String.fromEnvironment('APP_ENV');
    if (appEnv.trim().isNotEmpty) {
      return appEnv.trim().toLowerCase();
    }

    const flutterAppEnv = String.fromEnvironment('FLUTTER_APP_ENV');
    if (flutterAppEnv.trim().isNotEmpty) {
      return flutterAppEnv.trim().toLowerCase();
    }

    return kReleaseMode ? 'prod' : 'dev';
  }

  String _resolvePlatform() {
    if (kIsWeb) return 'web';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  String? _resolveOsVersion() {
    return null;
  }

  String? _normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
