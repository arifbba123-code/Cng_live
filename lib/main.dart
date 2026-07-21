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
import 'data/datasources/remote/pump_remote_datasource.dart';
import 'data/datasources/remote/status_remote_datasource.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/pump_repository.dart';
import 'data/repositories/pump_repository_impl.dart';
import 'data/repositories/status_repository.dart';
import 'data/repositories/status_repository_impl.dart';
import 'firebase_options.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/pump_viewmodel.dart';
import 'presentation/viewmodels/status_viewmodel.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/otp_screen.dart';
import 'views/home/home_screen.dart';
import 'views/pump/pump_detail_screen.dart';
import 'views/pump/update_status_screen.dart';

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
    options: DefaultFirebaseOptions.currentPlatform,
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

  // Offline-first sync: uploads any queued status updates automatically
  // the moment connectivity returns (Step 22, Section 13).
  final syncService = SyncService(
    connectivityService: connectivityService,
    pendingUpdatesQueue: pendingUpdatesQueue,
    statusRemoteDataSource: statusRemoteDataSource,
  )..start();

  // Push notifications: registers FCM + local notification channel.
  // Foreground/tap callbacks are no-ops for now since the
  // Notifications screen itself is outside this MVP's scope — the
  // service still initializes so tokens are issued and channels exist
  // for future wiring.
  final notificationService = NotificationService();
  await notificationService.initialize(
    onForegroundMessage: (_) {},
    onMessageOpenedApp: (_) {},
  );

  // Auto-login: if Firebase Auth already has a signed-in driver from a
  // previous session, skip straight to Home instead of Login.
  final initialRoute = authRepository.isLoggedIn ? '/home' : '/login';

  runApp(CngLiveApp(
    authRepository: authRepository,
    pumpRepository: pumpRepository,
    statusRepository: statusRepository,
    initialRoute: initialRoute,
  ));
}

class CngLiveApp extends StatelessWidget {
  const CngLiveApp({
    super.key,
    required this.authRepository,
    required this.pumpRepository,
    required this.statusRepository,
    required this.initialRoute,
  });

  final AuthRepository authRepository;
  final PumpRepository pumpRepository;
  final StatusRepository statusRepository;
  final String initialRoute;

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
          create: (_) => StatusViewModel(statusRepository),
        ),
      ],
      child: MaterialApp(
        title: 'CNG LIVE',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        initialRoute: initialRoute,
        routes: {
          '/login': (context) => const LoginScreen(),
          '/otp': (context) => const OtpScreen(),
          '/home': (context) => const HomeScreen(),
          '/pump-detail': (context) => const PumpDetailScreen(),
          '/update-status': (context) => const UpdateStatusScreen(),
        },
      ),
    );
  }
}
