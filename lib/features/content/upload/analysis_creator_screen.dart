import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/artifact_model.dart' show EvidenceModel;
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/localization.dart';
import '../../artifacts/domain/artifact_domain.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/shared_app_bar.dart';
import '../provider/content_repository.dart';
import '../../auth/providers/auth_controller.dart';
import '../../artifacts/presentation/analysis_editor_dialog.dart';
import '../../artifacts/infrastructure/artifact_model_mapper.dart';

class AnalysisCreatorScreen extends ConsumerStatefulWidget {
  const AnalysisCreatorScreen({super.key});

  @override
  ConsumerState<AnalysisCreatorScreen> createState() =>
      _AnalysisCreatorScreenState();
}

class _AnalysisCreatorScreenState extends ConsumerState<AnalysisCreatorScreen> {
  final _titleController = TextEditingController();
  final List<Evidence> _evidence = [];
  bool _isSubmitting = false;
  String _selectedClassification = AppConstants.classificationTangible;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _addEvidence() async {
    final result = await Navigator.push<Evidence>(
      context,
      MaterialPageRoute(builder: (context) => const EvidenceEditorScreen()),
    );
    if (result != null) {
      setState(() => _evidence.add(result));
    }
  }

  Future<void> _editEvidence(int index) async {
    final result = await Navigator.push<Evidence>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EvidenceEditorScreen(initialEvidence: _evidence[index]),
      ),
    );
    if (result != null) {
      setState(() => _evidence[index] = result);
    }
  }

  Future<void> _submitAnalysis() async {
    if (_isSubmitting) return;

    final messenger = ScaffoldMessenger.of(context);
    final user = ref.read(userProvider);
    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: TranslatedText('Please sign in before submitting quiz'),
        ),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: TranslatedText('Please enter a quiz title'),
        ),
      );
      return;
    }

    if (_evidence.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: TranslatedText('Please add at least one evidence piece'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final analysisContent = LearningContent(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      type: AppConstants.contentTypeAnalysis,
      authorId: user.uid,
      authorName: user.displayName ?? user.email,
      gradeLevel: _selectedClassification,
      subject: 'Heritage Quiz',
      status: AppConstants.statusPending,
      uploadedAt: DateTime.now(),
      extraData: {
        'evidence': _evidence
            .map((evidence) => evidenceModelToJson(EvidenceModel.fromDomain(evidence)))
            .toList(),
      },
    );

    try {
      await ref
          .read(contentControllerProvider.notifier)
          .uploadContent(analysisContent);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: TranslatedText('Quiz submitted for review'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = AppTheme.kAccent;

    return Scaffold(
      backgroundColor: AppTheme.kBg,
      appBar: SharedAppBar(
        title: 'Heritage Quiz',
        showProfile: false,
        switcherOnRight: true,
        extraActions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAnalysis,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const TranslatedText(
                      'Publish',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accentColor.withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('QUIZ IDENTITY'),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: _inputDecoration(
                    'Title',
                    'e.g., Bronze Age Pottery Verification',
                    icon: Icons.title_rounded,
                  ),
                ),
                const SizedBox(height: 24),
                _sectionLabel('CLASSIFICATION'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const TranslatedText('Tangible'),
                        selected:
                            _selectedClassification ==
                            AppConstants.classificationTangible,
                        onSelected: (_) {
                          setState(() {
                            _selectedClassification =
                                AppConstants.classificationTangible;
                          });
                        },
                        selectedColor: accentColor.withValues(alpha: 0.2),
                        backgroundColor: AppTheme.kSurface,
                        labelStyle: TextStyle(
                          color:
                              _selectedClassification ==
                                  AppConstants.classificationTangible
                              ? Colors.white
                              : Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const TranslatedText('Intangible'),
                        selected:
                            _selectedClassification ==
                            AppConstants.classificationIntangible,
                        onSelected: (_) {
                          setState(() {
                            _selectedClassification =
                                AppConstants.classificationIntangible;
                          });
                        },
                        selectedColor: accentColor.withValues(alpha: 0.2),
                        backgroundColor: AppTheme.kSurface,
                        labelStyle: TextStyle(
                          color:
                              _selectedClassification ==
                                  AppConstants.classificationIntangible
                              ? Colors.white
                              : Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionLabel('EVIDENCE PIECES'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_evidence.length} Items',
                        style: const TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_evidence.isEmpty)
                  _buildEmptyState()
                else
                  ..._evidence.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final e = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _StandaloneEvidenceCard(
                        index: idx,
                        evidence: e,
                        onTap: () => _editEvidence(idx),
                        onDelete: () => setState(() => _evidence.removeAt(idx)),
                      ),
                    );
                  }),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _addEvidence,
                  icon: const Icon(Icons.add_task_rounded, size: 18),
                  label: const TranslatedText(
                    'Add Evidence Piece',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return TranslatedText(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.white24,
        letterSpacing: 1.5,
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    String hint, {
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.1), fontSize: 13),
      filled: true,
      fillColor: AppTheme.kSurface,
      prefixIcon: icon != null
          ? Icon(icon, color: AppTheme.kAccent, size: 20)
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.kAccent.withValues(alpha: 0.5)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Widget _buildEmptyState() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 16),
            const TranslatedText(
              'No evidence pieces added yet.',
              style: TextStyle(color: Colors.white12, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandaloneEvidenceCard extends StatelessWidget {
  final int index;
  final Evidence evidence;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _StandaloneEvidenceCard({
    required this.index,
    required this.evidence,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 20,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.kAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppTheme.kAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      evidence.questionText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white24,
                      size: 20,
                    ),
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(
                    label: evidence.isShortAnswer
                        ? 'Open Observation'
                        : 'Multiple Choice',
                    icon: evidence.isShortAnswer
                        ? Icons.short_text
                        : Icons.list,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 8),
                  if (!evidence.isShortAnswer)
                    _InfoChip(
                      label: '${evidence.options.length} Options',
                      icon: Icons.checklist_rtl_rounded,
                      color: Colors.greenAccent,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
