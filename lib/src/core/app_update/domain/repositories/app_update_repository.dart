import 'package:movi/src/core/app_update/domain/entities/app_update_context.dart';
import 'package:movi/src/core/app_update/domain/entities/app_update_decision.dart';

abstract interface class AppUpdateRepository {
  Future<AppUpdateDecision> check(AppUpdateContext context);
}
