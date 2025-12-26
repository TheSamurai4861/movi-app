import 'package:movi/src/core/reporting/domain/entities/content_report.dart';

abstract class ContentReportsRepository {
  Future<void> createReport(ContentReport report);
}

