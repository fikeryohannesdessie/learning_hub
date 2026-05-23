import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_controller.dart';
import '../../../core/localization/localization.dart';
import '../../../core/widgets/shared_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/auth_domain.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  int _currentStep = 1;

  final _emailController = TextEditingController();
  final _q1Controller = TextEditingController();
  final _q2Controller = TextEditingController();
  final _q3Controller = TextEditingController();
  final _newPasswordController = TextEditingController();

  final _emailFormKey = GlobalKey<FormState>();
  final _securityFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailController.dispose();
    _q1Controller.dispose();
    _q2Controller.dispose();
    _q3Controller.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _verifyEmail() {
    if (_emailFormKey.currentState!.validate()) {
      setState(() {
        _errorMsg = null;
        _currentStep = 2;
      });
    }
  }

  Future<void> _verifySecurityAnswers() async {
    if (_securityFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMsg = null;
      });

      final isVerified = await ref.read(authControllerProvider.notifier).verifySecurityAnswers(
        _emailController.text.trim(),
        [
          _q1Controller.text.trim(),
          _q2Controller.text.trim(),
          _q3Controller.text.trim(),
        ],
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (isVerified) {
          setState(() => _currentStep = 3);
        } else {
          setState(() => _errorMsg = 'Incorrect answers. Please try again.');
        }
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_passwordFormKey.currentState!.validate()) {
      await ref.read(authControllerProvider.notifier).resetPassword(
        _emailController.text.trim(),
        _newPasswordController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      final authState = ref.read(authControllerProvider);

      if (!authState.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: TranslatedText('Password reset successfully! You can now log in.'),
          backgroundColor: Colors.green,
        ));
        context.go('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: TranslatedText('Failed to reset password: ${authState.error}'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: AppTheme.kBg,
      appBar: SharedAppBar(
        title: getTranslatedSync('Recover Account', currentLang),
        showProfile: false,
      ),
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
            // Step indicator
            _buildStepIndicator(currentLang),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: GlassCard(
                      padding: const EdgeInsets.all(32.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(_currentStep),
                          child: _buildCurrentStep(currentLang),
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

  Widget _buildStepIndicator(String lang) {
    const steps = ['Email', 'Verify', 'Reset'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = (i ~/ 2) + 2;
            return Expanded(
              child: Container(
                height: 1.5,
                color: _currentStep >= stepIndex
                    ? AppTheme.kAccent.withOpacity(0.8)
                    : Colors.white.withOpacity(0.12),
              ),
            );
          }
          final stepIndex = (i ~/ 2) + 1;
          final isActive = _currentStep == stepIndex;
          final isDone = _currentStep > stepIndex;
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
                    color: (isActive || isDone) ? AppTheme.kAccent : Colors.white.withOpacity(0.12),
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

  Widget _buildCurrentStep(String lang) {
    switch (_currentStep) {
      case 1: return _buildStep1Email(lang);
      case 2: return _buildStep2Security(lang);
      case 3: return _buildStep3NewPassword(lang);
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildStep1Email(String lang) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepHeader(
            icon: Icons.manage_accounts_outlined,
            title: 'Find your account',
            subtitle: 'Enter the email address linked to your account.',
          ),
          const SizedBox(height: 28),
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            validatorMsg: 'Please enter your email',
            currentLang: lang,
            validator: (value) => EmailAddress.isValid(value ?? '')
                ? null
                : getTranslatedSync('Please enter your email', lang),
          ),
          const SizedBox(height: 28),
          _primaryButton(label: 'Continue', onPressed: _verifyEmail),
          const SizedBox(height: 12),
          _ghostButton(label: 'Back to Login', onPressed: () => context.go('/login')),
        ],
      ),
    );
  }

  Widget _buildStep2Security(String lang) {
    return Form(
      key: _securityFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepHeader(
            icon: Icons.shield_outlined,
            title: 'Verify your identity',
            subtitle: 'Answer your security questions to confirm account ownership.',
          ),
          if (_errorMsg != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                   const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: TranslatedText(getTranslatedSync(_errorMsg!, lang), style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          _questionField(number: 1, controller: _q1Controller, question: "What is your mother's maiden name?", currentLang: lang),
          const SizedBox(height: 12),
          _questionField(number: 2, controller: _q2Controller, question: "What was the name of your first pet?", currentLang: lang),
          const SizedBox(height: 12),
          _questionField(number: 3, controller: _q3Controller, question: "What city were you born in?", currentLang: lang),
          const SizedBox(height: 28),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.kAccent, strokeWidth: 2))
              : _primaryButton(label: 'Verify Identity', onPressed: _verifySecurityAnswers),
          const SizedBox(height: 12),
          _ghostButton(label: 'Back', onPressed: () => setState(() => _currentStep = 1)),
        ],
      ),
    );
  }

  Widget _buildStep3NewPassword(String lang) {
    final authState = ref.watch(authControllerProvider);
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepHeader(
            icon: Icons.lock_reset_outlined,
            title: 'Set a new password',
            subtitle: 'Choose a strong password you haven\'t used before.',
          ),
          const SizedBox(height: 28),
          _buildTextField(
            controller: _newPasswordController,
            label: 'New Password',
            validatorMsg: 'Minimum 6 characters',
            isObscure: true,
            minLength: 6,
            currentLang: lang,
            validator: (value) => Password.isValid(value ?? '')
                ? null
                : getTranslatedSync('Minimum 6 characters', lang),
          ),
          const SizedBox(height: 28),
          authState.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.kAccent, strokeWidth: 2))
              : _primaryButton(label: 'Reset Password', onPressed: _resetPassword),
        ],
      ),
    );
  }

  Widget _stepHeader({required IconData icon, required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3),
        ),
        const SizedBox(height: 6),
        TranslatedText(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.5)),
      ],
    );
  }

  Widget _questionField({required int number, required TextEditingController controller, required String question, required String currentLang}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.kAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: Text('$number', style: const TextStyle(color: AppTheme.kAccent, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TranslatedText(question, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ),
            ],
          ),
        ),
        _buildTextField(controller: controller, label: 'Your answer', validatorMsg: 'Required', currentLang: currentLang),
      ],
    );
  }

  Widget _primaryButton({required String label, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
        backgroundColor: AppTheme.kAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: TranslatedText(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
    );
  }

  Widget _ghostButton({required String label, required VoidCallback onPressed}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white54,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: TranslatedText(label, style: const TextStyle(fontSize: 14)),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.kAccent, width: 1.5)),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
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
