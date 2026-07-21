import 'package:flutter/foundation.dart';

import '../../data/models/status_update_model.dart';
import '../../data/repositories/status_repository.dart';

enum StatusSubmitState { idle, loading, success, error }

class StatusViewModel extends ChangeNotifier {
  StatusViewModel(this._statusRepository);

  final StatusRepository _statusRepository;

  StatusSubmitState _state = StatusSubmitState.idle;
  String? _errorMessage;
  StatusUpdateModel? _submittedUpdate;

  StatusSubmitState get state => _state;
  bool get isLoading => _state == StatusSubmitState.loading;
  bool get isSuccess => _state == StatusSubmitState.success;
  String? get errorMessage => _errorMessage;
  StatusUpdateModel? get submittedUpdate => _submittedUpdate;

  Future<void> submitStatusUpdate(StatusUpdateModel update) async {
    _state = StatusSubmitState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _statusRepository.submitStatusUpdate(update);

    result.when(
      success: (submitted) {
        _submittedUpdate = submitted;
        _state = StatusSubmitState.success;
        notifyListeners();
      },
      failure: (failure) {
        _errorMessage = failure.message;
        _state = StatusSubmitState.error;
        notifyListeners();
      },
    );
  }

  void reset() {
    _state = StatusSubmitState.idle;
    _errorMessage = null;
    _submittedUpdate = null;
    notifyListeners();
  }
}
