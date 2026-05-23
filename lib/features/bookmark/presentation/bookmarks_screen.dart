import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chpa/core/theme/app_theme.dart';
import 'package:chpa/features/bookmark/provider/bookmark_provider.dart';
import 'package:chpa/core/localization/localization.dart';
import 'package:chpa/core/widgets/shared_app_bar.dart';
import 'package:chpa/core/widgets/glass_card.dart';

import 'package:chpa/core/constants/app_constants.dart';
import 'package:chpa/core/utils/audio_utils.dart';
import 'package:chpa/features/content/infrastructure/content_model_mapper.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = ref.watch(bookmarksProvider);
    final tangibleBookmarks = bookmarks
        .where(
          (bookmark) => bookmark.matchesClassification(
            AppConstants.classificationTangible,
          ),
        )
        .toList()
      ..sort((a, b) => b.bookmarkedAt.compareTo(a.bookmarkedAt));
    final intangibleBookmarks = bookmarks
        .where(
          (bookmark) => bookmark.matchesClassification(
            AppConstants.classificationIntangible,
          ),
        )
        .toList()
      ..sort((a, b) => b.bookmarkedAt.compareTo(a.bookmarkedAt));

    return Scaffold(
      backgroundColor: AppTheme.kBg,
      appBar: SharedAppBar(
        title: 'My Library',
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.kAccent,
          labelColor: AppTheme.kAccent,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(
              child: Text(
                'TANGIBLE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Tab(
              child: Text(
                'INTANGIBLE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookmarkList(tangibleBookmarks),
          _buildBookmarkList(intangibleBookmarks),
        ],
      ),
    );
  }

  Widget _buildBookmarkList(List<BookmarkItem> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 80,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            const TranslatedText(
              'Your library is empty',
              style: TextStyle(fontSize: 18, color: Colors.white54),
            ),
            const SizedBox(height: 8),
            const TranslatedText(
              'Save archives, Analyses, and 3D views here',
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _BookmarkTile(item: item);
      },
    );
  }
}

class _BookmarkTile extends ConsumerWidget {
  final BookmarkItem item;
  const _BookmarkTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    IconData iconData;
    Color iconColor;
    String typeLabel;

    switch (item.type) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        typeLabel = 'Book/PDF';
        break;
      case 'worksheet':
        iconData = Icons.assignment;
        iconColor = Colors.teal;
        typeLabel = 'Worksheet';
        break;
      case 'analysis':
        iconData = Icons.psychology;
        iconColor = Colors.orange;
        typeLabel = 'Analysis';
        break;
      case 'artifact_3d':
        iconData = Icons.view_in_ar;
        iconColor = Colors.blue;
        typeLabel = '3D View';
        break;
      case 'artifact':
        iconData = Icons.museum;
        iconColor = AppTheme.primaryColor;
        typeLabel = 'Artifact';
        break;
      case 'audio':
        iconData = Icons.audiotrack_rounded;
        iconColor = Colors.purpleAccent;
        typeLabel = 'Audio';
        break;
      case 'video':
        iconData = Icons.videocam_rounded;
        iconColor = AppTheme.kAncientBlue;
        typeLabel = 'Video';
        break;
      default:
        iconData = Icons.bookmark;
        iconColor = Colors.grey;
        typeLabel = 'Other';
    }

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 16,
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(iconData, color: iconColor),
        ),
        title: TranslatedText(
          item.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            TranslatedText(
              typeLabel,
              style: TextStyle(
                color: iconColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            TranslatedText(
              'Saved on ${_formatDate(item.bookmarkedAt)}',
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.bookmark_remove, color: Colors.grey),
          onPressed: () async {
            final isAdded = await ref
                .read(bookmarksProvider.notifier)
                .toggleBookmark(item);
            if (context.mounted && !isAdded) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: TranslatedText('Bookmark removed successfully!'),
                ),
              );
            }
          },
        ),
        onTap: () => _handleNavigation(context, ref, item),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleNavigation(BuildContext context, WidgetRef ref, BookmarkItem item) {
    switch (item.type) {
      case 'pdf':
      case 'worksheet':
        context.push('/pdf-viewer', extra: item.extraData);
        break;
      case 'analysis':
        context.push('/analysis-taking', extra: item.extraData);
        break;
      case 'artifact_3d':
        context.push('/artifact-3d', extra: item.extraData);
        break;
      case 'artifact':
        context.push('/artifact-viewer', extra: item.extraData);
        break;
      case 'audio':
        final content = contentModelFromJson(item.extraData);
        showAudioPreview(context, ref, content);
        break;
      case 'video':
        context.push('/video-viewer', extra: item.extraData);
        break;
    }
  }
}
