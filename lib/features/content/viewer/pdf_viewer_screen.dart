import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'pdf_local_viewer_stub.dart'
    if (dart.library.io) 'pdf_local_viewer_io.dart';
import 'pdf_web_viewer_stub.dart'
    if (dart.library.html) 'pdf_web_viewer_web.dart';
import '../../../core/utils/api_config.dart';
import '../provider/content_repository.dart';
import 'package:chpa/features/bookmark/provider/bookmark_provider.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_app_bar.dart';
import '../infrastructure/content_model_mapper.dart';

class PDFViewerScreen extends ConsumerStatefulWidget {
  final LearningContent content;

  const PDFViewerScreen({super.key, required this.content});

  @override
  ConsumerState<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends ConsumerState<PDFViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey =
      GlobalKey<SfPdfViewerState>();
  bool _hideViewer = false;

  // #region debug-point A:web-pdf-screen
  void _reportDebug(String hypothesisId, String msg, Map<String, Object?> data) {
    unawaited(
      http
          .post(
            Uri.parse('http://127.0.0.1:7777/event'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'sessionId': 'web-pdf-blank',
              'runId': 'pre-fix',
              'hypothesisId': hypothesisId,
              'location': 'pdf_viewer_screen.dart',
              'msg': '[DEBUG] $msg',
              'data': data,
              'ts': DateTime.now().millisecondsSinceEpoch,
            }),
          )
          .catchError((_) {}),
    );
  }
  // #endregion

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_hideViewer) return;

    setState(() {
      _hideViewer = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.pop();
      }
    });
  }

  Future<Uint8List> _fetchPdfBytes(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw StateError('Failed to load PDF: HTTP ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  String? _resolveDirectWebPdfUrl() {
    final rawUrl = widget.content.url;
    _reportDebug('A', 'Resolving web PDF URL', {
      'contentId': widget.content.id,
      'rawUrl': rawUrl,
      'uriOrigin': Uri.base.origin,
    });
    if (rawUrl != null && rawUrl.isNotEmpty) {
      if (rawUrl.startsWith('assets/') || rawUrl.startsWith('file://')) {
        _reportDebug('A', 'Web URL resolution rejected local-only path', {
          'rawUrl': rawUrl,
        });
        return null;
      }
      if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
        _reportDebug('A', 'Web URL resolution using absolute URL', {
          'resolvedUrl': rawUrl,
        });
        return rawUrl;
      }
      if (rawUrl.startsWith('/')) {
        final resolved = '${Uri.base.origin}$rawUrl';
        _reportDebug('A', 'Web URL resolution using origin-relative URL', {
          'resolvedUrl': resolved,
        });
        return resolved;
      }
    }

    _reportDebug('A', 'Web URL resolution skipped direct embed path', {
      'reason': 'No explicit remote URL present',
    });
    return null;
  }

  Widget _buildViewerFromUrl(String rawUrl) {
    var url = rawUrl;
    if (url.startsWith('file://')) {
      url = Uri.parse(url).toFilePath();
    } else if (url.contains('%')) {
      try {
        url = Uri.decodeFull(url);
      } catch (_) {}
    }

    if (url.startsWith('assets/')) {
      return SfPdfViewer.asset(
        url,
        key: _pdfViewerKey,
        controller: _pdfViewerController,
        enableDoubleTapZooming: true,
        canShowScrollHead: false,
        canShowPaginationDialog: false,
      );
    }

    if (url.startsWith('http')) {
      return FutureBuilder<Uint8List>(
        future: _fetchPdfBytes(url),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: TranslatedText('Error loading PDF: ${snapshot.error}'),
            );
          }
          final bytes = snapshot.data;
          if (bytes == null || bytes.isEmpty) {
            return const Center(child: TranslatedText('PDF data is empty'));
          }
          return SfPdfViewer.memory(
            bytes,
            key: _pdfViewerKey,
            controller: _pdfViewerController,
            enableDoubleTapZooming: true,
            canShowScrollHead: false,
            canShowPaginationDialog: false,
          );
        },
      );
    }

    final localViewer = buildLocalPdfViewer(
      url,
      _pdfViewerKey,
      _pdfViewerController,
    );
    if (localViewer != null) {
      return localViewer;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          TranslatedText('File not found at: $url'),
          const SizedBox(height: 8),
          Text(
            'Original: ${widget.content.url}',
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackViewer(
    AsyncValue<Uint8List?> fileAsync,
    Size screenSize,
    bool isPageClosing,
  ) {
    return fileAsync.when(
      data: (bytes) {
        if (_hideViewer || isPageClosing) return const SizedBox.expand();
        _reportDebug('D', 'Building fallback PDF viewer', {
          'hasBytes': bytes != null,
          'byteLength': bytes?.length,
          'contentUrl': widget.content.url,
        });

        late final Widget viewer;
        if (bytes != null && bytes.isNotEmpty) {
          viewer = SfPdfViewer.memory(
            bytes,
            key: _pdfViewerKey,
            controller: _pdfViewerController,
            enableDoubleTapZooming: true,
            canShowScrollHead: false,
            canShowPaginationDialog: false,
          );
        } else if (widget.content.url != null && widget.content.url!.isNotEmpty) {
          viewer = _buildViewerFromUrl(widget.content.url!);
        } else {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.picture_as_pdf_outlined, size: 56, color: Colors.white54),
                  SizedBox(height: 16),
                  TranslatedText('PDF file is missing for this item'),
                  SizedBox(height: 8),
                  TranslatedText('Please re-upload the PDF and try again'),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          width: screenSize.width,
          height: screenSize.height,
          child: viewer,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) {
        _reportDebug('D', 'Fallback viewer entered error state', {
          'error': err.toString(),
        });
        return Center(child: TranslatedText('Error loading PDF: $err'));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final isPageClosing = route != null && !route.isCurrent;
    _reportDebug('D', 'PDF screen build', {
      'contentId': widget.content.id,
      'hideViewer': _hideViewer,
      'routeIsCurrent': route?.isCurrent,
      'isPageClosing': isPageClosing,
      'isWeb': kIsWeb,
    });

    if (_hideViewer || isPageClosing) {
      _reportDebug('D', 'PDF screen returned empty scaffold', {
        'hideViewer': _hideViewer,
        'isPageClosing': isPageClosing,
      });
      return const Scaffold(
        backgroundColor: AppTheme.kBg,
        body: SizedBox.expand(),
      );
    }

    final fileAsync = ref.watch(contentFileProvider(widget.content.id));
    final screenSize = MediaQuery.sizeOf(context);
    final webPdfUrl = kIsWeb ? _resolveDirectWebPdfUrl() : null;
    final webViewer = webPdfUrl == null ? null : buildWebPdfViewer(webPdfUrl);
    _reportDebug('B', 'Viewer strategy selected', {
      'webPdfUrl': webPdfUrl,
      'usingWebViewer': webViewer != null,
      'screenWidth': screenSize.width,
      'screenHeight': screenSize.height,
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppTheme.kBg,
        appBar: SharedAppBar(
          title: widget.content.title,
          showProfile: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _handleBack,
          ),
          extraActions: [
            Consumer(
              builder: (context, ref, _) {
                final bookmarks = ref.watch(bookmarksProvider);
                final isBookmarked =
                    bookmarks.any((b) => b.id == widget.content.id);
                return IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  color: isBookmarked ? AppTheme.kAccent : null,
                  onPressed: () async {
                    final isAdded = await ref
                        .read(bookmarksProvider.notifier)
                        .toggleBookmark(
                          BookmarkItem(
                            id: widget.content.id,
                            title: widget.content.title,
                            type: 'pdf',
                            extraData: contentModelToJson(widget.content),
                            bookmarkedAt: DateTime.now(),
                          ),
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: TranslatedText(
                            isAdded
                                ? 'File added to bookmarks'
                                : 'File removed from bookmarks',
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: webViewer != null
            ? SizedBox(
                width: screenSize.width,
                height: screenSize.height,
                child: webViewer,
              )
            : _buildFallbackViewer(fileAsync, screenSize, isPageClosing),
      ),
    );
  }
}
