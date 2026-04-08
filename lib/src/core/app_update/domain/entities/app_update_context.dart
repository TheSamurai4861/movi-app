import 'package:flutter/foundation.dart';

@immutable
class AppUpdateContext {
  const AppUpdateContext({
    required this.appId,
    required this.environment,
    required this.currentVersion,
    required this.buildNumber,
    required this.platform,
    this.osVersion,
  });

  final String appId;
  final String environment;
  final String currentVersion;
  final String buildNumber;
  final String platform;
  final String? osVersion;
}
