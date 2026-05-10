import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/translated_text.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/shared_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;

  String get _roleName {
    switch (AppRouter.currentUserRole) {
      case 'admin': return 'ADMINISTRATOR';
      case 'contributor': return 'CONTRIBUTOR';
      default: return 'VIEWER';
    }
  }

  String get _displayName {
    switch (AppRouter.currentUserRole) {
      case 'admin': return 'System Admin';
      case 'contributor': return 'Curator Name';
      default: return 'Heritage Explorer';
    }
  }

  String get _email {
    switch (AppRouter.currentUserRole) {
      case 'admin': return 'admin@chpa.org';
      case 'contributor': return 'curator@example.com';
      default: return 'explorer@example.com';
    }
  }

  String get _initial {
    switch (AppRouter.currentUserRole) {
      case 'admin': return 'A';
      case 'contributor': return 'C';
      default: return 'H';
    }
  }

  String get _homeRoute {
    switch (AppRouter.currentUserRole) {
      case 'admin': return '/admin-dashboard';
      case 'contributor': return '/contributor-dashboard';
      default: return '/home';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBg,
      extendBodyBehindAppBar: true,
      appBar: SharedAppBar(
        title: 'Heritage Profile',
        extraActions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit_note,
              color: AppTheme.kParchment,
            ),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: Stack(
        children: [
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
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 80,
              24,
              40,
            ),
            child: Column(
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 32),
                const _SectionTitle(title: 'PERSONAL INFORMATION'),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 20,
                  child: Column(
                    children: [
                      TextField(
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          label: TranslatedText('Display Name'),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          label: TranslatedText('Institution'),
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const _SectionTitle(title: 'DISCOVERY BIO'),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 20,
                  child: TextField(
                    enabled: _isEditing,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      label: TranslatedText('Professional Bio'),
                      prefixIcon: Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                if (_isEditing)
                  ElevatedButton(
                    onPressed: () => setState(() => _isEditing = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kAccent,
                      foregroundColor: AppTheme.kBg,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const TranslatedText(
                      'SAVE CHANGES',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  )
                else ...[
                  _ActionButton(
                    icon: Icons.logout,
                    label: 'SECURE LOG OUT',
                    color: AppTheme.kTerracotta,
                    onTap: () => context.go('/login'),
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon: Icons.delete_forever,
                    label: 'Delete Account',
                    color: AppTheme.errorColor,
                    onTap: () {},
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.go(_homeRoute),
                  child: const Text('Back To Home'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
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
                  color: AppTheme.kAccent.withOpacity(0.2),
                  width: 1,
                ),
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
                    AppTheme.kTerracotta.withOpacity(0.2),
                    AppTheme.kTerracotta.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppTheme.kTerracotta.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _initial,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.kTerracotta,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _displayName,
          style: const TextStyle(
            color: AppTheme.kParchment,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _email,
          style: TextStyle(
            color: AppTheme.kParchment.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.kTerracotta.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.kTerracotta.withOpacity(0.3)),
          ),
          child: TranslatedText(
            _roleName,
            style: const TextStyle(
              color: AppTheme.kTerracotta,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}