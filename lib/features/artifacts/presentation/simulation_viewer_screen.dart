import 'package:flutter/material.dart';
import '../domain/artifact_domain.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import 'heritage_viewer.dart';

class SimulationViewerScreen extends StatelessWidget {
  final ArtifactContentItem item;

  const SimulationViewerScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    switch (_normalizeSimulationId(item.simulationId)) {
      case 'lalibela':
        return HeritageViewer(
          title: item.title.isEmpty ? '3D Heritage Explorer' : item.title,
          simulationId: 'lalibela',
        );
      default:
        return Container(
          color: AppTheme.kBg,
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GlassCard(
              frosted: true,
              borderRadius: 24,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.view_in_ar_outlined,
                    color: AppTheme.kAccent,
                    size: 44,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.title.isEmpty ? '3D simulation unavailable' : item.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The requested heritage simulation is not configured yet.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }

  String _normalizeSimulationId(String? rawId) {
    final normalized = (rawId ?? '').trim().toLowerCase();
    if (normalized.isEmpty ||
        normalized == 'artifact_viewer' ||
        normalized == 'biete_giyorgis') {
      return 'lalibela';
    }
    return normalized;
  }
}
