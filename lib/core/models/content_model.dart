class ContentModel {
  final String id;
  final String title;
  final String type; // pdf, Analysis
  final String authorId;
  final String authorName;
  final String status; // pending, approved, rejected
  final String? url; // Firebase Storage URL
  final String? gradeLevel; // highschool, college
  final String? subject;
  final String? description;
  final DateTime uploadedAt;
  final DateTime? approvedAt;
  final Map<String, dynamic>? extraData;
  final String? rejectionReason;

  ContentModel({
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

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    return ContentModel(
      id: (json['id'] ?? json['Id'] ?? '') as String,
      title: (json['title'] ?? json['Title'] ?? 'Untitled') as String,
      type: (json['type'] ?? json['Type'] ?? 'document') as String,
      authorId: (json['authorId'] ?? json['AuthorId'] ?? '') as String,
      authorName: (json['authorName'] ?? json['AuthorName'] ?? 'Anonymous') as String,
      status: (json['status'] ?? json['Status'] ?? 'pending') as String,
      url: (json['url'] ?? json['Url']) as String?,
      gradeLevel: (json['gradeLevel'] ?? json['GradeLevel'] ?? 'tangible') as String?,
      subject: (json['subject'] ?? json['Subject'] ?? 'General') as String?,
      description: (json['description'] ?? json['Description']) as String?,
      uploadedAt: DateTime.tryParse((json['uploadedAt'] ?? json['UploadedAt'] ?? '') as String) ?? DateTime.now(),
      approvedAt: json['approvedAt'] != null ? DateTime.tryParse(json['approvedAt'] as String) : null,
      extraData: json['extraData'] != null ? Map<String, dynamic>.from(json['extraData'] as Map) : null,
      rejectionReason: (json['rejectionReason'] ?? json['RejectionReason']) as String?,
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
      'subject': subject ?? 'General',
      'gradeLevel': gradeLevel ?? 'highschool',
      'description': description,
      'uploadedAt': uploadedAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'extraData': extraData,
      'rejectionReason': rejectionReason,
    };
  }

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
