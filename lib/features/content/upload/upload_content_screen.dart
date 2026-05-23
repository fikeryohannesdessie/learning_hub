import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/translated_text.dart';
import '../domain/content_domain.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_controller.dart';
import '../provider/content_repository.dart';

class UploadContentScreen extends ConsumerStatefulWidget {
  final String? initialType;

  const UploadContentScreen({super.key, this.initialType});

  @override
  ConsumerState<UploadContentScreen> createState() =>
      _UploadContentScreenState();
}

class _UploadContentScreenState extends ConsumerState<UploadContentScreen> {
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = AppConstants.contentTypePDF;
  String _selectedGrade = AppConstants.gradeLevelHighSchool;
  PlatformFile? _pickedFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
      if (_selectedType == AppConstants.contentTypeAudio) {
        _selectedGrade = AppConstants.classIntangible;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final isVideo = _selectedType == AppConstants.contentTypeVideo;
    final isAudio = _selectedType == AppConstants.contentTypeAudio;

    final result = await FilePicker.platform.pickFiles(
      type: isVideo
          ? FileType.video
          : (isAudio ? FileType.audio : FileType.custom),
      allowedExtensions: (isVideo || isAudio) ? null : ['pdf'],
      withData: kIsWeb,
    );

    if (!mounted) return;

    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _upload() async {
    final title = _titleController.text.trim();
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();
    final requiresFile =
        _selectedType == AppConstants.contentTypePDF ||
        _selectedType == AppConstants.contentTypeVideo ||
        _selectedType == AppConstants.contentTypeAudio;

    if (title.isEmpty || subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TranslatedText('Please fill in the required fields'),
        ),
      );
      return;
    }

    if (requiresFile && _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TranslatedText(
            _selectedType == AppConstants.contentTypeVideo
                ? 'Please pick a video file'
                : (_selectedType == AppConstants.contentTypeAudio
                    ? 'Please pick an audio file'
                    : 'Please pick a PDF file'),
          ),
        ),
      );
      return;
    }

    final user = ref.read(userProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TranslatedText('No signed-in contributor found'),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      Uint8List? fileBytes;

      if (_pickedFile != null) {
        if (kIsWeb) {
          fileBytes = _pickedFile!.bytes;
        } else if (_pickedFile!.path != null) {
          fileBytes = await io.File(_pickedFile!.path!).readAsBytes();
        }
      }

      final content = LearningContent(
        id: const Uuid().v4(),
        title: title,
        type: _selectedType,
        authorId: user.uid,
        authorName: user.displayName ?? user.email,
        gradeLevel: _selectedGrade,
        subject: subject,
        description: description.isEmpty ? null : description,
        uploadedAt: DateTime.now(),
        status: AppConstants.statusPending,
        url: kIsWeb ? null : _pickedFile?.path,
      );

      await ref
          .read(contentControllerProvider.notifier)
          .uploadContent(content, bytes: fileBytes);

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: TranslatedText('Content uploaded for review')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: TranslatedText('Upload failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white60),
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: AppTheme.kSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.kAccent.withOpacity(0.5)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }

  Widget _sectionLabel(String label, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: AppTheme.kAccent),
          const SizedBox(width: 8),
        ],
        TranslatedText(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white54,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = _selectedType == AppConstants.contentTypeVideo;

    return Scaffold(
      backgroundColor: AppTheme.kBg,
      appBar: SharedAppBar(
        title: 'Upload Resources',
        showProfile: false,
        switcherOnRight: true,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -90,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.kAccent.withOpacity(0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION 1: IDENTIFICATION
                _sectionLabel('IDENTIFICATION', icon: Icons.badge_outlined),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          'Title',
                          'Enter the content title',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _subjectController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          'Subject',
                          'e.g. Heritage, History, Culture',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          'Description',
                          'Provide context for the admin reviewer',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // SECTION 2: HERITAGE TYPE
                _sectionLabel('HERITAGE TYPE', icon: Icons.account_tree_outlined),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final useVerticalLayout = constraints.maxWidth < 520;

                      final typeItems = <DropdownMenuItem<String>>[
                        if (widget.initialType == null ||
                            widget.initialType == AppConstants.contentTypePDF)
                          const DropdownMenuItem(
                            value: AppConstants.contentTypePDF,
                            child: TranslatedText('Archival Document'),
                          ),
                        if (widget.initialType == null ||
                            widget.initialType == AppConstants.contentTypePDF)
                          const DropdownMenuItem(
                            value: AppConstants.contentTypeWorksheet,
                            child: TranslatedText('Research Notes'),
                          ),
                        if (widget.initialType == null ||
                            widget.initialType == AppConstants.contentTypeVideo)
                          const DropdownMenuItem(
                            value: AppConstants.contentTypeVideo,
                            child: TranslatedText('Video'),
                          ),
                        if (widget.initialType == null ||
                            widget.initialType == AppConstants.contentTypeAudio)
                          const DropdownMenuItem(
                            value: AppConstants.contentTypeAudio,
                            child: TranslatedText('Audio'),
                          ),
                      ];

                      final typeDropdown = DropdownButtonFormField<String>(
                        value: _selectedType,
                        isExpanded: true,
                        dropdownColor: AppTheme.kSurface,
                        style: const TextStyle(color: Colors.white),
                        items: typeItems,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedType = value;
                            _pickedFile = null;
                            // Automate Intangible classification for Audio
                            if (value == AppConstants.contentTypeAudio) {
                              _selectedGrade = AppConstants.classIntangible;
                            }
                          });
                        },
                        decoration: _inputDecoration('Type', ''),
                      );

                      final isAudioType = _selectedType == AppConstants.contentTypeAudio;

                      final classificationDropdown = isAudioType
                          ? const SizedBox.shrink()
                          : DropdownButtonFormField<String>(
                              value: _selectedGrade,
                              isExpanded: true,
                              dropdownColor: AppTheme.kSurface,
                              style: const TextStyle(color: Colors.white),
                              items: const [
                                DropdownMenuItem(
                                  value: AppConstants.classTangible,
                                  child: TranslatedText('Tangible'),
                                ),
                                DropdownMenuItem(
                                  value: AppConstants.classIntangible,
                                  child: TranslatedText('Intangible'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _selectedGrade = value);
                              },
                              decoration: _inputDecoration('Classification', ''),
                            );

                      if (useVerticalLayout) {
                        return Column(
                          children: [
                            typeDropdown,
                            if (!isAudioType) ...[
                              const SizedBox(height: 14),
                              classificationDropdown,
                            ],
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: typeDropdown),
                          if (!isAudioType) ...[
                            const SizedBox(width: 14),
                            Expanded(child: classificationDropdown),
                          ],
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // SECTION 3: ATTACHMENT
                _sectionLabel('RESOURCE FILE', icon: Icons.cloud_upload_outlined),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_pickedFile != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.kBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: ListTile(
                            leading: Icon(
                              isVideo
                                  ? Icons.video_file
                                  : (_selectedType == AppConstants.contentTypeAudio
                                      ? Icons.audiotrack
                                      : Icons.picture_as_pdf),
                              color: AppTheme.kAccent,
                            ),
                            title: Text(
                              _pickedFile!.name,
                              style: const TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white54),
                              onPressed: () => setState(() => _pickedFile = null),
                            ),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: _pickFile,
                        icon: Icon(
                          isVideo
                              ? Icons.video_library_outlined
                              : (_selectedType == AppConstants.contentTypeAudio
                                  ? Icons.audiotrack_outlined
                                  : Icons.attach_file),
                        ),
                        label: TranslatedText(
                          _pickedFile == null
                              ? (isVideo
                                  ? 'Pick video file'
                                  : (_selectedType == AppConstants.contentTypeAudio
                                      ? 'Pick audio file'
                                      : 'Pick PDF file'))
                              : 'Change file',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withOpacity(0.12)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),
                if (_isUploading)
                  const Center(
                    child: CircularProgressIndicator(color: AppTheme.kAccent),
                  )
                else
                  ElevatedButton(
                    onPressed: _upload,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 58),
                      backgroundColor: AppTheme.kAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: AppTheme.kAccent.withOpacity(0.3),
                    ),
                    child: const TranslatedText(
                      'Submit for Review',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
