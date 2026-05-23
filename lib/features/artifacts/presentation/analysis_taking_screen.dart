import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/artifact_domain.dart';
import '../provider/artifact_controller.dart';
import '../../auth/providers/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../bookmark/provider/bookmark_provider.dart';
import '../../../core/localization/localization.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/shared_app_bar.dart';
import '../../../core/models/artifact_model.dart' show AnalysisModel;
import '../infrastructure/artifact_model_mapper.dart';

class AnalysisTakingScreen extends ConsumerStatefulWidget {
  final Analysis analysis;
  final String? artifactId;
  final String? sectionId;
  final String? classification;

  const AnalysisTakingScreen({
    super.key,
    required this.analysis,
    this.artifactId,
    this.sectionId,
    this.classification,
  });

  @override
  ConsumerState<AnalysisTakingScreen> createState() =>
      _AnalysisTakingScreenState();
}

class _AnalysisTakingScreenState extends ConsumerState<AnalysisTakingScreen> {
  int _currentEvidenceIndex = 0;
  final Map<int, dynamic> _answers = {};
  final _shortAnswerController = TextEditingController();
  bool _isSubmitted = false;
  double _finalScore = 0.0;
  int _correctCount = 0;

  @override
  void dispose() {
    _shortAnswerController.dispose();
    super.dispose();
  }

  void _onEvidenceChange(int newIndex) {
    setState(() {
      _currentEvidenceIndex = newIndex;
      final e = widget.analysis.evidence[_currentEvidenceIndex];
      if (e.isShortAnswer) {
        _shortAnswerController.text =
            (_answers[_currentEvidenceIndex] as String?) ?? '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final evidenceList = widget.analysis.evidence;

    if (evidenceList.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.kBg,
        appBar: SharedAppBar(title: 'Heritage Challenge', showProfile: false),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              borderRadius: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.quiz_outlined,
                    size: 56,
                    color: Colors.white38,
                  ),
                  const SizedBox(height: 16),
                  const TranslatedText(
                    'No heritage challenges are available yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const TranslatedText(
                    'This section does not have any questions to answer right now.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const TranslatedText('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final currentEvidence = evidenceList[_currentEvidenceIndex];

    return Scaffold(
      backgroundColor: AppTheme.kBg,
      appBar: SharedAppBar(
        title: _isSubmitted ? 'Assessment Result' : 'Heritage Challenge',
        showProfile: false,
        bottom: null,
        extraActions: _isSubmitted
            ? []
            : [
                Consumer(
                  builder: (context, ref, _) {
                    final bookmarkId = widget.artifactId != null
                        ? '${widget.artifactId}_${widget.sectionId}_${widget.analysis.id}'
                        : 'standalone_${widget.analysis.id}';
                    final bookmarks = ref.watch(bookmarksProvider);
                    final isBookmarked = bookmarks.any(
                      (b) => b.id == bookmarkId,
                    );
                    return IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      ),
                      color: isBookmarked ? AppTheme.kAccent : null,
                      onPressed: () async {
                        final isAdded = await ref
                            .read(bookmarksProvider.notifier)
                            .toggleBookmark(
                              BookmarkItem(
                                id: bookmarkId,
                                title: 'Challenge: Heritage Verification',
                                type: 'analysis',
                                extraData: {
                                  'analysis': analysisModelToJson(
                                    AnalysisModel.fromDomain(widget.analysis),
                                  ),
                                  'artifactId': widget.artifactId,
                                  'sectionId': widget.sectionId,
                                  if (widget.classification != null)
                                    'classification': widget.classification,
                                },
                                bookmarkedAt: DateTime.now(),
                              ),
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: TranslatedText(
                                isAdded
                                    ? 'Analysis added to bookmarks'
                                    : 'Analysis removed from bookmarks',
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
      ),
      body: _isSubmitted
          ? _buildResultView(evidenceList)
          : Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentEvidenceIndex + 1) / evidenceList.length,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.kAccent,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TranslatedText(
                          'Question ${_currentEvidenceIndex + 1} of ${evidenceList.length}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TranslatedText(
                          currentEvidence.questionText,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),

                        if (currentEvidence.isShortAnswer) ...[
                          const TranslatedText(
                            'Your Answer',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white24,
                              fontSize: 10,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _shortAnswerController,
                            onChanged: (val) {
                              setState(
                                () => _answers[_currentEvidenceIndex] = val,
                              );
                            },
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Type your answer here...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.03),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppTheme.kAccent,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(20),
                            ),
                          ),
                        ] else ...[
                          ...currentEvidence.options.asMap().entries.map((
                            entry,
                          ) {
                            final idx = entry.key;
                            final option = entry.value;
                            final isSelected =
                                _answers[_currentEvidenceIndex] == idx;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: _isSubmitted
                                    ? null
                                    : () {
                                        setState(
                                          () =>
                                              _answers[_currentEvidenceIndex] =
                                                  idx,
                                        );
                                      },
                                borderRadius: BorderRadius.circular(12),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(16),
                                  borderRadius: 12,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.kAccent
                                                : Colors.white38,
                                          ),
                                          color: isSelected
                                              ? AppTheme.kAccent
                                              : Colors.transparent,
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TranslatedText(
                                          option,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
                _buildFooter(evidenceList),
              ],
            ),
    );
  }

  Widget _buildFooter(List<Evidence> evidenceList) {
    final isLastPiece = _currentEvidenceIndex == evidenceList.length - 1;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.kSurface,
        border: Border(top: BorderSide(color: AppTheme.kGlassBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentEvidenceIndex > 0)
            TextButton(
              onPressed: () => _onEvidenceChange(_currentEvidenceIndex - 1),
              child: const TranslatedText('Back'),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton(
            onPressed:
                (_answers[_currentEvidenceIndex] != null &&
                    _answers[_currentEvidenceIndex].toString().isNotEmpty)
                ? (isLastPiece
                      ? _submitAnalysis
                      : () => _onEvidenceChange(_currentEvidenceIndex + 1))
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: TranslatedText(
              isLastPiece ? 'Submit Challenge' : 'Next Piece',
            ),
          ),
        ],
      ),
    );
  }

  void _submitAnalysis() async {
    final evidenceList = widget.analysis.evidence;
    int verifiedCount = 0;
    _answers.forEach((eIdx, answer) {
      final e = evidenceList[eIdx];
      if (e.isShortAnswer) {
        final viewerAnswer = (answer as String).trim().toLowerCase();
        final correctAns = (e.correctShortAnswer ?? '').trim().toLowerCase();
        if (viewerAnswer == correctAns) {
          verifiedCount++;
        }
      } else {
        if (e.correctAnswerIndex == (answer as int)) {
          verifiedCount++;
        }
      }
    });

    if (evidenceList.isEmpty) return;

    final score = (verifiedCount / evidenceList.length) * 100;
    final user = ref.read(userProvider);

    if (user != null) {
      final result = AnalysisResult(
        userId: user.uid,
        userName: user.displayName ?? 'Explorer',
        artifactId: widget.artifactId ?? 'standalone',
        sectionId: widget.sectionId ?? 'standalone',
        score: (score).toInt(),
        totalQuestions: evidenceList.length,
        completedAt: DateTime.now(),
      );

      // Only submit if it's tied to a real artifact/section
      if (widget.artifactId != null && widget.sectionId != null) {
        await ref
            .read(artifactControllerProvider.notifier)
            .submitAnalysisResult(result);
      }

      if (mounted) {
        setState(() {
          _isSubmitted = true;
          _finalScore = score;
          _correctCount = verifiedCount;
        });
      }
    }
  }

  Widget _buildResultView(List<Evidence> evidenceList) {
    final bool isPassed = _finalScore >= 70;
    final String performanceText = _finalScore >= 90
        ? 'Heritage Master'
        : _finalScore >= 75
        ? 'Heritage Explorer'
        : _finalScore >= 60
        ? 'Heritage Apprentice'
        : 'Keep Learning';

    final Color resultColor = AppTheme.kAccent;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1500),
            curve: Curves.elasticOut,
            tween: Tween(begin: 0, end: _finalScore),
            builder: (context, value, child) {
              return Column(
                children: [
                  if (isPassed) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.kAccent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: resultColor.withValues(alpha: 0.1),
                          blurRadius: 40,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: CircularProgressIndicator(
                            value: value / 100,
                            strokeWidth: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.04),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              resultColor,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${value.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: resultColor,
                                letterSpacing: -2,
                              ),
                            ),
                            const TranslatedText(
                              'CHALLENGE',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          TranslatedText(
            performanceText,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TranslatedText(
              isPassed
                  ? 'Great job! You have successfully completed this heritage challenge.'
                  : 'Keep going! Review the heritage details and try the challenge again.',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 48),

          // Details Card
          GlassCard(
            padding: const EdgeInsets.all(24),
            borderRadius: 32,
            child: Column(
              children: [
                _buildResultStatItem(
                  Icons.verified,
                  'Correct Answers',
                  '$_correctCount / ${evidenceList.length}',
                  Colors.greenAccent,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    color: Colors.white.withValues(alpha: 0.05),
                    height: 1,
                  ),
                ),
                _buildResultStatItem(
                  Icons.unpublished_outlined,
                  'Incorrect Answers',
                  '${evidenceList.length - _correctCount}',
                  const Color(0xFFFF4D4D),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isSubmitted = false;
                      _currentEvidenceIndex = 0;
                      _answers.clear();
                      _finalScore = 0.0;
                      _correctCount = 0;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const TranslatedText(
                    'Retry Challenge',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: isPassed ? Colors.white : AppTheme.kAccent,
                    foregroundColor: isPassed ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const TranslatedText(
                    'Complete Challenge',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TranslatedText(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
