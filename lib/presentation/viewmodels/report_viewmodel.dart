import 'package:flutter/foundation.dart';

import '../../data/models/report_model.dart';
import '../../data/repositories/report_repository.dart';

class ReportViewModel extends ChangeNotifier {
  ReportViewModel(this._reportRepository);

  final ReportRepository _reportRepository;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<bool> submitReport({
    required String statusUpdateId,
    required String pumpId,
    required String reportedBy,
    required String reason,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final report = ReportModel(
      id: '',
      statusUpdateId: statusUpdateId,
      pumpId: pumpId,
      reportedBy: reportedBy,
      reason: reason,
      timestamp: DateTime.now(),
    );

    final result = await _reportRepository.submitReport(report);
    var success = false;

    result.when(
      success: (_) => success = true,
      failure: (failure) => _errorMessage = failure.message,
    );

    _isSubmitting = false;
    notifyListeners();
    return success;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
