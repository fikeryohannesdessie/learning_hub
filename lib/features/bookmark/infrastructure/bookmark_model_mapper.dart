import 'dart:convert';

import '../../../core/models/bookmark_model.dart';
import 'bookmark_dto.dart';

BookmarkModel bookmarkModelFromJson(Map<String, dynamic> json) {
  Map<String, dynamic> safeExtra = <String, dynamic>{};
  final extra = json['extraData'] ?? json['ExtraData'] ?? const <String, dynamic>{};
  if (extra != null) {
    try {
      final encoded = jsonEncode(extra);
      safeExtra = Map<String, dynamic>.from(jsonDecode(encoded) as Map);
    } catch (_) {
      safeExtra = Map<String, dynamic>.from(extra as Map);
    }
  }

  return BookmarkModel.fromDomain(
    BookmarkDto.fromJson(<String, dynamic>{...json, 'extraData': safeExtra}).toDomain(),
  );
}

Map<String, dynamic> bookmarkModelToJson(BookmarkModel model) {
  return BookmarkDto.fromDomain(model).toJson();
}
