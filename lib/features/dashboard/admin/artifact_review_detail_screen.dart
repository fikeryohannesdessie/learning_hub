import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../artifacts/domain/artifact_domain.dart';
import '../../artifacts/provider/artifact_repository.dart';
import '../../auth/providers/auth_controller.dart';
import '../../../core/constants/app_constants.dart';
import '../../content/domain/content_domain.dart';
import '../../../core/localization/localization.dart';
import '../../../core/localization/translated_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/shared_app_bar.dart';

class ArtifactReviewDetailScreen extends ConsumerWidget {
  final Artifact artifact;

  const ArtifactReviewDetailScreen({super.key, required this.artifact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.kBg,
      appBar: SharedAppBar(title: 'Review Artifact', showProfile: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ThumbnailPreview(
                artifactId: artifact.id,
                thumbnailUrl: artifact.thumbnailUrl,
              ),
              const SizedBox(height: 16),
              TranslatedText(
                artifact.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    child: TranslatedText(
                      'By ${artifact.authorName}',
                      style: const TextStyle(color: AppTheme.kParchment),
                    ),
                  ),
                  _AuthorVerificationBadge(uid: artifact.authorId),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Narrative:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.kAccent,
                ),
              ),
              TranslatedText(
                artifact.description,
                style: const TextStyle(color: AppTheme.kParchment),
              ),
              const SizedBox(height: 32),
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
                  const Expanded(
                    child: TranslatedText(
                      'Heritage Sections',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.kParchment,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppTheme.kGlassBorder),
              ...artifact.sections.map(
                (section) => _SectionReviewTile(
                  section: section,
                  artifactId: artifact.id,
                  artifactTitle: artifact.title,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: AppTheme.kSurface,
          border: Border(top: BorderSide(color: AppTheme.kGlassBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showRejectDialog(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const TranslatedText('Reject'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(artifactControllerProvider.notifier)
                      .updateArtifactStatus(artifact.id, 'approved');
                  if (context.mounted) {
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: TranslatedText('Artifact Approved!'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF82),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const TranslatedText('Approve'),
              ),
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
        title: const TranslatedText('Reject Artifact'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            label: TranslatedText('Reason'),
            hintText: 'Why is this artifact being rejected?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const TranslatedText('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;
              await ref
                  .read(artifactControllerProvider.notifier)
                  .updateArtifactStatus(
                    artifact.id,
                    'rejected',
                    reason: reason,
                  );
              if (context.mounted) {
                Navigator.pop(context);
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: TranslatedText('Artifact Rejected')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const TranslatedText('Reject'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ThumbnailPreview extends ConsumerWidget {
  final String artifactId;
  final String? thumbnailUrl;

  const _ThumbnailPreview({required this.artifactId, this.thumbnailUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localThumbnail = ref.watch(artifactThumbnailProvider(artifactId));

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.kAccent.withOpacity(0.18),
            AppTheme.kTerracotta.withOpacity(0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.kGlassBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: localThumbnail.when(
          data: (bytes) {
            if (bytes != null) {
              return Image.memory(
                bytes,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallback(),
              );
            }
            if (thumbnailUrl != null && thumbnailUrl!.startsWith('http')) {
              return Image.network(
                thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallback(),
              );
            }
            return _buildFallback();
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildFallback(),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Icon(
        Icons.account_balance,
        size: 56,
        color: AppTheme.kAccent.withOpacity(0.4),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionReviewTile extends StatelessWidget {
  final HeritageSection section;
  final String artifactId;
  final String artifactTitle;

  const _SectionReviewTile({
    required this.section,
    required this.artifactId,
    required this.artifactTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: TranslatedText(
          section.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: TranslatedText(
                '${section.parts.length} Parts • ${section.analysis == null ? 'No Analysis' : 'Analysis included'}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            if (section.analysis != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showAnalysisPreview(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.kAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.kAccent.withOpacity(0.5)),
                  ),
                  child: const TranslatedText(
                    'Preview Analysis',
                    style: TextStyle(
                      color: AppTheme.kAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        iconColor: AppTheme.kAccent,
        collapsedIconColor: AppTheme.kParchment,
        children: [
          ...section.parts.map(
            (part) => Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: TranslatedText(
                      part.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
                  ...part.details.map(
                    (detail) => Padding(
                      padding: const EdgeInsets.only(left: 24, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TranslatedText(
                            detail.title,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.kParchment.withOpacity(0.65),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...detail.contents.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(left: 12, bottom: 4),
                              child: InkWell(
                                onTap: () => _previewContent(context, item),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.05),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getContentIcon(item.type),
                                        size: 16,
                                        color: AppTheme.kAccent,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TranslatedText(
                                          item.title,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.kParchment,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.play_circle_outline,
                                        size: 18,
                                        color: Colors.white24,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: AppTheme.kGlassBorder),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getContentIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'text':
        return Icons.article;
      case 'simulation':
        return Icons.view_in_ar;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _previewContent(BuildContext context, ArtifactContentItem item) {
    if (item.type == 'video') {
      context.push('/video-viewer', extra: {'url': item.url ?? '', 'title': item.title, 'fileId': item.fileId});
    } else if (item.type == 'pdf') {
      final dummyContent = LearningContent(
        id: item.fileId ?? item.id,
        title: item.title,
        type: AppConstants.contentTypePDF,
        authorId: 'preview',
        authorName: 'System',
        uploadedAt: DateTime.now(),
        url: item.url,
      );
      context.push('/pdf-viewer', extra: dummyContent);
    } else if (item.type == 'text') {
      _showTextPreview(context, item);
    } else if (item.type == 'simulation') {
      context.push(
        '/artifact-3d',
        extra: {
          'specificSim': item.simulationId ?? 'lalibela',
          'title': item.title,
        },
      );
    }
  }

  void _showAnalysisPreview(BuildContext context) {
    final questions = section.analysis?.evidence ?? const <Evidence>[];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.kSurface,
        title: TranslatedText(
          'Analysis Preview: $artifactTitle',
          style: const TextStyle(color: AppTheme.kParchment),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: questions.isEmpty
              ? const Center(
                  child: TranslatedText(
                    'No analysis questions available',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (context, i) {
                    final q = questions[i];
                    final opts = q.options;
                    final correct = q.correctAnswerIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Q${i + 1}: ${q.questionText}',
                            style: const TextStyle(
                              color: AppTheme.kAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (q.isShortAnswer)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Text(
                                q.correctShortAnswer ?? 'No answer provided',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            ...List.generate(opts.length, (optIdx) {
                              final isCorrect = optIdx == correct;
                              return Padding(
                                padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      isCorrect ? Icons.check_circle : Icons.circle_outlined,
                                      size: 16,
                                      color: isCorrect ? Colors.green : Colors.white38,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        opts[optIdx],
                                        style: TextStyle(
                                          color: isCorrect ? Colors.green : Colors.white70,
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

  void _showTextPreview(BuildContext context, ArtifactContentItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.kSurface,
        title: TranslatedText(
          item.title,
          style: const TextStyle(color: AppTheme.kParchment),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              item.text ?? 'No content',
              style: const TextStyle(color: AppTheme.kParchment, height: 1.6),
            ),
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
}

// ─────────────────────────────────────────────────────────────────────────────

/// Shows a verified badge next to the author's name if they are a verified
/// contributor. Uses a direct SQL query via [DatabaseHelper] — no box polling.
class _AuthorVerificationBadge extends ConsumerWidget {
  final String uid;
  const _AuthorVerificationBadge({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByUidProvider(uid));
    return userAsync.when(
      data: (user) {
        if (user == null || !(user.isVerified ?? false)) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Tooltip(
            message: 'Verified Contributor',
            child: Icon(Icons.verified, size: 16, color: Colors.blue.shade400),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
