import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background handler — required by firebase_messaging to be
/// a top-level (or static) function, not a class method.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Runs in a separate isolate when the app is terminated/backgrounded.
  // Keep this minimal — no UI, no BuildContext available here.
}

class NotificationService {
  NotificationService({
    FirebaseMessaging? firebaseMessaging,
    FlutterLocalNotificationsPlugin? localNotificationsPlugin,
  })  : _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
        _localNotificationsPlugin =
            localNotificationsPlugin ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin;

  static const String _androidChannelId = 'cng_live_default_channel';
  static const String _androidChannelName = 'CNG LIVE Notifications';
  static const String _androidChannelDescription =
      'Pump status alerts, favourites, achievements, and points updates.';

  final AndroidNotificationChannel _androidChannel =
      const AndroidNotificationChannel(
    _androidChannelId,
    _androidChannelName,
    description: _androidChannelDescription,
    importance: Importance.high,
  );

  Future<void> initialize({
    required void Function(RemoteMessage message) onForegroundMessage,
    required void Function(RemoteMessage message) onMessageOpenedApp,
    void Function(NotificationResponse response)? onLocalNotificationTap,
  }) async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermission();
    await _initializeLocalNotifications(onLocalNotificationTap);

    if (Platform.isAndroid) {
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }

    // Foreground: message arrives while the app is open and visible.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
      onForegroundMessage(message);
    });

    // Background (tapped): app was backgrounded, user tapped the
    // system notification, bringing the app to foreground.
    FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);

    // Terminated: app was fully closed and launched by tapping a
    // notification — check for an initial message once at startup.
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      onMessageOpenedApp(initialMessage);
    }
  }

  Future<NotificationSettings> _requestPermission() {
    return _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  Future<void> _initializeLocalNotifications(
    void Function(NotificationResponse response)? onTap,
  ) async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onTap,
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['relatedPumpId'] as String?,
    );
  }

  Future<String?> getFcmToken() {
    return _firebaseMessaging.getToken();
  }

  Stream<String> get onTokenRefresh => _firebaseMessaging.onTokenRefresh;

  Future<void> subscribeToTopic(String topic) {
    return _firebaseMessaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) {
    return _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}
