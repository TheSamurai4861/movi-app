import 'package:flutter/foundation.dart';

@immutable
class AppUpdateDecision {
  const AppUpdateDecision({
    required this.status,
    required this.currentVersion,
    required this.platform,
    required this.checkedAt,
    this.reasonCode,
    this.message,
    this.minSupportedVersion,
    this.latestVersion,
    this.updateUrl,
    this.cacheTtl = const Duration(hours: 6),
  });

  final AppUpdateStatus status;
  final String currentVersion;
  final String platform;
  final DateTime checkedAt;
  final String? reasonCode;
  final String? message;
  final String? minSupportedVersion;
  final String? latestVersion;
  final Uri? updateUrl;
  final Duration cacheTtl;

  bool get isBlocking => status == AppUpdateStatus.forceUpdate;
  bool get isAllowed => !isBlocking;

  AppUpdateDecision copyWith({
    AppUpdateStatus? status,
    String? currentVersion,
    String? platform,
    DateTime? checkedAt,
    Object? reasonCode = _sentinel,
    Object? message = _sentinel,
    Object? minSupportedVersion = _sentinel,
    Object? latestVersion = _sentinel,
    Object? updateUrl = _sentinel,
    Duration? cacheTtl,
  }) {
    return AppUpdateDecision(
      status: status ?? this.status,
      currentVersion: currentVersion ?? this.currentVersion,
      platform: platform ?? this.platform,
      checkedAt: checkedAt ?? this.checkedAt,
      reasonCode: identical(reasonCode, _sentinel)
          ? this.reasonCode
          : reasonCode as String?,
      message: identical(message, _sentinel)
          ? this.message
          : message as String?,
      minSupportedVersion: identical(minSupportedVersion, _sentinel)
          ? this.minSupportedVersion
          : minSupportedVersion as String?,
      latestVersion: identical(latestVersion, _sentinel)
          ? this.latestVersion
          : latestVersion as String?,
      updateUrl: identical(updateUrl, _sentinel)
          ? this.updateUrl
          : updateUrl as Uri?,
      cacheTtl: cacheTtl ?? this.cacheTtl,
    );
  }

  static const Object _sentinel = Object();

  factory AppUpdateDecision.allow({
    required String currentVersion,
    required String platform,
    required DateTime checkedAt,
    String reasonCode = 'app_update_allowed',
    String? latestVersion,
    String? minSupportedVersion,
    String? message,
    Uri? updateUrl,
    Duration cacheTtl = const Duration(hours: 6),
  }) {
    return AppUpdateDecision(
      status: AppUpdateStatus.allowed,
      currentVersion: currentVersion,
      platform: platform,
      checkedAt: checkedAt,
      reasonCode: reasonCode,
      latestVersion: latestVersion,
      minSupportedVersion: minSupportedVersion,
      message: message,
      updateUrl: updateUrl,
      cacheTtl: cacheTtl,
    );
  }

  factory AppUpdateDecision.softUpdate({
    required String currentVersion,
    required String platform,
    required DateTime checkedAt,
    String reasonCode = 'app_update_recommended',
    String? latestVersion,
    String? minSupportedVersion,
    String? message,
    Uri? updateUrl,
    Duration cacheTtl = const Duration(hours: 6),
  }) {
    return AppUpdateDecision(
      status: AppUpdateStatus.softUpdate,
      currentVersion: currentVersion,
      platform: platform,
      checkedAt: checkedAt,
      reasonCode: reasonCode,
      latestVersion: latestVersion,
      minSupportedVersion: minSupportedVersion,
      message: message,
      updateUrl: updateUrl,
      cacheTtl: cacheTtl,
    );
  }

  factory AppUpdateDecision.forceUpdate({
    required String currentVersion,
    required String platform,
    required DateTime checkedAt,
    String reasonCode = 'app_update_required',
    String? latestVersion,
    String? minSupportedVersion,
    String? message,
    Uri? updateUrl,
    Duration cacheTtl = const Duration(hours: 6),
  }) {
    return AppUpdateDecision(
      status: AppUpdateStatus.forceUpdate,
      currentVersion: currentVersion,
      platform: platform,
      checkedAt: checkedAt,
      reasonCode: reasonCode,
      latestVersion: latestVersion,
      minSupportedVersion: minSupportedVersion,
      message: message,
      updateUrl: updateUrl,
      cacheTtl: cacheTtl,
    );
  }
}

enum AppUpdateStatus { allowed, softUpdate, forceUpdate }
