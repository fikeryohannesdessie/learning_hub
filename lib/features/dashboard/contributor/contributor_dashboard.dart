import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/translated_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/floating_island_nav.dart';
import '../../../core/models/artifact_model.dart';
import '../../../core/models/content_model.dart';

class ContributorDashboard extends StatefulWidget {
  const ContributorDashboard({super.key});

  @override
  State<ContributorDashboard> createState() => _ContributorDashboardState();
}

class _ContributorDashboardState extends State<ContributorDashboard> {
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

  void _openContributorRoute(BuildContext context, int index) {
    if (index == 0) {
      setState(() => _navIndex = 0);
      return;
    }

    setState(() => _navIndex = index);

    if (index == 1) {
      context.push('/artifact-builder');
    } else if (index == 2) {
      context.push('/analyze-evidence');
    } else if (index == 3) {
      context.push(
        '/upload-content',
        extra: {'initialType': AppConstants.contentTypeVideo},
      );
    } else if (index == 4) {
      context.push(
        '/upload-content',
        extra: {'initialType': AppConstants.contentTypePDF},
      );
    } else if (index == 5) {
      context.push('/contributor-stats');
    }

    // Reset nav index after push returns or just keep it 0 for portal
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _navIndex = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
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
              SliverToBoxAdapter(child: _buildWelcomeSection()),
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
              _buildMockUploadsFeed(),
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

  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portal Access granted,',
            style: TextStyle(
              color: AppTheme.kParchment.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Aster Kebede',
            style: TextStyle(
              color: AppTheme.kParchment,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('Active Exhibits', '3', AppTheme.kAccent),
              const SizedBox(width: 12),
              _buildStatCard('Total Views', '1.2K', AppTheme.kTerracotta),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
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
          'Quick Actions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white38,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickActionBtn(
              icon: Icons.auto_awesome,
              label: 'Exhibit',
              color: AppTheme.kAccent,
              onTap: () => context.push('/artifact-builder'),
            ),
            _QuickActionBtn(
              icon: Icons.videocam,
              label: 'Video',
              color: Colors.orangeAccent,
              onTap: () => context.push(
                '/upload-content',
                extra: {'initialType': AppConstants.contentTypeVideo},
              ),
            ),
            _QuickActionBtn(
              icon: Icons.description,
              label: 'Docs',
              color: Colors.blueAccent,
              onTap: () => context.push(
                '/upload-content',
                extra: {'initialType': AppConstants.contentTypePDF},
              ),
            ),
            _QuickActionBtn(
              icon: Icons.psychology,
              label: 'Quiz',
              color: Colors.greenAccent,
              onTap: () => context.push('/analyze-evidence'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMockUploadsFeed() {
    final mockArtifacts = [
      ArtifactModel(
        id: 'a1',
        title: 'Aksumite Coins',
        description: 'Analysis of gold coins.',
        authorId: 'me',
        authorName: 'Aster',
        status: AppConstants.statusApproved,
        sections: [],
        createdAt: DateTime.now(),
      ),
    ];
    final mockContent = [
      ContentModel(
        id: 'c1',
        title: 'Harar Gates Video',
        type: AppConstants.contentTypeVideo,
        authorId: 'me',
        authorName: 'Aster',
        status: AppConstants.statusPending,
        uploadedAt: DateTime.now(),
      ),
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < mockArtifacts.length) {
            return _ActivityCard(
              title: mockArtifacts[index].title,
              type: 'Exhibit',
              status: mockArtifacts[index].status,
              date: mockArtifacts[index].createdAt,
            );
          } else {
            final cIndex = index - mockArtifacts.length;
            return _ActivityCard(
              title: mockContent[cIndex].title,
              type: mockContent[cIndex].type.toUpperCase(),
              status: mockContent[cIndex].status,
              date: mockContent[cIndex].uploadedAt,
            );
          }
        },
        childCount: mockArtifacts.length + mockContent.length,
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String type;
  final String status;
  final DateTime date;

  const _ActivityCard({
    required this.title,
    required this.type,
    required this.status,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final isApproved = status == AppConstants.statusApproved;
    final isPending = status == AppConstants.statusPending;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                type == 'Exhibit' ? Icons.auto_awesome : Icons.cloud_done,
                color: Colors.white38,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$type • ${date.day}/${date.month}/${date.year}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isApproved
                    ? Colors.green.withOpacity(0.1)
                    : (isPending
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: isApproved
                      ? Colors.green
                      : (isPending ? Colors.orange : Colors.red),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
