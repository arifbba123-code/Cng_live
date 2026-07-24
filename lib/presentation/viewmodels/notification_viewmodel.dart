import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationViewModel extends ChangeNotifier {
  NotificationViewModel(this._notificationRepository);

  final NotificationRepository _notificationRepository;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<NotificationModel>>? _subscription;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void watchNotifications(String userId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _notificationRepository.watchNotifications(userId).listen(
      (notifications) {
        _notifications = notifications;
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      // Optimistic update — the live stream will confirm this shortly
      // after, but the tap should feel instant (Step 18 dot fade-out).
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
    await _notificationRepository.markAsRead(userId, notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    await _notificationRepository.markAllAsRead(userId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
