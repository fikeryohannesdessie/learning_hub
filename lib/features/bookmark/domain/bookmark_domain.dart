const String _contentTypeArtifact = 'artifact';
const String _contentTypeAnalysis = 'analysis';
const String _contentTypeAudio = 'audio';
const String _classificationTangible = 'tangible';
const String _classificationIntangible = 'intangible';

class BookmarkItem {
  final String id;
  final String title;
  final String type; // pdf, analysis, artifact_3d, artifact
  final Map<String, dynamic> extraData;
  final DateTime bookmarkedAt;

  const BookmarkItem({
    required this.id,
    required this.title,
    required this.type,
    this.extraData = const {},
    required this.bookmarkedAt,
  });

  BookmarkItem copyWith({
    String? id,
    String? title,
    String? type,
    Map<String, dynamic>? extraData,
    DateTime? bookmarkedAt,
  }) {
    return BookmarkItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      extraData: extraData ?? this.extraData,
      bookmarkedAt: bookmarkedAt ?? this.bookmarkedAt,
    );
  }

  String? get classification {
    final direct = _extractClassification(extraData);
    if (direct != null) {
      return direct;
    }

    if (type == _contentTypeArtifact || type == 'artifact_3d') {
      return _classificationTangible;
    }

    if (type == _contentTypeAudio) {
      return _classificationIntangible;
    }

    if (type == _contentTypeAnalysis &&
        extraData['artifactId'] != null) {
      return _classificationTangible;
    }

    return null;
  }

  bool matchesClassification(String targetClassification) {
    return classification == _normalizeClassification(targetClassification);
  }
}

String? _extractClassification(Map<String, dynamic> data) {
  final normalized = _normalizeClassification(
    data['classification'] ?? data['gradeLevel'],
  );
  if (normalized != null) {
    return normalized;
  }

  final nested = data['extraData'];
  if (nested is Map) {
    return _extractClassification(Map<String, dynamic>.from(nested));
  }

  return null;
}

String? _normalizeClassification(Object? value) {
  if (value is! String) {
    return null;
  }

  switch (value.trim().toLowerCase()) {
    case 'tangible':
      return _classificationTangible;
    case 'intangible':
      return _classificationIntangible;
    case 'highschool':
      return _classificationTangible;
    case 'college':
    case 'university':
      return _classificationIntangible;
    default:
      return null;
  }
}

abstract class IBookmarkRepository {
  Future<List<BookmarkItem>> getBookmarks();

  Future<bool> toggleBookmark(BookmarkItem bookmark);

  Future<bool> isBookmarked(String id);
}
