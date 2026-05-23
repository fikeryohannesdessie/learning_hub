import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/localization.dart';
import '../../../core/localization/translated_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/shared_app_bar.dart';
import '../../../core/utils/audio_utils.dart';
import '../../artifacts/domain/artifact_domain.dart';
import '../../content/application/content_application.dart';
import '../../content/domain/content_domain.dart';

class ContentCollectionScreen extends ConsumerWidget {
  final String title;
  final String classification;
  final String? type;

  const ContentCollectionScreen({
    super.key,
    required this.title,
    required this.classification,
    this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(
      approvedContentProvider((gradeLevel: classification, type: type)),
    );

    return Scaffold(
      backgroundColor: AppTheme.kBg,
      appBar: SharedAppBar(title: title),
      body: contentAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return _EmptyCollectionState(title: title);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount = 1;
              double childAspectRatio = 1.25;

              if (width >= 1200) {
                crossAxisCount = 4;
                childAspectRatio = 0.92;
              } else if (width >= 900) {
                crossAxisCount = 3;
                childAspectRatio = 0.98;
              } else if (width >= 640) {
                crossAxisCount = 2;
                childAspectRatio = 1.05;
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _CollectionHero(
                        title: title,
                        count: items.length,
                        classification: classification,
                        type: type,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _ContentGridItem(item: items[index]),
                        childCount: items.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: TranslatedText(
              'Error: $err',
              style: const TextStyle(color: AppTheme.kParchment),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectionHero extends StatelessWidget {
  final String title;
  final int count;
  final String classification;
  final String? type;

  const _CollectionHero({
    required this.title,
    required this.count,
    required this.classification,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _accentForType(type);
    final icon = _iconForType(type);

    return GlassCard(
      borderRadius: 22,
      color: const Color(0xFF17120D),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            Positioned(
              top: -18,
              right: -10,
              child: Icon(
                icon,
                size: 96,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            Positioned(
              bottom: -12,
              left: -8,
              child: Icon(
                Icons.auto_stories_rounded,
                size: 88,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: accent.withOpacity(0.28)),
                    ),
                    child: Text(
                      '$count ITEMS',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TranslatedText(
                    title,
                    style: const TextStyle(
                      color: AppTheme.kParchment,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TranslatedText(
                    '${classification.toUpperCase()} viewer collection',
                    style: TextStyle(
                      color: AppTheme.kParchment.withOpacity(0.72),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentGridItem extends ConsumerWidget {
  final LearningContent item;

  const _ContentGridItem({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPdfLike =
        item.type == AppConstants.contentTypePDF ||
        item.type == AppConstants.contentTypeWorksheet;
    final isAnalysis = item.type == AppConstants.contentTypeAnalysis;
    final accent = _accentForType(item.type);
    final icon = _iconForType(item.type);
    final tag = _labelForType(item.type);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openItem(context, ref, item),
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
                      const Color(0xFF2A2016),
                      accent.withOpacity(0.84),
                      AppTheme.kAncientBlue.withOpacity(
                        isAnalysis ? 0.82 : 0.64,
                      ),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: -16,
                      right: -6,
                      child: Icon(
                        icon,
                        size: 82,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    Positioned(
                      bottom: -12,
                      left: -6,
                      child: Icon(
                        isPdfLike
                            ? Icons.menu_book_rounded
                            : Icons.history_edu_rounded,
                        size: 74,
                        color: Colors.white.withOpacity(0.06),
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
                              color: Colors.black.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: Text(
                              tag.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(icon, size: 34, color: Colors.white70),
                          const SizedBox(height: 10),
                          Text(
                            isAnalysis
                                ? 'Expert heritage review'
                                : 'Cultural knowledge resource',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.88),
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
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.kParchment,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 14,
                        color: AppTheme.kParchment.withOpacity(0.55),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TranslatedText(
                          item.subject ?? 'General',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.kParchment.withOpacity(0.62),
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
                        color: AppTheme.kParchment.withOpacity(0.55),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TranslatedText(
                          item.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.kParchment.withOpacity(0.62),
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
    );
  }

  void _openItem(BuildContext context, WidgetRef ref, LearningContent item) {
    final isPdfLike =
        item.type == AppConstants.contentTypePDF ||
        item.type == AppConstants.contentTypeWorksheet;

    if (isPdfLike) {
      context.push('/pdf-viewer', extra: item);
      return;
    }

    if (item.type == AppConstants.contentTypeAnalysis) {
      final evidencesData =
          (item.extraData?['evidence'] as List?) ??
          (item.extraData?['evidences'] as List?) ??
          (item.extraData?['questions'] as List?) ??
          [];

      final evidences = evidencesData.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return Evidence(
          questionText:
              (map['factText'] ?? map['questionText'] ?? map['question'] ?? '')
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
    } else if (item.type == AppConstants.contentTypeAudio) {
      showAudioPreview(context, ref, item);
    } else if (item.type == AppConstants.contentTypeVideo) {
      context.push('/video-viewer', extra: {
        'url': item.url ?? '',
        'title': item.title,
        'fileId': item.id,
        'classification': item.gradeLevel,
      });
    }
  }
}

class _EmptyCollectionState extends StatelessWidget {
  final String title;

  const _EmptyCollectionState({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
                border: Border.all(color: AppTheme.kGlassBorder),
              ),
              child: const Icon(
                Icons.collections_bookmark_outlined,
                size: 34,
                color: AppTheme.kAccent,
              ),
            ),
            const SizedBox(height: 18),
            TranslatedText(
              'No $title available yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.kParchment,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Approved viewer resources for this collection will appear here once they are available.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.kParchment.withOpacity(0.6),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _accentForType(String? type) {
  switch (type) {
    case AppConstants.contentTypeAnalysis:
      return AppTheme.kAncientBlue;
    case AppConstants.contentTypeWorksheet:
      return AppTheme.kTerracotta;
    case AppConstants.contentTypeAudio:
      return Colors.purpleAccent;
    case AppConstants.contentTypeVideo:
      return AppTheme.kAncientBlue;
    case AppConstants.contentTypePDF:
    default:
      return AppTheme.kAccent;
  }
}

IconData _iconForType(String? type) {
  switch (type) {
    case AppConstants.contentTypeAnalysis:
      return Icons.psychology_rounded;
    case AppConstants.contentTypeWorksheet:
      return Icons.assignment_rounded;
    case AppConstants.contentTypeAudio:
      return Icons.audiotrack_rounded;
    case AppConstants.contentTypeVideo:
      return Icons.videocam_rounded;
    case AppConstants.contentTypePDF:
    default:
      return Icons.auto_stories_rounded;
  }
}

String _labelForType(String? type) {
  switch (type) {
    case AppConstants.contentTypeAnalysis:
      return 'Analysis';
    case AppConstants.contentTypeWorksheet:
      return 'Report';
    case AppConstants.contentTypeAudio:
      return 'Audio';
    case AppConstants.contentTypeVideo:
      return 'Video';
    case AppConstants.contentTypePDF:
    default:
      return 'Document';
  }
}
