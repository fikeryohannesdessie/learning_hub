import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/localization.dart';
import '../../../core/localization/translated_text.dart';
import '../../../core/widgets/shared_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/floating_island_nav.dart';
import '../../../core/utils/audio_utils.dart';
import '../../artifacts/application/artifact_application.dart';
import '../../artifacts/domain/artifact_domain.dart';
import '../../bookmark/application/bookmark_application.dart';
import '../../bookmark/domain/bookmark_domain.dart';
import '../../content/application/content_application.dart';
import '../../content/domain/content_domain.dart';
import '../../content/infrastructure/content_model_mapper.dart';

class ViewerDashboard extends ConsumerStatefulWidget {
  const ViewerDashboard({super.key});

  @override
  ConsumerState<ViewerDashboard> createState() => _ViewerDashboardState();
}

class _ViewerDashboardState extends ConsumerState<ViewerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _navIndex = 0;

  static const _items = [
    FloatingNavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Explore',
    ),
    FloatingNavItem(
      icon: Icons.museum_outlined,
      activeIcon: Icons.museum,
      label: 'Exhibits',
    ),
    FloatingNavItem(
      icon: Icons.auto_stories_outlined,
      activeIcon: Icons.auto_stories,
      label: 'Docs',
    ),
    FloatingNavItem(
      icon: Icons.psychology_outlined,
      activeIcon: Icons.psychology,
      label: 'Challenges',
    ),
    FloatingNavItem(
      icon: Icons.history_edu_outlined,
      activeIcon: Icons.history_edu,
      label: 'Notes',
    ),
    FloatingNavItem(
      icon: Icons.favorite_border,
      activeIcon: Icons.favorite,
      label: 'Saved',
    ),
    FloatingNavItem(
      icon: Icons.view_in_ar_outlined,
      activeIcon: Icons.view_in_ar,
      label: '3D',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBg,
      extendBody: true,
      appBar: SharedAppBar(
        title: 'CHPA Heritage',
        switcherOnRight: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              child: TranslatedText(
                'TANGIBLE',
                style: TextStyle(letterSpacing: 1.2),
              ),
            ),
            Tab(
              child: TranslatedText(
                'INTANGIBLE',
                style: TextStyle(letterSpacing: 1.2),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // ── Background ambient gradient ─────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.6),
                  radius: 0.8,
                  colors: [
                    AppTheme.kAccent.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main scrollable content ─────────────────────────────────────
          TabBarView(
            controller: _tabController,
            children: [
              _ClassificationSection(
                classification: AppConstants.classificationTangible,
                tabIndex: _navIndex,
              ),
              _ClassificationSection(
                classification: AppConstants.classificationIntangible,
                tabIndex: _navIndex,
              ),
            ],
          ),

          // ── Floating island nav ─────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingIslandNav(
              items: _items,
              currentIndex: _navIndex,
              onTap: (index) {
                if (index == 6) {
                  context.push('/artifact-3d');
                } else {
                  setState(() => _navIndex = index);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Classification tab body
// ────────────────────────────────────────────────────────────────────────────

class _ClassificationSection extends ConsumerWidget {
  final String classification;
  final int tabIndex;
  const _ClassificationSection({
    required this.classification,
    required this.tabIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(
      approvedContentProvider((
        gradeLevel: classification,
        type: AppConstants.contentTypePDF,
      )),
    );
    final analysisAsync = ref.watch(
      approvedContentProvider((
        gradeLevel: classification,
        type: AppConstants.contentTypeAnalysis,
      )),
    );
    final reportsAsync = ref.watch(
      approvedContentProvider((
        gradeLevel: classification,
        type: AppConstants.contentTypeWorksheet,
      )),
    );
    final audioAsync = classification == AppConstants.classificationIntangible
        ? ref.watch(
            approvedContentProvider((
              gradeLevel: classification,
              type: AppConstants.contentTypeAudio,
            )),
          )
        : null;
    final videoAsync = ref.watch(
      approvedContentProvider((
        gradeLevel: classification,
        type: AppConstants.contentTypeVideo,
      )),
    );
    final bookmarks = ref.watch(bookmarksProvider);
    final filteredBookmarks = bookmarks
        .where((bookmark) => bookmark.matchesClassification(classification))
        .toList()
      ..sort((a, b) => b.bookmarkedAt.compareTo(a.bookmarkedAt));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tabIndex == 0 || tabIndex == 1) ...[
            _SectionHeader(
              title: 'Featured Exhibits',
              actionLabel: 'Show All',
              onSeeAll: () => context.push('/artifacts', extra: classification),
            ),
            const SizedBox(height: 12),
            _FeaturedArtifactsList(classification: classification),
            const SizedBox(height: 24),
          ],
          if (tabIndex == 0 || tabIndex == 2) ...[
            _SectionHeader(
              title: 'Archival Documents',
              onSeeAll: () => context.push(
                '/content-collection',
                extra: {
                  'title': 'Archival Documents',
                  'classification': classification,
                  'type': AppConstants.contentTypePDF,
                },
              ),
            ),
            const SizedBox(height: 12),
            _ContentList(
              asyncValue: docsAsync,
              placeholder: 'No archival documents yet',
            ),
            const SizedBox(height: 24),
          ],
          if (tabIndex == 0) ...[
            _SectionHeader(
              title: '3D Heritage Explorer',
              onSeeAll: () => context.push(
                '/artifact-3d',
                extra: {
                  'specificSim': 'lalibela',
                  'title': '3D Heritage Explorer',
                },
              ),
            ),
            const SizedBox(height: 12),
            _Artifact3DCard(
              onTap: () => context.push(
                '/artifact-3d',
                extra: {
                  'specificSim': 'lalibela',
                  'title': 'Heritage 3D Preview',
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (tabIndex == 0) ...[
            _SectionHeader(
              title: 'Visual Media',
              onSeeAll: () => context.push(
                '/content-collection',
                extra: {
                  'title': 'Visual Media',
                  'classification': classification,
                  'type': AppConstants.contentTypeVideo,
                },
              ),
            ),
            const SizedBox(height: 12),
            _ContentList(
              asyncValue: videoAsync,
              placeholder: 'No visual media yet',
            ),
            const SizedBox(height: 24),
          ],
          if (tabIndex == 0 || tabIndex == 3) ...[
            _SectionHeader(
              title: 'Heritage Challenges',
              onSeeAll: () => context.push(
                '/content-collection',
                extra: {
                  'title': 'Heritage Challenges',
                  'classification': classification,
                  'type': AppConstants.contentTypeAnalysis,
                },
              ),
            ),
            const SizedBox(height: 12),
            _ContentList(
              asyncValue: analysisAsync,
              placeholder: 'No challenges yet',
            ),
            const SizedBox(height: 24),
          ],
          if (tabIndex == 0 || tabIndex == 4) ...[
            _SectionHeader(
              title: 'Research Notes',
              onSeeAll: () => context.push(
                '/content-collection',
                extra: {
                  'title': 'Research Notes',
                  'classification': classification,
                  'type': AppConstants.contentTypeWorksheet,
                },
              ),
            ),
            const SizedBox(height: 12),
            _ContentList(
              asyncValue: reportsAsync,
              placeholder: 'No research notes yet',
            ),
            const SizedBox(height: 24),
          ],
          if (audioAsync != null && (tabIndex == 0)) ...[
            _SectionHeader(
              title: 'Oral Traditions & Audio',
              actionLabel: 'Show All',
              onSeeAll: () => context.push(
                '/content-collection',
                extra: {
                  'title': 'Oral Traditions',
                  'classification': classification,
                  'type': AppConstants.contentTypeAudio,
                },
              ),
            ),
            const SizedBox(height: 12),
            _ContentList(
              asyncValue: audioAsync,
              placeholder: 'No audio heritage yet',
            ),
            const SizedBox(height: 24),
          ],
          if (tabIndex == 5) ...[
            _SectionHeader(
              title: 'Personal Collection',
              onSeeAll: () => context.push('/bookmarks'),
            ),
            const SizedBox(height: 12),
            if (filteredBookmarks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.collections_bookmark_outlined,
                        size: 48,
                        color: AppTheme.kAccent.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      const TranslatedText(
                        'Your collection is empty',
                        style: TextStyle(color: AppTheme.kParchment),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filteredBookmarks.map((item) => _BookmarkTile(item: item)),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Section header
// ────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onSeeAll;
  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
    this.actionLabel = 'See All',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: AppTheme.kAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            TranslatedText(
              title,
              style: const TextStyle(
                color: AppTheme.kParchment,
                fontWeight: FontWeight.bold,
                fontSize: 17,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: onSeeAll,
          child: Row(
            children: [
              TranslatedText(
                actionLabel,
                style: const TextStyle(color: AppTheme.kAccent, fontSize: 13),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppTheme.kAccent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Artifact cards
// ────────────────────────────────────────────────────────────────────────────

class _FeaturedArtifactsList extends ConsumerWidget {
  final String classification;
  const _FeaturedArtifactsList({required this.classification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artifactsAsync = ref.watch(
      approvedArtifactsByClassificationProvider(classification),
    );
    return artifactsAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.kGlassBorder),
            ),
            child: const Center(
              child: TranslatedText(
                'No exhibits available yet',
                style: TextStyle(color: AppTheme.kParchment),
              ),
            ),
          );
        }
        final previewItems = list.take(4).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 212,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: previewItems.length,
                separatorBuilder: (_, index) => const SizedBox(width: 14),
                itemBuilder: (context, i) =>
                    _ArtifactCard(artifact: previewItems[i]),
              ),
            ),
            if (list.length > previewItems.length) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.kGlassBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.grid_view_rounded,
                      size: 16,
                      color: AppTheme.kAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TranslatedText(
                        '${list.length} exhibits available. Tap Show All for the full collection.',
                        style: TextStyle(
                          color: AppTheme.kParchment.withValues(alpha: 0.8),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(child: TranslatedText('Error: $e')),
    );
  }
}

class _ArtifactCard extends StatelessWidget {
  final Artifact artifact;
  const _ArtifactCard({required this.artifact});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push(
        '/artifact-detail',
        extra: artifact,
      ),
      child: SizedBox(
        width: 200,
        child: GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 18,
          color: const Color(0xFF17120D),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3B2A1A),
                        AppTheme.kTerracotta.withValues(alpha: 0.82),
                        AppTheme.kAncientBlue.withValues(alpha: 0.72),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        top: -18,
                        right: -10,
                        child: Icon(
                          Icons.architecture_rounded,
                          size: 88,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      Positioned(
                        bottom: -10,
                        left: -6,
                        child: Icon(
                          Icons.travel_explore_rounded,
                          size: 82,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: TranslatedText(
                                artifact.classification.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.account_balance_rounded,
                              size: 34,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 10),
                            TranslatedText(
                              'Cultural heritage',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      artifact.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.kParchment,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.layers_outlined,
                          size: 14,
                          color: AppTheme.kParchment.withValues(alpha: 0.55),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TranslatedText(
                            '${artifact.sections.length} Themes',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.kParchment.withValues(alpha: 0.62),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: AppTheme.kParchment.withValues(alpha: 0.55),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TranslatedText(
                            artifact.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.kParchment.withValues(alpha: 0.62),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Content list
// ────────────────────────────────────────────────────────────────────────────

class _ContentList extends StatelessWidget {
  final AsyncValue<List<LearningContent>> asyncValue;
  final String placeholder;
  const _ContentList({required this.asyncValue, required this.placeholder});

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: (list) {
        if (list.isEmpty) {
          return SizedBox(
            width: double.infinity,
            child: GlassCard(
              borderRadius: 16,
              child: Center(
                child: TranslatedText(
                  placeholder,
                  style: const TextStyle(color: AppTheme.kParchment),
                ),
              ),
            ),
          );
        }
        return SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, index) => const SizedBox(width: 14),
            itemBuilder: (_, i) => _ContentCard(item: list[i]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: TranslatedText('Error: $e')),
    );
  }
}

class _ContentCard extends ConsumerWidget {
  final LearningContent item;
  const _ContentCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPDF =
        item.type == AppConstants.contentTypePDF ||
        item.type == AppConstants.contentTypeWorksheet;
    final isAudio = item.type == AppConstants.contentTypeAudio;
    final isVideo = item.type == AppConstants.contentTypeVideo;

    final color = isPDF
        ? AppTheme.kTerracotta
        : (isAudio
              ? Colors.purpleAccent
              : (isVideo ? AppTheme.kAccent : AppTheme.kAncientBlue));
    final icon = isPDF
        ? Icons.article_outlined
        : (isAudio
              ? Icons.audiotrack_rounded
              : (isVideo
                    ? Icons.video_library_outlined
                    : Icons.psychology_outlined));

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (isPDF) {
          context.push('/pdf-viewer', extra: item);
        } else if (item.type == AppConstants.contentTypeAnalysis) {
          final evidencesData =
              (item.extraData?['evidence'] as List?) ??
              (item.extraData?['evidences'] as List?) ??
              (item.extraData?['questions'] as List?) ??
              [];
          final evidences = evidencesData.map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            return Evidence(
              questionText:
                  (map['factText'] ??
                          map['questionText'] ??
                          map['question'] ??
                          '')
                      as String,
              options: List<String>.from(
                map['possibilities'] ?? map['options'] ?? [],
              ),
              correctAnswerIndex:
                  (map['verifiedIndex'] ??
                          map['correctAnswerIndex'] ??
                          map['correctIndex'] ??
                          0)
                      as int,
              isShortAnswer:
                  (map['isShortAnswer'] ??
                          map['IsShortAnswer'] ??
                          map['isSummary'] ??
                          false)
                      as bool,
              correctShortAnswer:
                  (map['correctShortAnswer'] ??
                          map['CorrectShortAnswer'] ??
                          map['summaryText'])
                      as String?,
            );
          }).toList();
          context.push(
            '/analysis-taking',
            extra: {
              'analysis': Analysis(id: item.id, evidence: evidences),
              'artifactId': null,
              'sectionId': null,
              'classification': item.gradeLevel,
            },
          );
        } else if (isAudio) {
          showAudioPreview(context, ref, item);
        } else if (isVideo) {
          context.push(
            '/video-viewer',
            extra: {
              'url': item.url ?? '',
              'title': item.title,
              'fileId': item.id,
              'classification': item.gradeLevel,
            },
          );
        }
      },
      child: SizedBox(
        width: 145,
        child: GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.3),
                        color.withValues(alpha: 0.55),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(icon, size: 44, color: Colors.white70),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.kParchment,
                      ),
                    ),
                    TranslatedText(
                      item.subject ?? 'General',
                      style: TextStyle(
                        color: AppTheme.kParchment.withValues(alpha: 0.55),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 3D card
// ────────────────────────────────────────────────────────────────────────────

class _Artifact3DCard extends StatelessWidget {
  final VoidCallback onTap;
  const _Artifact3DCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                AppTheme.kAncientBlue.withValues(alpha: 0.7),
                AppTheme.kAccent.withValues(alpha: 0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppTheme.kAccent.withValues(alpha: 0.3)),
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  Icons.view_in_ar_rounded,
                  size: 80,
                  color: Colors.white24,
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TranslatedText(
                        'Ancient Artifact Survey',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TranslatedText(
                        'Interactive Heritage Simulation',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.kAccent.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.play_arrow, size: 14, color: Colors.black),
                      SizedBox(width: 4),
                      Text(
                        'Launch 3D',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Bookmark tile
// ────────────────────────────────────────────────────────────────────────────

class _BookmarkTile extends ConsumerWidget {
  final BookmarkItem item;
  const _BookmarkTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color iconColor;
    final IconData iconData;
    final String typeLabel;

    switch (item.type) {
      case 'pdf':
        iconData = Icons.article_outlined;
        iconColor = AppTheme.kTerracotta;
        typeLabel = 'Document';
        break;
      case 'worksheet':
        iconData = Icons.assignment_outlined;
        iconColor = AppTheme.kAncientBlue;
        typeLabel = 'Worksheet';
        break;
      case 'analysis':
        iconData = Icons.psychology_outlined;
        iconColor = AppTheme.kAccent;
        typeLabel = 'Challenge';
        break;
      case 'artifact_3d':
        iconData = Icons.view_in_ar_outlined;
        iconColor = AppTheme.kAncientBlue;
        typeLabel = '3D View';
        break;
      case 'artifact':
        iconData = Icons.account_balance_outlined;
        iconColor = AppTheme.kAccent;
        typeLabel = 'Artifact';
        break;
      case 'audio':
        iconData = Icons.audiotrack_rounded;
        iconColor = Colors.purpleAccent;
        typeLabel = 'Audio';
        break;
      case 'video':
        iconData = Icons.video_library_outlined;
        iconColor = AppTheme.kAccent;
        typeLabel = 'Video';
        break;
      default:
        iconData = Icons.bookmark_outline;
        iconColor = Colors.grey;
        typeLabel = 'Saved';
    }

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 16,
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(iconData, color: iconColor),
        ),
        title: TranslatedText(
          item.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.kParchment,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            TranslatedText(
              typeLabel,
              style: TextStyle(
                color: iconColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.bookmark_remove,
            color: AppTheme.kParchment.withValues(alpha: 0.4),
          ),
          onPressed: () async =>
              ref.read(bookmarksProvider.notifier).toggleBookmark(item),
        ),
        onTap: () {
          switch (item.type) {
            case 'pdf':
            case 'worksheet':
              context.push('/pdf-viewer', extra: item.extraData);
              break;
            case 'analysis':
              context.push('/analysis-taking', extra: item.extraData);
              break;
            case 'artifact_3d':
              context.push('/artifact-3d', extra: item.extraData);
              break;
            case 'artifact':
              context.push('/artifact-viewer', extra: item.extraData);
              break;
            case 'audio':
              final content = contentModelFromJson(item.extraData);
              showAudioPreview(context, ref, content);
              break;
            case 'video':
              context.push('/video-viewer', extra: item.extraData);
              break;
          }
        },
      ),
    );
  }
}
// Recompile everything with the DDD
