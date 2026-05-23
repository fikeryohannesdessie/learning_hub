import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:go_router/go_router.dart';
import '../provider/content_repository.dart';
import '../domain/content_domain.dart';
import 'package:chpa/features/bookmark/provider/bookmark_provider.dart';
import '../../../core/localization/localization.dart';
import '../../bookmark/domain/bookmark_domain.dart';
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
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey<SfPdfViewerState>();
  bool _hideViewer = false;

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  /// Manually handles the back action by hiding the PDF viewer first.
  /// This ensures it's unmounted before the pop animation frames can
  /// trigger the Syncfusion RenderBox assertion crash.
  void _handleBack() {
    if (_hideViewer) return;
    
    setState(() {
      _hideViewer = true;
    });

    // We wait exactly one frame before popping to guarantee the 
    // widget tree is updated and SfPdfViewer is fully gone.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final isPageClosing = route != null && !route.isCurrent;

    // Aggressive unmounting if a pop is detected via any method.
    if (_hideViewer || isPageClosing) {
      return const Scaffold(
        backgroundColor: AppTheme.kBg,
        body: SizedBox.expand(),
      );
    }

    final fileAsync = ref.watch(contentFileProvider(widget.content.id));
    final screenSize = MediaQuery.sizeOf(context);

    return PopScope(
      // We set canPop to false to manually intercept all pop requests, 
      // including system gestures (swiping) and Android back buttons.
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        
        // If the pop was intercepted (didPop is false), trigger our safe unmount logic.
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
                final isBookmarked = bookmarks.any((b) => b.id == widget.content.id);
                return IconButton(
                  icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                  color: isBookmarked ? AppTheme.kAccent : null,
                  onPressed: () async {
                    final isAdded = await ref.read(bookmarksProvider.notifier).toggleBookmark(
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
                        SnackBar(content: TranslatedText(isAdded ? 'File added to bookmarks' : 'File removed from bookmarks')),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
        body: fileAsync.when(
          data: (bytes) {
            if (_hideViewer || isPageClosing) return const SizedBox.expand();

            Widget viewer;
            if (bytes != null) {
              viewer = SfPdfViewer.memory(
                bytes,
                key: _pdfViewerKey,
                controller: _pdfViewerController,
                enableDoubleTapZooming: true,
                canShowScrollHead: false,
                canShowPaginationDialog: false,
              );
            } else if (widget.content.url != null && widget.content.url!.isNotEmpty) {
              String url = widget.content.url!;
              if (url.startsWith('file://')) {
                url = Uri.parse(url).toFilePath();
              } else if (url.contains('%')) {
                try {
                  url = Uri.decodeFull(url);
                } catch (_) {}
              }

              if (url.startsWith('http')) {
                viewer = SfPdfViewer.network(
                  url,
                  key: _pdfViewerKey,
                  controller: _pdfViewerController,
                  enableDoubleTapZooming: true,
                  canShowScrollHead: false,
                  canShowPaginationDialog: false,
                );
              } else if (url.startsWith('assets/')) {
                viewer = SfPdfViewer.asset(
                  url,
                  key: _pdfViewerKey,
                  controller: _pdfViewerController,
                  enableDoubleTapZooming: true,
                  canShowScrollHead: false,
                  canShowPaginationDialog: false,
                );
              } else {
                final file = File(url);
                if (file.existsSync()) {
                  viewer = SfPdfViewer.file(
                    file,
                    key: _pdfViewerKey,
                    controller: _pdfViewerController,
                    enableDoubleTapZooming: true,
                    canShowScrollHead: false,
                    canShowPaginationDialog: false,
                  );
                } else {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        TranslatedText('File not found at: $url'),
                        const SizedBox(height: 8),
                        Text('Original: ${widget.content.url}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  );
                }
              }
            } else {
              return const Center(child: TranslatedText('Content not available'));
            }

            return SizedBox(
              width: screenSize.width,
              height: screenSize.height,
              child: viewer,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: TranslatedText('Error loading PDF: $err')),
        ),
      ),
    );
  }
}
