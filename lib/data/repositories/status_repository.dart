import '../../core/network/network_result.dart';
import '../models/status_update_model.dart';

/// CNG LIVE — Status Repository (Interface)
///
/// Defines the contract for submitting and reading status updates.
/// Backs the Update Status screen (Step 15) and Pump Detail's Status
/// History timeline (Step 14).
///
/// Offline-first note (Step 22, Section 13): [submitStatusUpdate] never
/// blocks or throws when offline — the implementation is responsible
/// for queueing the write locally (pending_updates_queue.dart) and
/// syncing automatically once connectivity returns. The returned
/// Result reflects submission being *accepted* (queued or sent), not
/// necessarily confirmed by the server yet.
abstract class StatusRepository {
  /// Submits a new status update. Writes to both the pump's
  /// statusHistory subcollection and the flat statusUpdates mirror
  /// (Step 22, Section 14) in a single logical operation.
  ///
  /// If offline, queues locally and returns success immediately with
  /// the update in a "pending sync" state — UI should reflect this via
  /// StatusUpdateModel's future pendingSync flag (see repository impl).
  Future<Result<StatusUpdateModel>> submitStatusUpdate(StatusUpdateModel update);

  /// Live stream of the most recent updates for one pump, newest first
  /// — powers Pump Detail's Status History timeline (Step 14, default
  /// view shows last 3, "View Full History" expands further).
  Stream<List<StatusUpdateModel>> watchStatusHistory(
    String pumpId, {
    int limit = 3,
  });

  /// One-off fetch of a pump's full status history (Step 14 "View Full
  /// History" expanded view), with pagination support.
  Future<Result<List<StatusUpdateModel>>> getFullStatusHistory(
    String pumpId, {
    int limit = 20,
    StatusUpdateModel? startAfter,
  });

  /// A single driver's own contribution history, newest first — powers
  /// Profile's Recent Activity (Step 16) and the full My Contributions
  /// screen (Step 2 screen list), paginated via infinite scroll.
  Future<Result<List<StatusUpdateModel>>> getUserContributions(
    String userId, {
    int limit = 20,
    StatusUpdateModel? startAfter,
  });

  /// Whether there are updates still queued locally awaiting sync —
  /// used to drive the "Pending sync" badge on pump cards (Step 22,
  /// Section 13) after the driver comes back online.
  Future<bool> hasPendingUpdates();
}
