import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/constants/firestore_paths.dart';
import '../../core/utils/distance_calculator.dart';
import '../../services/location_service.dart';

/// CNG LIVE — On-Screen Debug Report
///
/// TEMPORARY DIAGNOSTIC SCREEN — not part of the approved architecture.
///
/// Exists because the device this app is tested on has no logcat/adb
/// access. Every value that the normal Home → PumpViewModel →
/// PumpRepositoryImpl → PumpRemoteDataSource → PumpModel → Firestore
/// pipeline depends on is re-computed here, independently, and printed
/// straight to the screen — so the exact stage where a pump drops out
/// of "nearby" is visible without needing a single log line.
///
/// It intentionally duplicates (rather than imports) the private
/// bounding-box/radius logic from PumpRepositoryImpl, because the
/// point is to verify that logic against the raw Firestore data, not
/// to trust it.
class DebugReportScreen extends StatefulWidget {
  const DebugReportScreen({super.key});

  @override
  State<DebugReportScreen> createState() => _DebugReportScreenState();
}

class _DebugReportScreenState extends State<DebugReportScreen> {
  static const double _defaultRadiusKm = 150;
  static const double _kmPerDegreeLat = 110.574;

  final _locationService = LocationService();

  bool _isLoading = true;

  // GPS
  bool? _serviceEnabled;
  LocationPermission? _permission;
  Position? _position;
  String? _locationErrorMessage;

  // Firestore
  int? _unfilteredDocCount;
  List<_DocReport> _docReports = [];
  String? _firestoreErrorMessage;

  // The exact query the app uses (PumpRemoteDataSource.watchPumpsInBoundingBox
  // / filterPumpsInBoundingBox), run here directly so its result count is
  // visible on screen.
  int? _afterLatitudeQueryCount;
  int? _afterLongitudeFilterCount;
  int? _afterRadiusFilterCount;
  String? _boundingBoxQueryErrorMessage;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _isLoading = true);
    await _runLocationDiagnostics();
    await _runFirestoreDiagnostics();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _runLocationDiagnostics() async {
    try {
      _serviceEnabled = await _locationService.isLocationServiceEnabled();
      _permission = await _locationService.checkPermission();

      if (_permission == LocationPermission.denied) {
        _permission = await _locationService.requestPermission();
      }

      if (_permission == LocationPermission.always ||
          _permission == LocationPermission.whileInUse) {
        _position = await _locationService.getCurrentPosition();
      }
      _locationErrorMessage = null;
    } catch (e) {
      _locationErrorMessage = e.toString();
    }
  }

  Future<void> _runFirestoreDiagnostics() async {
    final pumpsRef =
        FirebaseFirestore.instance.collection(FirestorePaths.pumps);

    // 1. Raw, unfiltered dump — exactly what is physically in /pumps,
    // with no query conditions at all.
    try {
      final snapshot = await pumpsRef.get();
      _unfilteredDocCount = snapshot.docs.length;
      _docReports = snapshot.docs.map((doc) {
        final data = doc.data();
        return _DocReport(
          id: doc.id,
          rawData: data,
          latitudeRaw: data[FirestorePaths.fieldLatitude],
          longitudeRaw: data[FirestorePaths.fieldLongitude],
        );
      }).toList();
      _firestoreErrorMessage = null;
    } catch (e) {
      _firestoreErrorMessage = e.toString();
      _unfilteredDocCount = null;
      _docReports = [];
    }

    // 2. Re-run the SAME staged query the real app uses, so we can see
    // exactly which stage a document survives or drops out at. Only
    // meaningful if we have a device position to build the bounding box.
    if (_position == null) return;

    final lat = _position!.latitude;
    final lng = _position!.longitude;
    const radiusKm = _defaultRadiusKm;

    final latDelta = radiusKm / _kmPerDegreeLat;
    final kmPerDegreeLng = _kmPerDegreeLat * cos(lat * pi / 180);
    final lngDelta = kmPerDegreeLng == 0 ? 180.0 : radiusKm / kmPerDegreeLng;
    final minLat = lat - latDelta;
    final maxLat = lat + latDelta;
    final minLng = lng - lngDelta;
    final maxLng = lng + lngDelta;

    try {
      // Stage A: the exact Firestore .where() clause PumpRemoteDataSource
      // sends over the wire (server-side range filter on latitude only).
      final stageASnapshot = await pumpsRef
          .where(FirestorePaths.fieldLatitude, isGreaterThanOrEqualTo: minLat)
          .where(FirestorePaths.fieldLatitude, isLessThanOrEqualTo: maxLat)
          .get();
      _afterLatitudeQueryCount = stageASnapshot.docs.length;

      // Stage B: client-side longitude range filter (mirrors
      // PumpRemoteDataSource's longitude trimming).
      final stageBDocs = stageASnapshot.docs.where((doc) {
        final lngVal =
            (doc.data()[FirestorePaths.fieldLongitude] as num?)?.toDouble() ??
                0.0;
        return lngVal >= minLng && lngVal <= maxLng;
      }).toList();
      _afterLongitudeFilterCount = stageBDocs.length;

      // Stage C: exact circular radius filter (mirrors
      // PumpRepositoryImpl._filterAndSortByRadius).
      final stageCDocs = stageBDocs.where((doc) {
        final data = doc.data();
        final docLat = (data[FirestorePaths.fieldLatitude] as num?)
                ?.toDouble() ??
            0.0;
        final docLng = (data[FirestorePaths.fieldLongitude] as num?)
                ?.toDouble() ??
            0.0;
        final distanceKm = DistanceCalculator.distanceInKm(
          lat1: lat,
          lon1: lng,
          lat2: docLat,
          lon2: docLng,
        );
        return distanceKm <= radiusKm;
      }).toList();
      _afterRadiusFilterCount = stageCDocs.length;

      // Annotate every raw doc with its per-stage pass/fail so we can
      // point at the exact doc + exact stage where it disappears.
      for (final report in _docReports) {
        report.boundingBox = _BoundingBoxResult(
          minLat: minLat,
          maxLat: maxLat,
          minLng: minLng,
          maxLng: maxLng,
          radiusKm: radiusKm,
          userLat: lat,
          userLng: lng,
        );
      }
      _boundingBoxQueryErrorMessage = null;
    } catch (e) {
      _boundingBoxQueryErrorMessage = e.toString();
      _afterLatitudeQueryCount = null;
      _afterLongitudeFilterCount = null;
      _afterRadiusFilterCount = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🐞 Debug Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Re-run diagnostics',
            onPressed: _isLoading ? null : _runDiagnostics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SelectionArea(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _sectionHeader('📍 Device GPS'),
                  _buildGpsSection(),
                  const SizedBox(height: AppSpacing.xxl),
                  _sectionHeader('🔥 Firestore Overview'),
                  _buildFirestoreOverviewSection(),
                  const SizedBox(height: AppSpacing.xxl),
                  _sectionHeader('🧭 Query Pipeline (staged)'),
                  _buildPipelineSection(),
                  const SizedBox(height: AppSpacing.xxl),
                  _sectionHeader(
                    'Raw Firestore Documents (${_docReports.length})',
                  ),
                  ..._docReports.map(_buildDocCard),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );

  Widget _kv(String key, String value, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style.copyWith(fontSize: 13),
            children: [
              TextSpan(
                text: '$key: ',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(
                text: value,
                style: TextStyle(
                  color: valueColor,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      );

  Widget _card(List<Widget> children) => Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      );

  Widget _buildGpsSection() {
    return _card([
      _kv('Location service enabled', '${_serviceEnabled ?? "unknown"}'),
      _kv('Permission status', '${_permission ?? "unknown"}'),
      _kv(
        'Latitude',
        _position != null ? '${_position!.latitude}' : 'null — no fix obtained',
        valueColor: _position == null ? Colors.red : null,
      ),
      _kv(
        'Longitude',
        _position != null ? '${_position!.longitude}' : 'null — no fix obtained',
        valueColor: _position == null ? Colors.red : null,
      ),
      if (_position != null)
        _kv('Position accuracy (m)', '${_position!.accuracy}'),
      if (_locationErrorMessage != null)
        _kv('GPS error', _locationErrorMessage!, valueColor: Colors.red),
      if (_position == null && _locationErrorMessage == null)
        _kv(
          'Note',
          'No exception was thrown, but no position was obtained. '
              'This usually means permission is not "always"/"whileInUse".',
          valueColor: Colors.orange,
        ),
    ]);
  }

  Widget _buildFirestoreOverviewSection() {
    return _card([
      _kv('Collection name', "'${FirestorePaths.pumps}'"),
      _kv(
        'Total documents (NO filters)',
        _unfilteredDocCount?.toString() ?? 'unknown',
        valueColor: (_unfilteredDocCount ?? 0) == 0 ? Colors.red : Colors.green,
      ),
      if (_firestoreErrorMessage != null)
        _kv('Firestore error', _firestoreErrorMessage!, valueColor: Colors.red),
    ]);
  }

  Widget _buildPipelineSection() {
    if (_position == null) {
      return _card([
        _kv(
          'Skipped',
          'No device position available — the bounding-box query cannot '
              'be reproduced without a GPS fix. Fix the GPS section above first.',
          valueColor: Colors.orange,
        ),
      ]);
    }

    return _card([
      _kv('User latitude', '${_position!.latitude}'),
      _kv('User longitude', '${_position!.longitude}'),
      _kv('Radius (km)', '$_defaultRadiusKm'),
      const Divider(),
      _kv(
        'Stage A — after Firestore latitude range .where() '
        '(the actual server-side query the app sends)',
        '${_afterLatitudeQueryCount ?? "error"}',
        valueColor: (_afterLatitudeQueryCount ?? 0) == 0 ? Colors.red : Colors.green,
      ),
      _kv(
        'Stage B — after client-side longitude filter',
        '${_afterLongitudeFilterCount ?? "error"}',
        valueColor: (_afterLongitudeFilterCount ?? 0) == 0 ? Colors.red : Colors.green,
      ),
      _kv(
        'Stage C — after exact-radius Haversine filter (final list shown on Home)',
        '${_afterRadiusFilterCount ?? "error"}',
        valueColor: (_afterRadiusFilterCount ?? 0) == 0 ? Colors.red : Colors.green,
      ),
      if (_boundingBoxQueryErrorMessage != null)
        _kv('Query error', _boundingBoxQueryErrorMessage!, valueColor: Colors.red),
      if (_unfilteredDocCount != null &&
          _unfilteredDocCount! > 0 &&
          (_afterLatitudeQueryCount ?? 0) == 0)
        _kv(
          '⚠️ Diagnosis',
          'Documents exist in /pumps but Stage A already returns 0. '
              'This means the "latitude" field type/value in Firestore does '
              'not match what a numeric range query expects — check the '
              'per-document field types below.',
          valueColor: Colors.red,
        ),
    ]);
  }

  Widget _buildDocCard(_DocReport report) {
    final latType = report.latitudeRaw?.runtimeType.toString() ?? 'null';
    final lngType = report.longitudeRaw?.runtimeType.toString() ?? 'null';
    final isLatNumeric = report.latitudeRaw is num;
    final isLngNumeric = report.longitudeRaw is num;

    const encoder = JsonEncoder.withIndent('  ');
    String prettyJson;
    try {
      prettyJson = encoder.convert(_sanitizeForJson(report.rawData));
    } catch (e) {
      prettyJson = '(could not encode: $e)\n${report.rawData}';
    }

    final box = report.boundingBox;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'doc.id = ${report.id}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            _kv(
              'latitude value / type',
              '${report.latitudeRaw} / $latType',
              valueColor: isLatNumeric ? null : Colors.red,
            ),
            _kv(
              'longitude value / type',
              '${report.longitudeRaw} / $lngType',
              valueColor: isLngNumeric ? null : Colors.red,
            ),
            if (!isLatNumeric || !isLngNumeric)
              _kv(
                '⚠️ Diagnosis',
                'latitude/longitude is stored as ${!isLatNumeric ? latType : lngType}, '
                    'not a Firestore number. PumpModel.fromFirestore silently '
                    'falls back to 0.0 for this, and the range query on the '
                    'raw field will not match a numeric bound either way.',
                valueColor: Colors.red,
              ),
            if (box != null && isLatNumeric && isLngNumeric) ...[
              const Divider(),
              _buildBoundingBoxCheck(report, box),
            ],
            const SizedBox(height: 8),
            const Text('Raw JSON:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                prettyJson,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoundingBoxCheck(_DocReport report, _BoundingBoxResult box) {
    final docLat = (report.latitudeRaw as num).toDouble();
    final docLng = (report.longitudeRaw as num).toDouble();

    final passesLat = docLat >= box.minLat && docLat <= box.maxLat;
    final passesLng = docLng >= box.minLng && docLng <= box.maxLng;
    final distanceKm = DistanceCalculator.distanceInKm(
      lat1: box.userLat,
      lon1: box.userLng,
      lat2: docLat,
      lon2: docLng,
    );
    final passesRadius = distanceKm <= box.radiusKm;

    final appears = passesLat && passesLng && passesRadius;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kv(
          'Stage A: within latitude range [${box.minLat.toStringAsFixed(4)}, '
          '${box.maxLat.toStringAsFixed(4)}]',
          passesLat ? 'PASS' : 'FAIL',
          valueColor: passesLat ? Colors.green : Colors.red,
        ),
        _kv(
          'Stage B: within longitude range [${box.minLng.toStringAsFixed(4)}, '
          '${box.maxLng.toStringAsFixed(4)}]',
          passesLng ? 'PASS' : 'FAIL',
          valueColor: passesLng ? Colors.green : Colors.red,
        ),
        _kv(
          'Stage C: distance ${distanceKm.toStringAsFixed(1)} km '
          '<= radius ${box.radiusKm.toStringAsFixed(0)} km',
          passesRadius ? 'PASS' : 'FAIL',
          valueColor: passesRadius ? Colors.green : Colors.red,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _kv(
            'Result',
            appears
                ? 'WOULD appear on Home screen'
                : 'WOULD NOT appear on Home screen',
            valueColor: appears ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  /// Firestore Timestamp isn't directly JSON-encodable — convert any
  /// value jsonEncode can't handle into a readable string instead of
  /// throwing and blanking out the whole card.
  dynamic _sanitizeForJson(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _sanitizeForJson(v)));
    }
    if (value is List) {
      return value.map(_sanitizeForJson).toList();
    }
    if (value is Timestamp) {
      return '${value.toDate().toIso8601String()} (Timestamp)';
    }
    if (value is num || value is String || value is bool || value == null) {
      return value;
    }
    return value.toString();
  }
}

class _DocReport {
  _DocReport({
    required this.id,
    required this.rawData,
    required this.latitudeRaw,
    required this.longitudeRaw,
  });

  final String id;
  final Map<String, dynamic> rawData;
  final dynamic latitudeRaw;
  final dynamic longitudeRaw;
  _BoundingBoxResult? boundingBox;
}

class _BoundingBoxResult {
  _BoundingBoxResult({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    required this.radiusKm,
    required this.userLat,
    required this.userLng,
  });

  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;
  final double radiusKm;
  final double userLat;
  final double userLng;
}
