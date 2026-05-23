import '../../features/content/domain/content_domain.dart';

class ContentModel extends LearningContent {
  ContentModel({
    required super.id,
    required super.title,
    required super.type,
    required super.authorId,
    required super.authorName,
    super.status,
    super.url,
    super.gradeLevel,
    super.subject,
    super.description,
    required super.uploadedAt,
    super.approvedAt,
    super.extraData,
    super.rejectionReason,
  });

  factory ContentModel.fromDomain(LearningContent content) {
    return ContentModel(
      id: content.id,
      title: content.title,
      type: content.type,
      authorId: content.authorId,
      authorName: content.authorName,
      status: content.status,
      url: content.url,
      gradeLevel: content.gradeLevel,
      subject: content.subject,
      description: content.description,
      uploadedAt: content.uploadedAt,
      approvedAt: content.approvedAt,
      extraData: content.extraData,
      rejectionReason: content.rejectionReason,
    );
  }

  @override
  ContentModel copyWith({
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
    return ContentModel(
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
