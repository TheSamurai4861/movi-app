import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/reporting/domain/entities/content_report.dart';
import 'package:movi/src/core/reporting/domain/repositories/content_reports_repository.dart';
import 'package:movi/src/core/supabase/supabase_error_mapper.dart';

class SupabaseContentReportsRepository implements ContentReportsRepository {
  SupabaseContentReportsRepository(this._client);

  final SupabaseClient _client;

  static const String _table = 'content_reports';

  @override
  Future<void> createReport(ContentReport report) async {
    try {
      await _client.from(_table).insert(report.toJson());
    } catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace: stackTrace);
    }
  }
}

