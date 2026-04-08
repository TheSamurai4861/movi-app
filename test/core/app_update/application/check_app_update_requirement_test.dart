import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/app_update/application/check_app_update_requirement.dart';
import 'package:movi/src/core/app_update/domain/entities/app_update_context.dart';
import 'package:movi/src/core/app_update/domain/entities/app_update_decision.dart';
import 'package:movi/src/core/app_update/domain/repositories/app_update_repository.dart';
import 'package:movi/src/core/app_update/domain/services/app_runtime_info_provider.dart';

void main() {
  test('delegates runtime context to repository', () async {
    final context = AppUpdateContext(
      appId: 'movi',
      environment: 'prod',
      currentVersion: '1.0.2',
      buildNumber: '9',
      platform: 'android',
    );
    final repository = _FakeRepository();
    final useCase = CheckAppUpdateRequirement(
      runtimeInfoProvider: _FakeRuntimeInfoProvider(context),
      repository: repository,
    );

    final decision = await useCase();

    expect(repository.receivedContext, same(context));
    expect(decision.status, AppUpdateStatus.allowed);
  });
}

class _FakeRuntimeInfoProvider implements AppRuntimeInfoProvider {
  const _FakeRuntimeInfoProvider(this.context);

  final AppUpdateContext context;

  @override
  Future<AppUpdateContext> loadContext() async => context;
}

class _FakeRepository implements AppUpdateRepository {
  AppUpdateContext? receivedContext;

  @override
  Future<AppUpdateDecision> check(AppUpdateContext context) async {
    receivedContext = context;
    return AppUpdateDecision.allow(
      currentVersion: context.currentVersion,
      platform: context.platform,
      checkedAt: DateTime.now().toUtc(),
    );
  }
}
