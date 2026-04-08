import 'dart:convert';

import 'package:movi/src/core/app_update/domain/entities/app_update_context.dart';
import 'package:movi/src/core/app_update/domain/entities/app_update_decision.dart';

class AppUpdateRemoteResponse {
  const AppUpdateRemoteResponse({
    required this.status,
    required this.reasonCode,
    required this.currentVersion,
    required this.platform,
    required this.checkedAt,
    this.message,
    this.minSupportedVersion,
    this.latestVersion,
    this.updateUrl,
    this.cacheTtl = const Duration(hours: 6),
  });

  factory AppUpdateRemoteResponse.fromJson(
    Map<String, dynamic> json, {
    required AppUpdateContext context,
    required DateTime checkedAt,
  }) {
    final normalizedStatus = _readRequiredString(json, 'status').toLowerCase();
    final ttlSeconds = _readInt(json, 'cacheTtlSeconds') ?? 21600;
    final updateUrl = _readOptionalUri(json['updateUrl']);

    return AppUpdateRemoteResponse(
      status: _parseStatus(normalizedStatus),
      reasonCode:
          _readOptionalString(json['reasonCode']) ??
          _defaultReasonCode(normalizedStatus),
      currentVersion:
          _readOptionalString(json['currentVersion']) ?? context.currentVersion,
      platform: _readOptionalString(json['platform']) ?? context.platform,
      checkedAt: checkedAt,
      message: _readOptionalString(json['message']),
      minSupportedVersion: _readOptionalString(json['minSupportedVersion']),
      latestVersion: _readOptionalString(json['latestVersion']),
      updateUrl: updateUrl,
      cacheTtl: Duration(seconds: ttlSeconds < 0 ? 0 : ttlSeconds),
    );
  }

  final AppUpdateStatus status;
  final String reasonCode;
  final String currentVersion;
  final String platform;
  final DateTime checkedAt;
  final String? message;
  final String? minSupportedVersion;
  final String? latestVersion;
  final Uri? updateUrl;
  final Duration cacheTtl;

  AppUpdateDecision toDecision() {
    switch (status) {
      case AppUpdateStatus.allowed:
        return AppUpdateDecision.allow(
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
      case AppUpdateStatus.softUpdate:
        return AppUpdateDecision.softUpdate(
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
      case AppUpdateStatus.forceUpdate:
        return AppUpdateDecision.forceUpdate(
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

  Map<String, dynamic> toCacheJson() {
    return <String, dynamic>{
      'status': _encodeStatus(status),
      'reasonCode': reasonCode,
      'currentVersion': currentVersion,
      'platform': platform,
      'checkedAt': checkedAt.toUtc().toIso8601String(),
      'message': message,
      'minSupportedVersion': minSupportedVersion,
      'latestVersion': latestVersion,
      'updateUrl': updateUrl?.toString(),
      'cacheTtlSeconds': cacheTtl.inSeconds,
    };
  }

  static AppUpdateRemoteResponse fromCacheJson(Map<String, dynamic> json) {
    final checkedAtRaw = _readRequiredString(json, 'checkedAt');
    final checkedAt = DateTime.parse(checkedAtRaw).toUtc();
    final ttlSeconds = _readInt(json, 'cacheTtlSeconds') ?? 21600;

    return AppUpdateRemoteResponse(
      status: _parseStatus(_readRequiredString(json, 'status').toLowerCase()),
      reasonCode:
          _readOptionalString(json['reasonCode']) ?? 'app_update_cached_decision',
      currentVersion: _readRequiredString(json, 'currentVersion'),
      platform: _readRequiredString(json, 'platform'),
      checkedAt: checkedAt,
      message: _readOptionalString(json['message']),
      minSupportedVersion: _readOptionalString(json['minSupportedVersion']),
      latestVersion: _readOptionalString(json['latestVersion']),
      updateUrl: _readOptionalUri(json['updateUrl']),
      cacheTtl: Duration(seconds: ttlSeconds < 0 ? 0 : ttlSeconds),
    );
  }

  static Map<String, dynamic> decodeJsonMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw FormatException('Unexpected app update response: ${value.runtimeType}');
  }

  static String _readRequiredString(Map<String, dynamic> json, String key) {
    final value = _readOptionalString(json[key]);
    if (value == null) {
      throw FormatException('App update response missing "$key".');
    }
    return value;
  }

  static String? _readOptionalString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static int? _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static Uri? _readOptionalUri(Object? value) {
    final text = _readOptionalString(value);
    if (text == null) return null;
    return Uri.tryParse(text);
  }

  static AppUpdateStatus _parseStatus(String status) {
    switch (status) {
      case 'allowed':
        return AppUpdateStatus.allowed;
      case 'soft_update':
      case 'softupdate':
        return AppUpdateStatus.softUpdate;
      case 'force_update':
      case 'forceupdate':
        return AppUpdateStatus.forceUpdate;
      default:
        throw FormatException('Unknown app update status "$status".');
    }
  }

  static String _encodeStatus(AppUpdateStatus status) {
    switch (status) {
      case AppUpdateStatus.allowed:
        return 'allowed';
      case AppUpdateStatus.softUpdate:
        return 'soft_update';
      case AppUpdateStatus.forceUpdate:
        return 'force_update';
    }
  }

  static String _defaultReasonCode(String status) {
    switch (status) {
      case 'allowed':
        return 'app_update_allowed';
      case 'soft_update':
        return 'app_update_recommended';
      case 'force_update':
        return 'app_update_required';
      default:
        return 'app_update_unknown';
    }
  }
}
