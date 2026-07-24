import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/extensions/datetime_extensions.dart';
import '../../data/models/pump_model.dart';
import '../../data/models/status_update_model.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/pump_viewmodel.dart';
import '../../presentation/viewmodels/user_viewmodel.dart';
import '../widgets/status_badge.dart';

class PumpDetailScreen extends StatefulWidget {
  const PumpDetailScreen({super.key});

  @override
  State<PumpDetailScreen> createState() => _PumpDetailScreenState();
}

class _PumpDetailScreenState extends State<PumpDetailScreen> {
  late final PumpViewModel _pumpViewModel;
  String? _pumpId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pumpId == null) {
      _pumpViewModel = context.read<PumpViewModel>();
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _pumpId = args;
        _pumpViewModel.watchPumpDetail(_pumpId!);
      }
    }
  }

  @override
  void dispose() {
    _pumpViewModel.clearSelectedPump();
    super.dispose();
  }

  void _openUpdateStatus() {
    Navigator.of(context).pushNamed('/update-status', arguments: _pumpId);
  }

  void _openReportWrongUpdate() {
    final latestUpdate =
        _pumpViewModel.statusHistory.isNotEmpty ? _pumpViewModel.statusHistory.first : null;
    if (latestUpdate == null) {
      context.showAppSnackBar('No status update to report yet.');
      return;
    }
    Navigator.of(context).pushNamed('/report-wrong-update', arguments: {
      'pumpId': _pumpId,
      'statusUpdateId': latestUpdate.id,
    });
  }

  void _toggleFavourite() {
    final userId = context.read<AuthViewModel>().user?.id;
    final pumpId = _pumpId;
    if (userId == null || pumpId == null) return;
    context.read<UserViewModel>().toggleFavourite(userId, pumpId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<PumpViewModel>();
    final userViewModel = context.watch<UserViewModel>();
    final isFavourite =
        _pumpId != null && userViewModel.isFavourite(_pumpId!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pump Details'),
        actions: [
          IconButton(
            icon: Icon(
              isFavourite ? AppIcons.favourites : Icons.star_border_rounded,
              color: isFavourite ? theme.colorScheme.secondary : null,
            ),
            tooltip: isFavourite ? 'Remove from favourites' : 'Add to favourites',
            onPressed: _toggleFavourite,
          ),
        ],
      ),
      body: _buildBody(theme, viewModel),
    );
  }

  Widget _buildBody(ThemeData theme, PumpViewModel viewModel) {
    if (viewModel.isLoadingDetail && viewModel.selectedPump == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.detailError != null && viewModel.selectedPump == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(viewModel.detailError!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () => _pumpViewModel.watchPumpDetail(_pumpId!),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final pump = viewModel.selectedPump;
    if (pump == null) {
      return const SizedBox.shrink();
    }

    final statusColors = context.statusColors;
    final Color statusColor = StatusBadge.colorFor(context, pump.currentStatus);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(pump.name, style: theme.textTheme.headlineMedium),
              ),
              if (pump.verified)
                Icon(AppIcons.verified,
                    color: theme.colorScheme.secondary,
                    size: AppIcons.sizeBadge),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(AppIcons.location,
                  size: AppIcons.sizeInline,
                  color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Text(pump.area, style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: statusColors.tintFor(statusColor),
              borderRadius: BorderRadius.circular(16),
              border: Border(left: BorderSide(color: statusColor, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pump.currentStatus.label,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontSize: 18, color: statusColor),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(AppIcons.queue,
                        size: AppIcons.sizeInline,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      pump.lastUpdatedAt != null
                          ? 'Updated ${pump.lastUpdatedAt!.toRelative()}'
                          : 'No recent update',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                if (pump.currentStatus == PumpStatus.longQueue &&
                    pump.queueMinutes != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Est. Queue Time: ${pump.queueMinutes} min',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: statusColors.longQueueText),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Status History', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (viewModel.statusHistory.isEmpty)
            Text('No updates yet', style: theme.textTheme.bodySmall)
          else
            ...viewModel.statusHistory.map(
              (update) => _StatusHistoryTile(update: update),
            ),
          const SizedBox(height: AppSpacing.xxxl),
          ElevatedButton(
            onPressed: _openUpdateStatus,
            child: const Text('Update Status'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            icon: Icon(AppIcons.report),
            label: const Text('Report Wrong Update'),
            onPressed: _openReportWrongUpdate,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _StatusHistoryTile extends StatelessWidget {
  const _StatusHistoryTile({required this.update});

  final StatusUpdateModel update;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color statusColor = StatusBadge.colorFor(context, update.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${update.timestamp.toRelative()}   ${update.status.label}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (update.userName != null)
                  Text('by ${update.userName}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
