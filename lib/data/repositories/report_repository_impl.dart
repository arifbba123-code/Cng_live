import '../../core/errors/error_handler.dart';
import '../../core/network/network_result.dart';
import '../datasources/remote/report_remote_datasource.dart';
import '../models/report_model.dart';
import 'report_repository.dart';

/// CNG LIVE — Report Repository (Implementation)
///
/// Implements the approved ReportRepository contract by delegating all
/// Firestore access to ReportRemoteDataSource and converting thrown
/// exceptions into typed Failures via ErrorHandler.handle(), mirroring
/// StatusRepositoryImpl's established pattern.
class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl(this._remoteDataSource);

  final ReportRemoteDataSource _remoteDataSource;

  @override
  Future<Result<ReportModel>> submitReport(ReportModel report) async {
    try {
      final submitted = await _remoteDataSource.submitReport(report);
      return Result.success(submitted);
    } catch (e) {
      return Result.failure(ErrorHandler.handle(e, context: 'submitReport'));
    }
  }

  @override
  Future<Result<List<ReportModel>>> getReportsByUser(String userId) async {
    try {
      final reports = await _remoteDataSource.getReportsByUser(userId);
      return Result.success(reports);
    } catch (e) {
      return Result.failure(
        ErrorHandler.handle(e, context: 'getReportsByUser'),
      );
    }
  }

  @override
  Future<Result<List<ReportModel>>> getReportsForStatusUpdate(
    String statusUpdateId,
  ) async {
    try {
      final reports =
          await _remoteDataSource.getReportsForStatusUpdate(statusUpdateId);
      return Result.success(reports);
    } catch (e) {
      return Result.failure(
        ErrorHandler.handle(e, context: 'getReportsForStatusUpdate'),
      );
    }
  }
}
