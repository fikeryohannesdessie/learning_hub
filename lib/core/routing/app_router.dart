import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/contributor_verification_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/dashboard/admin/admin_dashboard.dart';
import '../../features/dashboard/contributor/contributor_dashboard.dart';
import '../../features/dashboard/viewer/viewer_dashboard.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

class AppRouter {
  static String currentUserRole = 'viewer';

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-contributor',
        builder: (context, state) => const ContributorVerificationScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const ViewerDashboard(),
      ),
      GoRoute(
        path: '/viewer-dashboard',
        builder: (context, state) => const ViewerDashboard(),
      ),
      GoRoute(
        path: '/contributor-dashboard',
        builder: (context, state) => const ContributorDashboard(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/artifact-builder',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Artifact Builder',
        ),
      ),
      GoRoute(
        path: '/analyze-evidence',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Analysis Creator',
        ),
      ),
      GoRoute(
        path: '/upload-content',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Upload Content',
        ),
      ),
      GoRoute(
        path: '/contributor-stats',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Contributor Stats',
        ),
      ),
    ],
  );
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(title),
      ),
    );
  }
}
