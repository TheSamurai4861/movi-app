import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/app_update/data/models/app_update_remote_response.dart';
import 'package:movi/src/core/app_update/domain/entities/app_update_context.dart';
import 'package:movi/src/core/app_update/domain/entities/app_update_decision.dart';

void main() {
  test('cache json serializes soft update status with api format', () {
    final response = AppUpdateRemoteResponse(
      status: AppUpdateStatus.softUpdate,
      reasonCode: 'cached_soft_update',
      currentVersion: '1.0.2',
      platform: 'windows',
      checkedAt: DateTime.utc(2026, 4, 8, 20),
    );

    final json = response.toCacheJson();
    final decoded = AppUpdateRemoteResponse.fromCacheJson(json);

    expect(json['status'], 'soft_update');
    expect(decoded.status, AppUpdateStatus.softUpdate);
  });

  test('cache json remains backward compatible with legacy camelCase status', () {
    final decoded = AppUpdateRemoteResponse.fromCacheJson(<String, dynamic>{
      'status': 'softUpdate',
      'reasonCode': 'cached_soft_update',
      'currentVersion': '1.0.2',
      'platform': 'windows',
      'checkedAt': DateTime.utc(2026, 4, 8, 20).toIso8601String(),
      'cacheTtlSeconds': 21600,
    });

    expect(decoded.status, AppUpdateStatus.softUpdate);
  });

  test('remote json still parses underscored status values', () {
    final decoded = AppUpdateRemoteResponse.fromJson(
      <String, dynamic>{
        'status': 'force_update',
        'reasonCode': 'app_update_required',
      },
      context: const AppUpdateContext(
        appId: 'movi',
        environment: 'prod',
        currentVersion: '1.0.2',
        buildNumber: '9',
        platform: 'windows',
      ),
      checkedAt: DateTime.utc(2026, 4, 8, 20),
    );

    expect(decoded.status, AppUpdateStatus.forceUpdate);
  });
}
