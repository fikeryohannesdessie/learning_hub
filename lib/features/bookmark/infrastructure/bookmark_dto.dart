import '../domain/bookmark_domain.dart';

class BookmarkDto {
  final String id;
  final String title;
  final String type;
  final Map<String, dynamic> extraData;
  final DateTime bookmarkedAt;

  const BookmarkDto({
    required this.id,
    required this.title,
    required this.type,
    required this.extraData,
    required this.bookmarkedAt,
  });

  factory BookmarkDto.fromJson(Map<String, dynamic> json) {
    return BookmarkDto(
      id: (json['id'] ?? json['Id'] ?? '') as String,
      title: (json['title'] ?? json['Title'] ?? 'Untitled') as String,
      type: (json['type'] ?? json['Type'] ?? 'artifact') as String,
      extraData: Map<String, dynamic>.from(
        json['extraData'] ?? json['ExtraData'] ?? const {},
      ),
      bookmarkedAt: DateTime.tryParse(
            (json['bookmarkedAt'] ?? json['BookmarkedAt'] ?? '') as String,
          ) ??
          DateTime.now(),
    );
  }

  factory BookmarkDto.fromRow(Map<String, dynamic> row, Map<String, dynamic> extraData) {
    return BookmarkDto(
      id: row['id'] as String,
      title: row['title'] as String,
      type: row['type'] as String,
      extraData: extraData,
      bookmarkedAt: DateTime.parse(row['bookmarked_at'] as String),
    );
  }

  factory BookmarkDto.fromDomain(BookmarkItem bookmark) {
    return BookmarkDto(
      id: bookmark.id,
      title: bookmark.title,
      type: bookmark.type,
      extraData: bookmark.extraData,
      bookmarkedAt: bookmark.bookmarkedAt,
    );
  }

  BookmarkItem toDomain() {
    return BookmarkItem(
      id: id,
      title: title,
      type: type,
      extraData: extraData,
      bookmarkedAt: bookmarkedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'extraData': extraData,
      'bookmarkedAt': bookmarkedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'bookmarked_at': bookmarkedAt.toIso8601String(),
    };
  }
}
