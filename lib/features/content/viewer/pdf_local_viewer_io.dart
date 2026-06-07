import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

Widget? buildLocalPdfViewer(
  String path,
  GlobalKey<SfPdfViewerState> viewerKey,
  PdfViewerController controller,
) {
  final file = File(path);
  if (!file.existsSync()) {
    return null;
  }

  return SfPdfViewer.file(
    file,
    key: viewerKey,
    controller: controller,
    enableDoubleTapZooming: true,
    canShowScrollHead: false,
    canShowPaginationDialog: false,
  );
}
