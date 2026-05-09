import 'package:flutter/material.dart';

import '../../../core/localization/translated_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/floating_island_nav.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/shared_app_bar.dart';

class ViewerDashboard extends StatefulWidget {
  const ViewerDashboard({super.key});

  @override
  State<ViewerDashboard> createState() => _ViewerDashboardState();
}

class _ViewerDashboardState extends State<ViewerDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _navIndex = 0;

  static const _items = [
    FloatingNavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Explore',
    ),
    FloatingNavItem(
      icon: Icons.museum_outlined,
      activeIcon: Icons.museum,
      label: 'Exhibits',
    ),
    FloatingNavItem(
      icon: Icons.auto_stories_outlined,
      activeIcon: Icons.auto_stories,
      label: 'Docs',
    ),
    FloatingNavItem(
      icon: Icons.psychology_outlined,
      activeIcon: Icons.psychology,
      label: 'Challenges',
    ),
    FloatingNavItem(
      icon: Icons.history_edu_outlined,
      activeIcon: Icons.history_edu,
      label: 'Notes',
    ),
    FloatingNavItem(
      icon: Icons.favorite_border,
      activeIcon: Icons.favorite,
      label: 'Saved',
      badgeCount: 3,
    ),
    FloatingNavItem(
      icon: Icons.view_in_ar_outlined,
      activeIcon: Icons.view_in_ar,
      label: '3D',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBg,
      extendBody: true,
      appBar: SharedAppBar(
        title: 'CHPA Heritage',
        switcherOnRight: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              child: TranslatedText(
                'TANGIBLE',
                style: TextStyle(letterSpacing: 1.2),
              ),
            ),
            Tab(
              child: TranslatedText(
                'INTANGIBLE',
                style: TextStyle(letterSpacing: 1.2),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.6),
                  radius: 0.8,
                  colors: [
                    AppTheme.kAccent.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          TabBarView(
            controller: _tabController,
            children: [
              _DashboardSection(
                classification: 'TANGIBLE',
                navIndex: _navIndex,
              ),
              _DashboardSection(
                classification: 'INTANGIBLE',
                navIndex: _navIndex,
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingIslandNav(
              items: _items,
              currentIndex: _navIndex,
              onTap: (index) {
                if (index == 6) {
                  setState(() => _navIndex = index);
                } else {
                  setState(() => _navIndex = index);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  final String classification;
  final int navIndex;

  const _DashboardSection({
    required this.classification,
    required this.navIndex,
  });

  static const _artifactCards = [
    _ArtifactCardData(
      title: 'Lalibela Stone Churches',
      subtitle: '7 Themes',
      author: 'Aster Kebede',
      tag: 'TANGIBLE',
    ),
    _ArtifactCardData(
      title: 'Axum Obelisk Archive',
      subtitle: '5 Themes',
      author: 'Daniel Bekele',
      tag: 'TANGIBLE',
    ),
    _ArtifactCardData(
      title: 'Harar Gateways',
      subtitle: '6 Themes',
      author: 'Mahi Abebe',
      tag: 'TANGIBLE',
    ),
    _ArtifactCardData(
      title: 'Coffee Ceremony Memory',
      subtitle: '4 Themes',
      author: 'Sara Tadesse',
      tag: 'INTANGIBLE',
    ),
  ];

  static const _documents = [
    _ContentCardData(
      title: 'Site Preservation Charter',
      subject: 'Archival Document',
      icon: Icons.article_outlined,
      color: AppTheme.kTerracotta,
    ),
    _ContentCardData(
      title: 'UNESCO Field Report',
      subject: 'Research File',
      icon: Icons.assignment_outlined,
      color: AppTheme.kAncientBlue,
    ),
  ];

  static const _challenges = [
    _ContentCardData(
      title: 'Artifact Attribution Challenge',
      subject: 'Critical Thinking',
      icon: Icons.psychology_outlined,
      color: AppTheme.kAccent,
    ),
    _ContentCardData(
      title: 'Ritual Timeline Match',
      subject: 'Interactive Quiz',
      icon: Icons.extension_outlined,
      color: AppTheme.kAncientBlue,
    ),
  ];

  static const _notes = [
    _ContentCardData(
      title: 'Field Note Summary',
      subject: 'Research Notes',
      icon: Icons.history_edu_outlined,
      color: AppTheme.kAncientBlue,
    ),
    _ContentCardData(
      title: 'Conservation Checklist',
      subject: 'Worksheet',
      icon: Icons.checklist_rounded,
      color: AppTheme.kTerracotta,
    ),
  ];

  static const _saved = [
    _SavedItemData(
      title: 'Aksumite Coins Collection',
      typeLabel: 'Artifact',
      icon: Icons.account_balance_outlined,
      color: AppTheme.kAccent,
    ),
    _SavedItemData(
      title: 'Oral Traditions Primer',
      typeLabel: 'Document',
      icon: Icons.article_outlined,
      color: AppTheme.kTerracotta,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (navIndex == 0 || navIndex == 1 || navIndex == 2) ...[
            _buildHero(),
            const SizedBox(height: 24),
          ],
          if (navIndex == 0 || navIndex == 1) ...[
            const _SectionHeader(
              title: 'Featured Exhibits',
              actionLabel: 'Show All',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 212,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final card = _artifactCards[
                      classification == 'TANGIBLE' ? index : (index + 1) % 4];
                  return _ArtifactCard(card: card);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (navIndex == 0 || navIndex == 2) ...[
            const _SectionHeader(title: 'Archival Documents'),
            const SizedBox(height: 12),
            _HorizontalContentList(items: _documents),
            const SizedBox(height: 24),
          ],
          if (navIndex == 0 || navIndex == 6) ...[
            const _SectionHeader(title: '3D Heritage Explorer'),
            const SizedBox(height: 12),
            const _Artifact3DCard(),
            const SizedBox(height: 24),
          ],
          if (navIndex == 0 || navIndex == 3) ...[
            const _SectionHeader(title: 'Heritage Challenges'),
            const SizedBox(height: 12),
            _HorizontalContentList(items: _challenges),
            const SizedBox(height: 24),
          ],
          if (navIndex == 0 || navIndex == 4) ...[
            const _SectionHeader(title: 'Research Notes'),
            const SizedBox(height: 12),
            _HorizontalContentList(items: _notes),
            const SizedBox(height: 24),
          ],
          if (navIndex == 5) ...[
            const _SectionHeader(title: 'Personal Collection'),
            const SizedBox(height: 12),
            ..._saved.map((item) => _SavedTile(item: item)),
          ],
          if (navIndex == 0 || navIndex == 5 || navIndex == 6) ...[
            const SizedBox(height: 24),
          ],
          if (navIndex == 0) ...[
            const _SectionHeader(title: 'Personal Collection'),
            const SizedBox(height: 12),
            ..._saved.map((item) => _SavedTile(item: item)),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return GlassCard(
      frosted: true,
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      glowColor: AppTheme.kAccent,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.kAccent, AppTheme.kTerracotta],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.account_balance,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back,',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.kParchment.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Heritage Explorer',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.kParchment,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;

  const _SectionHeader({
    required this.title,
    this.actionLabel = 'See All',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
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
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {},
          child: Row(
            children: [
              TranslatedText(
                actionLabel,
                style: const TextStyle(color: AppTheme.kAccent, fontSize: 13),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppTheme.kAccent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ArtifactCard extends StatelessWidget {
  final _ArtifactCardData card;

  const _ArtifactCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 18,
        color: const Color(0xFF17120D),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF3B2A1A),
                      AppTheme.kTerracotta.withOpacity(0.82),
                      AppTheme.kAncientBlue.withOpacity(0.72),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: -18,
                      right: -10,
                      child: Icon(
                        Icons.architecture_rounded,
                        size: 88,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    Positioned(
                      bottom: -10,
                      left: -6,
                      child: Icon(
                        Icons.travel_explore_rounded,
                        size: 82,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: TranslatedText(
                              card.tag,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.account_balance_rounded,
                            size: 34,
                            color: Colors.white70,
                          ),
                          const SizedBox(height: 10),
                          TranslatedText(
                            'Cultural heritage',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.88),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    card.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.kParchment,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.layers_outlined,
                        size: 14,
                        color: AppTheme.kParchment.withOpacity(0.55),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TranslatedText(
                          card.subtitle,
                          style: TextStyle(
                            color: AppTheme.kParchment.withOpacity(0.62),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: AppTheme.kParchment.withOpacity(0.55),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TranslatedText(
                          card.author,
                          style: TextStyle(
                            color: AppTheme.kParchment.withOpacity(0.62),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalContentList extends StatelessWidget {
  final List<_ContentCardData> items;

  const _HorizontalContentList({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, index) => _ContentCard(item: items[index]),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final _ContentCardData item;

  const _ContentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      item.color.withOpacity(0.3),
                      item.color.withOpacity(0.55),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(item.icon, size: 44, color: Colors.white70),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TranslatedText(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.kParchment,
                    ),
                  ),
                  TranslatedText(
                    item.subject,
                    style: TextStyle(
                      color: AppTheme.kParchment.withOpacity(0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Artifact3DCard extends StatelessWidget {
  const _Artifact3DCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppTheme.kAncientBlue.withOpacity(0.7),
              AppTheme.kAccent.withOpacity(0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppTheme.kAccent.withOpacity(0.3)),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.view_in_ar_rounded,
                size: 80,
                color: Colors.white24,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      'Ancient Artifact Survey',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TranslatedText(
                      'Interactive Heritage Simulation',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.kAccent.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, size: 14, color: Colors.black),
                    SizedBox(width: 4),
                    Text(
                      'Launch 3D',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedTile extends StatelessWidget {
  final _SavedItemData item;

  const _SavedTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 16,
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, color: item.color),
        ),
        title: TranslatedText(
          item.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.kParchment,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: TranslatedText(
            item.typeLabel,
            style: TextStyle(
              color: item.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: Icon(
          Icons.bookmark_remove,
          color: AppTheme.kParchment.withOpacity(0.4),
        ),
      ),
    );
  }
}

class _ArtifactCardData {
  final String title;
  final String subtitle;
  final String author;
  final String tag;

  const _ArtifactCardData({
    required this.title,
    required this.subtitle,
    required this.author,
    required this.tag,
  });
}

class _ContentCardData {
  final String title;
  final String subject;
  final IconData icon;
  final Color color;

  const _ContentCardData({
    required this.title,
    required this.subject,
    required this.icon,
    required this.color,
  });
}

class _SavedItemData {
  final String title;
  final String typeLabel;
  final IconData icon;
  final Color color;

  const _SavedItemData({
    required this.title,
    required this.typeLabel,
    required this.icon,
    required this.color,
  });
}
