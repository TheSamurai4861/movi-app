import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/app_update/data/models/app_update_remote_request.dart';
import 'package:movi/src/core/app_update/data/models/app_update_remote_response.dart';
import 'package:movi/src/core/app_update/domain/entities/app_update_context.dart';

class AppUpdateEdgeService {
  const AppUpdateEdgeService(this._client);

  static const String functionName = 'check-app-version';

  final SupabaseClient _client;

  Future<AppUpdateRemoteResponse> fetchDecision(AppUpdateContext context) async {
    final checkedAt = DateTime.now().toUtc();
    final response = await _client.functions.invoke(
      functionName,
      body: AppUpdateRemoteRequest.fromContext(context).toJson(),
    );

    final data = AppUpdateRemoteResponse.decodeJsonMap(response.data);
    return AppUpdateRemoteResponse.fromJson(
      data,
      context: context,
      checkedAt: checkedAt,
    );
  }
}
