import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_elevation.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/extensions/context_extensions.dart';
import '../../data/models/leaderboard_model.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/leaderboard_viewmodel.dart';

/// CNG LIVE — Leaderboard Screen (Step 16/20)
///
/// Weekly top-10 rankings, read-only from /leaderboard. Podium
/// treatment (gold/silver/bronze) for the top 3 reuses AppColors'
/// dedicated podium palette; the sticky "Your Rank" card at the bottom
/// uses AppElevation.level2 per the Step 20 elevation scale.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      context.read<LeaderboardViewModel>().watchLeaderboard();
      final userId = context.read<AuthViewModel>().user?.id;
      if (userId != null) {
        context.read<LeaderboardViewModel>().loadMyRank(userId);
      }
    }
  }

  Color? _podiumColor(int rank) {
    switch (rank) {
      case 1:
        return AppColors.gold;
      case 2:
        return AppColors.silver;
      case 3:
        return AppColors.bronze;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LeaderboardViewModel>();
    final currentUserId = context.watch<AuthViewModel>().user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(
        children: [
          Expanded(child: _buildList(context, viewModel, currentUserId)),
          if (viewModel.myRank != null)
            _YourRankCard(entry: viewModel.myRank!),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    LeaderboardViewModel viewModel,
    String? currentUserId,
  ) {
    if (viewModel.isLoading && viewModel.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null && viewModel.entries.isEmpty) {
      return Center(
        child: Text(viewModel.error!, style: context.textTheme.bodyMedium),
      );
    }

    if (viewModel.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.leaderboard,
                size: AppIcons.sizeEmptyState,
                color: context.colors.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text('No rankings yet this week',
                style: context.textTheme.bodyMedium),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.sm,
      ),
      itemCount: viewModel.entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final entry = viewModel.entries[index];
        final podiumColor = _podiumColor(entry.rank);
        final isMe = entry.userId == currentUserId;

        return Material(
          elevation: AppElevation.level0,
          color: isMe
              ? context.colors.secondaryContainer
              : context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: podiumColor ?? context.colors.surfaceContainerHighest,
              foregroundColor: podiumColor != null ? Colors.black87 : null,
              child: Text('${entry.rank}'),
            ),
            title: Text(entry.name),
            trailing: Text(
              '${entry.points} pts',
              style: context.textTheme.labelMedium,
            ),
          ),
        );
      },
    );
  }
}

class _YourRankCard extends StatelessWidget {
  const _YourRankCard({required this.entry});

  final LeaderboardEntryModel entry;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: AppElevation.level2,
      color: context.colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Text('Your Rank', style: context.textTheme.labelLarge),
            const Spacer(),
            Text('#${entry.rank}', style: context.textTheme.titleMedium),
            const SizedBox(width: AppSpacing.md),
            Text('${entry.points} pts', style: context.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
