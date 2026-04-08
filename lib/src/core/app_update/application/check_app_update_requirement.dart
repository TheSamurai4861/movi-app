import 'package:movi/src/core/app_update/domain/entities/app_update_decision.dart';
import 'package:movi/src/core/app_update/domain/repositories/app_update_repository.dart';
import 'package:movi/src/core/app_update/domain/services/app_runtime_info_provider.dart';

class CheckAppUpdateRequirement {
  const CheckAppUpdateRequirement({
    required AppRuntimeInfoProvider runtimeInfoProvider,
    required AppUpdateRepository repository,
  }) : _runtimeInfoProvider = runtimeInfoProvider,
       _repository = repository;

  final AppRuntimeInfoProvider _runtimeInfoProvider;
  final AppUpdateRepository _repository;

  Future<AppUpdateDecision> call() async {
    final context = await _runtimeInfoProvider.loadContext();
    return _repository.check(context);
  }
}
