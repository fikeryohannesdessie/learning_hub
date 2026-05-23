import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/artifact_domain.dart';
import '../../content/domain/content_domain.dart';
import '../../../core/localization/localization.dart';
import '../provider/artifact_repository.dart';
import '../../auth/providers/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../content/viewer/pdf_viewer_screen.dart';
import '../../content/viewer/video_viewer_screen.dart';
import 'simulation_viewer_screen.dart';

enum ContentWrapperType { material, analysis }

class FlattenedContent {
  final HeritageSection section;
  final String sectionTitle;
  final String sectionId;
  final String partTitle;
  final String detailTitle;
  final ArtifactContentItem? item;
  final ContentWrapperType type;

  FlattenedContent({
    required this.sectionTitle,
    required this.sectionId,
    required this.section,
    this.partTitle = '',
    this.detailTitle = '',
    this.item,
    required this.type,
  });

  // Legacy Aliases
  String get SectionId => sectionId;
  String get SectionTitle => sectionTitle;
}

class ArtifactPlayerScreen extends ConsumerStatefulWidget {
  final Artifact artifact;
  final String? initialContentId;

  const ArtifactPlayerScreen({
    super.key,
    required this.artifact,
    this.initialContentId,
  });

  @override
  ConsumerState<ArtifactPlayerScreen> createState() =>
      _ArtifactPlayerScreenState();
}

class _ArtifactPlayerScreenState extends ConsumerState<ArtifactPlayerScreen> {
  late List<FlattenedContent> _flatContent;
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _kDarkBg = Color(0xFF0A0A0A);
  static const _kCard = Color(0xFF161616);
  static const _kCardBorder = Color(0xFF282828);

  @override
  void initState() {
    super.initState();
    _flattenContent();
    _setInitialIndex();
  }

  void _flattenContent() {
    _flatContent = [];
    for (var section in widget.artifact.sections) {
      for (var part in section.parts) {
        for (var detail in part.details) {
          for (var item in detail.contents) {
            _flatContent.add(
              FlattenedContent(
                section: section,
                sectionTitle: section.title,
                sectionId: section.id,
                partTitle: part.title,
                detailTitle: detail.title,
                item: item,
                type: ContentWrapperType.material,
              ),
            );
          }
        }
      }
      if (section.analysis != null) {
        _flatContent.add(
          FlattenedContent(
            section: section,
            sectionTitle: section.title,
            sectionId: section.id,
            type: ContentWrapperType.analysis,
          ),
        );
      }
    }
  }

  void _setInitialIndex() {
    if (widget.initialContentId != null) {
      final index = _flatContent.indexWhere(
        (c) => c.item?.id == widget.initialContentId,
      );
      if (index != -1) {
        _currentIndex = index;
        return;
      }
    }
    _currentIndex = 0;
  }

  bool _isItemCompleted(FlattenedContent content, UserProgress progress) {
    if (content.type == ContentWrapperType.material) {
      return progress.completedContentIds.contains(content.item!.id);
    } else {
      final score = progress.analysisScores[content.sectionId];
      return score != null && score >= 70;
    }
  }

  void _markAsCompleted(String contentId) {
    final user = ref.read(userProvider);
    if (user != null) {
      final progressAsync = ref.read(
        viewerArtifactProgressProvider((user.uid, widget.artifact.id)),
      );
      progressAsync.whenData((progress) {
        if (progress != null) {
          if (!progress.completedContentIds.contains(contentId)) {
            final newProgress = progress.copyWith(
              completedContentIds: [...progress.completedContentIds, contentId],
              lastAccessedItemId: contentId,
              lastAccessedAt: DateTime.now(),
            );
            ref
                .read(artifactControllerProvider.notifier)
                .saveUserProgress(newProgress);
          }
        } else {
          final newProgress = UserProgress(
            userId: user.uid,
            artifactId: widget.artifact.id,
            completedContentIds: [contentId],
            lastAccessedItemId: contentId,
            lastAccessedAt: DateTime.now(),
          );
          ref
              .read(artifactControllerProvider.notifier)
              .saveUserProgress(newProgress);
        }
      });
    }
  }

  void _onNext(UserProgress progress) {
    final current = _flatContent[_currentIndex];

    // Check completion before allowing next
    if (!_isItemCompleted(current, progress)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Center(
            heightFactor: 1.0,
            child: TranslatedText(
              'Please complete the current investigation or challenge before proceeding.',
              textAlign: TextAlign.center,
            ),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_currentIndex < _flatContent.length - 1) {
      setState(() => _currentIndex++);
      _saveLastAccessed();
    } else {
      _showCompletionDialog();
    }
  }

  void _onPrevious() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _saveLastAccessed();
    }
  }

  void _saveLastAccessed() {
    final user = ref.read(userProvider);
    if (user != null && _flatContent.isNotEmpty) {
      final currentItem = _flatContent[_currentIndex];
      if (currentItem.item != null) {
        final progressAsync = ref.read(
          viewerArtifactProgressProvider((user.uid, widget.artifact.id)),
        );
        progressAsync.whenData((progress) {
          final newProgress =
              progress?.copyWith(
                lastAccessedItemId: currentItem.item!.id,
                lastAccessedAt: DateTime.now(),
              ) ??
              UserProgress(
                userId: user.uid,
                artifactId: widget.artifact.id,
                lastAccessedItemId: currentItem.item!.id,
                lastAccessedAt: DateTime.now(),
              );
          ref
              .read(artifactControllerProvider.notifier)
              .saveUserProgress(newProgress);
        });
      }
    }
  }

  void _showCompletionDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Completion',
      pageBuilder: (context, anim1, anim2) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Material(
            color: Colors.transparent,
            child: GlassCard(
              borderRadius: 32,
              frosted: true,
              blur: 20,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.kAccent.withOpacity(0.15),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.kAccent.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const TranslatedText(
                    'Exhibit Exploration Complete!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const TranslatedText(
                    'Remarkable journey! You have explored the entire heritage exhibit. You can now revisit any theme or attempt more challenges to deepen your understanding.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      context.pop(); // Go back to dashboard
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const TranslatedText(
                      'Finish & Return',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const TranslatedText(
                    "Viewer perspective",
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_flatContent.isEmpty) {
      return Scaffold(
        backgroundColor: _kDarkBg,
        appBar: AppBar(
          backgroundColor: _kDarkBg,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: TranslatedText(
            'No content available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final user = ref.watch(userProvider);
    final progressAsync = ref.watch(
      viewerArtifactProgressProvider((user?.uid ?? '', widget.artifact.id)),
    );
    final progress =
        progressAsync.asData?.value ??
        UserProgress(
          userId: user?.uid ?? '',
          artifactId: widget.artifact.id,
          lastAccessedAt: DateTime.now(),
        );

    final currentItem = _flatContent[_currentIndex];

    // Check if locked
    bool isLocked = false;
    if (_currentIndex > 0) {
      int sectionIndex = widget.artifact.sections.indexWhere(
        (s) => s.id == currentItem.sectionId,
      );
      if (sectionIndex > 0) {
        final previousSection = widget.artifact.sections[sectionIndex - 1];
        for (var part in previousSection.parts) {
          for (var detail in part.details) {
            for (var c in detail.contents) {
              if (!progress.completedContentIds.contains(c.id)) {
                isLocked = true;
                break;
              }
            }
          }
        }
        if (previousSection.analysis != null &&
            !progress.analysisScores.containsKey(previousSection.id)) {
          isLocked = true;
        }
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kDarkBg,
      drawer: _buildCurriculumDrawer(progress),
      extendBody: false,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, currentItem),
            Expanded(
              child: isLocked
                  ? _buildLockedScreen()
                  : _buildContentTab(currentItem, progress),
            ),
            _buildPlayerControls(progress, isLocked),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 64, color: Colors.white38),
          const SizedBox(height: 24),
          const TranslatedText(
            "Content Restricted",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const TranslatedText(
            "Complete the previous theme and its heritage challenge to unlock this area.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentIndex = 0;
              });
            },
            child: const TranslatedText("Go Back"),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, FlattenedContent current) {
    return Container(
      color: _kCard,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TranslatedText(
                  widget.artifact.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                TranslatedText(
                  current.type == ContentWrapperType.analysis
                      ? '${current.sectionTitle} • Challenge'
                      : '${current.sectionTitle} • ${current.item?.title ?? ""}',
                  style: const TextStyle(color: AppTheme.kAccent, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPlayerControls(UserProgress progress, bool isLocked) {
    final hasNext = _currentIndex < _flatContent.length - 1;
    final hasPrev = _currentIndex > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: _kCard,
        border: Border(top: BorderSide(color: _kCardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: hasPrev ? _onPrevious : null,
            icon: Icon(
              Icons.arrow_back_ios,
              size: 14,
              color: hasPrev ? Colors.white : Colors.white24,
            ),
            label: TranslatedText(
              "Previous",
              style: TextStyle(
                color: hasPrev ? Colors.white : Colors.white24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: (isLocked) ? null : () => _onNext(progress),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.kAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TranslatedText(
                  hasNext ? "Next" : "Finish",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Icon(
                  hasNext
                      ? Icons.arrow_forward_ios
                      : Icons.check_circle_outline,
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTab(
    FlattenedContent current,
    UserProgress progress,
  ) {
    if (current.type == ContentWrapperType.analysis) {
      final hasTaken = progress.analysisScores.containsKey(current.sectionId);
      final score = progress.analysisScores[current.sectionId] ?? 0;
      final hasPassed = hasTaken && score >= 70;
      final isFailed = hasTaken && score < 70;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology,
              size: 80,
              color: hasPassed
                  ? Colors.green
                  : (isFailed ? Colors.orange : AppTheme.kAccent),
            ),
            const SizedBox(height: 24),
            TranslatedText(
              hasPassed
                  ? "Challenge Completed"
                  : (isFailed ? "Challenge Pending" : "Heritage Challenge"),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (hasTaken) ...[
              TranslatedText(
                "Your Score: ${score.clamp(0, 100)}%",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              if (isFailed)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: TranslatedText(
                    "You need 70% mastery to progress. Review the heritage details and try again.",
                    style: TextStyle(color: Colors.orange, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
            ] else
              const TranslatedText(
              "Verify your understanding before moving on. 70% mastery is recommended.",
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!hasPassed)
              ElevatedButton(
                onPressed: () {
                  final analysis = current.section.analysis;
                  if (analysis == null || analysis.evidence.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: TranslatedText(
                          'This theme has no challenge questions yet.',
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
                      'sectionId': current.sectionId,
                      'classification': widget.artifact.classification,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: TranslatedText(
                  isFailed ? "Retry Challenge" : "Start Challenge",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
          ],
        ),
      );
    }

    final isCompleted = progress.completedContentIds.contains(current.item!.id);

    return Column(
      children: [
        Expanded(
          child: () {
            switch (current.item!.type) {
              case 'pdf':
                return PDFViewerScreen(
                  content: LearningContent(
                    id: current.item!.fileId ?? current.item!.id,
                    title: current.item!.title,
                    type: 'pdf',
                    url: current.item!.url,
                    authorId: 'system',
                    authorName: 'System',
                    gradeLevel: 'N/A',
                    subject: 'N/A',
                    uploadedAt: DateTime.now(),
                  ),
                );
              case 'video':
                return VideoViewerScreen(
                  url: current.item!.url ?? "",
                  title: current.item!.title,
                  fileId: current.item!.fileId,
                  classification: widget.artifact.classification,
                );
              case 'text':
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TranslatedText(
                        "Current Insight • ${current.item!.type.toUpperCase()}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.kAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TranslatedText(
                        current.item!.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.kAccent.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 32),
                      TranslatedText(
                        current.item!.text ?? "",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          height: 1.8,
                        ),
                      ),
                    ],
                  ),
                );
              case 'simulation':
                return SimulationViewerScreen(item: current.item!);
              default:
                return const SizedBox();
            }
          }(),
        ),
        // Mark as Done action bar
        Container(
          padding: const EdgeInsets.all(16),
          color: _kCard,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: isCompleted
                    ? null
                    : () => _markAsCompleted(current.item!.id),
                icon: Icon(
                  isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                ),
                label: TranslatedText(
                  isCompleted ? "Completed" : "Mark as Done",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted
                      ? Colors.green.withOpacity(0.2)
                      : AppTheme.kAccent,
                  foregroundColor: isCompleted ? Colors.green : Colors.white,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurriculumDrawer(UserProgress progress) {
    return Drawer(
      backgroundColor: _kDarkBg,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const TranslatedText(
                    "Heritage Pathway",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: _kCardBorder),
            Expanded(
              child: ListView.builder(
                itemCount: _flatContent.length,
                itemBuilder: (context, index) {
                  final item = _flatContent[index];
                  final isCurrent = index == _currentIndex;
                  final isCompleted = _isItemCompleted(item, progress);

                  return ListTile(
                    tileColor: isCurrent
                        ? AppTheme.kAccent.withOpacity(0.1)
                        : null,
                    leading: Icon(
                      item.type == ContentWrapperType.analysis
                          ? Icons.psychology
                          : Icons.play_circle_outline,
                      color: isCurrent
                          ? AppTheme.kAccent
                          : (isCompleted ? Colors.green : Colors.white38),
                    ),
                    title: TranslatedText(
                      item.type == ContentWrapperType.analysis
                          ? "${item.sectionTitle} Challenge"
                          : item.item!.title,
                      style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.white70,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: TranslatedText(
                      item.sectionTitle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                    trailing: isCompleted
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context); // Close Drawer
                      setState(() {
                        _currentIndex = index;
                      });
                      _saveLastAccessed();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
