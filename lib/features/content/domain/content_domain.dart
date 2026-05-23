import 'dart:typed_data';

class LearningContent {
  final String id;
  final String title;
  final String type; // pdf, analysis
  final String authorId;
  final String authorName;
  final String status; // pending, approved, rejected
  final String? url;
  final String? gradeLevel;
  final String? subject;
  final String? description;
  final DateTime uploadedAt;
  final DateTime? approvedAt;
  final Map<String, dynamic>? extraData;
  final String? rejectionReason;

  const LearningContent({
    required this.id,
    required this.title,
    required this.type,
    required this.authorId,
    required this.authorName,
    this.status = 'pending',
    this.url,
    this.gradeLevel = 'highschool',
    this.subject = 'General',
    this.description,
    required this.uploadedAt,
    this.approvedAt,
    this.extraData,
    this.rejectionReason,
  });

  LearningContent copyWith({
    String? id,
    String? title,
    String? type,
    String? authorId,
    String? authorName,
    String? status,
    String? url,
    String? gradeLevel,
    String? subject,
    String? description,
    DateTime? uploadedAt,
    DateTime? approvedAt,
    Map<String, dynamic>? extraData,
    String? rejectionReason,
  }) {
    return LearningContent(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      status: status ?? this.status,
      url: url ?? this.url,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      extraData: extraData ?? this.extraData,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

sealed class ContentFailure implements Exception {
  const ContentFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class IContentRepository {
  Stream<List<LearningContent>> getApprovedContent({
    required String gradeLevel,
    String? type,
  });

  Stream<List<LearningContent>> getAllContent();

  Stream<List<LearningContent>> getContributorContent(String contributorId);

  Stream<List<LearningContent>> getPendingContent();

  Future<void> uploadContent(
    LearningContent content, {
    List<int>? bytes,
  });

  Future<void> updateContentStatus(
    String contentId,
    String status, {
    String? reason,
  });

  Future<Uint8List?> getFileBytes(String contentId);

  Future<void> upsertFileBytes(String contentId, Uint8List bytes);

  Future<void> deleteContentByAuthorId(String authorId);
}
