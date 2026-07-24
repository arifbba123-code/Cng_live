import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../data/models/badge_model.dart';
import '../../data/models/status_update_model.dart';
import '../../data/repositories/badge_repository.dart';
import '../../data/repositories/status_repository.dart';

enum StatusSubmitState { idle, loading, success, error }

class StatusViewModel extends ChangeNotifier {
  StatusViewModel(this._statusRepository, [this._badgeRepository]);

  final StatusRepository _statusRepository;

  /// Optional — badge-progress tracking is a secondary effect of a
  /// successful submission (Step 16), not core to status posting
  /// itself, so this stays nullable rather than forcing every existing
  /// call site (and every test) to supply one.
  final BadgeRepository? _badgeRepository;

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
        // Fire-and-forget: badge progress must never block or fail the
        // submission flow the driver is actually waiting on.
        unawaited(_updateBadgeProgress(submitted));
      },
      failure: (failure) {
        _errorMessage = failure.message;
        _state = StatusSubmitState.error;
        notifyListeners();
      },
    );
  }

  /// Advances the 3 client-trackable badges from BadgeCatalog after a
  /// successful submission. topContributor is deliberately excluded —
  /// it's driven by the weekly leaderboard recomputation server-side,
  /// not by any single status update (see LeaderboardRepository's doc
  /// comment).
  ///
  /// SCOPE NOTE: fastReporter's real definition ("within 5 minutes of
  /// arrival") and trustedDriver's real definition ("90%+ accuracy")
  /// both need data this app doesn't currently track client-side
  /// (arrival timestamps, historical flag ratio). As a pragmatic
  /// approximation: fastReporter counts GPS-verified updates, and
  /// trustedDriver counts total updates while only unlocking on an
  /// update that wasn't itself flagged. Replacing this with the exact
  /// definitions is a follow-up, not guessed at further here.
  Future<void> _updateBadgeProgress(StatusUpdateModel update) async {
    final badgeRepository = _badgeRepository;
    if (badgeRepository == null) return;

    try {
      await _incrementBadge(badgeRepository, update.userId, BadgeId.hundredUpdatesClub);
      if (!update.isFlagged) {
        await _incrementBadge(badgeRepository, update.userId, BadgeId.trustedDriver);
      }
      if (update.gpsVerified) {
        await _incrementBadge(badgeRepository, update.userId, BadgeId.fastReporter);
      }
    } catch (_) {
      // Badge tracking is best-effort — a failure here shouldn't
      // surface anywhere the driver would see it.
    }
  }

  Future<void> _incrementBadge(
    BadgeRepository badgeRepository,
    String userId,
    BadgeId badgeId,
  ) async {
    final currentResult = await badgeRepository.getBadgeById(userId, badgeId);
    await currentResult.when(
      success: (badge) async {
        if (badge.isUnlocked) return;
        final newProgress = badge.progressCurrent + 1;
        if (newProgress >= badge.definition.targetValue) {
          await badgeRepository.unlockBadge(userId: userId, badgeId: badgeId);
        } else {
          await badgeRepository.updateBadgeProgress(
            userId: userId,
            badgeId: badgeId,
            progressCurrent: newProgress,
          );
        }
      },
      failure: (_) async {},
    );
  }

  void reset() {
    _state = StatusSubmitState.idle;
    _errorMessage = null;
    _submittedUpdate = null;
    notifyListeners();
  }
}
