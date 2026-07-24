import '../../core/network/network_result.dart';
import '../models/pump_model.dart';

/// CNG LIVE — Pump Repository (Interface)
///
/// Defines the contract for pump list/detail access and live status
/// streaming. Backs Home Screen (Step 13), Pump Detail (Step 14), and
/// Search (Step 2 screen list). Pumps are curated/admin-seeded for MVP
/// (Step 1) — no create/delete methods are exposed to driver-facing
/// ViewModels.
abstract class PumpRepository {
  /// Live stream of pumps near the given coordinates, ordered by
  /// distance. Powers Home Screen's "Nearby Pumps" list (Step 13) and
  /// stays live via Firestore snapshots — no manual refresh needed for
  /// status changes, only for the driver's own location changing.
  Stream<List<PumpModel>> watchNearbyPumps({
    required double latitude,
    required double longitude,
    double radiusKm = 150,
  });

  /// Live stream of every pump in /pumps, unfiltered by location —
  /// powers the Home Screen map view, which plots every pump on the
  /// map rather than just the ones within a nearby radius.
  Stream<List<PumpModel>> watchAllPumps();

  /// Live stream of a single pump's document — powers Pump Detail's
  /// hero status card (Step 14), auto-updating without a pull-to-refresh
  /// when another driver posts a new status.
  Stream<PumpModel> watchPumpById(String pumpId);

  /// One-off fetch, used where a stream isn't appropriate (e.g. pre-
  /// filling the Update Status screen's selected-pump card, Step 15).
  Future<Result<PumpModel>> getPumpById(String pumpId);

  /// Text search across pump name/area — backs the Search screen
  /// (Step 2 screen list) with debounced queries (core/utils/debouncer).
  Future<Result<List<PumpModel>>> searchPumps(String query);

  /// Returns pumps filtered by status/verified-only, per the Filter
  /// sheet on Home Screen (Step 13, "Filter ⚙").
  Future<Result<List<PumpModel>>> filterPumps({
    PumpStatus? status,
    bool? verifiedOnly,
    required double latitude,
    required double longitude,
    double radiusKm = 150,
  });
}
