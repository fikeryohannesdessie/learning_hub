import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/contributor_verification_screen.dart';
import '../../features/dashboard/viewer/viewer_dashboard.dart';
import '../../features/dashboard/contributor/contributor_dashboard.dart';
import '../../features/dashboard/admin/admin_dashboard.dart';
import '../../features/dashboard/admin/artifact_review_detail_screen.dart';
import '../../features/auth/providers/auth_controller.dart';
import '../../features/content/viewer/pdf_viewer_screen.dart';
import '../../features/artifact_3d/artifact_3d_viewer_screen.dart';
import '../../features/bookmark/presentation/bookmarks_screen.dart';
import '../../features/artifacts/presentation/artifact_builder_screen.dart';
import '../../features/artifacts/presentation/artifact_list_screen.dart';
import '../../features/artifacts/presentation/artifact_detail_screen.dart';
import '../../features/artifacts/presentation/artifact_viewer_screen.dart';
import '../../features/artifacts/presentation/artifact_player_screen.dart';
import '../../features/artifacts/presentation/contributor_artifact_stats_screen.dart';
import '../../features/content/domain/content_domain.dart';
import '../../features/artifacts/domain/artifact_domain.dart';
import '../../features/artifacts/presentation/analysis_taking_screen.dart';
import '../../features/content/upload/upload_content_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/content/upload/analysis_creator_screen.dart';
import '../constants/app_constants.dart';
import '../../features/content/viewer/video_viewer_screen.dart';
import '../../features/content/viewer/content_collection_screen.dart';
import '../../features/artifacts/infrastructure/artifact_model_mapper.dart';
import '../../features/content/infrastructure/content_model_mapper.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(userProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = user != null;
      final isOnVerifyScreen = state.matchedLocation == '/verify-contributor';
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password';

      if (!isLoggedIn && !isLoggingIn && state.matchedLocation != '/') {
        return '/login';
      }

      // Check for contributor verification
      if (isLoggedIn && user.role == AppConstants.roleContributor) {
        final isVerified = user.isVerified ?? false;

        if (!isVerified && !isOnVerifyScreen) {
          return '/verify-contributor';
        }

        if (isVerified) {
          // If verified but still on verify screen, move to home
          if (isOnVerifyScreen) return '/home';
        }
      }

      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/verify-contributor',
        builder: (context, state) => const ContributorVerificationScreen(),
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
        path: '/home',
        builder: (context, state) {
          final user = ref.watch(userProvider);
          if (user == null)
            return const Center(child: CircularProgressIndicator());

          if (user.role == AppConstants.roleAdmin) {
            return const AdminDashboard();
          } else if (user.role == AppConstants.roleContributor) {
            return const ContributorDashboard();
          } else {
            return const ViewerDashboard();
          }
        },
      ),
      GoRoute(
        path: '/pdf-viewer',
        builder: (context, state) {
          if (state.extra is LearningContent) {
            final content = state.extra as LearningContent;
            return PDFViewerScreen(content: content);
          } else if (state.extra is Map<String, dynamic>) {
            final extra = state.extra as Map<String, dynamic>;
            final content = contentModelFromJson(extra);
            return PDFViewerScreen(content: content);
          }
          return const Scaffold(
            body: Center(child: Text("Invalid Document content")),
          );
        },
      ),
      GoRoute(
        path: '/artifact-3d',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return Artifact3DViewerScreen(
            // Placeholder until 3D path provided
            specificSim: extra?['specificSim'],
            title: extra?['title'] ?? '3D Artifact Viewer',
          );
        },
      ),
      GoRoute(
        path: '/bookmarks',
        builder: (context, state) => const BookmarksScreen(),
      ),
      GoRoute(
        path: '/content-collection',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ContentCollectionScreen(
            title: extra['title'] as String,
            classification: extra['classification'] as String,
            type: extra['type'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/artifact-builder',
        builder: (context, state) => const ArtifactBuilderScreen(),
      ),
      GoRoute(
        path: '/upload-content',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return UploadContentScreen(initialType: extra?['initialType']);
        },
      ),
      GoRoute(
        path: '/upload-artifact',
        builder: (context, state) => const UploadContentScreen(),
      ),
      GoRoute(
        path: '/analyze-evidence',
        builder: (context, state) => const AnalysisCreatorScreen(),
      ),
      GoRoute(
        path: '/artifact-review-detail',
        builder: (context, state) {
          final artifact = state.extra as Artifact;
          return ArtifactReviewDetailScreen(artifact: artifact);
        },
      ),
      GoRoute(
        path: '/artifacts',
        builder: (context, state) {
          final classification = state.extra as String?;
          return ArtifactListScreen(classification: classification);
        },
      ),
      GoRoute(
        path: '/artifact-detail',
        builder: (context, state) {
          Artifact artifact;
          if (state.extra is Artifact) {
            artifact = state.extra as Artifact;
          } else {
            artifact = artifactModelFromJson(
              state.extra as Map<String, dynamic>,
            );
          }
          return ArtifactDetailScreen(artifact: artifact);
        },
      ),
      GoRoute(
        path: '/artifact-viewer',
        builder: (context, state) {
          Artifact artifact;
          if (state.extra is Artifact) {
            artifact = state.extra as Artifact;
          } else {
            artifact = artifactModelFromJson(
              state.extra as Map<String, dynamic>,
            );
          }
          return ArtifactViewerScreen(artifact: artifact);
        },
      ),
      GoRoute(
        path: '/analysis-taking',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          Analysis analysis;
          if (extra['analysis'] is Analysis) {
            analysis = extra['analysis'] as Analysis;
          } else {
            analysis = analysisModelFromJson(
              extra['analysis'] as Map<String, dynamic>,
            );
          }
          return AnalysisTakingScreen(
            analysis: analysis,
            artifactId: extra['artifactId'] as String?,
            sectionId: extra['sectionId'] as String?,
            classification: extra['classification'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/artifact-player',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          Artifact artifact;
          if (extra['artifact'] is Artifact) {
            artifact = extra['artifact'] as Artifact;
          } else {
            artifact = artifactModelFromJson(
              extra['artifact'] as Map<String, dynamic>,
            );
          }
          return ArtifactPlayerScreen(
            artifact: artifact,
            initialContentId: extra['initialContentId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/contributor-stats',
        builder: (context, state) => const ContributorArtifactStatsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/video-viewer',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return VideoViewerScreen(
            url: extra['url'] as String? ?? '',
            title: extra['title'] as String,
            fileId: extra['fileId'] as String?,
            classification: extra['classification'] as String?,
          );
        },
      ),
    ],
  );
});
