import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/translated_text.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/shared_app_bar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBg,
      appBar: const SharedAppBar(title: 'Recover Account'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1A24)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            _StepIndicator(currentStep: _currentStep),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: GlassCard(
                      padding: const EdgeInsets.all(32),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: KeyedSubtree(
                          key: ValueKey(_currentStep),
                          child: _buildCurrentStep(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (_currentStep) {
      case 1:
        return _ForgotPasswordStep(
          icon: Icons.manage_accounts_outlined,
          title: 'Find your account',
          subtitle: 'Enter the email address linked to your account.',
          fields: const [
            _FieldSpec(label: 'Email Address', icon: Icons.email_outlined),
          ],
          primaryLabel: 'Continue',
          secondaryLabel: 'Back to Login',
          onPrimary: () => setState(() => _currentStep = 2),
          onSecondary: () => context.go('/login'),
        );
      case 2:
        return _ForgotPasswordStep(
          icon: Icons.shield_outlined,
          title: 'Verify your identity',
          subtitle:
              'Answer your security questions to confirm account ownership.',
          fields: const [
            _FieldSpec(
              label: "What is your mother's maiden name?",
              icon: Icons.help_outline,
            ),
            _FieldSpec(
              label: "What was the name of your first pet?",
              icon: Icons.pets_outlined,
            ),
            _FieldSpec(
              label: 'What city were you born in?',
              icon: Icons.location_city_outlined,
            ),
          ],
          primaryLabel: 'Verify Identity',
          secondaryLabel: 'Back',
          onPrimary: () => setState(() => _currentStep = 3),
          onSecondary: () => setState(() => _currentStep = 1),
        );
      default:
        return _ForgotPasswordStep(
          icon: Icons.lock_reset_outlined,
          title: 'Set a new password',
          subtitle: 'Choose a strong password you have not used before.',
          fields: const [
            _FieldSpec(
              label: 'New Password',
              icon: Icons.lock_outline,
              obscureText: true,
            ),
          ],
          primaryLabel: 'Reset Password',
          onPrimary: () => context.go('/login'),
        );
    }
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const steps = ['Email', 'Verify', 'Reset'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepIndex = (index ~/ 2) + 2;
            return Expanded(
              child: Container(
                height: 1.5,
                color: currentStep >= stepIndex
                    ? AppTheme.kAccent.withOpacity(0.8)
                    : Colors.white.withOpacity(0.12),
              ),
            );
          }

          final stepIndex = (index ~/ 2) + 1;
          final isActive = currentStep == stepIndex;
          final isDone = currentStep > stepIndex;

          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? AppTheme.kAccent
                      : isActive
                      ? AppTheme.kAccent.withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: (isActive || isDone)
                        ? AppTheme.kAccent
                        : Colors.white.withOpacity(0.12),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '$stepIndex',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive ? AppTheme.kAccent : Colors.white38,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              TranslatedText(
                steps[stepIndex - 1],
                style: TextStyle(
                  fontSize: 11,
                  color: (isActive || isDone) ? Colors.white70 : Colors.white30,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ForgotPasswordStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_FieldSpec> fields;
  final String primaryLabel;
  final String? secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;

  const _ForgotPasswordStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.kAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.kAccent.withOpacity(0.25)),
          ),
          child: Icon(icon, color: AppTheme.kAccent, size: 26),
        ),
        const SizedBox(height: 16),
        TranslatedText(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        TranslatedText(
          subtitle,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        for (var i = 0; i < fields.length; i++) ...[
          TextField(
            obscureText: fields[i].obscureText,
            decoration: InputDecoration(
              label: TranslatedText(fields[i].label),
              prefixIcon: Icon(fields[i].icon),
            ),
          ),
          if (i != fields.length - 1) const SizedBox(height: 12),
        ],
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: onPrimary,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            backgroundColor: AppTheme.kAccent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: TranslatedText(
            primaryLabel,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        if (secondaryLabel != null && onSecondary != null) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: onSecondary,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white54,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: TranslatedText(
              secondaryLabel!,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }
}

class _FieldSpec {
  final String label;
  final IconData icon;
  final bool obscureText;

  const _FieldSpec({
    required this.label,
    required this.icon,
    this.obscureText = false,
  });
}
