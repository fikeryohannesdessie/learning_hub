import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_controller.dart';
import '../../../../core/localization/translated_text.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_app_bar.dart';
import '../domain/auth_domain.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _q1Controller = TextEditingController();
  final _q2Controller = TextEditingController();
  final _q3Controller = TextEditingController();

  String _selectedRole = 'contributor';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _q1Controller.dispose();
    _q2Controller.dispose();
    _q3Controller.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref.read(authControllerProvider.notifier).signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      role: _selectedRole,
      displayName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      securityAnswers: <String>[
        _q1Controller.text.trim(),
        _q2Controller.text.trim(),
        _q3Controller.text.trim(),
      ],
    );

    if (!mounted) {
      return;
    }

    final authState = ref.read(authControllerProvider);
    if (authState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Create account failed: ${authState.error}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_selectedRole == 'contributor') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created. Please submit your verification.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.kBg,
      extendBodyBehindAppBar: true,
      appBar: const SharedAppBar(
        title: 'Create Account',
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
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const TranslatedText(
                    'Fill in your details below to get started.',
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                  const SizedBox(height: 36),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      label: TranslatedText('Full Name'),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      label: TranslatedText('Email'),
                    ),
                    validator: (value) => EmailAddress.isValid(value ?? '')
                        ? null
                        : 'Enter a valid email',
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      label: const TranslatedText('Password'),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => Password.isValid(value ?? '')
                        ? null
                        : 'Password must be at least 6 characters',
                  ),
                  const SizedBox(height: 28),
                  const TranslatedText(
                    'I AM JOINING AS A',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white38,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _RoleTab(
                          label: 'Viewer',
                          isSelected: _selectedRole == 'viewer',
                          onTap: () => setState(() => _selectedRole = 'viewer'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RoleTab(
                          label: 'Contributor',
                          isSelected: _selectedRole == 'contributor',
                          onTap: () =>
                              setState(() => _selectedRole = 'contributor'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 20),
                  const TranslatedText(
                    'Account Recovery',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const TranslatedText(
                    'Answer these questions so you can recover your account if you forget your password.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white38,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _q1Controller,
                    decoration: const InputDecoration(
                      label: TranslatedText("Mother's maiden name"),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Answer this question';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _q2Controller,
                    decoration: const InputDecoration(
                      label: TranslatedText("First pet's name"),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Answer this question';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _q3Controller,
                    decoration: const InputDecoration(
                      label: TranslatedText('City you were born in'),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Answer this question';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  authState.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.kAccent,
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _createAccount,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: AppTheme.kAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const TranslatedText(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const TranslatedText(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.kAccent,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const TranslatedText(
                          'Sign In',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
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
}

class _RoleTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.kAccent.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.kAccent
                : Colors.white.withValues(alpha: 0.15),
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
}
