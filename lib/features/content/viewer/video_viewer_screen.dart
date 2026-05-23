import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bookmark/provider/bookmark_provider.dart';
import '../../bookmark/domain/bookmark_domain.dart';
import '../../../core/theme/app_theme.dart';
import '../provider/content_repository.dart';

class VideoViewerScreen extends ConsumerStatefulWidget {
  final String url;
  final String title;
  final String? fileId; // If provided, extract video from SQLite storage
  final String? classification;

  const VideoViewerScreen({
    super.key,
    required this.url,
    required this.title,
    this.fileId,
    this.classification,
  });

  @override
  ConsumerState<VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends ConsumerState<VideoViewerScreen> {
  // Local file player
  VideoPlayerController? _localController;
  bool _isLocalVideo = false;
  bool _localInitialized = false;
  bool _isPlaying = false;

  // Web player
  WebViewController? _webController;
  bool _isYouTubeVideo = false;
  String? _youTubeVideoId;
  bool _triedYouTubeFallback = false;

  @override
  void initState() {
    super.initState();
    _isLocalVideo = _detectLocalFile(widget.url);
    _youTubeVideoId = _extractYouTubeVideoId(widget.url);
    _isYouTubeVideo = _youTubeVideoId != null;
    if (_isLocalVideo) {
      _initLocalPlayer();
    } else {
      _initWebPlayer();
    }
  }

  bool _detectLocalFile(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return false;
    if (url.startsWith('/') || url.contains(':\\') || url.contains(':/')) return true;
    // Check for common video extensions without http scheme
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.mkv');
  }

  String _errorMessage = '';

  Future<void> _initLocalPlayer() async {
    try {
      String finalPath;

      if (widget.fileId != null) {
        final bytes = await ref.read(contentFileProvider(widget.fileId!).future);
        if (bytes == null) {
          if (mounted) setState(() => _errorMessage = 'Internal error: Video data missing from storage.');
          return;
        }
        
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${widget.fileId}_temp_video.mp4');
        if (!await file.exists()) {
           await file.writeAsBytes(bytes);
        }
        finalPath = file.path;
      } else {
        String path = widget.url;
        if (path.startsWith('file://')) {
          path = Uri.parse(path).toFilePath();
        } else if (path.contains('%')) {
          try {
            path = Uri.decodeFull(path);
          } catch (_) {}
        }
        finalPath = path;
      }

      final file = File(finalPath);
      _localController = VideoPlayerController.file(file);
      await _localController!.initialize();
      _localController!.addListener(() {
        if (mounted) setState(() => _isPlaying = _localController!.value.isPlaying);
      });
      if (mounted) setState(() => _localInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Failed to load video: $e');
    }
  }

  void _initWebPlayer() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            if (_isYouTubeVideo && !_triedYouTubeFallback) {
              _triedYouTubeFallback = true;
              _loadYouTubeWatchPage(useMobileHost: false);
              return;
            }

            if (mounted && !_isYouTubeVideo) {
              setState(() {
                _errorMessage = 'Failed to load video: ${error.description}';
              });
            }
          },
        ),
      );

    if (_youTubeVideoId != null) {
      _loadYouTubeWatchPage();
      return;
    }

    _webController!.loadRequest(Uri.parse(widget.url));
  }

  void _loadYouTubeWatchPage({bool useMobileHost = true}) {
    final videoId = _youTubeVideoId;
    if (videoId == null || _webController == null) {
      return;
    }

    final host = useMobileHost ? 'm.youtube.com' : 'www.youtube.com';
    final uri = Uri.https(host, '/watch', {'v': videoId});
    _webController!.loadRequest(uri);
  }

  String? _extractYouTubeVideoId(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      return null;
    }

    final host = uri.host.toLowerCase();
    if (host.contains('youtu.be')) {
      final segments = uri.pathSegments.where((segment) => segment.isNotEmpty);
      if (segments.isEmpty) {
        return null;
      }
      return segments.first;
    }

    if (!host.contains('youtube.com') && !host.contains('youtube-nocookie.com')) {
      return null;
    }

    final videoId = uri.queryParameters['v'];
    if (videoId != null && videoId.isNotEmpty) {
      return videoId;
    }

    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    if (segments.length >= 2 &&
        (segments.first == 'embed' || segments.first == 'shorts' || segments.first == 'live')) {
      return segments[1];
    }

    return null;
  }

  @override
  void dispose() {
    _localController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 16), overflow: TextOverflow.ellipsis),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final bookmarks = ref.watch(bookmarksProvider);
              final isBookmarked = bookmarks.any((b) => b.id == 'vid_${widget.url}');
              return IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? AppTheme.kAccent : Colors.white70,
                ),
                onPressed: () {
                  ref.read(bookmarksProvider.notifier).toggleBookmark(
                        BookmarkItem(
                          id: 'vid_${widget.url}',
                          title: widget.title,
                          type: 'video',
                          bookmarkedAt: DateTime.now(),
                          extraData: {
                            'url': widget.url,
                            'title': widget.title,
                            'fileId': widget.fileId,
                          if (widget.classification != null)
                            'classification': widget.classification,
                          },
                        ),
                      );
                },
              );
            },
          ),
        ],
      ),
      body: _isLocalVideo ? _buildLocalPlayer() : _buildWebPlayer(),
    );
  }

  Widget _buildWebPlayer() {
    if (_webController == null) return const SizedBox.shrink();
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: WebViewWidget(controller: _webController!),
      ),
    );
  }

  Widget _buildLocalPlayer() {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 16), textAlign: TextAlign.center),
        ),
      );
    }

    if (!_localInitialized || _localController == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.kAccent));
    }

    final controller = _localController!;
    final duration = controller.value.duration;
    final position = controller.value.position;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Video display
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),

        const SizedBox(height: 16),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: AppTheme.kAccent,
              bufferedColor: Colors.white24,
              backgroundColor: Colors.white12,
            ),
          ),
        ),

        // Time display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(position), style: const TextStyle(color: Colors.white60, fontSize: 12)),
              Text(_formatDuration(duration), style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rewind 10s
            IconButton(
              icon: const Icon(Icons.replay_10, color: Colors.white70, size: 32),
              onPressed: () {
                final newPos = position - const Duration(seconds: 10);
                controller.seekTo(newPos < Duration.zero ? Duration.zero : newPos);
              },
            ),
            const SizedBox(width: 16),
            // Play/Pause
            GestureDetector(
              onTap: () {
                _isPlaying ? controller.pause() : controller.play();
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.kAccent,
                  shape: BoxShape.circle,
                ),
                child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(width: 16),
            // Forward 10s
            IconButton(
              icon: const Icon(Icons.forward_10, color: Colors.white70, size: 32),
              onPressed: () {
                final newPos = position + const Duration(seconds: 10);
                controller.seekTo(newPos > duration ? duration : newPos);
              },
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
