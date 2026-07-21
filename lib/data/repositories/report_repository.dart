import '../../core/network/network_result.dart';
import '../models/report_model.dart';

/// CNG LIVE — Report Repository (Interface)
///
/// Defines the contract for filing and reading "Report Wrong Update"
/// submissions (Step 14 Pump Detail action, Step 2 dedicated screen).
/// Per Step 22, Section 4's repository table, this is a distinct
/// repository from StatusRepository — reports dispute an update, they
/// don't belong to the update-authoring flow itself.
abstract class ReportRepository {
  /// Files a report against a specific status update. Does not modify
  /// or delete the disputed StatusUpdateModel — the implementation is
  /// responsible for also setting isFlagged = true on that update's
  /// document as part of this same logical operation (Step 14).
  Future<Result<ReportModel>> submitReport(ReportModel report);

  /// Reports filed by a specific driver — not exposed in any MVP screen
  /// yet, but useful for a driver to see their own report history and
  /// for future abuse-prevention (e.g. rate-limiting repeat reporters).
  Future<Result<List<ReportModel>>> getReportsByUser(String userId);

  /// All reports filed against a specific status update — used to
  /// determine whether an update has crossed a flagging threshold
  /// (e.g. 3+ reports) that should reduce its trust weight.
  Future<Result<List<ReportModel>>> getReportsForStatusUpdate(
    String statusUpdateId,
  );
}
