import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/domain/auth_domain.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_repository.dart';
import '../../../features/auth/providers/auth_controller.dart';
import '../../content/provider/content_repository.dart';
import '../../artifacts/provider/artifact_repository.dart';
import '../../../core/localization/translated_text.dart';
import '../../../core/widgets/shared_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/floating_island_nav.dart';
import '../../../core/widgets/audio_player_widget.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
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

  List<FloatingNavItem> _buildItems(
    List<LearningContent> allContent,
    List<Artifact> allArtifacts,
    List<AuthUser> allUsers,
  ) {
    bool isVerificationUpload(LearningContent content) {
      final subject = (content.subject ?? '').toLowerCase().trim();
      return subject == 'contributor verification' ||
          subject == 'institution verification';
    }

    final pendingContent = allContent
        .where(
          (c) =>
              c.status == AppConstants.statusPending && !isVerificationUpload(c),
        )
        .toList();

    final pendingArtifacts = allArtifacts
        .where((a) => a.status.toLowerCase().trim() == AppConstants.statusPending)
        .toList();

    final pendingUsers = allUsers
        .where(
          (u) =>
              (u.role == AppConstants.roleContributor) &&
              u.verificationSubmitted &&
              !u.isRejected &&
              !u.isVerified,
        )
        .length;

    return [
      _buildItem(
        Icons.museum_outlined,
        Icons.museum,
        'Exhibits',
        pendingArtifacts.length,
      ),
      _buildItem(
        Icons.menu_book_outlined,
        Icons.menu_book,
        'Docs',
        pendingContent
            .where(
              (c) => c.type.toLowerCase().trim() == AppConstants.contentTypePDF,
            )
            .length,
      ),
      _buildItem(
        Icons.video_library_outlined,
        Icons.video_library,
        'Videos',
        pendingContent
            .where(
              (c) =>
                  c.type.toLowerCase().trim() == AppConstants.contentTypeVideo,
            )
            .length,
      ),
      _buildItem(
        Icons.audiotrack_outlined,
        Icons.audiotrack,
        'Audio',
        pendingContent
            .where(
              (c) =>
                  c.type.toLowerCase().trim() == AppConstants.contentTypeAudio,
            )
            .length,
      ),
      _buildItem(
        Icons.psychology_outlined,
        Icons.psychology,
        'Quizzes',
        pendingContent
            .where(
              (c) =>
                  c.type.toLowerCase().trim() ==
                  AppConstants.contentTypeAnalysis,
            )
            .length,
      ),
      _buildItem(
        Icons.article_outlined,
        Icons.article,
        'Notes',
        pendingContent
            .where(
              (c) =>
                  c.type.toLowerCase().trim() ==
                  AppConstants.contentTypeWorksheet,
            )
            .length,
      ),
      _buildItem(
        Icons.verified_user_outlined,
        Icons.verified_user,
        'Verify',
        pendingUsers,
      ),
      _buildItem(
        Icons.people_outline,
        Icons.people,
        'Users',
        allUsers.where((u) => u.role != 'admin').length,
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
        showProfile: true,
        switcherOnRight: false,
        extraActions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.kAccent),
            tooltip: 'Force Sync',
            onPressed: () {
              // Triggering state updates across providers
              ref.invalidate(pendingContentProvider);
              ref.invalidate(allArtifactsProvider);
              ref.invalidate(pendingVerificationsProvider);
              ref.invalidate(pendingContributorsProvider);
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
            child: Consumer(
              builder: (context, ref, _) {
                final List<LearningContent> contentList =
                    ref.watch(allContentProvider).asData?.value ?? const [];
                final List<Artifact> artifactList =
                    ref.watch(allArtifactsProvider).asData?.value ?? const [];
                final List<AuthUser> userList =
                    ref.watch(allUsersProvider).asData?.value ?? const [];
                return FloatingIslandNav(
                  items: _buildItems(contentList, artifactList, userList),
                  currentIndex: _bottomNavIndex,
                  onTap: (index) => setState(() => _bottomNavIndex = index),
                );
              },
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

// Old _AdminGlassBottomNavBar and _NavItem removed — replaced by FloatingIslandNav

class _ReviewListSection extends ConsumerWidget {
  final String type;
  const _ReviewListSection({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingContentProvider);
    return pendingAsync.when(
      data: (allPending) {
        String normalizeType(String rawType) {
          final t = rawType.toLowerCase().trim();
          switch (t) {
            case 'book': case 'books': case 'document':
            case 'documents': case 'doc': case 'pdfs':
              return AppConstants.contentTypePDF;
            case 'report': case 'reports': case 'worksheet': case 'worksheets':
              return AppConstants.contentTypeWorksheet;
            case 'analysis': case 'analyses': case 'quiz': case 'quizzes':
              return AppConstants.contentTypeAnalysis;
            case 'video': case 'videos':
              return AppConstants.contentTypeVideo;
            case 'audio': case 'audios':
              return AppConstants.contentTypeAudio;
            default:
              return t;
          }
        }

        final targetType = normalizeType(type);
        final filtered = allPending
            .where((c) {
              final subject = (c.subject ?? '').toLowerCase().trim();
              return normalizeType(c.type) == targetType &&
                  subject != 'contributor verification';
            })
            .toList()
          ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

        if (filtered.isEmpty) {
          return _EmptyReviewState(message: 'No pending ${type}s to review');
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          itemCount: filtered.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ContentReviewCard(content: filtered[index]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _ErrorDisplay(error: err),
    );
  }
}

class _VerificationSection extends ConsumerWidget {
  const _VerificationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationsAsync = ref.watch(pendingVerificationsProvider);
    final contributorsAsync = ref.watch(pendingContributorsProvider);

    return verificationsAsync.when(
      data: (pendingDocs) {
        return contributorsAsync.when(
          data: (pendingUsers) {
            if (pendingDocs.isEmpty && pendingUsers.isEmpty) {
              return const _EmptyReviewState(
                message: 'No pending contributor verifications',
              );
            }

            final List<Widget> cards = [];
            for (final doc in pendingDocs) {
              cards.add(
                _ContributorVerificationCard(
                  key: ValueKey(doc.id),
                  content: doc,
                ),
              );
            }
            for (final user in pendingUsers) {
              final hasDoc = pendingDocs.any((d) => d.authorId == user.uid);
              if (!hasDoc) {
                cards.add(
                  _UserOnlyVerificationCard(
                    key: ValueKey(user.uid),
                    user: user,
                  ),
                );
              }
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: cards.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: cards[index],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => _ErrorDisplay(error: err),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _ErrorDisplay(error: err),
    );
  }
}

class _ErrorDisplay extends StatelessWidget {
  final Object error;
  const _ErrorDisplay({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 48,
            ),
            const SizedBox(height: 12),
            TranslatedText(
              'Error loading verifications:\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserOnlyVerificationCard extends ConsumerWidget {
  final AuthUser user;
  const _UserOnlyVerificationCard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? user.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: AppTheme.kParchment,
                        ),
                      ),
                      Text(
                        'User Pending (Document Missing / Parsing Error)',
                        style: TextStyle(
                          color: Colors.orange.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.white10),
            TranslatedText(
              'Institution: ${user.institution ?? 'N/A'}',
              style: const TextStyle(color: AppTheme.kParchment, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Verification flag is set, but no credential file was found in the system.',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(authControllerProvider.notifier)
                        .updateVerificationStatus(
                          user.uid,
                          false,
                          reason:
                              'No credential documents were found. Please re-submit your verification.',
                        );
                  },
                  child: const TranslatedText(
                    'Reset Flag',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserDirectorySection extends ConsumerWidget {
  const _UserDirectorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      data: (list) {
        final manageableUsers = list
            .where((u) => u.role != AppConstants.roleAdmin)
            .toList();

        if (manageableUsers.isEmpty) {
          return const _EmptyReviewState(message: 'No users found');
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          itemCount: manageableUsers.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _UserCard(
              key: ValueKey(manageableUsers[index].uid),
              user: manageableUsers[index],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _ErrorDisplay(error: err),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final AuthUser user;
  const _UserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.kAncientBlue.withOpacity(0.18),
          child: Text(
            user.email[0].toUpperCase(),
            style: const TextStyle(
              color: AppTheme.kAncientBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.displayName ?? user.email,
          style: const TextStyle(color: AppTheme.kParchment),
        ),
        subtitle: Text(
          '${user.email} • ${user.role.toUpperCase()}',
          style: TextStyle(
            color: AppTheme.kParchment.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user.role == AppConstants.roleContributor)
              IconButton(
                icon: Icon(
                  user.isVerified
                      ? Icons.verified
                      : Icons.verified_user_outlined,
                  color: user.isVerified
                      ? Colors.blue.shade400
                      : Colors.white24,
                  size: 20,
                ),
                tooltip: user.isVerified
                    ? 'Revoke Verification'
                    : 'Verify Contributor',
                onPressed: () => ref
                    .read(authControllerProvider.notifier)
                    .updateVerificationStatus(
                      user.uid,
                      !user.isVerified,
                    ),
              ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppTheme.errorColor,
                size: 20,
              ),
              onPressed: () => _confirmUserDeletion(context, ref, user),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmUserDeletion(
    BuildContext context,
    WidgetRef ref,
    AuthUser user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const TranslatedText('Delete User?'),
        content: TranslatedText(
          'Are you sure you want to delete ${user.displayName ?? user.email}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const TranslatedText('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(authControllerProvider.notifier)
                  .adminDeleteUser(user.email);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const TranslatedText('DELETE'),
          ),
        ],
      ),
    );
  }
}

class _ArtifactReviewSection extends ConsumerWidget {
  const _ArtifactReviewSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artifactsAsync = ref.watch(allArtifactsProvider);

    return artifactsAsync.when(
      data: (artifacts) {
        final pendingArtifacts = artifacts
            .where((a) {
              return a.status.toLowerCase().trim() ==
                  AppConstants.statusPending;
            })
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (pendingArtifacts.isEmpty) {
          return const _EmptyReviewState(
            message: 'No pending exhibits to review',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          itemCount: pendingArtifacts.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ArtifactReviewCard(artifact: pendingArtifacts[index]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _ErrorDisplay(error: err),
    );
  }
}

class _ArtifactReviewCard extends ConsumerWidget {
  final Artifact artifact;
  const _ArtifactReviewCard({required this.artifact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      borderRadius: 16,
      glowColor: AppTheme.kAccent,
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.kAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.account_balance,
            color: AppTheme.kAccent,
            size: 22,
          ),
        ),
        title: TranslatedText(
          artifact.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.kParchment,
          ),
        ),
        subtitle: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            TranslatedText(
              'By ${artifact.authorName}',
              style: TextStyle(color: AppTheme.kParchment.withOpacity(0.5)),
            ),
            _AuthorVerificationBadge(uid: artifact.authorId),
            Text(
              '• ${artifact.sections.length} Themes',
              style: TextStyle(
                color: AppTheme.kParchment.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.kAccent),
        onTap: () => context.push('/artifact-review-detail', extra: artifact),
      ),
    );
  }
}

class _ContributorVerificationCard extends ConsumerWidget {
  final LearningContent content;
  const _ContributorVerificationCard({super.key, required this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      borderRadius: 16,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VerificationDocumentThumbnail(
                  contentId: content.id,
                  type: content.type,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.kParchment,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.kAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const TranslatedText(
                          'Contributor Request',
                          style: TextStyle(
                            color: AppTheme.kAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance,
                            size: 14,
                            color: Colors.white38,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Institution/Archive: ${content.title}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.badge,
                            size: 14,
                            color: Colors.white38,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ID: ${content.gradeLevel ?? 'N/A'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handlePreview(context, ref),
                    icon: const Icon(Icons.zoom_in, size: 18),
                    label: const TranslatedText('Examine Detail'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showRejectDialog(context, ref),
                  icon: const Icon(Icons.close, color: AppTheme.errorColor),
                  tooltip: 'Reject',
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    await ref
                        .read(authControllerProvider.notifier)
                        .updateVerificationStatus(content.authorId, true);
                    await ref
                        .read(contentControllerProvider.notifier)
                        .updateContentStatus(
                          content.id,
                          AppConstants.statusApproved,
                        );
                  },
                  icon: const Icon(Icons.check, color: Colors.green),
                  tooltip: 'Approve',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handlePreview(BuildContext context, WidgetRef ref) async {
    final bytes = await ref.read(contentFileProvider(content.id).future);
    if (!context.mounted) return;

    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TranslatedText('Could not load credential.')),
      );
      return;
    }

    if (content.type == AppConstants.contentTypePDF) {
      context.push('/pdf-viewer', extra: content);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.kSurface,
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const TranslatedText('Credential Image'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: InteractiveViewer(
                  child: Image.memory(
                    bytes,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text:
          'Your credentials could not be verified. Please ensure the documents are clear and valid.',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.kSurface,
        title: const TranslatedText('Reject Verification'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Reason for Rejection',
            labelStyle: TextStyle(color: AppTheme.kAccent),
            hintText: 'Enter why the credentials were rejected...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const TranslatedText(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () async {
              final reason = controller.text.trim();
              Navigator.pop(context);
              await ref
                  .read(authControllerProvider.notifier)
                  .updateVerificationStatus(
                    content.authorId,
                    false,
                    reason: reason.isNotEmpty ? reason : null,
                  );
              await ref
                  .read(contentControllerProvider.notifier)
                  .updateContentStatus(content.id, AppConstants.statusRejected);
            },
            child: const TranslatedText('Reject Access'),
          ),
        ],
      ),
    );
  }
}

class _VerificationDocumentThumbnail extends ConsumerWidget {
  final String contentId;
  final String type;

  const _VerificationDocumentThumbnail({
    required this.contentId,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (type == AppConstants.contentTypePDF) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.picture_as_pdf,
          color: Colors.redAccent,
          size: 40,
        ),
      );
    }

    return FutureBuilder<Uint8List?>(
      future: ref.read(contentFileProvider(contentId).future),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 100,
            height: 100,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.data == null) {
          return Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.image_not_supported, color: Colors.white24),
          );
        }
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: MemoryImage(snapshot.data!),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}

class _ContentReviewCard extends ConsumerWidget {
  final LearningContent content;
  const _ContentReviewCard({required this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      borderRadius: 16,
      padding: EdgeInsets.zero,
      child: Padding(
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
                      TranslatedText(
                        content.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          TranslatedText(
                            'By ${content.authorName}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          _AuthorVerificationBadge(uid: content.authorId),
                          Text(
                            '• Level: ${content.gradeLevel ?? 'N/A'}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(content.type).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getTypeColor(content.type)),
                  ),
                  child: Text(
                    content.type.toUpperCase(),
                    style: TextStyle(
                      color: _getTypeColor(content.type),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (content.type == AppConstants.contentTypeAnalysis) {
                        _showAnalysisPreview(context);
                      } else if (content.type ==
                          AppConstants.contentTypeVideo) {
                        context.push(
                          '/video-viewer',
                          extra: {
                            'url': content.url ?? '',
                            'title': content.title,
                            'fileId': content.id,
                          },
                        );
                      } else if (content.type ==
                          AppConstants.contentTypeAudio) {
                        _showAudioPreview(context, ref);
                      } else {
                        context.push('/pdf-viewer', extra: content);
                      }
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const TranslatedText('Preview'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showRejectDialog(context, ref),
                  icon: const Icon(Icons.close, color: AppTheme.errorColor),
                  tooltip: 'Reject',
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => ref
                      .read(contentControllerProvider.notifier)
                      .updateContentStatus(
                        content.id,
                        AppConstants.statusApproved,
                      ),
                  icon: const Icon(Icons.check, color: Colors.green),
                  tooltip: 'Approve',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.kSurface,
        title: const TranslatedText('Reject Content'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Reason for Rejection',
            labelStyle: TextStyle(color: AppTheme.kAccent),
            hintText: 'Enter why this content was rejected...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const TranslatedText(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(contentControllerProvider.notifier)
                  .updateContentStatus(content.id, AppConstants.statusRejected);
            },
            child: const TranslatedText('Reject Content'),
          ),
        ],
      ),
    );
  }

  void _showAnalysisPreview(BuildContext context) {
    // Check both 'evidence' and 'questions' for backward compatibility
    final questions =
        (content.extraData?['evidence'] as List? ??
                content.extraData?['questions'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.kSurface,
        title: TranslatedText(
          'Quiz Preview: ${content.title}',
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: questions.isEmpty
              ? const Center(
                  child: TranslatedText(
                    'No quiz questions available',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (context, i) {
                    final q = questions[i];
                    final opts = (q['options'] as List?)?.cast<String>() ?? [];
                    final correct =
                        q['correctAnswerIndex'] as int? ??
                        q['correctIndex'] as int? ??
                        0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Q${i + 1}: ${q['questionText'] ?? q['question'] ?? ''}',
                            style: const TextStyle(
                              color: AppTheme.kAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(opts.length, (optIdx) {
                            final isCorrect = optIdx == correct;
                            return Padding(
                              padding: const EdgeInsets.only(
                                left: 8.0,
                                bottom: 4.0,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isCorrect
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    size: 16,
                                    color: isCorrect
                                        ? Colors.green
                                        : Colors.white38,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      opts[optIdx],
                                      style: TextStyle(
                                        color: isCorrect
                                            ? Colors.green
                                            : Colors.white70,
                                        fontWeight: isCorrect
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const TranslatedText('Close'),
          ),
        ],
      ),
    );
  }

  void _showAudioPreview(BuildContext context, WidgetRef ref) async {
    final bytes = await ref.read(contentFileProvider(content.id).future);
    if (!context.mounted) return;

    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TranslatedText('Could not load audio file.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: AudioPlayerWidget(
          bytes: bytes,
          title: content.title,
          item: content,
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case AppConstants.contentTypeAnalysis:
        return Colors.orange;
      case AppConstants.contentTypeWorksheet:
        return Colors.teal;
      case AppConstants.contentTypeAudio:
        return Colors.purpleAccent;
      default:
        return AppTheme.kAccent;
    }
  }
}

class _AuthorVerificationBadge extends ConsumerWidget {
  final String uid;
  const _AuthorVerificationBadge({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByUidProvider(uid));
    return userAsync.when(
      data: (user) {
        if (user == null || !user.isVerified) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(Icons.verified, size: 14, color: Colors.blue.shade400),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, stackTrace) => const SizedBox.shrink(),
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
            Icons.checklist_rtl,
            size: 64,
            color: AppTheme.kAccent.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          TranslatedText(
            message,
            style: TextStyle(color: AppTheme.kParchment.withOpacity(0.45)),
          ),
        ],
      ),
    );
  }
}
