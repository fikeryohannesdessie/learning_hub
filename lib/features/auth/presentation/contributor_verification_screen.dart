import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/auth_controller.dart';
import '../../content/provider/content_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/translated_text.dart';
import '../../../core/localization/language_switcher.dart';
import '../../../core/widgets/glass_card.dart';

class ContributorVerificationScreen extends ConsumerStatefulWidget {
  const ContributorVerificationScreen({super.key});

  @override
  ConsumerState<ContributorVerificationScreen> createState() =>
      _ContributorVerificationScreenState();
}

class _ContributorVerificationScreenState
    extends ConsumerState<ContributorVerificationScreen> {
  final _institutionController = TextEditingController();
  final _idNumberController = TextEditingController();
  PlatformFile? _credentialFile;
  bool _isSubmitting = false;
  bool _isEditing = false; // Toggle for resubmission form

  @override
  void dispose() {
    _institutionController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  void _pickCredential() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null) setState(() => _credentialFile = result.files.first);
  }

  void _submit() async {
    if (_credentialFile == null ||
        _idNumberController.text.isEmpty ||
        _institutionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TranslatedText(
            'Please fill all fields and upload a credential',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(userProvider);
      if (user == null) return;
      Uint8List? credentialBytes = _credentialFile!.bytes;
      if (credentialBytes == null && _credentialFile!.path != null) {
        credentialBytes = await io.File(_credentialFile!.path!).readAsBytes();
      }

      // Ensure the content type is correctly set
      final extension = _credentialFile!.extension?.toLowerCase();
      final contentType =
          (extension == 'jpg' || extension == 'jpeg' || extension == 'png')
          ? AppConstants.contentTypeImage
          : AppConstants.contentTypePDF;

      final content = LearningContent(
        id: 'verify_${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
        title: _institutionController.text.trim(),
        subject: 'Contributor Verification',
        type: contentType,
        authorId: user.uid,
        authorName: user.displayName ?? user.email,
        gradeLevel: _idNumberController.text.trim(),
        uploadedAt: DateTime.now(),
        status: AppConstants.statusPending,
      );

      await ref
          .read(contentControllerProvider.notifier)
          .uploadContent(content, bytes: credentialBytes);
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            institution: _institutionController.text.trim(),
            idNumber: _idNumberController.text.trim(),
            credentialFileId: content.id,
          );
      await ref
          .read(authControllerProvider.notifier)
          .submitVerification(user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TranslatedText(
              'Verification submitted! Admins will review it soon.',
            ),
          ),
        );
        setState(() {
          _isSubmitting = false;
          _isEditing = false; // Reset editing state after submission
        });
        // Optionally sign out or navigate away
        // ref.read(authControllerProvider.notifier).signOut();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: TranslatedText('Submission failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    // 1. Pending State
    if (user != null &&
        (user.verificationSubmitted ?? false) &&
        !(user.isRejected ?? false)) {
      return Scaffold(
        backgroundColor: AppTheme.kBg,
        appBar: AppBar(
          title: const TranslatedText('Verification Pending'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: const [LanguageSwitcher()],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: GlassCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.hourglass_empty,
                    size: 80,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  TranslatedText(
                    'Under Review',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Column(
                      children: [
                        TranslatedText(
                          'Your credentials are being reviewed by our administrators.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(height: 8),
                        TranslatedText(
                          'This usually takes 24–48 hours. Please check back later.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                    icon: const Icon(Icons.arrow_back),
                    label: const TranslatedText('Return to Login Screen'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 2. Main Form (Initial or Rejected)
    return Scaffold(
      backgroundColor: AppTheme.kBg,
      appBar: AppBar(
        title: const TranslatedText('Contributor Verification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          const LanguageSwitcher(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (user != null && (user.isRejected ?? false)) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const TranslatedText(
                              'Verification Not Approved',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const TranslatedText(
                          'Reason for rejection:',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TranslatedText(
                          user.verificationComment ??
                              'Please ensure your uploaded documents are clear and valid for Contributor identification.',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_isEditing)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: const Icon(Icons.edit_note),
                        label: const TranslatedText('Update My Information'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
                if (user != null &&
                    (!(user.isRejected ?? false) || _isEditing)) ...[
                  const Icon(
                    Icons.verified_user,
                    size: 80,
                    color: AppTheme.kAccent,
                  ),
                  const SizedBox(height: 24),
                  TranslatedText(
                    (user.isRejected ?? false)
                        ? 'Update Your Credentials'
                        : 'Verify Your Account',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const TranslatedText(
                    'To ensure the authenticity of our heritage records, contributors must verify their identities before publishing artifacts.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _institutionController,
                    decoration: const InputDecoration(
                      label: TranslatedText('Institution / Archive'),
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _idNumberController,
                    decoration: const InputDecoration(
                      label: TranslatedText('Contributor Identity Number'),
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        const TranslatedText(
                          'Upload ID/Credential (PDF or Image)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (_credentialFile != null)
                          ListTile(
                            leading: const Icon(
                              Icons.file_present,
                              color: Colors.white,
                            ),
                            title: TranslatedText(
                              _credentialFile!.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () =>
                                  setState(() => _credentialFile = null),
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed: _pickCredential,
                          icon: const Icon(Icons.upload_file),
                          label: TranslatedText(
                            _credentialFile == null
                                ? 'Pick File'
                                : 'Change File',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _isSubmitting
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.kAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: TranslatedText(
                            (user.isRejected ?? false)
                                ? 'Resubmit for Review'
                                : 'Submit for Review',
                          ),
                        ),
                  if (_isEditing)
                    TextButton(
                      onPressed: () => setState(() => _isEditing = false),
                      child: const TranslatedText('Cancel Update'),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
