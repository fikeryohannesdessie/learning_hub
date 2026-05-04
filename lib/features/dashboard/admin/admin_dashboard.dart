import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/content_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/artifact_model.dart';
import '../../../core/localization/translated_text.dart';
import '../../../core/widgets/shared_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/floating_island_nav.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _bottomNavIndex = 0;

  Widget _buildBody() {
    switch (_bottomNavIndex) {
      case 0:
        return const _ArtifactReviewSection();
      case 1:
        return const _ReviewListSection(type: AppConstants.contentTypePDF);
      case 2:
        return const _ReviewListSection(type: AppConstants.contentTypeVideo);
      case 3:
        return const _ReviewListSection(type: AppConstants.contentTypeAudio);
      case 4:
        return const _ReviewListSection(type: AppConstants.contentTypeAnalysis);
      case 5:
        return const _ReviewListSection(
          type: AppConstants.contentTypeWorksheet,
        );
      case 6:
        return const _VerificationSection();
      case 7:
        return const _UserDirectorySection();
      default:
        return const SizedBox();
    }
  }

  FloatingNavItem _buildItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int count,
  ) {
    return FloatingNavItem(
      icon: icon,
      activeIcon: activeIcon,
      label: label,
      badgeCount: count,
    );
  }

  List<FloatingNavItem> _buildItems() {
    return [
      _buildItem(
        Icons.museum_outlined,
        Icons.museum,
        'Exhibits',
        2,
      ),
      _buildItem(
        Icons.menu_book_outlined,
        Icons.menu_book,
        'Docs',
        3,
      ),
      _buildItem(
        Icons.video_library_outlined,
        Icons.video_library,
        'Videos',
        1,
      ),
      _buildItem(
        Icons.audiotrack_outlined,
        Icons.audiotrack,
        'Audio',
        0,
      ),
      _buildItem(
        Icons.psychology_outlined,
        Icons.psychology,
        'Quizzes',
        2,
      ),
      _buildItem(
        Icons.article_outlined,
        Icons.article,
        'Notes',
        1,
      ),
      _buildItem(
        Icons.verified_user_outlined,
        Icons.verified_user,
        'Verify',
        4,
      ),
      _buildItem(
        Icons.people_outline,
        Icons.people,
        'Users',
        12,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBg,
      extendBody: true,
      appBar: SharedAppBar(
        title: 'Admin Panel',
        switcherOnRight: false,
        extraActions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.kAccent),
            tooltip: 'Force Sync',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing Data...')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.kAncientBlue.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Positioned.fill(
            child: Column(
              children: [
                _TypeSubHeader(index: _bottomNavIndex),
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey('admin_tab_view_$_bottomNavIndex'),
                    child: _buildBody(),
                  ),
                ),
              ],
            ),
          ),
          // Floating island nav
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingIslandNav(
              items: _buildItems(),
              currentIndex: _bottomNavIndex,
              onTap: (index) => setState(() => _bottomNavIndex = index),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeSubHeader extends StatelessWidget {
  final int index;
  const _TypeSubHeader({required this.index});

  String get _title {
    switch (index) {
      case 0:
        return 'Exhibit Reviews';
      case 1:
        return 'Archival Document Reviews';
      case 2:
        return 'Video Reviews';
      case 3:
        return 'Audio Reviews';
      case 4:
        return 'Quiz Reviews';
      case 5:
        return 'Research Notes Reviews';
      case 6:
        return 'Contributor Verifications';
      case 7:
        return 'User Accounts';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.kAncientBlue.withOpacity(0.06),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.kAncientBlue.withOpacity(0.18),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.kAncientBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          TranslatedText(
            _title,
            style: const TextStyle(
              color: AppTheme.kParchment,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtifactReviewSection extends StatelessWidget {
  const _ArtifactReviewSection();

  @override
  Widget build(BuildContext context) {
    // Mock data for artifact reviews
    final mockArtifacts = [
      ArtifactModel(
        id: '1',
        title: 'Aksumite Obelisk Analysis',
        description: 'Deep dive into the architectural significance of Axum.',
        authorId: 'auth1',
        authorName: 'Dr. Kebede',
        status: AppConstants.statusPending,
        sections: [],
        createdAt: DateTime.now(),
        classification: AppConstants.classTangible,
      ),
      ArtifactModel(
        id: '2',
        title: 'Lalibela Rock-Hewn Churches',
        description: 'Spiritual and architectural journey.',
        authorId: 'auth2',
        authorName: 'Aster M.',
        status: AppConstants.statusPending,
        sections: [],
        createdAt: DateTime.now(),
        classification: AppConstants.classTangible,
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: mockArtifacts.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ArtifactReviewCard(artifact: mockArtifacts[index]),
      ),
    );
  }
}

class _ArtifactReviewCard extends StatelessWidget {
  final ArtifactModel artifact;
  const _ArtifactReviewCard({required this.artifact});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artifact.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${artifact.authorName} • ${artifact.classification?.toUpperCase()}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.pending_actions, color: Colors.orangeAccent),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            artifact.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewListSection extends StatelessWidget {
  final String type;
  const _ReviewListSection({required this.type});

  @override
  Widget build(BuildContext context) {
    // Mock data for content reviews
    final mockContent = [
      ContentModel(
        id: 'c1',
        title: 'Heritage Preservation Doc',
        type: type,
        authorId: 'auth1',
        authorName: 'Dr. Kebede',
        status: AppConstants.statusPending,
        uploadedAt: DateTime.now(),
        subject: 'History',
      ),
    ];

    if (type == AppConstants.contentTypeAudio) {
      return const _EmptyReviewState(message: 'No pending Audio heritage to review');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: mockContent.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ContentReviewCard(content: mockContent[index]),
      ),
    );
  }
}

class _ContentReviewCard extends StatelessWidget {
  final ContentModel content;
  const _ContentReviewCard({required this.content});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${content.authorName} • ${content.subject}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.description, color: AppTheme.kAccent),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerificationSection extends StatelessWidget {
  const _VerificationSection();

  @override
  Widget build(BuildContext context) {
    return const _EmptyReviewState(message: 'No pending contributor verifications');
  }
}

class _UserDirectorySection extends StatelessWidget {
  const _UserDirectorySection();

  @override
  Widget build(BuildContext context) {
    // Mock user directory
    final mockUsers = [
      UserModel(
        uid: 'u1',
        email: 'admin@chpa.gov.et',
        role: AppConstants.roleAdmin,
        createdAt: DateTime.now(),
        displayName: 'Admin User',
      ),
      UserModel(
        uid: 'u2',
        email: 'contributor@chpa.gov.et',
        role: AppConstants.roleContributor,
        createdAt: DateTime.now(),
        displayName: 'Aster Kebede',
        isVerified: true,
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: mockUsers.length,
      itemBuilder: (context, index) => ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.kAccent.withOpacity(0.1),
          child: Text(
            (mockUsers[index].displayName ?? 'U')[0],
            style: const TextStyle(color: AppTheme.kAccent),
          ),
        ),
        title: Text(
          mockUsers[index].displayName ?? 'Anonymous',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          '${mockUsers[index].role.toUpperCase()} • ${mockUsers[index].email}',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: mockUsers[index].isVerified == true
            ? const Icon(Icons.verified, color: Colors.blue, size: 20)
            : null,
      ),
    );
  }
}

class _EmptyReviewState extends StatelessWidget {
  final String message;
  const _EmptyReviewState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fact_check_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          TranslatedText(
            message,
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
