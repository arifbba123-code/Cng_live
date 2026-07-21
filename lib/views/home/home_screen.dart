import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/debouncer.dart';
import '../../core/utils/distance_calculator.dart';
import '../../data/models/pump_model.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/pump_viewmodel.dart';
import '../../services/location_service.dart';
import '../widgets/status_badge.dart';

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
    final hasPermission = await _locationService.hasPermission();
    if (!hasPermission) {
      final permission = await _locationService.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
    }

    final position = await _locationService.getCurrentPosition();
    _currentLat = position.latitude;
    _currentLng = position.longitude;

    if (!mounted) return;
    context.read<PumpViewModel>().watchNearbyPumps(
          latitude: position.latitude,
          longitude: position.longitude,
        );
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
    final error = _isSearchMode ? viewModel.searchError : viewModel.nearbyError;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CNG LIVE'),
        actions: [
          IconButton(
            icon: Icon(AppIcons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
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
      floatingActionButton: FloatingActionButton(
        onPressed: _loadNearbyPumps,
        child: const Icon(Icons.refresh_rounded),
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
