import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/extensions/context_extensions.dart';
import '../../data/models/pump_model.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/user_viewmodel.dart';
import '../widgets/status_badge.dart';

/// CNG LIVE — Favourites Screen
///
/// Lists the driver's favourited pumps, resolved from
/// UserRepository.watchFavouritePumps. Card layout intentionally
/// mirrors HomeScreen's _PumpCard so favourited pumps look the same
/// wherever a driver sees them.
class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  String? _watchedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.read<AuthViewModel>().user?.id;
    if (userId != null && userId != _watchedUserId) {
      _watchedUserId = userId;
      context.read<UserViewModel>().watchFavouritePumps(userId);
    }
  }

  void _openPumpDetail(PumpModel pump) {
    Navigator.of(context).pushNamed('/pump-detail', arguments: pump.id);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Favourites')),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, UserViewModel viewModel) {
    if (viewModel.isLoadingFavourites && viewModel.favouritePumps.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.favouritesError != null && viewModel.favouritePumps.isEmpty) {
      return Center(
        child: Text(viewModel.favouritesError!,
            style: context.textTheme.bodyMedium),
      );
    }

    if (viewModel.favouritePumps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.favourites,
                size: AppIcons.sizeEmptyState,
                color: context.colors.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text('No favourite pumps yet',
                style: context.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tap the star on any pump to save it here.',
              style: context.textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.sm,
      ),
      itemCount: viewModel.favouritePumps.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.cardGap),
      itemBuilder: (context, index) {
        final pump = viewModel.favouritePumps[index];
        return _FavouritePumpCard(
          pump: pump,
          onTap: () => _openPumpDetail(pump),
        );
      },
    );
  }
}

class _FavouritePumpCard extends StatelessWidget {
  const _FavouritePumpCard({required this.pump, required this.onTap});

  final PumpModel pump;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color statusColor = StatusBadge.colorFor(context, pump.currentStatus);
    final userId = context.read<AuthViewModel>().user?.id;

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
                    Text(pump.area, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      pump.currentStatus.label,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: statusColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(AppIcons.favourites, color: theme.colorScheme.secondary),
                tooltip: 'Remove from favourites',
                onPressed: userId == null
                    ? null
                    : () => context
                        .read<UserViewModel>()
                        .toggleFavourite(userId, pump.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
