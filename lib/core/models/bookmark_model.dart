import '../../features/bookmark/domain/bookmark_domain.dart';

class BookmarkModel extends BookmarkItem {
  BookmarkModel({
    required super.id,
    required super.title,
    required super.type,
    super.extraData,
    required super.bookmarkedAt,
  });

  factory BookmarkModel.fromDomain(BookmarkItem bookmark) {
    return BookmarkModel(
      id: bookmark.id,
      title: bookmark.title,
      type: bookmark.type,
      extraData: bookmark.extraData,
      bookmarkedAt: bookmark.bookmarkedAt,
    );
  }

}
