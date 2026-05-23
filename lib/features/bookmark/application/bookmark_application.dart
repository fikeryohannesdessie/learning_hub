import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/bookmark_domain.dart';
import '../infrastructure/bookmark_infrastructure.dart';

final bookmarkLocalDataSourceProvider = Provider<BookmarkLocalDataSource>((ref) {
  return BookmarkLocalDataSource();
});

final bookmarkRepositoryProvider = Provider<IBookmarkRepository>((ref) {
  return BookmarkRepositoryImpl(ref.watch(bookmarkLocalDataSourceProvider));
});

final bookmarksProvider =
    NotifierProvider<BookmarkController, List<BookmarkItem>>(
      BookmarkController.new,
    );

class BookmarkController extends Notifier<List<BookmarkItem>> {
  @override
  List<BookmarkItem> build() {
    Future.microtask(_load);
    return [];
  }

  IBookmarkRepository get _repository => ref.read(bookmarkRepositoryProvider);

  Future<void> _load() async {
    state = await _repository.getBookmarks();
  }

  Future<bool> toggleBookmark(BookmarkItem bookmark) async {
    final isAdded = await _repository.toggleBookmark(bookmark);
    await _load();
    return isAdded;
  }

  bool isBookmarked(String id) => state.any((bookmark) => bookmark.id == id);
}
