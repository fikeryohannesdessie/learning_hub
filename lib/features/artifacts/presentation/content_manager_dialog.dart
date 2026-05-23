import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/artifact_domain.dart';
import '../../../core/localization/localization.dart';
import '../../content/provider/content_repository.dart';

class ContentManagerDialog extends ConsumerStatefulWidget {
  final List<ArtifactContentItem> initialContents;

  const ContentManagerDialog({super.key, required this.initialContents});

  @override
  ConsumerState<ContentManagerDialog> createState() =>
      _ContentManagerDialogState();
}

class _ContentManagerDialogState extends ConsumerState<ContentManagerDialog> {
  late List<ArtifactContentItem> _contents;
  final Color _bgColor = const Color(0xFF0F0F0F);
  final Color _accentColor = const Color(0xFFFF4D4D);

  @override
  void initState() {
    super.initState();
    _contents = List.from(widget.initialContents);
  }

  void _addTextContent() async {
    final result = await showDialog<ArtifactContentItem>(
      context: context,
      builder: (ctx) => _ContentEditorDialog(
        type: 'text',
        title: 'Add Heritage Insight',
        icon: Icons.article,
        color: _accentColor,
      ),
    );
    if (result != null) setState(() => _contents.add(result));
  }

  void _addFileContent(String type) async {
    final resultFiles = await FilePicker.platform.pickFiles(
      type: type == 'pdf' ? FileType.custom : FileType.video,
      allowedExtensions: type == 'pdf' ? ['pdf'] : null,
    );

    if (resultFiles != null) {
      final file = resultFiles.files.first;
      final fileId = 'file_${const Uuid().v4()}';
      Uint8List? bytes;
      if (kIsWeb) {
        bytes = file.bytes;
      } else if (file.path != null) {
        bytes = await io.File(file.path!).readAsBytes();
      }
      
      if (bytes != null) {
        await ref
            .read(contentControllerProvider.notifier)
            .saveFileBytes(fileId, bytes);
        
        if (!mounted) return;
        
        final result = await showDialog<ArtifactContentItem>(
          context: context,
          builder: (ctx) => _ContentEditorDialog(
            type: type,
            title: 'Refine ${type.toUpperCase()}',
            initialTitle: file.name,
            icon: type == 'pdf' ? Icons.picture_as_pdf : Icons.video_library,
            color: type == 'pdf' ? Colors.redAccent : Colors.orangeAccent,
            fileId: fileId,
            url: file.name,
          ),
        );
        if (result != null) setState(() => _contents.add(result));
      }
    }
  }

  void _showVideoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add Video', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Choose how to add a video to this theme.', style: TextStyle(color: Colors.white38, fontSize: 13)),
              const SizedBox(height: 24),
              _VideoOptionTile(
                icon: Icons.upload_file_rounded,
                color: Colors.orangeAccent,
                title: 'Upload Video File',
                subtitle: 'Pick an MP4, MOV or other video from your device',
                onTap: () {
                  Navigator.pop(ctx);
                  _addFileContent('video');
                },
              ),
              const SizedBox(height: 12),
              _VideoOptionTile(
                icon: Icons.link_rounded,
                color: Colors.blueAccent,
                title: 'Add YouTube / URL Link',
                subtitle: 'Paste a YouTube or external video URL',
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await showDialog<ArtifactContentItem>(
                    context: context,
                    builder: (dialogCtx) => _ContentEditorDialog(
                      type: 'video',
                      title: 'Add Video Link',
                      icon: Icons.video_library,
                      color: Colors.deepOrange,
                      isUrl: true,
                    ),
                  );
                  if (result != null) setState(() => _contents.add(result));
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _addSimulationContent() async {
    final result = await showDialog<ArtifactContentItem>(
      context: context,
      builder: (ctx) => const _ContentEditorDialog(
        type: 'simulation',
        title: 'Add 3D Heritage Simulation',
        initialTitle: 'Biete Giyorgis 3D Exploration',
        initialSimulationId: 'lalibela',
        icon: Icons.view_in_ar_rounded,
        color: Color(0xFFD4A843),
      ),
    );
    if (result != null) setState(() => _contents.add(result));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const TranslatedText('Manage Content', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          const LanguageSwitcher(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _contents),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const TranslatedText('Done', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NEW CONTENT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white24, fontSize: 10, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _AddCircleButton(icon: Icons.article_rounded, label: 'Text', color: _accentColor, onTap: _addTextContent),
                    _AddCircleButton(icon: Icons.picture_as_pdf_rounded, label: 'PDF', color: Colors.redAccent, onTap: () => _addFileContent('pdf')),
                    _AddCircleButton(icon: Icons.video_collection_rounded, label: 'Video', color: Colors.orangeAccent, onTap: _showVideoOptions),
                    _AddCircleButton(icon: Icons.view_in_ar_rounded, label: '3D', color: const Color(0xFFD4A843), onTap: _addSimulationContent),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x0DFFFFFF)),
          Expanded(
            child: _contents.isEmpty
                ? _buildEmpty()
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _contents.length,
                    onReorder: (oldIdx, newIdx) {
                      setState(() {
                        if (newIdx > oldIdx) newIdx--;
                        final item = _contents.removeAt(oldIdx);
                        _contents.insert(newIdx, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      return _ContentItemCard(
                        key: ValueKey(_contents[index].id),
                        item: _contents[index],
                        index: index,
                        onDelete: () => setState(() => _contents.removeAt(index)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.layers_clear_outlined, size: 60, color: Colors.white.withOpacity(0.05)),
        const SizedBox(height: 24),
        const TranslatedText('No content items yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white24)),
      ]),
    );
  }
}

class _VideoOptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _VideoOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }
}

class _AddCircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AddCircleButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ContentItemCard extends StatelessWidget {
  final ArtifactContentItem item;
  final int index;
  final VoidCallback onDelete;

  const _ContentItemCard({super.key, required this.item, required this.index, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cfg = _getConfig();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (cfg['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(cfg['icon'] as IconData, color: cfg['color'] as Color, size: 20),
        ),
        title: Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Row(
          children: [
            Text((cfg['label'] as String).toUpperCase(), style: TextStyle(color: (cfg['color'] as Color), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            if (item.isResource) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                child: Text(item.resourceCategory?.toUpperCase() ?? 'RESOURCE', style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_indicator, color: Colors.white10),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20)),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getConfig() {
    switch (item.type) {
      case 'text': return {'icon': Icons.article_outlined, 'color': const Color(0xFFFF4D4D), 'label': 'Text'};
      case 'pdf': return {'icon': Icons.picture_as_pdf_outlined, 'color': Colors.redAccent, 'label': 'PDF'};
      case 'video': return {'icon': Icons.video_library_outlined, 'color': Colors.orangeAccent, 'label': 'Video'};
      case 'simulation': return {'icon': Icons.view_in_ar_outlined, 'color': const Color(0xFFD4A843), 'label': 'Simulation'};
      default: return {'icon': Icons.help_outline, 'color': Colors.grey, 'label': 'Item'};
    }
  }
}

class _ContentEditorDialog extends StatefulWidget {
  final String type;
  final String title;
  final String? initialTitle;
  final IconData icon;
  final Color color;
  final bool isUrl;
  final String? fileId;
  final String? url;
  final String? initialSimulationId;

  const _ContentEditorDialog({
    required this.type,
    required this.title,
    this.initialTitle,
    required this.icon,
    required this.color,
    this.isUrl = false,
    this.fileId,
    this.url,
    this.initialSimulationId,
  });

  @override
  State<_ContentEditorDialog> createState() => _ContentEditorDialogState();
}

class _ContentEditorDialogState extends State<_ContentEditorDialog> {
  late TextEditingController _titleController;
  late TextEditingController _mainController;
  late String _simulationId;
  bool _isResource = false;
  String _category = 'Research Notes';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _mainController = TextEditingController();
    _simulationId = widget.initialSimulationId ?? 'lalibela';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F0F0F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(widget.icon, color: widget.color, size: 24),
                const SizedBox(width: 12),
                Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ]),
              const SizedBox(height: 20),
              _buildField('Title', _titleController, 'e.g., Introduction to Quantum'),
              const SizedBox(height: 16),
              if (widget.type == 'text')
                _buildField('Content Area', _mainController, 'Document your cultural knowledge here...', maxLines: 6)
              else if (widget.isUrl)
                _buildField('Video URL', _mainController, 'https://youtube.com/...')
              else if (widget.type == 'simulation')
                _buildSimulationSelector(),
              const SizedBox(height: 24),
              const Text('Heritage RESOURCE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white24, fontSize: 10, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tag as Resource', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Show in the Resources tab for Viewers', style: TextStyle(color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isResource, 
                          onChanged: (v) => setState(() => _isResource = v),
                          activeColor: const Color(0xFFFF4D4D),
                        ),
                      ],
                    ),
                    if (_isResource) ...[
                      const Divider(height: 24, color: Color(0x0DFFFFFF)),
                      Row(
                        children: [
                          const Text('Category', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const Spacer(),
                          DropdownButton<String>(
                            value: _category,
                            dropdownColor: const Color(0xFF1A1A1A),
                            underline: const SizedBox(),
                            style: const TextStyle(color: Color(0xFFFF4D4D), fontWeight: FontWeight.bold, fontSize: 13),
                            onChanged: (v) => setState(() => _category = v!),
                            items: ['Research Notes', 'Reading', 'Video', 'Guide', 'Template'].map((c) {
                              return DropdownMenuItem(value: c, child: Text(c));
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white38)))),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final item = ArtifactContentItem(
                        id: const Uuid().v4(),
                        type: widget.type,
                        title: _titleController.text.isEmpty ? 'Untitled' : _titleController.text,
                        text: widget.type == 'text' ? _mainController.text : null,
                        url: widget.type == 'simulation'
                            ? null
                            : (widget.isUrl ? _mainController.text : widget.url),
                        fileId: widget.fileId,
                        simulationId: widget.type == 'simulation' ? _simulationId : null,
                        isResource: _isResource,
                        resourceCategory: _isResource ? _category : null,
                      );
                      Navigator.pop(context, item);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D4D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Add Content', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF4D4D), width: 1)),
          ),
        ),
      ],
    );
  }

  Widget _buildSimulationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Simulation',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _simulationId,
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF4D4D), width: 1),
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: 'lalibela',
              child: Text('Lalibela - Biete Giyorgis'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _simulationId = value);
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'This adds a native 3D heritage scene for learners to explore in-app.',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }
}
