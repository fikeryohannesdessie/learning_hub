import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_controller.dart';
import '../../../core/localization/localization.dart';
import '../../../core/widgets/heritage_logo.dart';
import '../../../core/widgets/shared_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/auth_domain.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authControllerProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      if (!mounted) {
        return;
      }
      final authState = ref.read(authControllerProvider);
      if (authState.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TranslatedText('Login Failed: ${authState.error}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.kBg,
      extendBodyBehindAppBar: true,
      appBar: SharedAppBar(
        showProfile: false,
        switcherOnRight: true,
      ),
      body: Stack(
        children: [
          // ── Background radial ambient glow ─────────────────────────────
          Positioned(
            top: -size.height * 0.15,
            left: size.width * 0.5 - 200,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.kAccent.withOpacity(0.20),
                    AppTheme.kTerracotta.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Bottom warm glow
          Positioned(
            bottom: -80,
            left: size.width * 0.5 - 160,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.kTerracotta.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ───────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 32),
                  child: Column(
                    children: [
                      // Logo + branding
                      const AnimatedHeritageLogoWidget(size: 88),
                      const SizedBox(height: 20),
                      const Text(
                        'CHPA',
                        style: TextStyle(
                          color: AppTheme.kAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const TranslatedText(
                        'Cultural Heritage\nProtection Authority',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.kParchment,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TranslatedText(
                        'Preserving our shared heritage',
                        style: TextStyle(
                          color: AppTheme.kParchment.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // ── Login card ─────────────────────────────────────
                      GlassCard(
                        frosted: true,
                        borderRadius: 24,
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const TranslatedText(
                                'Welcome Back',
                                style: TextStyle(
                                  color: AppTheme.kParchment,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),

                              // Email
                              TextFormField(
                                controller: _emailController,
                                keyboardType:
                                    TextInputType.emailAddress,
                                style: const TextStyle(
                                    color: AppTheme.kParchment),
                                decoration: const InputDecoration(
                                  label: TranslatedText('Email'),
                                  hintText: 'your@email.com',
                                  prefixIcon:
                                      Icon(Icons.email_outlined),
                                ),
                                validator: (v) => EmailAddress.isValid(v ?? '')
                                    ? null
                                    : 'Enter email',
                              ),
                              const SizedBox(height: 16),

                              // Password
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                    color: AppTheme.kParchment),
                                decoration: InputDecoration(
                                  label: const TranslatedText('Password'),
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppTheme.kParchment
                                          .withOpacity(0.5),
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword),
                                  ),
                                ),
                                validator: (v) => Password.isValid(v ?? '')
                                    ? null
                                    : 'Password too short',
                              ),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      context.push('/forgot-password'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const TranslatedText(
                                    'Forgot Password?',
                                    style: TextStyle(
                                        color: AppTheme.kAccent,
                                        fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Login button
                              authState.isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                          color: AppTheme.kAccent),
                                    )
                                  : ElevatedButton(
                                      onPressed: _login,
                                      child:
                                          const TranslatedText('Sign In'),
                                    ),
                              const SizedBox(height: 16),

                              // Sign up
                              TextButton(
                                onPressed: () =>
                                    context.push('/signup'),
                                child: Wrap(
                                  children: const [
                                    TranslatedText(
                                      "Don't have an account? ",
                                      style: TextStyle(color: Colors.white60, fontSize: 14),
                                    ),
                                    TranslatedText(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: AppTheme.kAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
