import '../domain/artifact_domain.dart';

class ArtifactDto {
  final String id;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final String status;
  final List<HeritageSectionDto> sections;
  final List<String> viewerIds;
  final DateTime createdAt;
  final String? rejectionReason;
  final String? thumbnailUrl;
  final bool isSequential;
  final String classification;
  final String? detailedDescription;
  final List<String>? heritageSignificance;

  const ArtifactDto({
    required this.id,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.status,
    required this.sections,
    required this.viewerIds,
    required this.createdAt,
    this.rejectionReason,
    this.thumbnailUrl,
    required this.isSequential,
    required this.classification,
    this.detailedDescription,
    this.heritageSignificance,
  });

  factory ArtifactDto.fromJson(Map<String, dynamic> json) {
    final rawStatus = ((json['status'] ?? json['Status'] ?? 'pending') as String)
        .trim()
        .toLowerCase();
    final normalizedStatus = rawStatus.isEmpty
        ? 'pending'
        : (rawStatus == 'approved' || rawStatus == 'rejected'
            ? rawStatus
            : 'pending');

    final rawClassification =
        ((json['classification'] ?? json['Classification'] ?? json['gradeLevel'] ?? 'tangible')
                as String)
            .trim()
            .toLowerCase();
    final normalizedClassification =
        rawClassification == 'intangible' ? 'intangible' : 'tangible';

    return ArtifactDto(
      id: (json['id'] ?? json['Id'] ?? '') as String,
      title: (json['title'] ?? json['Title'] ?? 'Untitled Artifact') as String,
      description: (json['description'] ?? json['Description'] ?? '') as String,
      authorId: (json['authorId'] ?? json['AuthorId'] ?? '') as String,
      authorName:
          (json['authorName'] ?? json['AuthorName'] ?? 'Anonymous') as String,
      status: normalizedStatus,
      sections: (json['sections'] ?? json['Sections'] ?? json['chapters'] ?? [])
          .map<HeritageSectionDto>(
            (e) => HeritageSectionDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      viewerIds:
          List<String>.from(json['viewerIds'] ?? json['enrolledViewerIds'] ?? []),
      createdAt: DateTime.tryParse(
            (json['createdAt'] ?? json['CreatedAt'] ?? '') as String,
          ) ??
          DateTime.now(),
      rejectionReason:
          (json['rejectionReason'] ?? json['RejectionReason']) as String?,
      thumbnailUrl: (json['thumbnailUrl'] ?? json['ThumbnailUrl'] ?? '') as String,
      isSequential: (json['isSequential'] ?? json['IsSequential'] ?? true) as bool,
      classification: normalizedClassification,
      detailedDescription:
          (json['detailedDescription'] ?? json['DetailedDescription']) as String?,
      heritageSignificance: List<String>.from(
        json['heritageSignificance'] ?? json['HeritageOutcomes'] ?? [],
      ),
    );
  }

  factory ArtifactDto.fromRow(
    Map<String, dynamic> row, {
    required List<HeritageSectionDto> sections,
    required List<String> viewerIds,
    List<String>? heritageSignificance,
  }) {
    return ArtifactDto(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String,
      authorId: row['author_id'] as String,
      authorName: row['author_name'] as String,
      status: row['status'] as String,
      sections: sections,
      viewerIds: viewerIds,
      createdAt: DateTime.parse(row['created_at'] as String),
      rejectionReason: row['rejection_reason'] as String?,
      thumbnailUrl: row['thumbnail_url'] as String?,
      isSequential: (row['is_sequential'] as int) == 1,
      classification: row['classification'] as String? ?? 'tangible',
      detailedDescription: row['detailed_description'] as String?,
      heritageSignificance: heritageSignificance,
    );
  }

  factory ArtifactDto.fromDomain(Artifact artifact) {
    return ArtifactDto(
      id: artifact.id,
      title: artifact.title,
      description: artifact.description,
      authorId: artifact.authorId,
      authorName: artifact.authorName,
      status: artifact.status,
      sections: artifact.sections.map(HeritageSectionDto.fromDomain).toList(),
      viewerIds: artifact.viewerIds,
      createdAt: artifact.createdAt,
      rejectionReason: artifact.rejectionReason,
      thumbnailUrl: artifact.thumbnailUrl,
      isSequential: artifact.isSequential,
      classification: artifact.classification,
      detailedDescription: artifact.detailedDescription,
      heritageSignificance: artifact.heritageSignificance,
    );
  }

  Artifact toDomain() {
    return Artifact(
      id: id,
      title: title,
      description: description,
      authorId: authorId,
      authorName: authorName,
      status: status,
      sections: sections.map((e) => e.toDomain()).toList(),
      viewerIds: viewerIds,
      createdAt: createdAt,
      rejectionReason: rejectionReason,
      thumbnailUrl: thumbnailUrl,
      isSequential: isSequential,
      classification: classification,
      detailedDescription: detailedDescription,
      heritageSignificance: heritageSignificance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'authorId': authorId,
      'authorName': authorName,
      'status': status,
      'sections': sections.map((e) => e.toJson()).toList(),
      'viewerIds': viewerIds,
      'createdAt': createdAt.toIso8601String(),
      'rejectionReason': rejectionReason,
      'thumbnailUrl': thumbnailUrl ?? '',
      'isSequential': isSequential,
      'classification': classification,
      'detailedDescription': detailedDescription,
      'heritageSignificance': heritageSignificance,
    };
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'author_id': authorId,
      'author_name': authorName,
      'status': status,
      'rejection_reason': rejectionReason,
      'thumbnail_url': thumbnailUrl ?? '',
      'is_sequential': isSequential ? 1 : 0,
      'classification': classification,
      'detailed_description': detailedDescription,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class HeritageSectionDto {
  final String id;
  final String title;
  final List<HeritagePartDto> parts;
  final AnalysisDto? analysis;

  const HeritageSectionDto({
    required this.id,
    required this.title,
    required this.parts,
    this.analysis,
  });

  factory HeritageSectionDto.fromJson(Map<String, dynamic> json) {
    return HeritageSectionDto(
      id: (json['id'] ?? json['Id'] ?? '') as String,
      title: (json['title'] ?? json['Title'] ?? 'Untitled Section') as String,
      parts: (json['parts'] ?? json['Parts'] ?? json['topics'] ?? [])
          .map<HeritagePartDto>(
            (e) => HeritagePartDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      analysis: json['analysis'] != null
          ? AnalysisDto.fromJson(Map<String, dynamic>.from(json['analysis']))
          : json['Analysis'] != null
              ? AnalysisDto.fromJson(Map<String, dynamic>.from(json['Analysis']))
              : json['quiz'] != null
                  ? AnalysisDto.fromJson(Map<String, dynamic>.from(json['quiz']))
                  : null,
    );
  }

  factory HeritageSectionDto.fromDomain(HeritageSection section) {
    return HeritageSectionDto(
      id: section.id,
      title: section.title,
      parts: section.parts.map(HeritagePartDto.fromDomain).toList(),
      analysis: section.analysis != null ? AnalysisDto.fromDomain(section.analysis!) : null,
    );
  }

  HeritageSection toDomain() {
    return HeritageSection(
      id: id,
      title: title,
      parts: parts.map((e) => e.toDomain()).toList(),
      analysis: analysis?.toDomain(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'parts': parts.map((e) => e.toJson()).toList(),
      'analysis': analysis?.toJson(),
    };
  }
}

class HeritagePartDto {
  final String id;
  final String title;
  final List<ArtifactDetailDto> details;

  const HeritagePartDto({
    required this.id,
    required this.title,
    required this.details,
  });

  factory HeritagePartDto.fromJson(Map<String, dynamic> json) {
    return HeritagePartDto(
      id: (json['id'] ?? json['Id'] ?? '') as String,
      title: (json['title'] ?? json['Title'] ?? 'Untitled Part') as String,
      details: (json['details'] ?? json['Details'] ?? json['subtopics'] ?? [])
          .map<ArtifactDetailDto>(
            (e) => ArtifactDetailDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }

  factory HeritagePartDto.fromDomain(HeritagePart part) {
    return HeritagePartDto(
      id: part.id,
      title: part.title,
      details: part.details.map(ArtifactDetailDto.fromDomain).toList(),
    );
  }

  HeritagePart toDomain() {
    return HeritagePart(
      id: id,
      title: title,
      details: details.map((e) => e.toDomain()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'details': details.map((e) => e.toJson()).toList(),
    };
  }
}

class ArtifactDetailDto {
  final String id;
  final String title;
  final List<ArtifactContentItemDto> contents;

  const ArtifactDetailDto({
    required this.id,
    required this.title,
    required this.contents,
  });

  factory ArtifactDetailDto.fromJson(Map<String, dynamic> json) {
    return ArtifactDetailDto(
      id: (json['id'] ?? json['Id'] ?? '') as String,
      title: (json['title'] ?? json['Title'] ?? 'Untitled Detail') as String,
      contents: (json['contents'] ?? json['Contents'] ?? [])
          .map<ArtifactContentItemDto>(
            (e) => ArtifactContentItemDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }

  factory ArtifactDetailDto.fromDomain(ArtifactDetail detail) {
    return ArtifactDetailDto(
      id: detail.id,
      title: detail.title,
      contents: detail.contents.map(ArtifactContentItemDto.fromDomain).toList(),
    );
  }

  ArtifactDetail toDomain() {
    return ArtifactDetail(
      id: id,
      title: title,
      contents: contents.map((e) => e.toDomain()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'contents': contents.map((e) => e.toJson()).toList(),
    };
  }
}

class ArtifactContentItemDto {
  final String type;
  final String? text;
  final String? fileId;
  final String? url;
  final String? simulationId;
  final String id;
  final String title;
  final bool isResource;
  final String? resourceCategory;

  const ArtifactContentItemDto({
    required this.type,
    this.text,
    this.fileId,
    this.url,
    this.simulationId,
    required this.id,
    required this.title,
    required this.isResource,
    this.resourceCategory,
  });

  factory ArtifactContentItemDto.fromJson(Map<String, dynamic> json) {
    return ArtifactContentItemDto(
      type: (json['type'] ?? json['Type'] ?? 'text') as String,
      text: (json['text'] ?? json['Text']) as String?,
      fileId: (json['fileId'] ?? json['FileId']) as String?,
      url: (json['url'] ?? json['Url']) as String?,
      simulationId: (json['simulationId'] ?? json['SimulationId']) as String?,
      id: (json['id'] ?? json['Id'] ?? '') as String,
      title: (json['title'] ?? json['Title'] ?? 'Untitled Item') as String,
      isResource: (json['isResource'] ?? json['IsResource'] ?? false) as bool,
      resourceCategory:
          (json['resourceCategory'] ?? json['ResourceCategory']) as String?,
    );
  }

  factory ArtifactContentItemDto.fromDomain(ArtifactContentItem item) {
    return ArtifactContentItemDto(
      type: item.type,
      text: item.text,
      fileId: item.fileId,
      url: item.url,
      simulationId: item.simulationId,
      id: item.id,
      title: item.title,
      isResource: item.isResource,
      resourceCategory: item.resourceCategory,
    );
  }

  ArtifactContentItem toDomain() {
    return ArtifactContentItem(
      type: type,
      text: text,
      fileId: fileId,
      url: url,
      simulationId: simulationId,
      id: id,
      title: title,
      isResource: isResource,
      resourceCategory: resourceCategory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'text': text,
      'fileId': fileId,
      'url': url,
      'simulationId': simulationId,
      'id': id,
      'title': title,
      'isResource': isResource,
      'resourceCategory': resourceCategory,
    };
  }
}

class AnalysisDto {
  final String id;
  final List<EvidenceDto> evidence;

  const AnalysisDto({
    required this.id,
    required this.evidence,
  });

  factory AnalysisDto.fromJson(Map<String, dynamic> json) {
    return AnalysisDto(
      id: (json['id'] ?? json['Id'] ?? '') as String,
      evidence: (json['evidence'] ??
              json['Evidence'] ??
              json['evidences'] ??
              json['questions'] ??
              [])
          .map<EvidenceDto>(
            (e) => EvidenceDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }

  factory AnalysisDto.fromDomain(Analysis analysis) {
    return AnalysisDto(
      id: analysis.id,
      evidence: analysis.evidence.map(EvidenceDto.fromDomain).toList(),
    );
  }

  Analysis toDomain() {
    return Analysis(
      id: id,
      evidence: evidence.map((e) => e.toDomain()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'evidence': evidence.map((e) => e.toJson()).toList()};
  }
}

class EvidenceDto {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final bool isShortAnswer;
  final String? correctShortAnswer;

  const EvidenceDto({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.isShortAnswer,
    this.correctShortAnswer,
  });

  factory EvidenceDto.fromJson(Map<String, dynamic> json) {
    return EvidenceDto(
      questionText: (json['questionText'] ?? '') != ''
          ? json['questionText'] as String
          : (json['factText'] ?? json['FactText'] ?? '') as String,
      options: List<String>.from(
        json['options'] ?? json['Options'] ?? json['possibilities'] ?? [],
      ),
      correctAnswerIndex:
          (json['correctAnswerIndex'] ??
                  json['CorrectAnswerIndex'] ??
                  json['verifiedIndex'] ??
                  0)
              as int,
      isShortAnswer:
          (json['isShortAnswer'] ??
                  json['IsShortAnswer'] ??
                  json['isSummary'] ??
                  false)
              as bool,
      correctShortAnswer:
          (json['correctShortAnswer'] ??
                  json['CorrectShortAnswer'] ??
                  json['summaryText'])
              as String?,
    );
  }

  factory EvidenceDto.fromDomain(Evidence evidence) {
    return EvidenceDto(
      questionText: evidence.questionText,
      options: evidence.options,
      correctAnswerIndex: evidence.correctAnswerIndex,
      isShortAnswer: evidence.isShortAnswer,
      correctShortAnswer: evidence.correctShortAnswer,
    );
  }

  Evidence toDomain() {
    return Evidence(
      questionText: questionText,
      options: options,
      correctAnswerIndex: correctAnswerIndex,
      isShortAnswer: isShortAnswer,
      correctShortAnswer: correctShortAnswer,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'isShortAnswer': isShortAnswer,
      'correctShortAnswer': correctShortAnswer,
    };
  }
}

class AnalysisResultDto {
  final String userId;
  final String artifactId;
  final String sectionId;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;
  final String userName;

  const AnalysisResultDto({
    required this.userId,
    required this.userName,
    required this.artifactId,
    required this.sectionId,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
  });

  factory AnalysisResultDto.fromJson(Map<String, dynamic> json) {
    return AnalysisResultDto(
      userId: (json['userId'] ?? json['UserId'] ?? json['user_id'] ?? '') as String,
      userName:
          (json['userName'] ?? json['UserName'] ?? json['user_name'] ?? json['viewerName'] ?? 'Viewer')
              as String,
      artifactId:
          (json['artifactId'] ?? json['ArtifactId'] ?? json['artifact_id'] ?? '') as String,
      sectionId:
          (json['sectionId'] ?? json['SectionId'] ?? json['section_id'] ?? '') as String,
      score: (json['score'] ?? json['Score'] ?? 0) as int,
      totalQuestions:
          (json['totalQuestions'] ??
                  json['TotalQuestions'] ??
                  json['total_questions'] ??
                  json['totalEvidences'] ??
                  0)
              as int,
      completedAt: DateTime.tryParse(
            (json['completedAt'] ?? json['CompletedAt'] ?? json['completed_at'] ?? '')
                as String,
          ) ??
          DateTime.now(),
    );
  }

  factory AnalysisResultDto.fromDomain(AnalysisResult result) {
    return AnalysisResultDto(
      userId: result.userId,
      userName: result.userName,
      artifactId: result.artifactId,
      sectionId: result.sectionId,
      score: result.score,
      totalQuestions: result.totalQuestions,
      completedAt: result.completedAt,
    );
  }

  AnalysisResult toDomain() {
    return AnalysisResult(
      userId: userId,
      userName: userName,
      artifactId: artifactId,
      sectionId: sectionId,
      score: score,
      totalQuestions: totalQuestions,
      completedAt: completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'artifactId': artifactId,
      'sectionId': sectionId,
      'score': score,
      'totalQuestions': totalQuestions,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toRow(String id) {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'artifact_id': artifactId,
      'section_id': sectionId,
      'score': score,
      'total_questions': totalQuestions,
      'completed_at': completedAt.toIso8601String(),
    };
  }
}

class UserProgressDto {
  final String userId;
  final String artifactId;
  final List<String> completedContentIds;
  final Map<String, int> analysisScores;
  final String? lastAccessedItemId;
  final DateTime lastAccessedAt;
  final int timeSpentSeconds;

  const UserProgressDto({
    required this.userId,
    required this.artifactId,
    required this.completedContentIds,
    required this.analysisScores,
    this.lastAccessedItemId,
    required this.lastAccessedAt,
    required this.timeSpentSeconds,
  });

  factory UserProgressDto.fromJson(Map<String, dynamic> json) {
    return UserProgressDto(
      userId: (json['userId'] ?? json['UserId'] ?? json['user_id'] ?? '') as String,
      artifactId:
          (json['artifactId'] ?? json['ArtifactId'] ?? json['artifact_id'] ?? '') as String,
      completedContentIds: List<String>.from(
        json['completedContentIds'] ?? json['CompletedContentIds'] ?? [],
      ),
      analysisScores:
          Map<String, int>.from(json['analysisScores'] ?? json['AnalysisScores'] ?? {}),
      lastAccessedItemId:
          (json['lastAccessedItemId'] ?? json['LastAccessedItemId'] ?? json['last_accessed_item_id'])
              as String?,
      lastAccessedAt: DateTime.tryParse(
            (json['lastAccessedAt'] ?? json['LastAccessedAt'] ?? json['last_accessed_at'] ?? '')
                as String,
          ) ??
          DateTime.now(),
      timeSpentSeconds:
          (json['timeSpentSeconds'] ?? json['TimeSpentSeconds'] ?? json['time_spent_seconds'] ?? 0)
              as int,
    );
  }

  factory UserProgressDto.fromRow(
    Map<String, dynamic> row, {
    required List<String> completedContentIds,
    required Map<String, int> analysisScores,
  }) {
    return UserProgressDto(
      userId: row['user_id'] as String,
      artifactId: row['artifact_id'] as String,
      completedContentIds: completedContentIds,
      analysisScores: analysisScores,
      lastAccessedItemId: row['last_accessed_item_id'] as String?,
      lastAccessedAt: DateTime.parse(row['last_accessed_at'] as String),
      timeSpentSeconds: row['time_spent_seconds'] as int,
    );
  }

  factory UserProgressDto.fromDomain(UserProgress progress) {
    return UserProgressDto(
      userId: progress.userId,
      artifactId: progress.artifactId,
      completedContentIds: progress.completedContentIds,
      analysisScores: progress.analysisScores,
      lastAccessedItemId: progress.lastAccessedItemId,
      lastAccessedAt: progress.lastAccessedAt,
      timeSpentSeconds: progress.timeSpentSeconds,
    );
  }

  UserProgress toDomain() {
    return UserProgress(
      userId: userId,
      artifactId: artifactId,
      completedContentIds: completedContentIds,
      analysisScores: analysisScores,
      lastAccessedItemId: lastAccessedItemId,
      lastAccessedAt: lastAccessedAt,
      timeSpentSeconds: timeSpentSeconds,
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'user_id': userId,
      'artifact_id': artifactId,
      'last_accessed_item_id': lastAccessedItemId,
      'last_accessed_at': lastAccessedAt.toIso8601String(),
      'time_spent_seconds': timeSpentSeconds,
    };
  }
}
