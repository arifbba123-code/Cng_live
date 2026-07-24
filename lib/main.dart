import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/network/connectivity_service.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local/pending_updates_queue.dart';
import 'data/datasources/remote/auth_remote_datasource.dart';
import 'data/datasources/remote/badge_remote_datasource.dart';
import 'data/datasources/remote/leaderboard_remote_datasource.dart';
import 'data/datasources/remote/notification_remote_datasource.dart';
import 'data/datasources/remote/pump_remote_datasource.dart';
import 'data/datasources/remote/report_remote_datasource.dart';
import 'data/datasources/remote/status_remote_datasource.dart';
import 'data/datasources/remote/user_remote_datasource.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/badge_repository.dart';
import 'data/repositories/badge_repository_impl.dart';
import 'data/repositories/leaderboard_repository.dart';
import 'data/repositories/leaderboard_repository_impl.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/notification_repository_impl.dart';
import 'data/repositories/pump_repository.dart';
import 'data/repositories/pump_repository_impl.dart';
import 'data/repositories/report_repository.dart';
import 'data/repositories/report_repository_impl.dart';
import 'data/repositories/status_repository.dart';
import 'data/repositories/status_repository_impl.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/user_repository_impl.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/leaderboard_viewmodel.dart';
import 'presentation/viewmodels/notification_viewmodel.dart';
import 'presentation/viewmodels/pump_viewmodel.dart';
import 'presentation/viewmodels/report_viewmodel.dart';
import 'presentation/viewmodels/status_viewmodel.dart';
import 'presentation/viewmodels/user_viewmodel.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'views/auth/forgot_password_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/register_screen.dart';
import 'views/debug/debug_report_screen.dart';
import 'views/home/main_shell.dart';
import 'views/pump/pump_detail_screen.dart';
import 'views/pump/report_wrong_update_screen.dart';
import 'views/pump/update_status_screen.dart';
import 'views/splash/splash_screen.dart';

/// Lets NotificationService's tap callbacks navigate without a
/// BuildContext of their own — they fire from FCM/local-notification
/// callbacks registered once in main(), before any screen exists.
final navigatorKey = GlobalKey<NavigatorState>();

/// Routes a notification payload to the right screen. Used by
/// onMessageOpenedApp (the app was backgrounded and the driver tapped
/// the system tray notification) so the deep-link logic lives in one
/// place rather than being duplicated.
void _handleNotificationDeepLink(Map<String, dynamic> data) {
  final navigator = navigatorKey.currentState;
  if (navigator == null) return;

  final pumpId = data['relatedPumpId'] as String? ?? data['pumpId'] as String?;
  final statusUpdateId = data['statusUpdateId'] as String?;

  if (data['type'] == 'report' && pumpId != null && statusUpdateId != null) {
    navigator.pushNamed('/report-wrong-update', arguments: {
      'pumpId': pumpId,
      'statusUpdateId': statusUpdateId,
    });
  } else if (pumpId != null) {
    navigator.pushNamed('/pump-detail', arguments: pumpId);
  }
  // No pumpId/statusUpdateId in the payload (e.g. an achievement or
  // points notification) — nothing to deep-link to, so the app just
  // opens to wherever it already was.
}

/// CNG LIVE — App Entry Point
///
/// Wires Firebase, Hive, every datasource/repository, and the two
/// background services (NotificationService, SyncService) by hand —
/// dependency injection (get_it) was intentionally descoped from the
/// MVP per an earlier decision in this build, so composition happens
/// directly here instead of a service locator.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDrScuNpwcJ8dnHtZLINebNlp2srxhUfdY",
      appId: "1:637750456503:android:d0f033dbd62250e3325d32",
      messagingSenderId: "637750456503",
      projectId: "cng-live-a9b7e",
      storageBucket: "cng-live-a9b7e.firebasestorage.app",
    ),
  );

  await Hive.initFlutter();

  final firebaseAuth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  final authRemoteDataSource = AuthRemoteDataSource(
    firebaseAuth: firebaseAuth,
    firestore: firestore,
  );
  final pumpRemoteDataSource = PumpRemoteDataSource(firestore: firestore);
  final statusRemoteDataSource = StatusRemoteDataSource(firestore: firestore);
  final reportRemoteDataSource = ReportRemoteDataSource(firestore: firestore);
  final notificationRemoteDataSource =
      NotificationRemoteDataSource(firestore: firestore);
  final badgeRemoteDataSource = BadgeRemoteDataSource(firestore: firestore);
  final userRemoteDataSource = UserRemoteDataSource(firestore: firestore);
  final leaderboardRemoteDataSource =
      LeaderboardRemoteDataSource(firestore: firestore);
  final pendingUpdatesQueue = HivePendingUpdatesQueue();
  final connectivityService = ConnectivityService();

  final AuthRepository authRepository =
      AuthRepositoryImpl(authRemoteDataSource);
  final PumpRepository pumpRepository =
      PumpRepositoryImpl(pumpRemoteDataSource);
  final StatusRepository statusRepository = StatusRepositoryImpl(
    statusRemoteDataSource,
    pendingUpdatesQueue,
  );
  final ReportRepository reportRepository =
      ReportRepositoryImpl(reportRemoteDataSource);
  final NotificationRepository notificationRepository =
      NotificationRepositoryImpl(notificationRemoteDataSource);
  final UserRepository userRepository = UserRepositoryImpl(
    userRemoteDataSource,
    pumpRemoteDataSource,
    badgeRemoteDataSource,
  );
  final LeaderboardRepository leaderboardRepository =
      LeaderboardRepositoryImpl(leaderboardRemoteDataSource);
  final BadgeRepository badgeRepository =
      BadgeRepositoryImpl(badgeRemoteDataSource);

  // Offline-first sync: uploads any queued status updates automatically
  // the moment connectivity returns (Step 22, Section 13).
  final syncService = SyncService(
    connectivityService: connectivityService,
    pendingUpdatesQueue: pendingUpdatesQueue,
    statusRemoteDataSource: statusRemoteDataSource,
  )..start();

  // Push notifications: registers FCM + local notification channel,
  // and deep-links taps to the relevant screen (Pump Detail / Report
  // Wrong Update) via the shared _handleNotificationDeepLink helper.
  // The in-app Notifications screen itself still reads live from
  // Firestore via NotificationRepository rather than from these push
  // payloads — this wiring only covers what happens when a driver
  // taps the system notification itself.
  final notificationService = NotificationService();
  await notificationService.initialize(
    // Foreground arrival only shows the local notification (handled
    // inside NotificationService itself) — it must NOT navigate the
    // driver away from whatever they're doing just because a message
    // arrived. Only an actual tap should deep-link.
    onForegroundMessage: (_) {},
    onMessageOpenedApp: (message) => _handleNotificationDeepLink(message.data),
    onLocalNotificationTap: (response) {
      final pumpId = response.payload;
      if (pumpId != null && pumpId.isNotEmpty) {
        navigatorKey.currentState?.pushNamed('/pump-detail', arguments: pumpId);
      }
    },
  );

  // Auto-login: if Firebase Auth already has a signed-in driver from a
  // previous session, the splash screen hands off to Home instead of
  // Login once it finishes.
  final postSplashRoute = authRepository.isLoggedIn ? '/home' : '/login';

  runApp(CngLiveApp(
    authRepository: authRepository,
    pumpRepository: pumpRepository,
    statusRepository: statusRepository,
    reportRepository: reportRepository,
    notificationRepository: notificationRepository,
    userRepository: userRepository,
    leaderboardRepository: leaderboardRepository,
    badgeRepository: badgeRepository,
    postSplashRoute: postSplashRoute,
  ));
}

class CngLiveApp extends StatelessWidget {
  const CngLiveApp({
    super.key,
    required this.authRepository,
    required this.pumpRepository,
    required this.statusRepository,
    required this.reportRepository,
    required this.notificationRepository,
    required this.userRepository,
    required this.leaderboardRepository,
    required this.badgeRepository,
    required this.postSplashRoute,
  });

  final AuthRepository authRepository;
  final PumpRepository pumpRepository;
  final StatusRepository statusRepository;
  final ReportRepository reportRepository;
  final NotificationRepository notificationRepository;
  final UserRepository userRepository;
  final LeaderboardRepository leaderboardRepository;
  final BadgeRepository badgeRepository;

  /// Route the splash screen navigates to once its fixed duration
  /// elapses: '/home' if a driver session already exists, else '/login'.
  final String postSplashRoute;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>(
          create: (_) => AuthViewModel(authRepository),
        ),
        ChangeNotifierProvider<PumpViewModel>(
          create: (_) => PumpViewModel(pumpRepository, statusRepository),
        ),
        ChangeNotifierProvider<StatusViewModel>(
          create: (_) => StatusViewModel(statusRepository, badgeRepository),
        ),
        ChangeNotifierProvider<ReportViewModel>(
          create: (_) => ReportViewModel(reportRepository),
        ),
        ChangeNotifierProvider<NotificationViewModel>(
          create: (_) => NotificationViewModel(notificationRepository),
        ),
        ChangeNotifierProvider<UserViewModel>(
          create: (_) => UserViewModel(userRepository),
        ),
        ChangeNotifierProvider<LeaderboardViewModel>(
          create: (_) => LeaderboardViewModel(leaderboardRepository),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'CNG LIVE',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => SplashScreen(nextRoute: postSplashRoute),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/home': (context) => const MainShell(),
          '/pump-detail': (context) => const PumpDetailScreen(),
          '/update-status': (context) => const UpdateStatusScreen(),
          '/report-wrong-update': (context) => const ReportWrongUpdateScreen(),
          '/debug-report': (context) => const DebugReportScreen(),
        },
      ),
    );
  }
}
