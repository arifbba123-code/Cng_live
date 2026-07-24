import 'package:hive/hive.dart';

import '../../models/status_update_model.dart';
import '../../models/pump_model.dart';

/// CNG LIVE — Pending Updates Queue (Abstraction)
///
/// The real home for the contract temporarily inlined inside
/// status_repository_impl.dart. Represents the local, offline-first
/// queue of status updates awaiting sync to Firestore (Step 22,
/// Section 13). Contains no Firebase imports and no business logic
/// beyond persistence — deciding *when* to enqueue vs. submit directly
/// (the connectivity check) belongs to a sync coordinator one layer up,
/// not here. This class only stores, lists, and removes queued items.
abstract class PendingUpdatesQueue {
  /// Whether there are any locally queued updates awaiting sync —
  /// backs StatusRepository.hasPendingUpdates() and the "Pending sync"
  /// badge on pump cards (Step 22, Section 13).
  Future<bool> hasPending();

  /// Adds a status update to the local queue, to be synced later.
  Future<void> enqueue(StatusUpdateModel update);

  /// Returns every currently queued update, oldest first — the order a
  /// sync coordinator should submit them in, so a driver's updates
  /// reach Firestore in the sequence they were made.
  Future<List<StatusUpdateModel>> getAll();

  /// Removes a single queued update — called by the sync coordinator
  /// once that update has been successfully submitted to Firestore.
  Future<void> remove(String updateId);

  /// Clears the entire queue. Used sparingly (e.g. after a full
  /// successful sync pass, or account logout) — not part of normal
  /// per-item sync flow.
  Future<void> clear();
}

/// CNG LIVE — Pending Updates Queue (Hive Implementation Skeleton)
///
/// Persists queued StatusUpdateModel entries to a local Hive box, keyed
/// by a locally generated id (separate from any Firestore document id,
/// since queued items haven't reached Firestore yet). Uses a plain
/// Map<String, dynamic> box rather than a generated Hive TypeAdapter to
/// avoid introducing build_runner codegen at this stage — acceptable
/// for the MVP queue's simple read/list/remove access pattern.
///
/// Serialization here is intentionally independent of
/// StatusUpdateModel.toFirestore()/fromFirestore() (which round-trip
/// through cloud_firestore's Timestamp type) — this file must not
/// import Firebase, so timestamps are stored as ISO-8601 strings
/// instead.
class HivePendingUpdatesQueue implements PendingUpdatesQueue {
  HivePendingUpdatesQueue({this.boxName = _defaultBoxName});

  static const String _defaultBoxName = 'pending_status_updates';
  final String boxName;

  Box<Map>? _box;

  /// Opens (or returns the already-open) Hive box. Call
  /// Hive.initFlutter() once during app startup (main.dart, per Step
  /// 22 Section 11) before this is ever invoked.
  Future<Box<Map>> _openBox() async {
    return _box ??= await Hive.openBox<Map>(boxName);
  }

  /// Locally generated id for a not-yet-synced update — a queued item
  /// has no Firestore document id yet, so this stands in until the
  /// sync coordinator submits it and the real id is assigned.
  String _generateLocalId() =>
      'local_${DateTime.now().microsecondsSinceEpoch}';

  Map<String, dynamic> _toMap(String localId, StatusUpdateModel update) {
    return {
      'localId': localId,
      'pumpId': update.pumpId,
      'userId': update.userId,
      'userName': update.userName,
      'status': update.status.toFirestoreValue(),
      'queueLength': update.queueLength,
      'photo': update.photo,
      'timestamp': update.timestamp.toIso8601String(),
      'isFlagged': update.isFlagged,
      'gpsVerified': update.gpsVerified,
    };
  }

  StatusUpdateModel _fromMap(Map map) {
    return StatusUpdateModel(
      id: map['localId'] as String,
      pumpId: map['pumpId'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String?,
      status: PumpStatus.fromFirestore(map['status'] as String?),
      queueLength: map['queueLength'] as String?,
      photo: map['photo'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isFlagged: map['isFlagged'] as bool? ?? false,
      gpsVerified: map['gpsVerified'] as bool? ?? false,
    );
  }

  @override
  Future<bool> hasPending() async {
    final box = await _openBox();
    return box.isNotEmpty;
  }

  @override
  Future<void> enqueue(StatusUpdateModel update) async {
    final box = await _openBox();
    final localId = _generateLocalId();
    await box.put(localId, _toMap(localId, update));
  }

  @override
  Future<List<StatusUpdateModel>> getAll() async {
    final box = await _openBox();
    final entries = box.values.toList();
    final updates = entries.map((raw) => _fromMap(raw)).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return updates;
  }

  @override
  Future<void> remove(String updateId) async {
    final box = await _openBox();
    await box.delete(updateId);
  }

  @override
  Future<void> clear() async {
    final box = await _openBox();
    await box.clear();
  }
}
