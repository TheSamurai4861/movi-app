import 'package:movi/src/core/app_update/domain/entities/app_update_context.dart';

abstract interface class AppRuntimeInfoProvider {
  Future<AppUpdateContext> loadContext();
}
