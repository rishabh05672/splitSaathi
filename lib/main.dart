import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'routes/app_router.dart';

// Services
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'services/invite_service.dart';
import 'services/notification_service.dart';
import 'services/settlement_service.dart';
import 'firebase_options.dart';

// Repositories
import 'repositories/auth_repository.dart';
import 'repositories/group_repository.dart';
import 'repositories/expense_repository.dart';
import 'repositories/invite_repository.dart';
import 'repositories/settlement_repository.dart';

// ViewModels
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/group_viewmodel.dart';
import 'viewmodels/expense_viewmodel.dart';
import 'viewmodels/invite_viewmodel.dart';
import 'viewmodels/member_viewmodel.dart';
import 'viewmodels/settlement_viewmodel.dart';
import 'viewmodels/global_dashboard_viewmodel.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Here we can handle background messages (e.g. log them or show local notifications if needed)
}

/// Entry point of SplitSaathi.
/// Initializes Firebase and sets up the dependency injection tree.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // Register FCM background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize services
  final authService = AuthService();
  final firestoreService = FirestoreService();
  final storageService = StorageService();
  final notificationService = NotificationService();
  final inviteService = InviteService(firestoreService);
  final settlementService = SettlementService(firestoreService);

  // Initialize repositories
  final authRepository = AuthRepository(
    authService,
    firestoreService,
    notificationService,
    storageService,
  );
  final groupRepository = GroupRepository(
    firestoreService,
    notificationService,
  );
  final expenseRepository = ExpenseRepository(
    firestoreService,
    groupRepository,
    notificationService,
  );
  final inviteRepository = InviteRepository(firestoreService, inviteService);
  final settlementRepository = SettlementRepository(
    firestoreService,
    settlementService,
    groupRepository,
    notificationService,
  );

  // Non-blocking initialization of notification service
  notificationService.initialize().then((_) async {
    debugPrint('Notification Service Initialized');
    
    // Get initial token and update it
    final token = await notificationService.getToken();
    if (token != null) {
      authRepository.updateFcmToken(token);
    }

    // Listen for token refreshes
    notificationService.onTokenRefresh.listen((newToken) {
      authRepository.updateFcmToken(newToken);
    });
  }).catchError((e) {
    debugPrint('Failed to initialize Notification Service: $e');
  });

  runApp(
    MultiProvider(
      providers: [
        // Services (available for direct use if needed)
        Provider<StorageService>.value(value: storageService),
        Provider<NotificationService>.value(value: notificationService),

        // ViewModels
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepository)),
        ChangeNotifierProvider(create: (_) => GroupViewModel(groupRepository)),
        ChangeNotifierProvider(
          create: (_) => ExpenseViewModel(
            expenseRepository,
            groupRepository,
            notificationService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => InviteViewModel(inviteRepository, groupRepository),
        ),
        ChangeNotifierProvider(create: (_) => MemberViewModel(groupRepository)),
        ChangeNotifierProvider(
          create: (_) => SettlementViewModel(
            settlementRepository,
            groupRepository,
            expenseRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              GlobalDashboardViewModel(expenseRepository, groupRepository),
        ),
      ],
      child: const SplitSaathiApp(),
    ),
  );
}

/// Root widget of the SplitSaathi app.
class SplitSaathiApp extends StatelessWidget {
  const SplitSaathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
