import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/extensions/datetime_extensions.dart';
import '../../data/models/notification_model.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import '../../presentation/viewmodels/notification_viewmodel.dart';

/// CNG LIVE — Notifications Screen (Step 18)
///
/// Reads the current driver's live notification list. Tapping an item
/// marks it read and, if it references a pump, opens that pump's
/// detail screen — otherwise it just stays on this screen (e.g.
/// achievement/points/system notifications with no pump to open).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? _watchedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.read<AuthViewModel>().user?.id;
    if (userId != null && userId != _watchedUserId) {
      _watchedUserId = userId;
      context.read<NotificationViewModel>().watchNotifications(userId);
    }
  }

  void _handleTap(NotificationModel notification) {
    final userId = _watchedUserId;
    if (userId == null) return;

    context.read<NotificationViewModel>().markAsRead(userId, notification.id);

    if (notification.relatedPumpId != null) {
      Navigator.of(context)
          .pushNamed('/pump-detail', arguments: notification.relatedPumpId);
    }
  }

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.pumpStatusAlert:
      case NotificationType.favouritePumpUpdate:
        return AppIcons.pump;
      case NotificationType.achievement:
        return AppIcons.leaderboard;
      case NotificationType.pointsEarned:
        return Icons.stars_rounded;
      case NotificationType.system:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NotificationViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (viewModel.unreadCount > 0)
            TextButton(
              onPressed: () {
                final userId = _watchedUserId;
                if (userId != null) {
                  context.read<NotificationViewModel>().markAllAsRead(userId);
                }
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, NotificationViewModel viewModel) {
    if (viewModel.isLoading && viewModel.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null && viewModel.notifications.isEmpty) {
      return Center(
        child: Text(viewModel.error!, style: context.textTheme.bodyMedium),
      );
    }

    if (viewModel.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.notifications,
                size: AppIcons.sizeEmptyState,
                color: context.colors.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text("You're all caught up", style: context.textTheme.bodyMedium),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: viewModel.notifications.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final notification = viewModel.notifications[index];
        return ListTile(
          leading: Icon(_iconFor(notification.type)),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Text(notification.body),
          trailing: Text(
            notification.timestamp.toRelative(),
            style: context.textTheme.bodySmall,
          ),
          onTap: () => _handleTap(notification),
        );
      },
    );
  }
}
