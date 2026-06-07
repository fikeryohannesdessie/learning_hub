import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';

Widget? buildWebPdfViewer(String url) {
  return _PdfWebViewer(url: url);
}

class _PdfWebViewer extends StatefulWidget {
  const _PdfWebViewer({required this.url});

  final String url;

  @override
  State<_PdfWebViewer> createState() => _PdfWebViewerState();
}

class _PdfWebViewerState extends State<_PdfWebViewer> {
  late String _viewType;

  // #region debug-point B:web-iframe
  void _reportDebug(String msg, Map<String, Object?> data) {
    http
        .post(
          Uri.parse('http://127.0.0.1:7777/event'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'sessionId': 'web-pdf-blank',
            'runId': 'pre-fix',
            'hypothesisId': 'B',
            'location': 'pdf_web_viewer_web.dart',
            'msg': '[DEBUG] $msg',
            'data': data,
            'ts': DateTime.now().millisecondsSinceEpoch,
          }),
        )
        .catchError((_) {});
  }
  // #endregion

  @override
  void initState() {
    super.initState();
    _reportDebug('Web PDF iframe initState', {'url': widget.url});
    _registerViewFactory();
  }

  @override
  void didUpdateWidget(covariant _PdfWebViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _reportDebug('Web PDF iframe URL changed', {
        'oldUrl': oldWidget.url,
        'newUrl': widget.url,
      });
      _registerViewFactory();
    }
  }

  void _registerViewFactory() {
    _viewType = 'pdf-viewer-${DateTime.now().microsecondsSinceEpoch}';
    final viewerUrl = widget.url;
    _reportDebug('Registering iframe view factory', {
      'viewType': _viewType,
      'viewerUrl': viewerUrl,
    });

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        _reportDebug('Creating iframe element', {
          'viewType': _viewType,
          'viewId': viewId,
          'viewerUrl': viewerUrl,
        });
        return html.IFrameElement()
          ..src = viewerUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _reportDebug('Rendering HtmlElementView', {'viewType': _viewType});
    return HtmlElementView(viewType: _viewType);
  }
}
