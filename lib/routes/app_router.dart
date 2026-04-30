import 'package:go_router/go_router.dart';
import 'package:split_saathi/views/main_navigation_screen.dart';
import '../views/auth/splash_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/home/home_screen.dart';
import '../views/profile/profile_screen.dart';
import '../views/groups/create_group_screen.dart';
import '../views/groups/group_detail_screen.dart';
import '../views/groups/member_management_screen.dart';
import '../views/invite/invite_screen.dart';
import '../views/invite/join_request_screen.dart';
import '../views/expenses/add_expense_screen.dart';
import '../views/expenses/expense_detail_screen.dart';
import 'package:split_saathi/models/expense_model.dart';

/// App-wide routing configuration using go_router.
/// Handles all navigation and deep links.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(path: '/', builder: (_, _s) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _s) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, _s) => const MainNavigationScreen()),
      GoRoute(path: '/profile', builder: (_, _s) => const ProfileScreen()),
      GoRoute(path: '/groups/create', builder: (_, _s) => const CreateGroupScreen()),
      GoRoute(
        path: '/groups/:groupId',
        builder: (_, state) => GroupDetailScreen(
          groupId: state.pathParameters['groupId']!,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/invite',
        builder: (_, state) => InviteScreen(
          groupId: state.pathParameters['groupId']!,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/requests',
        builder: (_, state) => JoinRequestScreen(
          groupId: state.pathParameters['groupId']!,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/members',
        builder: (_, state) => MemberManagementScreen(
          groupId: state.pathParameters['groupId']!,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/expense/add',
        builder: (_, state) => AddExpenseScreen(
          groupId: state.pathParameters['groupId']!,
          expense: state.extra as ExpenseModel?,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/expense/:expenseId',
        builder: (_, state) => ExpenseDetailScreen(
          groupId: state.pathParameters['groupId']!,
          expenseId: state.pathParameters['expenseId']!,
        ),
      ),
      // Deep link: /join?token=xxx
      GoRoute(
        path: '/join',
        builder: (_, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return JoinRequestScreen(groupId: '', token: token);
        },
      ),
    ],
  );
}
