import 'package:movi/src/core/app_update/domain/entities/app_update_context.dart';

class AppUpdateRemoteRequest {
  const AppUpdateRemoteRequest({
    required this.appId,
    required this.environment,
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    this.osVersion,
  });

  factory AppUpdateRemoteRequest.fromContext(AppUpdateContext context) {
    return AppUpdateRemoteRequest(
      appId: context.appId,
      environment: context.environment,
      appVersion: context.currentVersion,
      buildNumber: context.buildNumber,
      platform: context.platform,
      osVersion: context.osVersion,
    );
  }

  final String appId;
  final String environment;
  final String appVersion;
  final String buildNumber;
  final String platform;
  final String? osVersion;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'appId': appId,
      'environment': environment,
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'platform': platform,
      if (osVersion != null && osVersion!.trim().isNotEmpty)
        'osVersion': osVersion,
    };
  }
}
