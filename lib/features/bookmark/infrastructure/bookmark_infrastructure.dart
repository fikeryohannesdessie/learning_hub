import 'dart:convert';

import '../../../core/storage/database_helper.dart';
import '../domain/bookmark_domain.dart';
import 'bookmark_dto.dart';

class BookmarkLocalDataSource {
  BookmarkItem mapRowToBookmark(Map<String, dynamic> row) {
    Map<String, dynamic> extraData = {};
    final raw = row['extra_data'] as String?;
    if (raw != null && raw.isNotEmpty) {
      try {
        extraData = Map<String, dynamic>.from(jsonDecode(raw));
      } catch (_) {}
    }

    return BookmarkDto.fromRow(row, extraData).toDomain();
  }

  Map<String, dynamic> mapBookmarkToRow(BookmarkItem bookmark) {
    final row = BookmarkDto.fromDomain(bookmark).toRow();
    row['extra_data'] = jsonEncode(bookmark.extraData);
    return row;
  }

  Future<List<BookmarkItem>> getBookmarks() async {
    final rows = await db.getAllBookmarks();
    return rows.map(mapRowToBookmark).toList();
  }

  Future<bool> toggleBookmark(BookmarkItem bookmark) async {
    final exists = await db.bookmarkExists(bookmark.id);
    if (exists) {
      await db.deleteBookmark(bookmark.id);
      return false;
    }

    await db.upsertBookmark(mapBookmarkToRow(bookmark));
    return true;
  }

  Future<bool> isBookmarked(String id) {
    return db.bookmarkExists(id);
  }
}

class BookmarkRepositoryImpl implements IBookmarkRepository {
  BookmarkRepositoryImpl(this._localDataSource);

  final BookmarkLocalDataSource _localDataSource;

  @override
  Future<List<BookmarkItem>> getBookmarks() {
    return _localDataSource.getBookmarks();
  }

  @override
  Future<bool> toggleBookmark(BookmarkItem bookmark) {
    return _localDataSource.toggleBookmark(bookmark);
  }

  @override
  Future<bool> isBookmarked(String id) {
    return _localDataSource.isBookmarked(id);
  }
}
