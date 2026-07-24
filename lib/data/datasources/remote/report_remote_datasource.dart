import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/report_model.dart';

/// CNG LIVE — Report Remote Data Source
///
/// Owns every Firestore call needed for filing and reading reports
/// (Step 22, Section 14). Mirrors StatusRemoteDataSource's contract:
/// every method returns a plain model/value or throws a typed
/// exception (ServerException) — never a Result<T>, and never business
/// logic beyond the schema mechanics described below. This is the only
/// place in the app that imports cloud_firestore for report data.
class ReportRemoteDataSource {
  ReportRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reportsRef =>
      _firestore.collection(FirestorePaths.reports);

  CollectionReference<Map<String, dynamic>> _statusUpdatesRef() =>
      _firestore.collection(FirestorePaths.statusUpdates);

  /// Writes the report to /reports/{id} and, in the same batch, sets
  /// isFlagged = true on the disputed /statusUpdates/{statusUpdateId}
  /// document — per ReportRepository's doc comment, filing a report
  /// and flagging the update it disputes is one logical operation.
  Future<ReportModel> submitReport(ReportModel report) async {
    try {
      final docRef = _reportsRef.doc();
      final data = report.toFirestore();

      final batch = _firestore.batch();
      batch.set(docRef, data);
      batch.update(
        _statusUpdatesRef().doc(report.statusUpdateId),
        {FirestorePaths.fieldIsFlagged: true},
      );
      await batch.commit();

      return ReportModel(
        id: docRef.id,
        statusUpdateId: report.statusUpdateId,
        pumpId: report.pumpId,
        reportedBy: report.reportedBy,
        reason: report.reason,
        timestamp: report.timestamp,
        resolved: report.resolved,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<ReportModel>> getReportsByUser(String userId) async {
    try {
      final snapshot = await _reportsRef
          .where('reportedBy', isEqualTo: userId)
          .orderBy(FirestorePaths.fieldTimestamp, descending: true)
          .get();
      return snapshot.docs.map(ReportModel.fromFirestore).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<ReportModel>> getReportsForStatusUpdate(
    String statusUpdateId,
  ) async {
    try {
      final snapshot = await _reportsRef
          .where(FirestorePaths.fieldStatusUpdateId, isEqualTo: statusUpdateId)
          .orderBy(FirestorePaths.fieldTimestamp, descending: true)
          .get();
      return snapshot.docs.map(ReportModel.fromFirestore).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
