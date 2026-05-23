import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/language_switcher.dart';
import '../../../../core/localization/translated_text.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';

class ContributorVerificationScreen extends StatelessWidget {
  const ContributorVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => context.go('/login'),
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
                const Icon(
                  Icons.verified_user,
                  size: 80,
                  color: AppTheme.kAccent,
                ),
                const SizedBox(height: 24),
                Text(
                  'Verify Your Account',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const TranslatedText(
                  'To ensure the authenticity of our heritage records, contributors must verify their identities before publishing artifacts.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                const TextField(
                  decoration: InputDecoration(
                    label: TranslatedText('Institution / Archive'),
                    prefixIcon: Icon(Icons.account_balance_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
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
                      ListTile(
                        leading: const Icon(
                          Icons.file_present,
                          color: Colors.white,
                        ),
                        title: const TranslatedText(
                          'credential-placeholder.pdf',
                          style: TextStyle(color: Colors.white),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {},
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.upload_file),
                        label: const TranslatedText('Pick File'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    AppRouter.currentUserRole = 'contributor';
                    context.go('/contributor-dashboard');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.kAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const TranslatedText('Submit for Review'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
