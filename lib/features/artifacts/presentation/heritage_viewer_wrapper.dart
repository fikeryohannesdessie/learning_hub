import 'package:flutter/material.dart';
import 'heritage_viewer.dart';

/// A simple wrapper that provides the [HeritageViewer] widget
/// used by [SimulationViewerScreen] when displaying the native
/// 3D heritage simulation.
class HeritageViewerWrapper extends StatelessWidget {
  const HeritageViewerWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const HeritageViewer();
  }
}
