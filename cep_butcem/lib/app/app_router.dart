import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ✅ Splash
import '../../features/splash/splash_screen.dart';

// ✅ Onboarding + Setup
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/setup_budget/setup_budget_screen.dart';

// ✅ Shell (bottom bar)
import '../../features/shell/main_shell.dart';

// ✅ Tabs
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/profile/profile_screen.dart';

// ✅ Profile edit
import '../../features/profile/profile_edit_screen.dart';
import '../../core/state/profile_store.dart';

// ✅ Models
import '../../data/models/reminder_model.dart';
import '../../data/models/subscription_model.dart';
import '../../data/models/transaction_model.dart';

// ✅ Drawer pages (no bottom bar)
import '../../features/categories/categories_screen.dart';
import '../../features/reminders/reminders_screen.dart';
import '../../features/reminders/create_reminder_screen.dart';
import '../../features/reminders/edit_reminder_screen.dart';
import '../../features/subscriptions/subscriptions_screen.dart';
import '../../features/subscriptions/create_subscription_screen.dart';
import '../../features/subscriptions/edit_subscription_screen.dart';
import '../../features/transactions/add_transaction_screen.dart';
import '../features/profile/account/account_screen.dart';
import '../features/profile/account/add_account_type_screen.dart';
import '../../features/profile/settings_screen.dart';
import '../../features/profile/support_info_screen.dart';
import '../../features/profile/theme_settings_screen.dart';
import '../../features/profile/language_settings_screen.dart';
import '../../features/profile/notification_settings_screen.dart';
import '../../features/profile/privacy_screen.dart';
import '../../features/profile/version_screen.dart';
import '../../features/transactions/edit_transaction_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/setup-budget',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SetupBudgetScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/categories',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/reminders',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RemindersScreen(),
      ),
      GoRoute(
        path: '/reminders/create',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreateReminderScreen(),
      ),
      GoRoute(
        path: EditReminderScreen.routePath,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final reminder = state.extra as ReminderModel;
          return EditReminderScreen(reminder: reminder);
        },
      ),
      GoRoute(
        path: '/subscriptions',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SubscriptionsScreen(),
      ),
      GoRoute(
        path: '/subscriptions/create',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreateSubscriptionScreen(),
      ),
      GoRoute(
        path: EditSubscriptionScreen.routePath,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final subscription = state.extra as SubscriptionModel;
          return EditSubscriptionScreen(subscription: subscription);
        },
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as ProfileData?;
          return ProfileEditScreen(initialData: data);
        },
      ),
      GoRoute(
        path: AccountScreen.routePath,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: AddAccountTypeScreen.routePath,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddAccountTypeScreen(),
      ),
      GoRoute(
        path: '/add-transaction',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddTransactionScreen(),
      ),
      GoRoute(
        path: '/transactions/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final transaction = state.extra as TransactionModel;
          return EditTransactionScreen(transaction: transaction);
        },
      ),
      GoRoute(
        path: SettingsScreen.routePath,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: SupportInfoScreen.routePath,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SupportInfoScreen(),
      ),
      GoRoute(
        path: ThemeSettingsScreen.routePath,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      GoRoute(
        path: LanguageSettingsScreen.routePath,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LanguageSettingsScreen(),
      ),
      GoRoute(
        path: NotificationSettingsScreen.routePath,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: PrivacyScreen.routePath,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: VersionScreen.routePath,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const VersionScreen(),
      ),
    ],
  );
}

final GoRouter appRouter = AppRouter.router;
