import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../artifacts/domain/artifact_domain.dart';
import '../bookmark/domain/bookmark_domain.dart';
import '../../core/localization/localization.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_app_bar.dart';
import '../artifacts/presentation/simulation_viewer_screen.dart';
import '../bookmark/provider/bookmark_provider.dart';

class Artifact3DViewerScreen extends StatefulWidget {
  final String? specificSim;
  final String? title;

  const Artifact3DViewerScreen({super.key, this.specificSim, this.title});

  @override
  State<Artifact3DViewerScreen> createState() => _Artifact3DViewerScreenState();
}

class _Artifact3DViewerScreenState extends State<Artifact3DViewerScreen> {
  late final String _simulationId;

  @override
  void initState() {
    super.initState();
    _simulationId = _resolveSimulationId(widget.specificSim);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBg,
      appBar: SharedAppBar(
        title: widget.title ?? 'Artifact 3D View',
        showProfile: false,
        extraActions: [
          Consumer(
            builder: (context, ref, _) {
              final bookmarks = ref.watch(bookmarksProvider);
              final isBookmarked = bookmarks.any((b) => b.id == _simulationId);
              return IconButton(
                icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                color: isBookmarked ? AppTheme.kAccent : null,
                onPressed: () async {
                  final isAdded = await ref.read(bookmarksProvider.notifier).toggleBookmark(
                        BookmarkItem(
                          id: _simulationId,
                          title: widget.title ?? '3D Heritage Explorer',
                          type: 'artifact_3d',
                          extraData: {
                            'specificSim': _simulationId,
                            'title': widget.title,
                          },
                          bookmarkedAt: DateTime.now(),
                        ),
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: TranslatedText(isAdded ? 'Heritage model added' : 'Heritage model removed')),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SimulationViewerScreen(
        item: ArtifactContentItem(
          id: 'standalone-$_simulationId',
          type: 'simulation',
          simulationId: _simulationId,
          title: widget.title ?? '3D Heritage Explorer',
        ),
      ),
    );
  }

  String _resolveSimulationId(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    if (normalized.isEmpty ||
        normalized == 'artifact_viewer' ||
        normalized == 'biete_giyorgis') {
      return 'lalibela';
    }
    return normalized;
  }
}
