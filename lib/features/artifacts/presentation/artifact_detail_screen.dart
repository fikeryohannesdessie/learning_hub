import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../provider/artifact_controller.dart';
import '../domain/artifact_domain.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_controller.dart';
import '../../../core/localization/translated_text.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/shared_app_bar.dart';

class ArtifactDetailScreen extends ConsumerWidget {
  final Artifact artifact;

  const ArtifactDetailScreen({super.key, required this.artifact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final isEnrolled = artifact.viewerIds.contains(user?.uid);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.kBg,
        appBar: SharedAppBar(
          title: 'Heritage Info',
          bottom: TabBar(
            labelColor: AppTheme.kAccent,
            unselectedLabelColor: Colors.white54,
            indicatorColor: AppTheme.kAccent,
            tabs: const [
              Tab(child: TranslatedText('Overview')),
              Tab(child: TranslatedText('Flow')),
              Tab(child: TranslatedText('Expert')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            _buildPathTab(),
            _buildContributorTab(ref),
          ],
        ),
        bottomNavigationBar: _buildBottomAction(context, user, isEnrolled),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          const TranslatedText(
            'Scientific Importance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildHeritageOutcomes(),
          const SizedBox(height: 32),
          const TranslatedText(
            'Historical Narrative',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            artifact.detailedDescription?.isNotEmpty == true ? artifact.detailedDescription! : artifact.description,
            style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.white70),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPathTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const TranslatedText(
                'Exhibit Flow',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              TranslatedText(
                '${artifact.sections.length} Themes',
                style: const TextStyle(color: AppTheme.kAccent, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...artifact.sections.map((section) => _SectionTile(section: section)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildContributorTab(WidgetRef ref) {
    final contributorAsync = ref.watch(userByUidProvider(artifact.authorId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TranslatedText(
            'Primary Contributor',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 24),
          contributorAsync.when(
            data: (contributor) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.kAccent.withOpacity(0.1),
                      child: Text(
                        (contributor?.displayName ?? artifact.authorName)[0].toUpperCase(),
                        style: const TextStyle(color: AppTheme.kAccent, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TranslatedText(
                            contributor?.displayName ?? artifact.authorName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                          ),
                          TranslatedText(
                            contributor?.institution ?? 'Heritage Expert', 
                            style: const TextStyle(color: Colors.grey, fontSize: 14)
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.kAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const TranslatedText(
                              'VERIFIED CONTRIBUTOR',
                              style: TextStyle(color: AppTheme.kAccent, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const TranslatedText(
                  'About the Expert',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  contributor?.bio ?? 'This contributor has not provided a bio yet.',
                  style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.white70),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(child: TranslatedText('Could not load contributor profile')),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.kAccent.withOpacity(0.9), AppTheme.kAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, size: 64, color: Colors.white70),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TranslatedText(
                    artifact.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeritageOutcomes() {
    final outcomes = artifact.heritageSignificance ?? [];

    if (outcomes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No specific importance data has been listed yet.',
          style: TextStyle(fontSize: 14, color: Colors.white38, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      children: outcomes
          .map((outcome) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.kAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        outcome,
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildBottomAction(BuildContext context, dynamic user, bool isEnrolled) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: AppTheme.kSurface,
        border: Border(top: BorderSide(color: AppTheme.kGlassBorder)),
      ),
      child: Consumer(
        builder: (context, ref, _) => ElevatedButton(
          onPressed: () async {
            if (isEnrolled) {
              context.push('/artifact-viewer', extra: artifact);
            } else {
              if (user != null) {
                await ref.read(artifactControllerProvider.notifier).trackViewer(artifact.id, user.uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: TranslatedText('Exhibit added to your journey!')));
                  context.push('/artifact-viewer', extra: artifact);
                }
              }
            }
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: isEnrolled ? AppTheme.kSurface : AppTheme.kAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: TranslatedText(
            isEnrolled ? 'CONTINUE EXPLORING' : 'START JOURNEY',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final HeritageSection section;
  const _SectionTile({required this.section});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 12,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Colors.white,
          collapsedIconColor: Colors.white70,
          title: TranslatedText(
            section.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
          leading: const Icon(Icons.bookmarks, color: AppTheme.kAccent),
          children: [
            ...section.parts.map((part) => ListTile(
                  title: TranslatedText(part.title, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                  contentPadding: const EdgeInsets.only(left: 56, right: 16),
                  dense: true,
                  leading: const Icon(Icons.explore_outlined, size: 18, color: Colors.white30),
                )),
          ],
        ),
      ),
    );
  }
}
