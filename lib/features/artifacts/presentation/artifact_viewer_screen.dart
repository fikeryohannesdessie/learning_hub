import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/artifact_model.dart' show ArtifactModel;
import '../domain/artifact_domain.dart';
import '../../../core/localization/localization.dart';
import '../provider/artifact_repository.dart';
import '../../auth/providers/auth_controller.dart';
import '../../bookmark/provider/bookmark_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../infrastructure/artifact_model_mapper.dart';

class ArtifactViewerScreen extends ConsumerStatefulWidget {
  final Artifact artifact;

  const ArtifactViewerScreen({super.key, required this.artifact});

  @override
  ConsumerState<ArtifactViewerScreen> createState() =>
      _ArtifactViewerScreenState();
}

class _ArtifactViewerScreenState extends ConsumerState<ArtifactViewerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color _bgColor = const Color(0xFF0D0D0D);
  final Color _cardColor = const Color(0xFF1A1A1A);
  final Color _accentColor = AppTheme.kAccent;

  String? _selectedSectionId;
  DateTime? _entryTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _entryTime = DateTime.now();
  }

  @override
  void dispose() {
    _saveTimeSpent();
    _tabController.dispose();
    super.dispose();
  }

  void _saveTimeSpent() {
    if (_entryTime != null) {
      final spent = DateTime.now().difference(_entryTime!).inSeconds;
      final user = ref.read(userProvider);
      if (user != null && spent > 5) {
        final progressAsync = ref.read(
          viewerArtifactProgressProvider((user.uid, widget.artifact.id)),
        );
        progressAsync.whenData((progress) {
          final newProgress =
              progress?.copyWith(
                timeSpentSeconds: (progress.timeSpentSeconds) + spent,
              ) ??
              UserProgress(
                userId: user.uid,
                artifactId: widget.artifact.id,
                lastAccessedAt: DateTime.now(),
                timeSpentSeconds: spent,
              );
          ref
              .read(artifactControllerProvider.notifier)
              .saveUserProgress(newProgress);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final progressAsync = ref.watch(
      viewerArtifactProgressProvider((user.uid, widget.artifact.id)),
    );
    final bookmarks = ref.watch(bookmarksProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      body: progressAsync.when(
        data: (progress) {
          final p =
              progress ??
              UserProgress(
                userId: user.uid,
                artifactId: widget.artifact.id,
                lastAccessedAt: DateTime.now(),
              );
          return _buildRefinedDashboard(p, bookmarks);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildRefinedDashboard(
    UserProgress progress,
    List<BookmarkItem> bookmarks,
  ) {
    // Determine Breadcrumbs and Hero Info
    String stageLabel = "Flow 1";
    String sectionLabel = "Theme 1";
    String partLabel = "Heritage Detail 1";
    ArtifactContentItem? activeItem;

    if (progress.lastAccessedItemId != null ||
        progress.completedContentIds.isNotEmpty) {
      String? targetId = progress.lastAccessedItemId;
      if (targetId == null && progress.completedContentIds.isNotEmpty) {
        targetId = progress.completedContentIds.last;
      }

      for (int i = 0; i < widget.artifact.sections.length; i++) {
        final section = widget.artifact.sections[i];
        for (int j = 0; j < section.parts.length; j++) {
          final part = section.parts[j];
          for (var detail in part.details) {
            for (var content in detail.contents) {
              if (content.id == targetId) {
                stageLabel = "Flow ${i + 1}";
                sectionLabel = "Theme ${i + 1}";
                partLabel = "Heritage Detail ${j + 1}";
                activeItem = content;
                break;
              }
            }
          }
        }
      }
    }

    if (activeItem == null && widget.artifact.sections.isNotEmpty) {
      stageLabel = "Flow 1";
      sectionLabel = "Theme 1";
      partLabel = "Heritage Detail 1";
      if (widget.artifact.sections.first.parts.isNotEmpty &&
          widget.artifact.sections.first.parts.first.details.isNotEmpty &&
          widget
              .artifact
              .sections
              .first
              .parts
              .first
              .details
              .first
              .contents
              .isNotEmpty) {
        activeItem = widget
            .artifact
            .sections
            .first
            .parts
            .first
            .details
            .first
            .contents
            .first;
      } else {
        stageLabel = "";
        sectionLabel = "";
        partLabel = "";
      }
    }

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: _bgColor,
              expandedHeight: 450,
              pinned: true,
              leading: Center(
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => context.pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    bookmarks.any(
                          (b) =>
                              b.id == widget.artifact.id &&
                              b.type == 'artifact',
                        )
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final isAdded = await ref
                        .read(bookmarksProvider.notifier)
                        .toggleBookmark(
                          BookmarkItem(
                            id: widget.artifact.id,
                            title: widget.artifact.title,
                            type: 'artifact',
                            extraData: artifactModelToJson(
                              ArtifactModel.fromDomain(widget.artifact),
                            ),
                            bookmarkedAt: DateTime.now(),
                          ),
                        );
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: TranslatedText(
                          isAdded
                              ? 'Exhibit added to collection'
                              : 'Exhibit removed from collection',
                        ),
                      ),
                    );
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              title: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TranslatedText(
                      widget.artifact.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TranslatedText(
                      "Journey perspective",
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Hero Image / Background
                    _buildHeroBackground(ref, activeItem),
                    // Play Button Overlay
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          if (activeItem != null) {
                            context.push(
                              '/artifact-player',
                              extra: {
                                'artifact': widget.artifact,
                                'initialContentId': activeItem.id,
                              },
                            );
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _accentColor.withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                    // Bottom Labels
                    Positioned(
                      bottom: 80,
                      left: 20,
                      right: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.radio_button_checked,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: TranslatedText(
                                          "Current Insight • ${activeItem?.type.toUpperCase() ?? 'VIDEO'}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: const TranslatedText(
                                  "JOURNEY MILESTONES",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (stageLabel.isNotEmpty) ...[
                            TranslatedText(
                              stageLabel,
                              style: TextStyle(
                                color: _accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white24,
                              size: 14,
                            ),
                            TranslatedText(
                              sectionLabel,
                              style: TextStyle(
                                color: _accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white24,
                              size: 14,
                            ),
                            TranslatedText(
                              partLabel,
                              style: TextStyle(
                                color: _accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TranslatedText(
                      activeItem?.title ?? widget.artifact.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TranslatedText(
                      widget.artifact.description,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildFunctionalStatsGrid(progress),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Sticky Tab Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                child: Container(
                  color: _bgColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: _buildPillTabs(),
                ),
                maxHeight: 66,
                minHeight: 66,
              ),
            ),
            // Dynamic content based on tab index
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: _buildActiveTabSliver(progress),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),

        // Navigation Footer Overlay
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: _buildBottomNav(context),
        ),
      ],
    );
  }

  Widget _buildFunctionalStatsGrid(UserProgress progress) {
    // Logic for next item
    ArtifactContentItem? nextItem;
    HeritageSection? nextSection;
    bool found = false;
    for (var section in widget.artifact.sections) {
      if (found) break;
      for (var part in section.parts) {
        if (found) break;
        for (var detail in part.details) {
          if (found) break;
          for (var content in detail.contents) {
            if (!progress.completedContentIds.contains(content.id)) {
              nextItem = content;
              nextSection = section;
              found = true;
              break;
            }
          }
        }
      }
    }

    int sectionScore = 0;
    final String targetSectionId =
        _selectedSectionId ??
        nextSection?.id ??
        (widget.artifact.sections.isNotEmpty
            ? widget.artifact.sections.first.id
            : "");

    if (progress.analysisScores.containsKey(targetSectionId)) {
      sectionScore = progress.analysisScores[targetSectionId]!.clamp(0, 100);
    }

    int stageAvg = 0;
    int analysisCount = 0;
    int totalScore = 0;
    for (var s in widget.artifact.sections) {
      if (progress.analysisScores.containsKey(s.id)) {
        analysisCount++;
        totalScore += progress.analysisScores[s.id]!.clamp(0, 100);
      }
    }
    if (analysisCount > 0) stageAvg = (totalScore / analysisCount).toInt();

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (nextItem != null && nextSection != null) {
                _openContent(nextItem, nextSection);
              }
            },
            child: _buildFunctionalStatCard(
              "Next Asset",
              nextItem?.title ?? "Completed",
              isAction: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFunctionalStatCard("Theme Discovery", "$sectionScore%"),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFunctionalStatCard("Journey Progress", "$stageAvg%"),
        ),
      ],
    );
  }

  Widget _buildFunctionalStatCard(
    String label,
    String value, {
    bool isAction = false,
  }) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TranslatedText(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: isAction ? 14 : 20,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTabs() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _accentColor,
          borderRadius: BorderRadius.circular(26),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(child: TranslatedText("Journey")),
          Tab(child: TranslatedText("Assets")),
          Tab(child: TranslatedText("Status")),
        ],
      ),
    );
  }

  Widget _buildActiveTabSliver(UserProgress progress) {
    return ValueListenableBuilder(
      valueListenable: _tabController.animation!,
      builder: (context, anim, child) {
        final index = _tabController.index;
        if (index == 0) return _buildCurriculumSliver(progress);
        if (index == 1) return _buildResourcesSliver();
        return _buildGradesSliver(progress);
      },
    );
  }

  void _openContent(ArtifactContentItem item, HeritageSection section) {
    final user = ref.read(userProvider);
    if (user != null) {
      final progressAsync = ref.read(
        viewerArtifactProgressProvider((user.uid, widget.artifact.id)),
      );
      progressAsync.whenData((progress) {
        final newProgress =
            progress?.copyWith(
              lastAccessedItemId: item.id,
              lastAccessedAt: DateTime.now(),
            ) ??
            UserProgress(
              userId: user.uid,
              artifactId: widget.artifact.id,
              lastAccessedItemId: item.id,
              lastAccessedAt: DateTime.now(),
            );
        ref
            .read(artifactControllerProvider.notifier)
            .saveUserProgress(newProgress);
      });
    }

    context.push(
      '/artifact-player',
      extra: {'artifact': widget.artifact, 'initialContentId': item.id},
    );
  }

  void _openAnalysis(HeritageSection section) {
    final analysis = section.analysis;
    if (analysis == null || analysis.evidence.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TranslatedText(
            'This section does not have any challenge questions yet.',
          ),
        ),
      );
      return;
    }

    context.push(
      '/analysis-taking',
      extra: {
        'analysis': analysis,
        'artifactId': widget.artifact.id,
        'sectionId': section.id,
        'classification': widget.artifact.classification,
      },
    );
  }

  Widget _buildCurriculumSliver(UserProgress progress) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final section = widget.artifact.sections[index];
        // Sequential locking logic
        bool isUnlocked = true;
        if (index > 0) {
          final prevSection = widget.artifact.sections[index - 1];
          bool prevComplete = true;
          for (var part in prevSection.parts) {
            for (var detail in part.details) {
              for (var content in detail.contents) {
                if (!progress.completedContentIds.contains(content.id)) {
                  prevComplete = false;
                  break;
                }
              }
            }
          }
          isUnlocked = prevComplete;
        }
        return _buildSectionModule(section, progress, isUnlocked);
      }, childCount: widget.artifact.sections.length),
    );
  }

  Widget _buildSectionModule(
    HeritageSection section,
    UserProgress progress,
    bool isUnlocked,
  ) {
    final progressVal = _calculateSectionProgress(section, progress);

    final bool isSelected = _selectedSectionId == section.id;

    return GestureDetector(
      onTap: () => setState(() => _selectedSectionId = section.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        decoration: BoxDecoration(
          color: isSelected
              ? _accentColor.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? _accentColor.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Opacity(
          opacity: isUnlocked ? 1.0 : 0.4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progressVal,
                          strokeWidth: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _accentColor,
                          ),
                        ),
                        Text(
                          "${(progressVal * 100).toInt()}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${section.parts.length} details • ${isUnlocked ? 'Accessible' : 'Locked'}",
                          style: TextStyle(
                            color: isUnlocked
                                ? Colors.white38
                                : _accentColor.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isUnlocked)
                    const Icon(
                      Icons.lock_outline,
                      color: Colors.white38,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (isUnlocked) ...[
                ...section.parts.asMap().entries.map((partEntry) {
                  return _buildPartCard(
                    partEntry.value,
                    section,
                    progress,
                    partEntry.key == 0 && progressVal < 1.0,
                  );
                }),
                if (section.analysis != null) ...[
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final score = progress.analysisScores[section.id];
                      final hasTaken = score != null;
                      final hasPassed = hasTaken && score >= 70;
                      final isFailed = hasTaken && score < 70;

                      return GestureDetector(
                        onTap: hasPassed ? null : () => _openAnalysis(section),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: hasPassed
                                ? Colors.green.withValues(alpha: 0.1)
                                : (isFailed
                                      ? Colors.orange.withValues(alpha: 0.1)
                                      : _accentColor.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: hasPassed
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : (isFailed
                                        ? Colors.orange.withValues(alpha: 0.3)
                                        : _accentColor.withValues(alpha: 0.3)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: hasPassed
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : (isFailed
                                            ? Colors.orange.withValues(alpha: 0.2)
                                            : _accentColor.withValues(alpha: 0.2)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.psychology,
                                  color: hasPassed
                                      ? Colors.green
                                      : (isFailed
                                            ? Colors.orange
                                            : Colors.white),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hasPassed
                                          ? "Challenge Completed"
                                          : (isFailed
                                                ? "Challenge Refuted"
                                                : "Start Challenge"),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      hasTaken
                                          ? "Mastery: ${score.clamp(0, 100)}%"
                                          : "Verify your findings on this journey",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!hasPassed)
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white70,
                                  size: 14,
                                )
                              else
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ] else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: const Center(
                    child: Text(
                      "Complete previous section to unlock",
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartCard(
    HeritagePart part,
    HeritageSection section,
    UserProgress progress,
    bool isCurrent,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            part.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...part.details.map((detail) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (detail.title.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      detail.title,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                ...detail.contents.map((content) {
                  final isCompleted = progress.completedContentIds.contains(
                    content.id,
                  );
                  final isPlaying = progress.lastAccessedItemId == content.id;

                  return GestureDetector(
                    onTap: () => _openContent(content, section),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPlaying
                              ? _accentColor.withValues(alpha: 0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            content.type == 'video'
                                ? Icons.play_circle_filled
                                : Icons.description,
                            color: isPlaying
                                ? _accentColor
                                : (isCompleted ? Colors.green : Colors.white38),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              content.title,
                              style: TextStyle(
                                color: isPlaying
                                    ? Colors.white
                                    : Colors.white70,
                                fontSize: 13,
                                fontWeight: isPlaying
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isCompleted)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            )
                          else if (isPlaying)
                            _buildStatusBadge(
                              "Playing",
                              _accentColor.withValues(alpha: 0.2),
                              textColor: _accentColor,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
    String text,
    Color bgColor, {
    Color textColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildResourcesSliver() {
    final Map<String, List<ArtifactContentItem>> assetsBySection = {};
    for (var section in widget.artifact.sections) {
      final List<ArtifactContentItem> sectionAssets = [];
      for (var part in section.parts) {
        for (var detail in part.details) {
          for (var content in detail.contents) {
            if (content.isResource) {
              sectionAssets.add(content);
            }
          }
        }
      }
      if (sectionAssets.isNotEmpty) {
        assetsBySection[section.title] = sectionAssets;
      }
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const TranslatedText(
            "Study Resources",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const TranslatedText(
            "Helpful materials collected for this exhibit, including readings, videos, guides, and reference files.",
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 24),
          if (assetsBySection.isEmpty)
            const Center(
              child: TranslatedText(
                "No extra study materials are available for this exhibit yet.",
                style: TextStyle(color: Colors.white24),
              ),
            )
          else
            ...assetsBySection.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: TranslatedText(
                      entry.key,
                      style: TextStyle(
                        color: _accentColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3,
                        ),
                    itemCount: entry.value.length,
                    itemBuilder: (context, index) {
                      final res = entry.value[index];
                      return _buildAssetCard(
                        res.title,
                        _resourceLabel(res),
                        _resourceDescription(res),
                        onTap: () {
                          HeritageSection? targetSection;
                          for (var s in widget.artifact.sections) {
                            if (s.title == entry.key) {
                              targetSection = s;
                              break;
                            }
                          }
                          if (targetSection != null) {
                            _openContent(res, targetSection);
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  String _resourceLabel(ArtifactContentItem item) {
    final category = item.resourceCategory?.trim();
    if (category != null && category.isNotEmpty) {
      return category;
    }

    switch (item.type) {
      case 'video':
        return 'Video Resource';
      case 'pdf':
        return 'Reading Material';
      case 'simulation':
        return 'Interactive Resource';
      case 'text':
        return 'Background Notes';
      default:
        return 'Study Resource';
    }
  }

  String _resourceDescription(ArtifactContentItem item) {
    final category = item.resourceCategory?.trim().toLowerCase();
    switch (category) {
      case 'research notes':
        return 'Key findings and supporting notes for deeper study.';
      case 'reading':
        return 'Additional reading to build background knowledge.';
      case 'video':
        return 'A related video that explains or illustrates this topic.';
      case 'guide':
        return 'A step-by-step guide to help you explore this material.';
      case 'template':
        return 'A reusable template or worksheet for your own work.';
    }

    switch (item.type) {
      case 'video':
        return 'Watch this supporting video for more context.';
      case 'pdf':
        return 'Open this document for detailed reference information.';
      case 'simulation':
        return 'Explore this interactive material to examine the exhibit closely.';
      case 'text':
        return 'Read these notes for historical background and context.';
      default:
        return 'Useful background material related to this exhibit.';
    }
  }

  Widget _buildAssetCard(
    String title,
    String type,
    String sub, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              sub,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradesSliver(UserProgress progress) {
    int totalAnalyses = widget.artifact.sections
        .where((s) => s.analysis != null)
        .length;
    bool hasAuthenticated = progress.hasPassedArtifact(totalAnalyses);

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const TranslatedText(
            "Verification Status",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          if (totalAnalyses > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: hasAuthenticated
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasAuthenticated
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  TranslatedText(
                    "Heritage Journey Mastery",
                    style: TextStyle(
                      color: hasAuthenticated ? Colors.green : Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TranslatedText(
                    hasAuthenticated ? "JOURNEY COMPLETED" : "EXPLORATION PENDING",
                    style: TextStyle(
                      color: hasAuthenticated ? Colors.green : Colors.orange,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const TranslatedText(
                    "Master the themes to unlock heritage insights",
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.4,
            ),
            itemCount: widget.artifact.sections.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                int analysisCount = 0;
                int totalScore = 0;
                for (var s in widget.artifact.sections) {
                  if (progress.analysisScores.containsKey(s.id)) {
                    analysisCount++;
                    totalScore += progress.analysisScores[s.id]!.clamp(0, 100);
                  }
                }
                final avg = analysisCount > 0
                    ? (totalScore / analysisCount).toInt()
                    : 0;
                return _buildStatusStat("Total Exploration", "$avg%");
              }
              final section = widget.artifact.sections[index - 1];
              final score = progress.analysisScores[section.id];
              return GestureDetector(
                onTap: () {
                  if (section.analysis != null) _openAnalysis(section);
                },
                child: _buildStatusStat(
                  section.title,
                  score != null
                      ? "${score.clamp(0, 100)}%"
                      : (section.analysis != null
                            ? "Pending Challenge"
                            : "No Evidence"),
                  isActive: section.analysis != null,
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatusStat(String label, String value, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? _accentColor.withValues(alpha: 0.1) : _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? _accentColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isActive ? Colors.white70 : Colors.white38,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isActive ? _accentColor : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildNavItem(
                  Icons.museum_outlined,
                  "Museum",
                  false,
                  onTap: () => context.go('/home'),
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  Icons.archive_outlined,
                  "Archives",
                  false,
                  onTap: () => context.push('/artifacts'),
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  Icons.view_in_ar,
                  "3D View",
                  false,
                  onTap: () => context.push('/artifact-3d'),
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  Icons.history_edu,
                  "Exhibit",
                  true,
                  onTap: () {},
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  Icons.person_outline,
                  "Profile",
                  false,
                  onTap: () => context.push('/profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool active, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? _accentColor : Colors.white38, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? _accentColor : Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateSectionProgress(
    HeritageSection section,
    UserProgress progress,
  ) {
    final sectionContentIds = <String>{};

    for (final part in section.parts) {
      for (final detail in part.details) {
        for (final content in detail.contents) {
          sectionContentIds.add(content.id);
        }
      }
    }

    if (sectionContentIds.isEmpty) return 0.0;

    final completedIds = progress.completedContentIds
        .where(sectionContentIds.contains)
        .toSet();

    final ratio = completedIds.length / sectionContentIds.length;
    return ratio.clamp(0.0, 1.0);
  }

  Widget _buildHeroBackground(WidgetRef ref, ArtifactContentItem? activeItem) {
    final localThumbnail = ref.watch(
      artifactThumbnailProvider(widget.artifact.id),
    );

    return localThumbnail.when(
      data: (bytes) {
        if (bytes != null) {
          return _buildHeroImage(bytes: bytes);
        }

        final remoteThumbnail = widget.artifact.thumbnailUrl;
        if (remoteThumbnail != null &&
            remoteThumbnail.isNotEmpty &&
            remoteThumbnail.startsWith('http')) {
          return _buildHeroImage(imageUrl: remoteThumbnail);
        }

        final videoThumbnail = _getVideoThumbnail(activeItem);
        if (videoThumbnail != null) {
          return _buildHeroImage(imageUrl: videoThumbnail);
        }

        return _buildCulturalFallbackBackground();
      },
      loading: () {
        final videoThumbnail = _getVideoThumbnail(activeItem);
        if (videoThumbnail != null) {
          return _buildHeroImage(imageUrl: videoThumbnail);
        }
        return _buildCulturalFallbackBackground();
      },
      error: (_, stackTrace) {
        final videoThumbnail = _getVideoThumbnail(activeItem);
        if (videoThumbnail != null) {
          return _buildHeroImage(imageUrl: videoThumbnail);
        }
        return _buildCulturalFallbackBackground();
      },
    );
  }

  Widget _buildHeroImage({Uint8List? bytes, String? imageUrl}) {
    final ImageProvider? image = bytes != null
        ? MemoryImage(bytes)
        : (imageUrl != null && imageUrl.isNotEmpty
              ? NetworkImage(imageUrl)
              : null);
    if (image == null) {
      return _buildCulturalFallbackBackground();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image(
          image: image,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildCulturalFallbackBackground(),
        ),
        Container(color: Colors.black.withValues(alpha: 0.6)),
      ],
    );
  }

  Widget _buildCulturalFallbackBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF24170E),
            AppTheme.kTerracotta.withValues(alpha: 0.88),
            AppTheme.kAncientBlue.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -28,
            right: -10,
            child: Icon(
              Icons.account_balance_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Positioned(
            bottom: -16,
            left: -8,
            child: Icon(
              Icons.travel_explore_rounded,
              size: 132,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Positioned(
            bottom: 26,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    child: const Icon(
                      Icons.museum_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Cultural Heritage',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Traditional places, stories, craft, and identity',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _getVideoThumbnail(ArtifactContentItem? item) {
    if (item?.type == 'video' && item?.url != null) {
      final url = item!.url!;
      try {
        if (url.contains('youtube.com/watch?v=')) {
          final id = url.split('v=')[1].split('&')[0];
          return "https://img.youtube.com/vi/$id/0.jpg";
        }
        if (url.contains('youtu.be/')) {
          final id = url.split('be/')[1].split('?')[0];
          return "https://img.youtube.com/vi/$id/0.jpg";
        }
      } catch (e) {
        // Fallback for safety
      }
    }
    return null;
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });
  final Widget child;
  final double minHeight;
  final double maxHeight;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
