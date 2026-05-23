import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_controller.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/localization.dart';
import '../../../core/widgets/shared_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/auth_domain.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  final _q1Controller = TextEditingController();
  final _q2Controller = TextEditingController();
  final _q3Controller = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String? _selectedRole;

  // #region debug-point A:report-auth-state
  void _debugReport(String location, Map<String, Object?> data) {
    Future<void>(() async {
      try {
        final client = HttpClient();
        final request =
            await client.postUrl(Uri.parse('http://192.168.1.9:7777/event'));
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode({
          'sessionId': 'signup-async-loading',
          'runId': 'pre-fix',
          'hypothesisId': 'A',
          'location': location,
          'msg': '[DEBUG] signup auth state probe',
          'data': data,
          'ts': DateTime.now().millisecondsSinceEpoch,
        }));
        await request.close();
        client.close(force: true);
      } catch (_) {}
    });
  }
  // #endregion

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _q1Controller.dispose();
    _q2Controller.dispose();
    _q3Controller.dispose();
    super.dispose();
  }

  void _signup() async {
    if (_formKey.currentState!.validate() && _selectedRole != null) {
      final selectedRole = _selectedRole!;
      final shouldSignInAfterSignUp =
          selectedRole == AppConstants.roleContributor;

      await ref.read(authControllerProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            role: selectedRole,
            displayName: _nameController.text.trim(),
            securityAnswers: [
              _q1Controller.text.trim(),
              _q2Controller.text.trim(),
              _q3Controller.text.trim(),
            ],
            signInAfterSignUp: shouldSignInAfterSignUp,
          );

      if (!mounted) {
        return;
      }

      final authState = ref.read(authControllerProvider);
      if (authState.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: TranslatedText('Signup Failed: ${authState.error}'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }

      if (selectedRole == AppConstants.roleViewer) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: TranslatedText(
              'Account created successfully. Please sign in.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final currentLang = ref.watch(languageProvider);
    // #region debug-point A:signup-build
    _debugReport('signup_screen.dart:build', {
      'authStateType': authState.runtimeType.toString(),
      'selectedRole': _selectedRole,
      'isAsyncLoading': authState is AsyncLoading<void>,
      'isAsyncData': authState is AsyncData<void>,
      'hasError': authState.hasError,
    });
    // #endregion

    return Scaffold(
      backgroundColor: AppTheme.kBg,
      extendBodyBehindAppBar: true,
      appBar: SharedAppBar(
        title: 'Create Account',
        showProfile: false,
        switcherOnRight: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TranslatedText(
                    'Create an account',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const TranslatedText(
                    'Fill in your details below to get started.',
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                  const SizedBox(height: 36),

                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    validatorMsg: 'Name is required',
                    currentLang: currentLang,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    validatorMsg: 'Email is required',
                    currentLang: currentLang,
                    validator: (value) => EmailAddress.isValid(value ?? '')
                        ? null
                        : getTranslatedSync('Email is required', currentLang),
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    validatorMsg: 'Minimum 6 characters',
                    isObscure: true,
                    minLength: 6,
                    currentLang: currentLang,
                    validator: (value) => Password.isValid(value ?? '')
                        ? null
                        : getTranslatedSync('Minimum 6 characters', currentLang),
                  ),

                  const SizedBox(height: 28),

                  const TranslatedText(
                    'I AM JOINING AS A',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white38, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildRoleTab(AppConstants.roleViewer, 'Viewer')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildRoleTab(AppConstants.roleContributor, 'Contributor')),
                    ],
                  ),

                  // security questions — slide down after role is picked
                  AnimatedSize(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    child: _selectedRole == null
                        ? const SizedBox.shrink()
                        : _buildSecurityBlock(authState, currentLang),
                  ),

                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const TranslatedText('Already have an account? ', style: TextStyle(color: Colors.white54, fontSize: 14)),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.kAccent,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const TranslatedText('Sign In', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String role, String label) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.kAccent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.kAccent : Colors.white.withOpacity(0.15),
          ),
        ),
        child: TranslatedText(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppTheme.kAccent : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityBlock(AsyncValue<void> authState, String lang) {
    // #region debug-point D:security-block
    _debugReport('signup_screen.dart:_buildSecurityBlock', {
      'authStateType': authState.runtimeType.toString(),
      'selectedRole': _selectedRole,
      'isAsyncLoading': authState is AsyncLoading<void>,
      'isDynamic': false,
    });
    // #endregion
    final isSubmitting = authState is AsyncLoading<void>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        const Divider(color: Colors.white12),
        const SizedBox(height: 20),
        const TranslatedText(
          'Account Recovery',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const TranslatedText(
          'Answer these questions so you can recover your account if you forget your password.',
          style: TextStyle(fontSize: 13, color: Colors.white38, height: 1.5),
        ),
        const SizedBox(height: 20),
        _buildTextField(controller: _q1Controller, label: "Mother's maiden name", validatorMsg: 'Required', currentLang: lang),
        const SizedBox(height: 12),
        _buildTextField(controller: _q2Controller, label: "First pet's name", validatorMsg: 'Required', currentLang: lang),
        const SizedBox(height: 12),
        _buildTextField(controller: _q3Controller, label: 'City you were born in', validatorMsg: 'Required', currentLang: lang),
        const SizedBox(height: 28),
        isSubmitting
            ? const Center(child: CircularProgressIndicator(color: AppTheme.kAccent, strokeWidth: 2))
            : ElevatedButton(
                onPressed: _signup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: AppTheme.kAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const TranslatedText(
                  'Create Account',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String validatorMsg,
    required String currentLang,
    bool isObscure = false,
    int minLength = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        label: TranslatedText(label),
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: AppTheme.kAccent, fontSize: 13),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.kAccent, width: 1.5)),
        errorStyle: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
      ),
      validator: (value) {
        if (validator != null) {
          return validator(value);
        }
        if (value == null || value.trim().length < minLength) {
          return getTranslatedSync(validatorMsg, currentLang);
        }
        return null;
      },
    );
  }
}
