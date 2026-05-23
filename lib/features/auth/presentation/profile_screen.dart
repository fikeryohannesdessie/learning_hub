import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/localization.dart';
import '../../../core/widgets/shared_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/constants/app_constants.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _institutionController;
  late TextEditingController _idNumberController;
  late TextEditingController _bioController;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _nameController = TextEditingController(text: user?.displayName);
    _institutionController = TextEditingController(text: user?.institution);
    _idNumberController = TextEditingController(text: user?.idNumber);
    _bioController = TextEditingController(text: user?.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _idNumberController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = ref.read(userProvider);
      if (user != null) {
        await ref.read(authControllerProvider.notifier).updateProfile(
          displayName: _nameController.text.trim(),
          institution: _institutionController.text.trim(),
          idNumber: _idNumberController.text.trim(),
          bio: _bioController.text.trim(),
        );
        if (mounted) {
          setState(() {
            _isEditing = false;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: TranslatedText('Profile updated successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: TranslatedText('Error updating profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    final user = ref.watch(userProvider);
    final roleColor = user?.role == AppConstants.roleContributor
        ? AppTheme.kTerracotta
        : AppTheme.kAccent;

    return Scaffold(
      backgroundColor: AppTheme.kBg,
      extendBodyBehindAppBar: true,
      appBar: SharedAppBar(
        title: 'Heritage Profile',
        showProfile: false,
        extraActions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit_note, color: AppTheme.kParchment),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Ambient background gradient ─────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.7, -0.5),
                  radius: 1.2,
                  colors: [
                    AppTheme.kAccent.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.8, 0.4),
                  radius: 1.5,
                  colors: [
                    AppTheme.kAncientBlue.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ────────────────────────────────────────────────
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 80, 24, 40),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // ── Header Section ─────────────────────────────────────────
                  _buildProfileHeader(user, roleColor),
                  const SizedBox(height: 32),

                  // ── Personal Info Section ──────────────────────────────────
                  const _SectionTitle(title: 'PERSONAL INFORMATION'),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 20,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Display Name',
                          icon: Icons.person_outline,
                          enabled: _isEditing,
                          currentLang: currentLang,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _institutionController,
                          label: 'Institution',
                          icon: Icons.business_outlined,
                          enabled: _isEditing,
                          currentLang: currentLang,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── About Section ──────────────────────────────────────────
                  const _SectionTitle(title: 'DISCOVERY BIO'),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 20,
                    child: _buildTextField(
                      controller: _bioController,
                      label: user?.role == AppConstants.roleContributor
                          ? 'Professional Bio'
                          : 'About Me (Discovery Bio)',
                      icon: Icons.description_outlined,
                      enabled: _isEditing,
                      maxLines: 4,
                      isRequired: false,
                      currentLang: currentLang,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Actions Section ────────────────────────────────────────
                  if (_isEditing)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.kAccent,
                        foregroundColor: AppTheme.kBg,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: AppTheme.kAccent.withOpacity(0.3),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  color: AppTheme.kBg, strokeWidth: 2))
                          : const TranslatedText('SAVE CHANGES',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2)),
                    )
                  else ...[
                    _buildActionButton(
                      icon: Icons.logout,
                      label: 'SECURE LOG OUT',
                      color: AppTheme.kTerracotta,
                      onTap: () =>
                          ref.read(authControllerProvider.notifier).signOut(),
                    ),
                    if (user?.role != AppConstants.roleAdmin) ...[
                      const SizedBox(height: 16),
                      _buildActionButton(
                        icon: Icons.delete_forever,
                        label: 'Delete Account',
                        color: AppTheme.errorColor,
                        onTap: () =>
                            _showDeleteAccountDialog(context, currentLang),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user, Color roleColor) {
    if (user == null) return const SizedBox.shrink();

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.kAccent.withOpacity(0.2), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.kAccent.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    roleColor.withOpacity(0.2),
                    roleColor.withOpacity(0.05)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: roleColor.withOpacity(0.5), width: 2),
              ),
              child: Center(
                child: Text(
                  (user.displayName?.isNotEmpty == true
                          ? user.displayName![0]
                          : (user.email?.isNotEmpty == true ? user.email[0] : '?'))
                      .toUpperCase(),
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: roleColor,
                      letterSpacing: 1.2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          user.displayName ?? 'Heritage Explorer',
          style: const TextStyle(
            color: AppTheme.kParchment,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email ?? '',
          style: TextStyle(
              color: AppTheme.kParchment.withOpacity(0.5), fontSize: 14),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: roleColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: roleColor.withOpacity(0.3)),
          ),
          child: TranslatedText(
            (user.role as String? ?? '').toUpperCase(),
            style: TextStyle(
              color: roleColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        borderRadius: 16,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TranslatedText(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8),
              ),
             ),
            Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.3), size: 14),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, String lang) {
    final passwordController = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.kSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppTheme.errorColor.withOpacity(0.3))),
          title: const TranslatedText('Delete Account', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TranslatedText(
                'This action is permanent. Your data and artifacts will be removed. This cannot be undone.',
                style: TextStyle(color: AppTheme.kParchment, fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: AppTheme.kParchment),
                decoration: InputDecoration(
                  label: const TranslatedText('Confirm Password'),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(context),
              child: TranslatedText('Cancel', style: TextStyle(color: AppTheme.kParchment.withOpacity(0.6))),
            ),
            ElevatedButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      final password = passwordController.text.trim();
                      if (password.isEmpty) return;

                      setDialogState(() => isDeleting = true);
                      
                      final isCorrect = await ref.read(authControllerProvider.notifier).verifyPassword(password);
                      
                      if (isCorrect) {
                        await ref.read(authControllerProvider.notifier).deleteAccount();
                        if (context.mounted) Navigator.pop(context);
                      } else {
                        setDialogState(() => isDeleting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: TranslatedText(getTranslatedSync('Incorrect password', lang))),
                          );
                         }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: Colors.white),
              child: isDeleting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const TranslatedText('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String currentLang,
    bool enabled = true,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.kParchment, fontSize: 16),
      decoration: InputDecoration(
        label: TranslatedText(label),
        prefixIcon: Icon(icon, color: AppTheme.kAccent),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return getTranslatedSync('This field is required', currentLang);
        }
        return null;
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.kAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          TranslatedText(
            title,
            style: const TextStyle(
              color: AppTheme.kParchment,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}
