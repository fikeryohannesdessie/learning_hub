import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/content_domain.dart';
import '../../../features/auth/providers/auth_controller.dart';
import '../provider/content_repository.dart';
import '../../../core/localization/translated_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_app_bar.dart';

class UploadContentScreen extends ConsumerStatefulWidget {
  const UploadContentScreen({super.key});

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

  void _pickFile() async {
    final isVideo = _selectedType == AppConstants.contentTypeVideo;
    final result = await FilePicker.platform.pickFiles(
      type: isVideo ? FileType.video : FileType.custom,
      allowedExtensions: isVideo ? null : ['pdf'],
    );

    if (result != null) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  void _upload() async {
    if (_pickedFile == null && (_selectedType == AppConstants.contentTypePDF || _selectedType == AppConstants.contentTypeVideo)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: TranslatedText(_selectedType == AppConstants.contentTypeVideo ? 'Please pick a video file' : 'Please pick a PDF file')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = ref.read(userProvider)!;
      final id = const Uuid().v4();

      Uint8List? fileBytes;
      if (_pickedFile != null) {
        if (kIsWeb) {
          fileBytes = _pickedFile!.bytes;
        } else if (_pickedFile!.path != null) {
          final file = io.File(_pickedFile!.path!);
          fileBytes = await file.readAsBytes();
        }
      }

      final content = LearningContent(
        id: id,
        title: _titleController.text.trim(),
        type: _selectedType,
        authorId: user.uid,
        authorName: user.displayName ?? 'Local Contributor',
        gradeLevel: _selectedGrade,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        uploadedAt: DateTime.now(),
        // For video: store the local path directly as the url so VideoViewerScreen can open it
        url: kIsWeb ? null : _pickedFile?.path,
      );

      await ref
          .read(contentControllerProvider.notifier)
          .uploadContent(content, bytes: fileBytes);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: TranslatedText('Content uploaded for review')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: TranslatedText('Upload failed: $e')));
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color cardColor = AppTheme.kSurface;
    const Color accentColor = AppTheme.kAccent;

    return Scaffold(
      backgroundColor: AppTheme.kBg,
      appBar: SharedAppBar(
        title: 'Upload Content',
        showProfile: false,
        switcherOnRight: true,
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
                  colors: [
                    accentColor.withOpacity(0.18),
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
                _sectionLabel('Content Identity'),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: _inputDecoration('Title', 'Enter content title'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _subjectController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: _inputDecoration(
                    'Category',
                    'e.g., Oral History, Ritual Practice, Architecture',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white70),
                  decoration: _inputDecoration('Description', 'Provide context for reviewers'),
                ),
                const SizedBox(height: 24),
                _sectionLabel('Classification'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        dropdownColor: cardColor,
                        style: const TextStyle(color: Colors.white),
                        items: [
                          const DropdownMenuItem(
                            value: AppConstants.contentTypePDF,
                            child: TranslatedText('Book (PDF)'),
                          ),
                          const DropdownMenuItem(
                            value: AppConstants.contentTypeWorksheet,
                            child: TranslatedText('Worksheet'),
                          ),
                          const DropdownMenuItem(
                            value: AppConstants.contentTypeVideo,
                            child: TranslatedText('Video'),
                          ),
                        ],
                        onChanged: (v) => setState(() {
                          _selectedType = v!;
                          _pickedFile = null;
                        }),
                        decoration: _inputDecoration('Type', ''),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGrade,
                        dropdownColor: cardColor,
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(
                            value: AppConstants.gradeLevelHighSchool,
                            child: TranslatedText('Tangible Heritage'),
                          ),
                          DropdownMenuItem(
                            value: AppConstants.gradeLevelCollege,
                            child: TranslatedText('Intangible Heritage'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedGrade = v!),
                        decoration: _inputDecoration('Classification', ''),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionLabel('Attachment'),
                const SizedBox(height: 16),
                if (_pickedFile != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _selectedType == AppConstants.contentTypeVideo
                              ? Icons.video_file
                              : Icons.picture_as_pdf,
                          color: accentColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        _pickedFile!.name,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white24, size: 20),
                        onPressed: () => setState(() => _pickedFile = null),
                      ),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: Icon(
                    _selectedType == AppConstants.contentTypeVideo 
                        ? Icons.video_library 
                        : Icons.attach_file,
                    size: 18,
                  ),
                  label: TranslatedText(
                    _pickedFile == null
                        ? (_selectedType == AppConstants.contentTypeVideo 
                            ? 'Pick video recording' 
                            : 'Select PDF document')
                        : 'Change file source',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 48),
                if (_isUploading)
                  const Center(child: CircularProgressIndicator(color: accentColor))
                else
                  ElevatedButton(
                    onPressed: _upload,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const TranslatedText(
                      'Submit for Review',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 13),
      filled: true,
      fillColor: AppTheme.kSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.kAccent.withOpacity(0.5)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
//Compiler reshut needs to happen here

// Confirming everythign works fine bef

//confiriming everythign works fine before reshutting everthing back to itsplace

// Finishing off very little detailed things that are some little feature that need fixing
// Fixing the character inputs asell
