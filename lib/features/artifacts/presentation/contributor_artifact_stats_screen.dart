import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_controller.dart';
import '../provider/artifact_repository.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/shared_app_bar.dart';

class ContributorArtifactStatsScreen extends ConsumerWidget {
  const ContributorArtifactStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final artifactsAsync = ref.watch(allArtifactsProvider);


    return Scaffold(
      backgroundColor: AppTheme.kBg,
      appBar: const SharedAppBar(
        title: 'Artifact Performance',
        showProfile: false,
      ),
      body: artifactsAsync.when(
        data: (list) {
          final myArtifacts = list.where((c) => c.authorId == user?.uid).toList();
          
          if (myArtifacts.isEmpty) {
            return const Center(child: TranslatedText('You haven\'t contributed any artifacts yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myArtifacts.length,
            itemBuilder: (context, index) => _ArtifactStatsCard(artifact: myArtifacts[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: TranslatedText('Error: $err')),
      ),
    );
  }
}

class _ArtifactStatsCard extends ConsumerWidget {
  final Artifact artifact;
  const _ArtifactStatsCard({required this.artifact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(artifactResultsProvider(artifact.id));

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      borderRadius: 16,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Colors.white,
          collapsedIconColor: Colors.white70,
          title: TranslatedText(artifact.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          subtitle: TranslatedText('Status: ${artifact.status.toUpperCase()} • ${artifact.viewerIds.length} Viewers', style: const TextStyle(color: Colors.white70)),
          children: [
            resultsAsync.when(
              data: (results) {
                if (results.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: TranslatedText('No analysis submissions yet', style: TextStyle(color: Colors.white54)),
                  );
                }

                return Column(
                  children: [
                    const ListTile(
                      title: TranslatedText('Viewer Analysis Results', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.kAccent)),
                    ),
                    ...results.map((res) => ListTile(
                      leading: const Icon(Icons.person, color: Colors.white54),
                      title: TranslatedText(res.userName, style: const TextStyle(color: Colors.white)),
                      subtitle: TranslatedText('Verified: ${res.score}/${res.totalQuestions}', style: const TextStyle(color: Colors.white70)),
                      trailing: TranslatedText(
                        '${res.completedAt.day}/${res.completedAt.month}',
                        style: const TextStyle(fontSize: 12, color: Colors.white38),
                      ),
                    )),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(color: AppTheme.kAccent),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.all(16),
                child: TranslatedText('Error loading results: $err', style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}