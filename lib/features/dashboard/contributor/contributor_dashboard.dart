import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/translated_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/floating_island_nav.dart';
import '../../artifacts/application/artifact_application.dart';
import '../../auth/application/auth_application.dart';
import '../../content/application/content_application.dart';
import '../../artifacts/domain/artifact_domain.dart';
import '../../content/domain/content_domain.dart';

class ContributorDashboard extends ConsumerStatefulWidget {
  const ContributorDashboard({super.key});

  @override
  ConsumerState<ContributorDashboard> createState() =>
      _ContributorDashboardState();
}

class _ContributorDashboardState extends ConsumerState<ContributorDashboard> {
  int _navIndex = 0;

  static const _items = [
    FloatingNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Portal',
    ),
    FloatingNavItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      label: 'Exhibit',
    ),
    FloatingNavItem(
      icon: Icons.psychology_outlined,
      activeIcon: Icons.psychology,
      label: 'Quiz',
    ),
    FloatingNavItem(
      icon: Icons.audiotrack_rounded,
      activeIcon: Icons.audiotrack,
      label: 'Audio',
    ),
    FloatingNavItem(
      icon: Icons.videocam_rounded,
      activeIcon: Icons.videocam,
      label: 'Video',
    ),
    FloatingNavItem(
      icon: Icons.description_rounded,
      activeIcon: Icons.description,
      label: 'Document',
    ),
    FloatingNavItem(
      icon: Icons.query_stats_outlined,
      activeIcon: Icons.query_stats,
      label: 'Impact',
    ),
  ];

  Future<void> _openContributorRoute(BuildContext context, int index) async {
    if (index == 0) {
      if (mounted) setState(() => _navIndex = 0);
      return;
    }

    if (mounted) setState(() => _navIndex = index);

    if (index == 1) {
      await context.push('/artifact-builder');
    } else if (index == 2) {
      await context.push('/analyze-evidence');
    } else if (index == 3) {
      await context.push(
        '/upload-content',
        extra: {'initialType': AppConstants.contentTypeAudio},
      );
    } else if (index == 4) {
      await context.push(
        '/upload-content',
        extra: {'initialType': AppConstants.contentTypeVideo},
      );
    } else if (index == 5) {
      await context.push(
        '/upload-content',
        extra: {'initialType': AppConstants.contentTypePDF},
      );
    } else if (index == 6) {
      await context.push('/contributor-stats');
    }

    if (mounted) {
      setState(() => _navIndex = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final artifactsAsync = user != null
        ? ref.watch(contributorArtifactsProvider(user.uid))
        : const AsyncValue<List<Artifact>>.loading();
    final uploadsAsync = user != null
        ? ref.watch(contributorContentProvider(user.uid))
        : const AsyncValue<List<LearningContent>>.loading();

    return Scaffold(
      backgroundColor: AppTheme.kBg,
      extendBody: true,
      appBar: SharedAppBar(title: 'Contributor Portal', switcherOnRight: false),
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.kTerracotta.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildWelcomeSection(user)),
              if (user != null && !user.isVerified)
                SliverToBoxAdapter(
                  child: _buildVerificationBanner(context, user),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                sliver: SliverToBoxAdapter(
                  child: _buildQuickUploadSection(context),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppTheme.kTerracotta,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const TranslatedText(
                        'Upload Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.kParchment,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildUploadsFeed(artifactsAsync, uploadsAsync, context),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),

          // Floating island nav
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingIslandNav(
              items: _items,
              currentIndex: _navIndex,
              onTap: (index) => _openContributorRoute(context, index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(dynamic user) {
    final userName = user?.displayName?.isNotEmpty == true
        ? user!.displayName
        : (user?.email?.split('@')[0] ?? 'Contributor');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: GlassCard(
        frosted: true,
        borderRadius: 20,
        padding: const EdgeInsets.all(20),
        glowColor: AppTheme.kTerracotta,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.kTerracotta, AppTheme.kAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.account_balance,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TranslatedText(
                  'Welcome Back,',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.kParchment.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.kParchment,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.kTerracotta.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.kTerracotta.withOpacity(0.4),
                    ),
                  ),
                  child: const TranslatedText(
                    'CONTRIBUTOR',
                    style: TextStyle(
                      color: AppTheme.kTerracotta,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickUploadSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TranslatedText(
          'Quick Contribution',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.kAccent,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                title: 'Audio',
                icon: Icons.audiotrack_rounded,
                color: Colors.purpleAccent,
                onTap: () => context.push(
                  '/upload-content',
                  extra: {'initialType': AppConstants.contentTypeAudio},
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionTile(
                title: 'Video',
                icon: Icons.videocam_rounded,
                color: AppTheme.kAncientBlue,
                onTap: () => context.push(
                  '/upload-content',
                  extra: {'initialType': AppConstants.contentTypeVideo},
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionTile(
                title: 'PDF',
                icon: Icons.description_rounded,
                color: AppTheme.kTerracotta,
                onTap: () => context.push(
                  '/upload-content',
                  extra: {'initialType': AppConstants.contentTypePDF},
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerificationBanner(BuildContext context, dynamic user) {
    final bool isRejected = user.isRejected ?? false;
    final bool isSubmitted = user.verificationSubmitted ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        glowColor: isRejected
            ? AppTheme.errorColor
            : (isSubmitted ? Colors.orange : AppTheme.kAccent),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isRejected
                      ? Icons.error_outline
                      : (isSubmitted
                            ? Icons.hourglass_empty
                            : Icons.verified_user_outlined),
                  color: isRejected
                      ? AppTheme.errorColor
                      : (isSubmitted ? Colors.orange : AppTheme.kAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(
                        isRejected
                            ? 'Verification Rejected'
                            : (isSubmitted
                                  ? 'Verification Pending'
                                  : 'Account Unverified'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.kParchment,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TranslatedText(
                        isRejected
                            ? 'Please update your credentials to regain access.'
                            : (isSubmitted
                                  ? 'Your documents are being reviewed by admins.'
                                  : 'Verify your identity to start publishing artifacts.'),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.kParchment.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/verify-contributor'),
                  child: TranslatedText(
                    isRejected || isSubmitted ? 'Details' : 'Verify Now',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadsFeed(
    AsyncValue<List<Artifact>> artifactsAsync,
    AsyncValue<List<LearningContent>> uploadsAsync,
    BuildContext context,
  ) {
    return artifactsAsync.when(
      data: (artifacts) {
        return uploadsAsync.when(
          data: (uploads) {
            final allItems = <_ContributorUploadItem>[
              ...artifacts.map(_ContributorUploadItem.artifact),
              ...uploads
                  .where(
                    (item) =>
                        item.subject != 'Contributor Verification' &&
                        item.subject != 'Institution Verification',
                  )
                  .map(_ContributorUploadItem.content),
            ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (allItems.isEmpty) {
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: GlassCard(
                    borderRadius: 18,
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 52,
                            color: AppTheme.kAccent.withOpacity(0.35),
                          ),
                          const SizedBox(height: 16),
                          const TranslatedText(
                            "You haven't uploaded anything yet.",
                            style: TextStyle(color: AppTheme.kParchment),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TranslatedText(
                            'Artifacts, archival documents, field notes, oral history records, and videos will appear here with their current review status.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.kParchment.withOpacity(0.6),
                              height: 1.4,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            final pending = allItems.where((i) => i.status == AppConstants.statusPending).toList();
            final approved = allItems.where((i) => i.status == AppConstants.statusApproved).toList();
            final rejected = allItems.where((i) => i.status == AppConstants.statusRejected).toList();

            return SliverMainAxisGroup(
              slivers: [
                if (approved.isNotEmpty) ...[
                  _buildActivityHeader('Live & Published', approved.length, const Color(0xFF4CAF82)),
                  _buildNestedTypeGroups(approved),
                ],
                if (pending.isNotEmpty) ...[
                  _buildActivityHeader('Pending Review', pending.length, AppTheme.kAccent),
                  _buildNestedTypeGroups(pending),
                ],
                if (rejected.isNotEmpty) ...[
                  _buildActivityHeader('Needs Attention', rejected.length, AppTheme.errorColor),
                  _buildNestedTypeGroups(rejected),
                ],
              ],
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) =>
              SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) =>
          SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildNestedTypeGroups(List<_ContributorUploadItem> items) {
    // Group items by their typeLabel within this status group
    final groups = <String, List<_ContributorUploadItem>>{};
    for (final item in items) {
      groups.putIfAbsent(item.typeLabel, () => []).add(item);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final typeLabel = groups.keys.elementAt(index);
          final typeItems = groups[typeLabel]!;
          return _buildScrollableTypeContainer(typeLabel, typeItems);
        },
        childCount: groups.length,
      ),
    );
  }

  Widget _buildScrollableTypeContainer(String label, List<_ContributorUploadItem> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppTheme.kParchment.withOpacity(0.35),
                letterSpacing: 1.1,
              ),
            ),
          ),
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 12),
            borderRadius: 20,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: items.length > 2 ? 260 : double.infinity,
              ),
              child: Scrollbar(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: items.map((item) => Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                          child: _ContributorUploadCard(item: item),
                        )).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityHeader(String title, int count, Color color) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            TranslatedText(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.kParchment.withOpacity(0.5),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Divider(
                color: AppTheme.kParchment.withOpacity(0.05),
                thickness: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────

class _ContributorUploadItem {
  final String id;
  final String title;
  final String typeLabel;
  final String status;
  final DateTime createdAt;
  final IconData icon;
  final Color accent;
  final String meta;
  const _ContributorUploadItem({
    required this.id,
    required this.title,
    required this.typeLabel,
    required this.status,
    required this.createdAt,
    required this.icon,
    required this.accent,
    required this.meta,
  });

  factory _ContributorUploadItem.artifact(Artifact artifact) {
    return _ContributorUploadItem(
      id: artifact.id,
      title: artifact.title,
      typeLabel: 'Exhibit',
      status: artifact.status,
      createdAt: artifact.createdAt,
      icon: Icons.account_balance_rounded,
      accent: AppTheme.kTerracotta,
      meta:
          '${artifact.sections.length} Sections • ${artifact.viewerIds.length} Views',
    );
  }

  factory _ContributorUploadItem.content(LearningContent content) {
    return _ContributorUploadItem(
      id: content.id,
      title: content.title,
      typeLabel: _contentTypeLabel(content.type),
      status: content.status,
      createdAt: content.uploadedAt,
      icon: _contentTypeIcon(content.type),
      accent: _contentTypeAccent(content.type),
      meta:
          '${content.subject ?? 'General'} • ${content.gradeLevel ?? 'Uncategorized'}',
    );
  }
}

class _ContributorUploadCard extends StatelessWidget {
  final _ContributorUploadItem item;
  const _ContributorUploadCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              gradient: LinearGradient(
                colors: [
                  item.accent.withOpacity(0.22),
                  item.accent.withOpacity(0.38),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(item.icon, color: item.accent, size: 32),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.kParchment,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  TranslatedText(
                    item.typeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: item.accent,
                    ),
                  ),
                  Row(
                    children: [
                      _StatusBadge(status: item.status),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TranslatedText(
                          item.meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.kParchment.withOpacity(0.45),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(
              Icons.chevron_right,
              color: AppTheme.kParchment.withOpacity(0.25),
            ),
          ),
        ],
      ),
    );
  }
}

String _contentTypeLabel(String type) {
  switch (type) {
    case AppConstants.contentTypeAnalysis:
      return 'Quiz';
    case AppConstants.contentTypeWorksheet:
      return 'Research Notes';
    case AppConstants.contentTypeVideo:
      return 'Video';
    case AppConstants.contentTypeAudio:
      return 'Audio';
    case AppConstants.contentTypePDF:
      return 'Document';
    default:
      return 'Upload';
  }
}

IconData _contentTypeIcon(String type) {
  switch (type) {
    case AppConstants.contentTypeAnalysis:
      return Icons.psychology_rounded;
    case AppConstants.contentTypeWorksheet:
      return Icons.assignment_rounded;
    case AppConstants.contentTypeVideo:
      return Icons.video_library_rounded;
    case AppConstants.contentTypeAudio:
      return Icons.audiotrack_rounded;
    case AppConstants.contentTypePDF:
      return Icons.auto_stories_rounded;
    default:
      return Icons.file_present_rounded;
  }
}

Color _contentTypeAccent(String type) {
  switch (type) {
    case AppConstants.contentTypeAnalysis:
      return AppTheme.kAncientBlue;
    case AppConstants.contentTypeWorksheet:
      return AppTheme.kTerracotta;
    case AppConstants.contentTypeVideo:
      return AppTheme.kAccent;
    case AppConstants.contentTypeAudio:
      return Colors.purpleAccent;
    case AppConstants.contentTypePDF:
      return AppTheme.kAccent;
    default:
      return AppTheme.kAccent;
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label = status.toUpperCase();
    if (status == 'approved') {
      color = const Color(0xFF4CAF82);
    } else if (status == 'rejected') {
      color = AppTheme.errorColor;
    } else {
      color = AppTheme.kAccent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: TranslatedText(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
class _QuickActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: GlassCard(
        frosted: true,
        padding: const EdgeInsets.symmetric(vertical: 16),
        borderRadius: 18,
        glowColor: color.withOpacity(0.15),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            TranslatedText(
              title,
              style: const TextStyle(
                color: AppTheme.kParchment,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
