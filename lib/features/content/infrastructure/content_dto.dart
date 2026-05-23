import '../domain/content_domain.dart';


class ContentDto {
  final String id;
  final String title;
  final String type;
  final String authorId;
  final String authorName;
  final String status;
  final String? url;
  final String? gradeLevel;
  final String? subject;
  final String? description;
  final DateTime uploadedAt;
  final DateTime? approvedAt;
  final Map<String, dynamic>? extraData;
  final String? rejectionReason;

  const ContentDto({
    required this.id,
    required this.title,
    required this.type,
    required this.authorId,
    required this.authorName,
    required this.status,
    this.url,
    this.gradeLevel,
    this.subject,
    this.description,
    required this.uploadedAt,
    this.approvedAt,
    this.extraData,
    this.rejectionReason,
  });

  factory ContentDto.fromJson(Map<String, dynamic> json) {
    return ContentDto(
      id: (json['id'] ?? json['Id'] ?? '') as String,
      title: (json['title'] ?? json['Title'] ?? 'Untitled') as String,
      type: (json['type'] ?? json['Type'] ?? 'document') as String,
      authorId: (json['authorId'] ?? json['AuthorId'] ?? json['author_id'] ?? '')
          as String,
      authorName:
          (json['authorName'] ?? json['AuthorName'] ?? json['author_name'] ?? 'Anonymous')
              as String,
      status: (json['status'] ?? json['Status'] ?? 'pending') as String,
      url: (json['url'] ?? json['Url']) as String?,
      gradeLevel:
          (json['gradeLevel'] ?? json['GradeLevel'] ?? json['grade_level'] ?? 'highschool')
              as String?,
      subject: (json['subject'] ?? json['Subject'] ?? 'General') as String?,
      description: (json['description'] ?? json['Description']) as String?,
      uploadedAt: DateTime.tryParse(
            (json['uploadedAt'] ?? json['UploadedAt'] ?? json['uploaded_at'] ?? '')
                as String,
          ) ??
          DateTime.now(),
      approvedAt: json['approvedAt'] != null
          ? DateTime.tryParse(json['approvedAt'] as String)
          : json['approved_at'] != null
              ? DateTime.tryParse(json['approved_at'] as String)
              : null,
      extraData: json['extraData'] != null
          ? Map<String, dynamic>.from(json['extraData'] as Map)
          : json['extra_data'] is String
              ? null
              : null,
      rejectionReason:
          (json['rejectionReason'] ?? json['RejectionReason'] ?? json['rejection_reason'])
              as String?,
    );
  }

  factory ContentDto.fromRow(Map<String, dynamic> row, {Map<String, dynamic>? extraData}) {
    return ContentDto(
      id: row['id'] as String,
      title: row['title'] as String,
      type: row['type'] as String,
      authorId: row['author_id'] as String,
      authorName: row['author_name'] as String,
      status: row['status'] as String,
      url: row['url'] as String?,
      gradeLevel: row['grade_level'] as String?,
      subject: row['subject'] as String?,
      description: row['description'] as String?,
      uploadedAt: DateTime.parse(row['uploaded_at'] as String),
      approvedAt: row['approved_at'] != null
          ? DateTime.tryParse(row['approved_at'] as String)
          : null,
      extraData: extraData,
      rejectionReason: row['rejection_reason'] as String?,
    );
  }

  factory ContentDto.fromDomain(LearningContent content) {
    return ContentDto(
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

  LearningContent toDomain() {
    return LearningContent(
      id: id,
      title: title,
      type: type,
      authorId: authorId,
      authorName: authorName,
      status: status,
      url: url,
      gradeLevel: gradeLevel,
      subject: subject,
      description: description,
      uploadedAt: uploadedAt,
      approvedAt: approvedAt,
      extraData: extraData,
      rejectionReason: rejectionReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'authorId': authorId,
      'authorName': authorName,
      'status': status,
      'url': url,
      'gradeLevel': gradeLevel,
      'subject': subject,
      'description': description,
      'uploadedAt': uploadedAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'extraData': extraData,
      'rejectionReason': rejectionReason,
    };
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'author_id': authorId,
      'author_name': authorName,
      'status': status,
      'url': url,
      'grade_level': gradeLevel,
      'subject': subject,
      'description': description,
      'rejection_reason': rejectionReason,
      'uploaded_at': uploadedAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
    };
  }
}
