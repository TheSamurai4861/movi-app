import 'package:movi/src/core/reporting/domain/entities/content_report.dart';
import 'package:movi/src/core/reporting/domain/repositories/content_reports_repository.dart';

class ReportContentProblem {
  const ReportContentProblem(this._repo);

  final ContentReportsRepository _repo;

  Future<void> call(ContentReport report) => _repo.createReport(report);
}

