import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../provider/artifact_controller.dart';
import 'content_manager_dialog.dart';
import 'analysis_editor_dialog.dart';
import '../../auth/providers/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/localization.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/artifact_domain.dart' as domain;

class ArtifactBuilderScreen extends ConsumerStatefulWidget {
  const ArtifactBuilderScreen({super.key});

  @override
  ConsumerState<ArtifactBuilderScreen> createState() =>
      _ArtifactBuilderScreenState();
}

class _ArtifactBuilderScreenState extends ConsumerState<ArtifactBuilderScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _detailedDescriptionController = TextEditingController();
  final _heritageSignificanceController = TextEditingController();
  final _thumbnailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  PlatformFile? _pickedThumbnail;
  final List<domain.HeritageSection> _sections = [];
  bool _isSaving = false;
  bool _isSequential = true;
  String _classification = AppConstants.gradeLevelHighSchool;
  int _currentStep = 0; // 0: Info, 1: Pathways

  final Color _bgColor = AppTheme.kBg;
  final Color _cardColor = AppTheme.kSurface;
  final Color _accentColor = AppTheme.kAccent;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _detailedDescriptionController.dispose();
    _heritageSignificanceController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  void _addSection() {
    setState(() {
      _sections.add(
        domain.HeritageSection(
          id: 'sec_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Section ${_sections.length + 1}',
          parts: [],
        ),
      );
    });
  }

  void _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      setState(() {
        _pickedThumbnail = result.files.first;
        _thumbnailController.text = _pickedThumbnail!.name;
      });
    }
  }

  String _normalizedThumbnailUrl() =>
      _resolveThumbnailUrl(_thumbnailController.text) ?? '';

  String? _resolveThumbnailUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    String candidate = trimmed;

    final htmlSrcMatch = RegExp(
      r'''src\s*=\s*["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(candidate);
    if (htmlSrcMatch != null) {
      candidate = htmlSrcMatch.group(1)!.trim();
    }

    final cssUrlMatch = RegExp(
      r'''url\(\s*["']?([^"')]+)["']?\s*\)''',
      caseSensitive: false,
    ).firstMatch(candidate);
    if (cssUrlMatch != null) {
      candidate = cssUrlMatch.group(1)!.trim();
    }

    final markdownMatch = RegExp(r'\[[^\]]*\]\((https?:\/\/[^)]+)\)').firstMatch(
      candidate,
    );
    if (markdownMatch != null) {
      candidate = markdownMatch.group(1)!.trim();
    }

    final rawUrlMatch = RegExp(r'https?:\/\/\S+', caseSensitive: false)
        .firstMatch(candidate);
    if (rawUrlMatch != null) {
      candidate = rawUrlMatch.group(0)!.trim();
    }

    candidate = candidate.replaceAll(RegExp(r'''^["'\s]+|["'\s]+$'''), '');

    if (candidate.startsWith('//')) {
      candidate = 'https:$candidate';
    } else if (candidate.startsWith('www.')) {
      candidate = 'https://$candidate';
    }

    final direct = _normalizeWrappedImageUrl(candidate);
    if (direct != null) {
      return direct;
    }

    final uri = Uri.tryParse(candidate);
    if (uri == null || !uri.hasScheme) {
      return null;
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return null;
    }

    return uri.toString();
  }

  String? _normalizeWrappedImageUrl(String value) {
    Uri? uri = Uri.tryParse(value);
    if (uri == null) {
      return null;
    }

    if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }

    final queryParams = uri.queryParameters;
    final wrappedKeys = ['imgurl', 'mediaurl', 'mediaUrl', 'image_url', 'url'];

    for (final key in wrappedKeys) {
      final wrappedValue = queryParams[key];
      if (wrappedValue == null || wrappedValue.trim().isEmpty) {
        continue;
      }

      final decoded = Uri.decodeFull(wrappedValue).trim();
      final nested = _resolveThumbnailUrl(decoded);
      if (nested != null) {
        return nested;
      }
    }

    return uri.toString();
  }

  void _applyNormalizedThumbnailUrl() {
    final normalized = _resolveThumbnailUrl(_thumbnailController.text);
    if (normalized == null || normalized == _thumbnailController.text.trim()) {
      return;
    }

    _thumbnailController.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }

  bool _isValidThumbnailUrl(String value) {
    return _resolveThumbnailUrl(value) != null;
  }

  Future<void> _saveArtifact() async {
    if (_isSaving) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _currentStep = 0);
      return;
    }
    if (_sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snack('Add at least one section to your pathway', isError: true),
      );
      return;
    }

    final allHaveAnalyses = _sections.every(
      (s) => s.analysis != null && s.analysis!.evidence.isNotEmpty,
    );
    if (!allHaveAnalyses) {
      ScaffoldMessenger.of(context).showSnackBar(
        _snack(
          'Every section must have an expert analysis before publishing',
          isError: true,
        ),
      );
      return;
    }

    String? contentError;
    for (int i = 0; i < _sections.length; i++) {
      final sec = _sections[i];
      if (sec.parts.isEmpty) {
        contentError =
            'Section ${i + 1} "${sec.title}" must have at least one part';
        break;
      }
      for (final part in sec.parts) {
        if (part.details.isEmpty) {
          contentError =
              'Part "${part.title}" in section ${i + 1} must have at least one detail section';
          break;
        }
        for (final detail in part.details) {
          if (detail.contents.isEmpty) {
            contentError =
                'Detail "${detail.title}" in section ${i + 1} is empty. Add assets first.';
            break;
          }
        }
        if (contentError != null) break;
      }
      if (contentError != null) break;
    }

    if (contentError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(_snack(contentError, isError: true));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(userProvider);
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _snack(
              'You must be signed in to submit an artifact',
              isError: true,
            ),
          );
        }
        return;
      }

      Uint8List? thumbnailBytes;
      if (_pickedThumbnail != null) {
        if (kIsWeb) {
          thumbnailBytes = _pickedThumbnail!.bytes;
        } else if (_pickedThumbnail!.path != null) {
          thumbnailBytes = await io.File(_pickedThumbnail!.path!).readAsBytes();
        }
      }

      final artifact = domain.createArtifactDraft(
        id: 'artifact_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text,
        description: _descriptionController.text,
        authorId: user.uid,
        authorName: user.displayName ?? user.email,
        sections: _sections,
        createdAt: DateTime.now(),
        thumbnailUrl: _pickedThumbnail != null
            ? _pickedThumbnail!.name
            : _normalizedThumbnailUrl(),
        isSequential: _isSequential,
        classification: _classification,
        detailedDescription: _detailedDescriptionController.text,
        heritageSignificanceText: _heritageSignificanceController.text,
      );

      await ref
          .read(artifactControllerProvider.notifier)
          .createArtifact(artifact, thumbnailBytes: thumbnailBytes);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(_snack('Artifact submitted for authenticity review!'));
      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(_snack('Failed to submit artifact: $e', isError: true));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  SnackBar _snack(String msg, {bool isError = false}) {
    return SnackBar(
      content: TranslatedText(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const TranslatedText(
          'Exhibit Curator',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: ElevatedButton(
                onPressed: _saveArtifact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const TranslatedText(
                  'Submit',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          const LanguageSwitcher(),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Progress stepper header
          _buildStepHeader(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_bgColor, Colors.black],
                ),
              ),
              child: _currentStep == 0 ? _buildInfoStep() : _buildPathwayStep(),
            ),
          ),
          _buildStepFooter(),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    return Container(
      color: _bgColor,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Row(
        children: [
          _StepIndicator(
            step: 1,
            label: 'Identity',
            isActive: _currentStep == 0,
            isDone: _currentStep > 0,
            accentColor: _accentColor,
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: _currentStep > 0 ? _accentColor : Colors.white10,
            ),
          ),
          _StepIndicator(
            step: 2,
            label: 'Exhibit Flow',
            isActive: _currentStep == 1,
            isDone: false,
            accentColor: _accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Exhibit Identity'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              decoration: _inputDecoration(
                'Exhibit Title',
                'e.g., Aksumite Coin Layer A',
              ),
              validator: (v) => domain.ArtifactTitle.isValid(v ?? '')
                  ? null
                  : 'Title is required',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white70),
              decoration: _inputDecoration(
                'Short Description',
                'Showcased in lists',
              ),
              validator: (v) => domain.ArtifactDescription.isValid(v ?? '')
                  ? null
                  : 'Description is required',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _detailedDescriptionController,
              maxLines: 6,
              style: const TextStyle(color: Colors.white70),
              decoration: _inputDecoration(
                'Historical Narrative',
                'Provide deep context for viewers',
              ),
              validator: (v) => domain.ArtifactNarrative.isValid(v ?? '')
                  ? null
                  : 'Narrative is required',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _heritageSignificanceController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white70),
              decoration: _inputDecoration(
                'Scientific Significance',
                'Enter each core finding on a new line',
              ),
              validator: (v) =>
                  domain.HeritageSignificanceList.isValid(v ?? '')
                  ? null
                  : 'Significance is required',
            ),
            const SizedBox(height: 24),
            _sectionLabel('Visuals & Settings'),
            const SizedBox(height: 16),
            if (_pickedThumbnail != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image(
                        height: 140,
                        width: double.infinity,
                        image: kIsWeb
                            ? MemoryImage(_pickedThumbnail!.bytes!)
                                  as ImageProvider
                            : FileImage(io.File(_pickedThumbnail!.path!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.image, color: Colors.blue),
                      title: Text(
                        _pickedThumbnail!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: const TranslatedText(
                        'Background Image Selected',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.redAccent),
                        onPressed: () => setState(() {
                          _pickedThumbnail = null;
                          _thumbnailController.clear();
                        }),
                      ),
                    ),
                  ],
                ),
              ),

            if (_pickedThumbnail == null)
              TextFormField(
                controller: _thumbnailController,
                style: const TextStyle(color: Colors.white70),
                decoration: _inputDecoration(
                  'Background Image URL',
                  'Paste an image URL, Google image link, or image HTML snippet',
                ),
                onEditingComplete: () {
                  _applyNormalizedThumbnailUrl();
                  FocusScope.of(context).nextFocus();
                },
                onFieldSubmitted: (_) => _applyNormalizedThumbnailUrl(),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return null;
                  }
                  if (!_isValidThumbnailUrl(trimmed)) {
                    return 'Enter a valid http(s) image URL or upload a local image';
                  }
                  return null;
                },
              ),

            if (_pickedThumbnail == null)
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _thumbnailController,
                builder: (context, value, _) {
                  final previewUrl = _resolveThumbnailUrl(value.text);
                  if (previewUrl == null || value.text.trim().isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            previewUrl,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 140,
                                width: double.infinity,
                                color: Colors.black26,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(16),
                                child: const Text(
                                  'This link does not expose a direct image file. Try "Copy image address" or paste the raw image URL.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Remote Background Preview',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                previewUrl,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickThumbnail,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: TranslatedText(
                _pickedThumbnail == null
                    ? 'Upload Local Background'
                    : 'Change Background',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: _pickedThumbnail == null
                    ? _cardColor
                    : _accentColor.withValues(alpha: 0.1),
                foregroundColor: _pickedThumbnail == null
                    ? Colors.white70
                    : _accentColor,
                side: BorderSide(
                  color: _pickedThumbnail == null
                      ? Colors.white10
                      : _accentColor.withValues(alpha: 0.2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Guided Discovery",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Viewers must complete stages in order",
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isSequential,
                    onChanged: (v) => setState(() => _isSequential = v),
                    activeThumbColor: _accentColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionLabel('Heritage Type'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _GradeSegmentButton(
                      label: 'Tangible',
                      isActive:
                          _classification == AppConstants.gradeLevelHighSchool,
                      onTap: () => setState(
                        () =>
                            _classification = AppConstants.gradeLevelHighSchool,
                      ),
                      accentColor: _accentColor,
                    ),
                  ),
                  Expanded(
                    child: _GradeSegmentButton(
                      label: 'Intangible',
                      isActive:
                          _classification == AppConstants.gradeLevelCollege,
                      onTap: () => setState(
                        () => _classification = AppConstants.gradeLevelCollege,
                      ),
                      accentColor: _accentColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPathwayStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TranslatedText(
                'Exhibit Flow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatChip(
                    label: '${_sections.length} Themes',
                    icon: Icons.auto_awesome_motion,
                    color: _accentColor,
                  ),
                  _StatChip(
                    label:
                        '${_sections.fold(0, (sum, s) => sum + s.parts.length)} Heritage Details',
                    icon: Icons.history_edu,
                    color: Colors.white,
                  ),
                  _StatChip(
                    label:
                        '${_sections.fold(0, (sum, s) => sum + (s.analysis != null && s.analysis!.evidence.isNotEmpty ? 1 : 0))} Analyses',
                    icon: Icons.psychology_outlined,
                    color:
                        _sections.any(
                          (s) =>
                              s.analysis != null &&
                              s.analysis!.evidence.isNotEmpty,
                        )
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white10),
        Expanded(
          child: _sections.isEmpty
              ? _buildEmptyCurriculum()
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sections.length,
                  onReorder: (oldIdx, newIdx) {
                    setState(() {
                      if (newIdx > oldIdx) newIdx--;
                      final sec = _sections.removeAt(oldIdx);
                      _sections.insert(newIdx, sec);
                    });
                  },
                  itemBuilder: (context, index) {
                    return _HeritageSectionCard(
                      key: ValueKey(_sections[index].id),
                      section: _sections[index],
                      index: index,
                      onUpdate: (updated) =>
                          setState(() => _sections[index] = updated),
                      onDelete: () => setState(() => _sections.removeAt(index)),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyCurriculum() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.token_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const TranslatedText(
            'No themes yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          TranslatedText(
            'Tap the button below to add your first theme',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildStepFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgColor,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  foregroundColor: Colors.white,
                ),
                child: const TranslatedText('← Previous'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _currentStep == 0
                ? ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        setState(() => _currentStep = 1);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const TranslatedText(
                      'Next: Exhibit Flow →',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _addSection,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const TranslatedText(
                      'Add Theme',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
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
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white38,
        letterSpacing: 1.2,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.1), fontSize: 13),
      filled: true,
      fillColor: _cardColor,
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
        borderSide: BorderSide(color: _accentColor.withValues(alpha: 0.5)),
      ),
      contentPadding: const EdgeInsets.all(20),
    );
  }
}

class _GradeSegmentButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color accentColor;

  const _GradeSegmentButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: TranslatedText(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white38,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  final String label;
  final bool isActive;
  final bool isDone;
  final Color accentColor;

  const _StepIndicator({
    required this.step,
    required this.label,
    required this.isActive,
    required this.isDone,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? accentColor
        : (isDone ? Colors.green : Colors.white12);
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        TranslatedText(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white38,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          TranslatedText(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeritageSectionCard extends StatelessWidget {
  final domain.HeritageSection section;
  final int index;
  final void Function(domain.HeritageSection) onUpdate;
  final VoidCallback onDelete;

  const _HeritageSectionCard({
    super.key,
    required this.section,
    required this.index,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color accentColor = AppTheme.kAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.kGlassBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          title: Text(
            section.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            section.analysis != null && section.analysis!.evidence.isNotEmpty
                ? '${section.parts.length} Heritage Details • Quiz included'
                : '${section.parts.length} Heritage Details • Quiz missing (Required)',
            style: TextStyle(
              color:
                  section.analysis != null &&
                      section.analysis!.evidence.isNotEmpty
                  ? Colors.white38
                  : Colors.orangeAccent,
              fontSize: 13,
              fontWeight: section.analysis == null
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _editTitle(context),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Colors.white38,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.redAccent,
                ),
              ),
              const Icon(Icons.expand_more, color: Colors.white24),
            ],
          ),
          children: [
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PARTS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white24,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addPart,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Heritage Detail'),
                  style: TextButton.styleFrom(foregroundColor: accentColor),
                ),
              ],
            ),
            if (section.parts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No heritage details in this theme yet',
                  style: TextStyle(color: Colors.white12, fontSize: 13),
                ),
              ),
            ...section.parts.asMap().entries.map((entry) {
              final pIdx = entry.key;
              final part = entry.value;
              return _PartItem(
                part: part,
                onUpdate: (updated) {
                  final updatedParts = [...section.parts];
                  updatedParts[pIdx] = updated;
                  onUpdate(section.copyWith(parts: updatedParts));
                },
                onDelete: () {
                  final updatedParts = [...section.parts];
                  updatedParts.removeAt(pIdx);
                  onUpdate(section.copyWith(parts: updatedParts));
                },
              );
            }),
            const SizedBox(height: 12),
            _AnalysisSection(
              analysis: section.analysis,
              onEdit: () => _editAnalysis(context),
            ),
          ],
        ),
      ),
    );
  }

  void _editTitle(BuildContext context) async {
    final controller = TextEditingController(text: section.title);
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => _PremiumInputDialog(
        title: 'Rename Theme',
        label: 'Theme title',
        controller: controller,
      ),
    );
    if (title != null && title.isNotEmpty) {
      onUpdate(section.copyWith(title: title));
    }
  }

  void _addPart() {
    onUpdate(
      section.copyWith(
        parts: [
          ...section.parts,
          domain.HeritagePart(
            id: 'part_${DateTime.now().millisecondsSinceEpoch}',
            title: 'New Part ${section.parts.length + 1}',
            details: [],
          ),
        ],
      ),
    );
  }

  void _editAnalysis(BuildContext context) async {
    final updatedAnalysis = await Navigator.push<domain.Analysis>(
      context,
      MaterialPageRoute(
        builder: (ctx) => AnalysisEditorDialog(analysis: section.analysis),
        fullscreenDialog: true,
      ),
    );
    if (updatedAnalysis != null) {
      onUpdate(section.copyWith(analysis: updatedAnalysis));
    }
  }
}

class _AnalysisSection extends StatelessWidget {
  final domain.Analysis? analysis;
  final VoidCallback onEdit;

  const _AnalysisSection({required this.analysis, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final Color accentColor = AppTheme.kAccent;
    final bool hasAnalysis = analysis != null && analysis!.evidence.isNotEmpty;
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasAnalysis
              ? accentColor.withValues(alpha: 0.05)
              : Colors.orangeAccent.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasAnalysis
                ? accentColor.withValues(alpha: 0.2)
                : Colors.orangeAccent.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasAnalysis ? Icons.psychology : Icons.warning_amber_rounded,
              color: hasAnalysis ? accentColor : Colors.orangeAccent,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasAnalysis
                        ? 'Expert Quiz'
                        : 'Add Quiz (Mandatory)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: hasAnalysis ? Colors.white : Colors.orangeAccent,
                    ),
                  ),
                  if (hasAnalysis)
                    Text(
                      '${analysis!.evidence.length} Evidence Records • Authenticity check',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    )
                  else
                    const Text(
                      'Theme must have a quiz to be verified.',
                      style: TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: hasAnalysis
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.orangeAccent.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartItem extends StatelessWidget {
  final domain.HeritagePart part;
  final Function(domain.HeritagePart) onUpdate;
  final VoidCallback onDelete;

  const _PartItem({
    required this.part,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: const Icon(
            Icons.drag_indicator,
            color: Colors.white10,
            size: 20,
          ),
          title: Text(
            part.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            '${part.details.length} Detail Sections',
            style: const TextStyle(fontSize: 11, color: Colors.white24),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _editTitle(context),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: Colors.white24,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          children: [
            ...part.details.asMap().entries.map((entry) {
              final dIdx = entry.key;
              final detail = entry.value;
              return _DetailRow(
                detail: detail,
                onUpdate: (updated) {
                  final details = [...part.details];
                  details[dIdx] = updated;
                  onUpdate(part.copyWith(details: details));
                },
                onDelete: () {
                  final details = [...part.details];
                  details.removeAt(dIdx);
                  onUpdate(part.copyWith(details: details));
                },
              );
            }),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _addDetail,
              icon: const Icon(Icons.add, size: 14),
              label: const Text(
                'Add Detail Section',
                style: TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  void _editTitle(BuildContext context) async {
    final controller = TextEditingController(text: part.title);
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => _PremiumInputDialog(
        title: 'Rename Heritage Detail',
        label: 'Heritage Detail title',
        controller: controller,
      ),
    );
    if (title != null && title.isNotEmpty) {
      onUpdate(part.copyWith(title: title));
    }
  }

  void _addDetail() {
    onUpdate(
      part.copyWith(
        details: [
          ...part.details,
          domain.ArtifactDetail(
            id: 'detail_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Detail Section ${part.details.length + 1}',
            contents: [],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final domain.ArtifactDetail detail;
  final Function(domain.ArtifactDetail) onUpdate;
  final VoidCallback onDelete;

  const _DetailRow({
    required this.detail,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent = detail.contents.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.layers_outlined,
            size: 18,
            color: hasContent ? AppTheme.kAccent : Colors.white10,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                if (hasContent)
                  Text(
                    '${detail.contents.length} Artifact Assets',
                    style: const TextStyle(fontSize: 11, color: Colors.white24),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _manageContent(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              backgroundColor: AppTheme.kAccent.withValues(alpha: 0.1),
              foregroundColor: AppTheme.kAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              hasContent ? 'Edit' : '+ Asset',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.close, size: 16, color: Colors.white10),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _manageContent(BuildContext context) async {
    final result = await Navigator.push<List<domain.ArtifactContentItem>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ContentManagerDialog(initialContents: detail.contents),
      ),
    );
    if (result != null) onUpdate(detail.copyWith(contents: result));
  }
}

class _PremiumInputDialog extends StatelessWidget {
  final String title;
  final String label;
  final TextEditingController controller;

  const _PremiumInputDialog({
    required this.title,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D4D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save'),
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

extension SectionExtension on domain.HeritageSection {
  domain.HeritageSection copyWith({
    String? title,
    List<domain.HeritagePart>? parts,
    domain.Analysis? analysis,
  }) {
    return domain.HeritageSection(
      id: id,
      title: title ?? this.title,
      parts: parts ?? this.parts,
      analysis: analysis ?? this.analysis,
    );
  }
}

extension PartExtension on domain.HeritagePart {
  domain.HeritagePart copyWith({
    String? title,
    List<domain.ArtifactDetail>? details,
  }) {
    return domain.HeritagePart(
      id: id,
      title: title ?? this.title,
      details: details ?? this.details,
    );
  }
}

extension DetailExtension on domain.ArtifactDetail {
  domain.ArtifactDetail copyWith({
    String? title,
    List<domain.ArtifactContentItem>? contents,
  }) {
    return domain.ArtifactDetail(
      id: id,
      title: title ?? this.title,
      contents: contents ?? this.contents,
    );
  }
}
