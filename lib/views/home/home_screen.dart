import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/debouncer.dart';
import '../../core/utils/distance_calculator.dart';
import '../../data/datasources/remote/pump_remote_datasource.dart';
import '../../data/models/pump_model.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/pump_viewmodel.dart';
import '../../services/location_service.dart';
import '../debug/debug_report_screen.dart';
import '../widgets/status_badge.dart';
import 'pump_map_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _locationService = LocationService();
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 400));

  double? _currentLat;
  double? _currentLng;
  bool _isSearchMode = false;
  String? _locationError;

  /// Toggles the existing list body vs. the new Google Map view.
  /// Defaults to the original list so the Home Screen opens exactly as
  /// it did before this was added — the map is one tap away, not a
  /// replacement.
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNearbyPumps());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyPumps() async {
    setState(() => _locationError = null);

    try {
      final hasPermission = await _locationService.hasPermission();
      if (!hasPermission) {
        final permission = await _locationService.requestPermission();
        if (permission != LocationPermission.always &&
            permission != LocationPermission.whileInUse) {
          setState(() {
            _locationError =
                'Location permission is needed to find pumps near you. '
                'Please allow location access in Settings.';
          });
          return;
        }
      }

      final position = await _locationService.getCurrentPosition();
      _currentLat = position.latitude;
      _currentLng = position.longitude;

      // TEMPORARY DIAGNOSTIC — remove once root cause is confirmed.
      debugPrint(
        '[HomeScreen][DIAGNOSTIC] device position: '
        'latitude=${position.latitude}, longitude=${position.longitude}',
      );
      await PumpRemoteDataSource().debugDumpAllPumpsRaw();

      if (!mounted) return;
      context.read<PumpViewModel>().watchNearbyPumps(
            latitude: position.latitude,
            longitude: position.longitude,
          );
    } catch (e) {
      // Most commonly: device location/GPS is turned off, or the OS
      // timed out getting a fix. Without this catch, an exception here
      // would leave the nearby-pumps list silently empty forever, with
      // no indication of why.
      if (!mounted) return;
      setState(() {
        _locationError =
            'Could not get your location. Please make sure location/GPS '
            'is turned on, then try again.';
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _isSearchMode = query.trim().isNotEmpty);
    _debouncer.run(() {
      if (query.trim().isEmpty) {
        context.read<PumpViewModel>().clearSearch();
      } else {
        context.read<PumpViewModel>().searchPumps(query);
      }
    });
  }

  void _openPumpDetail(PumpModel pump) {
    Navigator.of(context).pushNamed('/pump-detail', arguments: pump.id);
  }

  /// Opens the on-screen Debug Report directly via Navigator.push —
  /// this is the FAB's job now (previously a plain refresh button).
  /// Kept as a widget push rather than the named '/debug-report' route
  /// so this button works even if that route entry is ever removed.
  void _openDebugReport() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DebugReportScreen()),
    );
  }

  Future<void> _handleLogout() async {
    await context.read<AuthViewModel>().logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<PumpViewModel>();

    final pumps = _isSearchMode ? viewModel.searchResults : viewModel.nearbyPumps;
    final isLoading =
        _isSearchMode ? viewModel.isSearching : viewModel.isLoadingNearby;
    final error = _isSearchMode
        ? viewModel.searchError
        : (_locationError ?? viewModel.nearbyError);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CNG LIVE'),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list_rounded : Icons.map_rounded),
            tooltip: _showMap ? 'Show list' : 'Show map',
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          if (!_showMap)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh nearby pumps',
              onPressed: _isSearchMode
                  ? () => viewModel.searchPumps(_searchController.text)
                  : _loadNearbyPumps,
            ),
          IconButton(
            icon: Icon(AppIcons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _showMap
          ? const PumpMapView()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                    vertical: AppSpacing.sm,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search pumps or area...',
                      prefixIcon: Icon(AppIcons.search),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _isSearchMode
                        ? () => viewModel.searchPumps(_searchController.text)
                        : _loadNearbyPumps,
                    child: _buildBody(theme, pumps, isLoading, error),
                  ),
                ),
              ],
            ),
      floatingActionButton: _showMap
          ? null
          : FloatingActionButton(
              onPressed: _openDebugReport,
              tooltip: 'Debug Report',
              child: const Text('🐞', style: TextStyle(fontSize: 20)),
            ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    List<PumpModel> pumps,
    bool isLoading,
    String? error,
  ) {
    if (isLoading && pumps.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && pumps.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Text(error, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: _isSearchMode
                      ? () => context
                          .read<PumpViewModel>()
                          .searchPumps(_searchController.text)
                      : _loadNearbyPumps,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (pumps.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Center(
            child: Text(
              _isSearchMode ? 'No pumps found' : 'No CNG pumps found nearby.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.sm,
      ),
      itemCount: pumps.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.cardGap),
      itemBuilder: (context, index) {
        final pump = pumps[index];
        return _PumpCard(
          pump: pump,
          distanceKm: (_currentLat != null && _currentLng != null)
              ? DistanceCalculator.distanceInKm(
                  lat1: _currentLat!,
                  lon1: _currentLng!,
                  lat2: pump.latitude,
                  lon2: pump.longitude,
                )
              : null,
          onTap: () => _openPumpDetail(pump),
        );
      },
    );
  }
}

class _PumpCard extends StatelessWidget {
  const _PumpCard({
    required this.pump,
    required this.distanceKm,
    required this.onTap,
  });

  final PumpModel pump;
  final double? distanceKm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color statusColor = StatusBadge.colorFor(context, pump.currentStatus);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: statusColor, width: 4)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pump.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      distanceKm != null
                          ? '${pump.area} · ${DistanceCalculator.format(distanceKm!)}'
                          : pump.area,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pump.currentStatus.label,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: statusColor),
                    ),
                  ],
                ),
              ),
              if (pump.verified)
                Icon(AppIcons.verified,
                    size: AppIcons.sizeBadge,
                    color: theme.colorScheme.secondary),
            ],
          ),
        ),
      ),
    );
  }
}
