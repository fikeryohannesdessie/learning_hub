import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/translated_text.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_app_bar.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  String? _selectedRole = 'contributor';

  @override
  Widget build(BuildContext context) {
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
                const TextField(
                  decoration: InputDecoration(label: TranslatedText('Full Name')),
                ),
                const SizedBox(height: 14),
                const TextField(
                  decoration: InputDecoration(label: TranslatedText('Email')),
                ),
                const SizedBox(height: 14),
                const TextField(
                  obscureText: true,
                  decoration: InputDecoration(label: TranslatedText('Password')),
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
                AnimatedSize(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  child: _selectedRole == null
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                            const TextField(
                              decoration: InputDecoration(
                                label: TranslatedText("Mother's maiden name"),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const TextField(
                              decoration: InputDecoration(
                                label: TranslatedText("First pet's name"),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const TextField(
                              decoration: InputDecoration(
                                label: TranslatedText('City you were born in'),
                              ),
                            ),
                            const SizedBox(height: 28),
                            ElevatedButton(
                              onPressed: () => context.go(
                                _selectedRole == 'contributor'
                                    ? '/verify-contributor'
                                    : '/home',
                              ),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
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
                          ],
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
              ? AppTheme.kAccent.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.kAccent
                : Colors.white.withOpacity(0.15),
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
