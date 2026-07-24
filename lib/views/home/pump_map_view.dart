import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/distance_calculator.dart';
import '../../data/models/pump_model.dart';
import '../../presentation/viewmodels/pump_viewmodel.dart';
import '../../services/location_service.dart';
import '../widgets/status_badge.dart';

/// CNG LIVE — Pump Map View
///
/// Shows every pump from the /pumps collection as a marker on a Google
/// Map, color-coded by currentStatus, plus the driver's own live
/// location as the standard blue dot. This is a second view on the
/// Home tab (toggled alongside the existing list), not a replacement
/// for it — HomeScreen's list body is untouched.
class PumpMapView extends StatefulWidget {
  const PumpMapView({super.key});

  @override
  State<PumpMapView> createState() => _PumpMapViewState();
}

class _PumpMapViewState extends State<PumpMapView> with WidgetsBindingObserver {
  final _locationService = LocationService();
  GoogleMapController? _mapController;

  Position? _currentPosition;

  bool _isCheckingLocation = true;
  bool _serviceEnabled = true;
  bool _permissionGranted = false;
  bool _permissionPermanentlyDenied = false;

  // Fallback camera target (Coimbatore) used until the driver's real
  // location resolves, so the map never opens on the middle of the
  // ocean (0, 0) while permission/GPS checks are still in flight.
  static const _fallbackCenter = LatLng(11.0168, 76.9558);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<PumpViewModel>().watchAllPumps();
    _initLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Covers the driver flipping GPS on/granting permission from the
    // system Settings screen and coming back — re-check rather than
    // leaving the friendly message stuck on screen forever.
    if (state == AppLifecycleState.resumed) {
      _initLocation();
    }
  }

  Future<void> _initLocation() async {
    setState(() => _isCheckingLocation = true);

    final serviceEnabled = await _locationService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() {
        _serviceEnabled = false;
        _permissionGranted = false;
        _isCheckingLocation = false;
      });
      return;
    }

    var permission = await _locationService.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _locationService.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() {
        _serviceEnabled = true;
        _permissionGranted = false;
        _permissionPermanentlyDenied = true;
        _isCheckingLocation = false;
      });
      return;
    }

    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      if (!mounted) return;
      setState(() {
        _serviceEnabled = true;
        _permissionGranted = false;
        _permissionPermanentlyDenied = false;
        _isCheckingLocation = false;
      });
      return;
    }

    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _serviceEnabled = true;
        _permissionGranted = true;
        _permissionPermanentlyDenied = false;
        _isCheckingLocation = false;
      });
      _animateToCurrentPosition();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _serviceEnabled = true;
        _permissionGranted = true;
        _isCheckingLocation = false;
      });
    }
  }

  Future<void> _animateToCurrentPosition() async {
    final position = _currentPosition;
    if (position == null || _mapController == null) return;
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        14,
      ),
    );
  }

  Future<void> _onMyLocationPressed() async {
    if (!_serviceEnabled || !_permissionGranted) {
      await _initLocation();
      return;
    }
    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() => _currentPosition = position);
      await _animateToCurrentPosition();
    } catch (_) {
      if (!mounted) return;
      context.showAppSnackBar(
        'Could not get your location. Please make sure GPS is turned on.',
      );
    }
  }

  BitmapDescriptor _markerIconFor(PumpStatus status) {
    switch (status) {
      case PumpStatus.stockAvailable:
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen);
      case PumpStatus.longQueue:
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow);
      case PumpStatus.noStock:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case PumpStatus.unverified:
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure);
    }
  }

  double? _distanceKmTo(PumpModel pump) {
    final position = _currentPosition;
    if (position == null) return null;
    return DistanceCalculator.distanceInKm(
      lat1: position.latitude,
      lon1: position.longitude,
      lat2: pump.latitude,
      lon2: pump.longitude,
    );
  }

  void _openPumpSheet(PumpModel pump) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _PumpBottomSheet(
        pump: pump,
        distanceKm: _distanceKmTo(pump),
      ),
    );
  }

  Set<Marker> _buildMarkers(List<PumpModel> pumps) {
    return pumps
        .map(
          (pump) => Marker(
            markerId: MarkerId(pump.id),
            position: LatLng(pump.latitude, pump.longitude),
            icon: _markerIconFor(pump.currentStatus),
            infoWindow: InfoWindow(title: pump.name, snippet: pump.area),
            onTap: () => _openPumpSheet(pump),
          ),
        )
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingLocation) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_serviceEnabled) {
      return _LocationMessage(
        icon: Icons.location_disabled_rounded,
        title: 'Turn on Location',
        message:
            'CNG LIVE needs your device\'s location (GPS) turned on to '
            'show the map and pumps near you.',
        actionLabel: 'Enable Location',
        onAction: () async {
          await _locationService.openLocationSettings();
          _initLocation();
        },
      );
    }

    if (!_permissionGranted) {
      return _LocationMessage(
        icon: Icons.location_off_rounded,
        title: 'Location Permission Needed',
        message: _permissionPermanentlyDenied
            ? 'Location access is currently blocked. Please enable it '
                'from your device Settings to see the map and nearby pumps.'
            : 'Please allow location access so CNG LIVE can show your '
                'position and nearby pumps on the map.',
        actionLabel:
            _permissionPermanentlyDenied ? 'Open Settings' : 'Allow Location',
        onAction: () async {
          if (_permissionPermanentlyDenied) {
            await _locationService.openAppSettings();
          }
          _initLocation();
        },
      );
    }

    final pumpViewModel = context.watch<PumpViewModel>();
    final pumps = pumpViewModel.allPumps;

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentPosition != null
                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                : _fallbackCenter,
            zoom: 13,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            _animateToCurrentPosition();
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: _buildMarkers(pumps),
        ),
        if (pumpViewModel.isLoadingAllPumps && pumps.isEmpty)
          const Positioned(
            top: AppSpacing.lg,
            left: 0,
            right: 0,
            child: Center(child: CircularProgressIndicator()),
          ),
        if (pumpViewModel.allPumpsError != null && pumps.isEmpty)
          Positioned(
            top: AppSpacing.lg,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Could not load pumps: ${pumpViewModel.allPumpsError}',
                  style: context.textTheme.bodySmall,
                ),
              ),
            ),
          ),
        Positioned(
          right: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: FloatingActionButton(
            heroTag: 'pump_map_my_location',
            tooltip: 'My Location',
            onPressed: _onMyLocationPressed,
            child: const Icon(Icons.my_location_rounded),
          ),
        ),
      ],
    );
  }
}

/// Friendly full-screen prompt shown in place of the map when GPS is
/// off or location permission hasn't been granted yet — never a raw
/// exception or a blank map.
class _LocationMessage extends StatelessWidget {
  const _LocationMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSpacing.xxxl * 2, color: theme.colorScheme.outline),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet shown when a pump marker is tapped: name, area, current
/// status, last-updated time, distance from the driver, and a shortcut
/// into the existing Update Status flow.
class _PumpBottomSheet extends StatelessWidget {
  const _PumpBottomSheet({required this.pump, required this.distanceKm});

  final PumpModel pump;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(pump.name, style: theme.textTheme.titleLarge),
                ),
                if (pump.verified)
                  Icon(Icons.verified_rounded,
                      size: AppSpacing.xl, color: theme.colorScheme.secondary),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(pump.area, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            StatusBadge(status: pump.currentStatus),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: AppSpacing.lg, color: theme.colorScheme.outline),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  pump.lastUpdatedAt != null
                      ? 'Updated ${DateFormatter.relative(pump.lastUpdatedAt!)}'
                      : 'No recent update',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            if (distanceKm != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(Icons.directions_car_rounded,
                      size: AppSpacing.lg, color: theme.colorScheme.outline),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${DistanceCalculator.format(distanceKm!)} away',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context)
                      .pushNamed('/update-status', arguments: pump.id);
                },
                child: const Text('Update Status'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context)
                      .pushNamed('/pump-detail', arguments: pump.id);
                },
                child: const Text('View Full Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
