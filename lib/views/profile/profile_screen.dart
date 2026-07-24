import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/extensions/context_extensions.dart';
import '../../data/models/badge_model.dart';
import '../../data/models/user_model.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/user_viewmodel.dart';

/// CNG LIVE — Profile Screen (Step 16)
///
/// Header (name, driver type, reputation level, points), the 4-badge
/// achievement grid (BadgeCatalog merged with UserViewModel's earned
/// state, per BadgeModel's doc comment on how that merge is supposed
/// to happen), Edit Profile, and account deletion.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _watchedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.read<AuthViewModel>().user?.id;
    if (userId != null && userId != _watchedUserId) {
      _watchedUserId = userId;
      context.read<UserViewModel>().watchProfile(userId);
      context.read<UserViewModel>().watchBadges(userId);
    }
  }

  Future<void> _editProfile(UserModel current) async {
    final nameController = TextEditingController(text: current.name);
    final driverTypeController = TextEditingController(text: current.driverType);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: driverTypeController,
              decoration: const InputDecoration(
                labelText: 'Driver Type (Ola / Uber / Private / Fleet)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    final updated = current.copyWith(
      name: nameController.text.trim(),
      driverType: driverTypeController.text.trim(),
    );
    final success = await context.read<UserViewModel>().updateProfile(updated);
    if (!mounted) return;
    context.showAppSnackBar(
      success ? 'Profile updated' : 'Could not update profile',
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This permanently deletes your profile, favourites, and badges. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final userId = _watchedUserId;
    if (userId == null) return;

    final deleted = await context.read<UserViewModel>().deleteAccountData(userId);
    if (!mounted) return;

    if (deleted) {
      await context.read<AuthViewModel>().logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } else {
      context.showAppSnackBar('Could not delete account. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<UserViewModel>();
    final user = viewModel.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(AppIcons.settings),
            tooltip: 'Edit Profile',
            onPressed: user == null ? null : () => _editProfile(user),
          ),
        ],
      ),
      body: _buildBody(context, viewModel, user),
    );
  }

  Widget _buildBody(BuildContext context, UserViewModel viewModel, UserModel? user) {
    if (viewModel.isLoadingProfile && user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.profileError != null && user == null) {
      return Center(
        child: Text(viewModel.profileError!, style: context.textTheme.bodyMedium),
      );
    }

    if (user == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: user.profilePhoto != null
                    ? NetworkImage(user.profilePhoto!)
                    : null,
                child: user.profilePhoto == null
                    ? Icon(AppIcons.profile, size: 32)
                    : null,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: context.textTheme.headlineMedium),
                    if (user.driverType.isNotEmpty)
                      Text(user.driverType, style: context.textTheme.bodySmall),
                    Text(
                      user.reputationLevel,
                      style: context.textTheme.labelMedium
                          ?.copyWith(color: context.colors.secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              _StatTile(label: 'Points', value: '${user.points}'),
              const SizedBox(width: AppSpacing.md),
              _StatTile(label: 'Reputation', value: '${user.reputation}'),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('Achievements', style: context.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _BadgeGrid(earnedBadges: viewModel.badges),
          const SizedBox(height: AppSpacing.xxxl),
          OutlinedButton.icon(
            icon: Icon(AppIcons.deleteAccount, color: context.colors.error),
            label: Text('Delete Account', style: TextStyle(color: context.colors.error)),
            onPressed: _confirmDeleteAccount,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: context.textTheme.headlineMedium),
            Text(label, style: context.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.earnedBadges});

  final List<BadgeModel> earnedBadges;

  BadgeModel? _earnedFor(BadgeId id) {
    for (final badge in earnedBadges) {
      if (badge.id == id) return badge;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.cardGap,
      crossAxisSpacing: AppSpacing.cardGap,
      childAspectRatio: 2.2,
      children: BadgeCatalog.all.map((definition) {
        final earned = _earnedFor(definition.id);
        final isUnlocked = earned?.isUnlocked ?? false;
        final progress = earned?.progressCurrent ?? 0;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isUnlocked
                ? context.colors.secondaryContainer
                : context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                isUnlocked ? AppIcons.verified : AppIcons.lock,
                color: isUnlocked
                    ? context.colors.secondary
                    : context.colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(definition.name, style: context.textTheme.labelMedium),
                    Text(
                      isUnlocked
                          ? 'Unlocked'
                          : '$progress / ${definition.targetValue}',
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
