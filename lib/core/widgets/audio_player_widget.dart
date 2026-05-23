import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_theme.dart';
import '../localization/translated_text.dart';
import '../../features/bookmark/provider/bookmark_provider.dart';
import '../../features/content/domain/content_domain.dart';
import '../../features/content/infrastructure/content_model_mapper.dart';

class AudioPlayerWidget extends ConsumerStatefulWidget {
  final String? url;
  final List<int>? bytes;
  final String title;
  final LearningContent item;

  const AudioPlayerWidget({
    super.key,
    this.url,
    this.bytes,
    required this.title,
    required this.item,
  });

  @override
  ConsumerState<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => _duration = newDuration);
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => _position = newPosition);
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });

    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      if (widget.bytes != null) {
        await _audioPlayer.setSource(
          BytesSource(Uint8List.fromList(widget.bytes!)),
        );
      } else if (widget.url != null && widget.url!.isNotEmpty) {
        await _audioPlayer.setSource(UrlSource(widget.url!));
      }
    } catch (e) {
      debugPrint('Audio initialization error: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.resume();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.kAncientBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.audiotrack,
                  color: AppTheme.kAncientBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    const TranslatedText(
                      'Audio Resource',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final bookmarks = ref.watch(bookmarksProvider);
                  final isBookmarked = bookmarks.any(
                    (b) => b.id == widget.item.id,
                  );

                  return IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? AppTheme.kAccent : Colors.white54,
                    ),
                    onPressed: () async {
                      final isAdded = await ref
                          .read(bookmarksProvider.notifier)
                          .toggleBookmark(
                            BookmarkItem(
                              id: widget.item.id,
                              title: widget.item.title,
                              type: 'audio',
                              extraData: contentModelToJson(widget.item),
                              bookmarkedAt: DateTime.now(),
                            ),
                          );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: TranslatedText(
                              isAdded
                                  ? 'Added to bookmarks'
                                  : 'Removed from bookmarks',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppTheme.kAncientBlue,
              inactiveTrackColor: Colors.white10,
              thumbColor: AppTheme.kAncientBlue,
            ),
            child: Slider(
              min: 0,
              max: _duration.inMilliseconds.toDouble() > 0
                  ? _duration.inMilliseconds.toDouble()
                  : 1.0,
              value: _position.inMilliseconds.toDouble().clamp(
                0.0,
                _duration.inMilliseconds.toDouble() > 0
                    ? _duration.inMilliseconds.toDouble()
                    : 1.0,
              ),
              onChanged: (value) {
                _audioPlayer.seek(Duration(milliseconds: value.toInt()));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _audioPlayer.seek(
                  Duration(milliseconds: _position.inMilliseconds - 10000),
                ),
                icon: const Icon(Icons.replay_10, color: Colors.white70),
              ),
              const SizedBox(width: 16),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppTheme.kAncientBlue,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _togglePlay,
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => _audioPlayer.seek(
                  Duration(milliseconds: _position.inMilliseconds + 10000),
                ),
                icon: const Icon(Icons.forward_10, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
