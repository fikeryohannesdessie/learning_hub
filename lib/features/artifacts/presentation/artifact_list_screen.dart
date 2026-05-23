import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../provider/artifact_repository.dart';
import '../domain/artifact_domain.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/localization.dart';
import '../../../core/widgets/shared_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/localization/translated_text.dart';

class ArtifactListScreen extends ConsumerWidget {
  final String? classification;
  const ArtifactListScreen({super.key, this.classification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artifactsAsync = classification != null
        ? ref.watch(approvedArtifactsByClassificationProvider(classification!))
        : ref.watch(approvedArtifactsProvider);

    return Scaffold(
      backgroundColor: AppTheme.kBg,
      appBar: SharedAppBar(
        title: classification == null
            ? 'All Artifacts'
            : '${classification!.toUpperCase()} Artifacts',
      ),
      body: artifactsAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04),
                        border: Border.all(color: AppTheme.kGlassBorder),
                      ),
                      child: const Icon(
                        Icons.museum_outlined,
                        size: 34,
                        color: AppTheme.kAccent,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const TranslatedText(
                      'No artifacts available yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.kParchment,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When approved heritage items are added, they will appear here in a dedicated collection view.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.kParchment.withOpacity(0.6),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount = 1;
              double childAspectRatio = 1.28;

              if (width >= 1200) {
                crossAxisCount = 4;
                childAspectRatio = 0.9;
              } else if (width >= 900) {
                crossAxisCount = 3;
                childAspectRatio = 0.96;
              } else if (width >= 640) {
                crossAxisCount = 2;
                childAspectRatio = 1.02;
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _ArtifactListHero(
                        count: list.length,
                        classification: classification,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _ArtifactGridItem(artifact: list[index]),
                        childCount: list.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: TranslatedText('Error: $err'),
          ),
        ),
      ),
    );
  }
}

class _ArtifactListHero extends StatelessWidget {
  final int count;
  final String? classification;

  const _ArtifactListHero({required this.count, required this.classification});

  @override
  Widget build(BuildContext context) {
    final label = classification == null
        ? 'Curated heritage collection'
        : '${classification!.toUpperCase()} heritage collection';

    return GlassCard(
      borderRadius: 22,
      color: const Color(0xFF17120D),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            Positioned(
              top: -18,
              right: -8,
              child: Icon(
                Icons.account_balance_rounded,
                size: 96,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            Positioned(
              bottom: -10,
              left: -4,
              child: Icon(
                Icons.travel_explore_rounded,
                size: 88,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.kAccent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppTheme.kAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '$count ITEMS',
                      style: const TextStyle(
                        color: AppTheme.kAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const TranslatedText(
                    'Show All',
                    style: TextStyle(
                      color: AppTheme.kParchment,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TranslatedText(
                    label,
                    style: TextStyle(
                      color: AppTheme.kParchment.withOpacity(0.72),
                      fontSize: 14,
                      height: 1.45,
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

class _ArtifactGridItem extends StatelessWidget {
  final Artifact artifact;
  const _ArtifactGridItem({required this.artifact});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push(
        '/artifact-detail',
        extra: artifact,
      ),
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
                      top: -16,
                      right: -6,
                      child: Icon(
                        Icons.architecture_rounded,
                        size: 84,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    Positioned(
                      bottom: -12,
                      left: -6,
                      child: Icon(
                        Icons.history_edu_rounded,
                        size: 78,
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
                            child: Text(
                              artifact.classification.toUpperCase(),
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
                          Text(
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
                    artifact.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.kParchment,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                          '${artifact.sections.length} Sections',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                          artifact.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
