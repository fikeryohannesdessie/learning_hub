import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/content/domain/content_domain.dart';
import '../../features/content/provider/content_repository.dart';
import '../localization/translated_text.dart';
import '../widgets/audio_player_widget.dart';

Future<void> showAudioPreview(
  BuildContext context,
  WidgetRef ref,
  LearningContent item,
) async {
  final bytes = await ref.read(contentFileProvider(item.id).future);
  if (!context.mounted) return;

  if (bytes == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: TranslatedText('Could not load audio file.')),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AudioPlayerWidget(bytes: bytes, title: item.title, item: item),
    ),
  );
}
