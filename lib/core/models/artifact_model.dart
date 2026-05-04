class ArtifactModel {
  final String id;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final String status; // pending, approved, rejected
  final List<HeritageSectionModel> sections;
  final List<String> viewerIds;
  final DateTime createdAt;
  final String? rejectionReason;
  final String? thumbnailUrl;
  final bool? isSequential;
  final String? classification;
  final String? detailedDescription;
  final List<String>? heritageSignificance;

  ArtifactModel({
    required this.id,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    this.status = 'pending',
    required this.sections,
    this.viewerIds = const [],
    required this.createdAt,
    this.rejectionReason,
    this.thumbnailUrl = '',
    this.isSequential = true,
    this.classification = 'tangible',
    this.detailedDescription,
    this.heritageSignificance,
  });

  factory ArtifactModel.fromJson(Map<String, dynamic> json) {
    final rawStatus =
        ((json['status'] ?? json['Status'] ?? 'pending') as String)
            .trim()
            .toLowerCase();
    final normalizedStatus = rawStatus.isEmpty
        ? 'pending'
        : (rawStatus == 'approved' || rawStatus == 'rejected'
              ? rawStatus
              : 'pending');

    final rawClassification =
        ((json['classification'] ??
                    json['Classification'] ??
                    json['gradeLevel'] ??
                    'tangible')
                as String)
            .trim()
            .toLowerCase();
    final normalizedClassification = rawClassification == 'intangible'
        ? 'intangible'
        : 'tangible';

    return ArtifactModel(
      id: (json['id'] ?? json['Id'] ?? '') as String,
      title: (json['title'] ?? json['Title'] ?? 'Untitled Artifact') as String,
      description: (json['description'] ?? json['Description'] ?? '') as String,
      authorId: (json['authorId'] ?? json['AuthorId'] ?? '') as String,
      authorName:
          (json['authorName'] ?? json['AuthorName'] ?? 'Anonymous') as String,
      status: normalizedStatus,
      sections: (json['sections'] ?? json['Sections'] ?? json['chapters'] ?? [])
          .map(
            (e) => HeritageSectionModel.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      viewerIds: List<String>.from(
        json['viewerIds'] ?? json['enrolledViewerIds'] ?? [],
      ),
      createdAt:
          DateTime.tryParse(
            (json['createdAt'] ?? json['CreatedAt'] ?? '') as String,
          ) ??
          DateTime.now(),
      rejectionReason:
          (json['rejectionReason'] ?? json['RejectionReason']) as String?,
      thumbnailUrl:
          (json['thumbnailUrl'] ?? json['ThumbnailUrl'] ?? '') as String,
      isSequential:
          (json['isSequential'] ?? json['IsSequential'] ?? true) as bool,
      classification: normalizedClassification,
      detailedDescription:
          (json['detailedDescription'] ?? json['DetailedDescription'])
              as String?,
      heritageSignificance: List<String>.from(
        json['heritageSignificance'] ?? json['HeritageOutcomes'] ?? [],
      ),
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
      'isSequential': isSequential ?? true,
      'classification': classification ?? 'tangible',
      'detailedDescription': detailedDescription,
      'heritageSignificance': heritageSignificance,
    };
  }

  ArtifactModel copyWith({
    String? id,
    String? title,
    String? description,
    String? authorId,
    String? authorName,
    String? status,
    List<HeritageSectionModel>? sections,
    List<String>? viewerIds,
    DateTime? createdAt,
    String? rejectionReason,
    String? thumbnailUrl,
    bool? isSequential,
    String? classification,
    String? detailedDescription,
    List<String>? heritageSignificance,
  }) {
    return ArtifactModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      status: status ?? this.status,
      sections: sections ?? this.sections,
      viewerIds: viewerIds ?? this.viewerIds,
      createdAt: createdAt ?? this.createdAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isSequential: isSequential ?? this.isSequential,
      classification: classification ?? this.classification,
      detailedDescription: detailedDescription ?? this.detailedDescription,
      heritageSignificance: heritageSignificance ?? this.heritageSignificance,
    );
  }

  List<HeritageSectionModel> get Sections => sections;
  List<String> get HeritageOutcomes => heritageSignificance ?? [];
}

class HeritageSectionModel {
  final String id;
  final String title;
  final List<HeritagePartModel> parts;
  final AnalysisModel? analysis;

  HeritageSectionModel({
    required this.id,
    required this.title,
    required this.parts,
    this.analysis,
  });

  factory HeritageSectionModel.fromJson(Map<String, dynamic> json) {
    return HeritageSectionModel(
      id: (json['id'] ?? json['Id'] ?? '') as String,
      title: (json['title'] ?? json['Title'] ?? 'Untitled Section') as String,
      parts: (json['parts'] ?? json['Parts'] ?? json['topics'] ?? [])
          .map((e) => HeritagePartModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      analysis: json['analysis'] != null
          ? AnalysisModel.fromJson(Map<String, dynamic>.from(json['analysis']))
          : json['Analysis'] != null
          ? AnalysisModel.fromJson(Map<String, dynamic>.from(json['Analysis']))
          : (json['quiz'] != null
                ? AnalysisModel.fromJson(
                    Map<String, dynamic>.from(json['quiz']),
                  )
                : null),
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

  HeritageSectionModel copyWith({
    String? id,
    String? title,
    List<HeritagePartModel>? parts,
    AnalysisModel? analysis,
  }) {
    return HeritageSectionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      parts: parts ?? this.parts,
      analysis: analysis ?? this.analysis,
    );
  }

  List<HeritagePartModel> get topics => parts;
  AnalysisModel? get Analysis => analysis;
}

class HeritagePartModel {
  final String id;
  final String title;
  final List<ArtifactDetailModel> details;

  HeritagePartModel({
    required this.id,
    required this.title,
    required this.details,
  });

  factory HeritagePartModel.fromJson(Map<String, dynamic> json) {
    return HeritagePartModel(
      id: (json['id'] ?? json['Id'] ?? '') as String,
      title: (json['title'] ?? json['Title'] ?? 'Untitled Part') as String,
      details: (json['details'] ?? json['Details'] ?? json['subtopics'] ?? [])
          .map(
            (e) => ArtifactDetailModel.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'details': details.map((e) => e.toJson()).toList(),
    };
  }

  HeritagePartModel copyWith({
    String? id,
    String? title,
    List<ArtifactDetailModel>? details,
  }) {
    return HeritagePartModel(
      id: id ?? this.id,
      title: title ?? this.title,
      details: details ?? this.details,
    );
  }

  List<ArtifactDetailModel> get subtopics => details;
}

class ArtifactDetailModel {
  final String id;
  final String title;
  final List<ArtifactContentItem> contents;

  ArtifactDetailModel({
    required this.id,
    required this.title,
    required this.contents,
  });

  factory ArtifactDetailModel.fromJson(Map<String, dynamic> json) {
    return ArtifactDetailModel(
      id: (json['id'] ?? json['Id'] ?? '') as String,
      title: (json['title'] ?? json['Title'] ?? 'Untitled Detail') as String,
      contents: (json['contents'] ?? json['Contents'] ?? [])
          .map(
            (e) => ArtifactContentItem.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'contents': contents.map((e) => e.toJson()).toList(),
    };
  }

  ArtifactDetailModel copyWith({
    String? id,
    String? title,
    List<ArtifactContentItem>? contents,
  }) {
    return ArtifactDetailModel(
      id: id ?? this.id,
      title: title ?? this.title,
      contents: contents ?? this.contents,
    );
  }
}

class ArtifactContentItem {
  final String type; // text, pdf, video, simulation
  final String? text;
  final String? fileId; // for local/remote file reference
  final String? url; // for external video links
  final String? simulationId; // identifier for native simulations
  final String id;
  final String title;
  final bool isResource;
  final String? resourceCategory; // Documentation, Media, Field Notes, etc.

  ArtifactContentItem({
    required this.type,
    this.text,
    this.fileId,
    this.url,
    this.simulationId,
    required this.id,
    required this.title,
    this.isResource = false,
    this.resourceCategory,
  });

  factory ArtifactContentItem.fromJson(Map<String, dynamic> json) {
    return ArtifactContentItem(
      type: (json['type'] ?? json['Type'] ?? 'text') as String,
      text: (json['text'] ?? json['Text']) as String?,
      fileId: (json['fileId'] ?? json['FileId']) as String?,
      url: (json['url'] ?? json['Url']) as String?,
      simulationId:
          (json['simulationId'] ?? json['SimulationId']) as String?,
      id: (json['id'] ?? json['Id'] ?? '') as String,
      title: (json['title'] ?? json['Title'] ?? 'Untitled Item') as String,
      isResource: (json['isResource'] ?? json['IsResource'] ?? false) as bool,
      resourceCategory:
          (json['resourceCategory'] ?? json['ResourceCategory']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'text': text,
      'fileId': fileId,
      'url': url,
      'id': id,
      'title': title,
      'isResource': isResource,
      'resourceCategory': resourceCategory,
      'simulationId': simulationId,
    };
  }

  ArtifactContentItem copyWith({
    String? type,
    String? text,
    String? fileId,
    String? url,
    String? id,
    String? title,
    bool? isResource,
    String? resourceCategory,
    String? simulationId,
  }) {
    return ArtifactContentItem(
      type: type ?? this.type,
      text: text ?? this.text,
      fileId: fileId ?? this.fileId,
      url: url ?? this.url,
      id: id ?? this.id,
      title: title ?? this.title,
      isResource: isResource ?? this.isResource,
      resourceCategory: resourceCategory ?? this.resourceCategory,
      simulationId: simulationId ?? this.simulationId,
    );
  }
}

class AnalysisModel {
  final String id;
  final List<EvidenceModel> evidence;

  AnalysisModel({
    required this.id,
    List<EvidenceModel>? evidence,
    List<EvidenceModel>? evidences,
  }) : this.evidence = evidence ?? evidences ?? const [];

  factory AnalysisModel.fromJson(Map<String, dynamic> json) {
    return AnalysisModel(
      id: (json['id'] ?? json['Id'] ?? '') as String,
      evidence:
          (json['evidence'] ??
                  json['Evidence'] ??
                  json['evidences'] ??
                  json['questions'] ??
                  [])
              .map((e) => EvidenceModel.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'evidence': evidence.map((e) => e.toJson()).toList()};
  }

  AnalysisModel copyWith({String? id, List<EvidenceModel>? evidence}) {
    return AnalysisModel(
      id: id ?? this.id,
      evidence: evidence ?? this.evidence,
    );
  }

  List<EvidenceModel> get evidences => evidence;
}

class EvidenceModel {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final bool isShortAnswer;
  final String? correctShortAnswer;

  EvidenceModel({
    String? questionText,
    List<String>? options,
    int? correctAnswerIndex,
    this.isShortAnswer = false,
    this.correctShortAnswer,
    String? factText,
    List<String>? possibilities,
    int? verifiedIndex,
  }) : this.questionText = questionText ?? factText ?? '',
       this.options = options ?? possibilities ?? const [],
       this.correctAnswerIndex = correctAnswerIndex ?? verifiedIndex ?? 0;

  factory EvidenceModel.fromJson(Map<String, dynamic> json) {
    return EvidenceModel(
      questionText: (json['questionText'] ?? "") != ""
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

  Map<String, dynamic> toJson() {
    return {
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'isShortAnswer': isShortAnswer,
      'correctShortAnswer': correctShortAnswer,
    };
  }

  EvidenceModel copyWith({
    String? questionText,
    List<String>? options,
    int? correctAnswerIndex,
    bool? isShortAnswer,
    String? correctShortAnswer,
  }) {
    return EvidenceModel(
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      isShortAnswer: isShortAnswer ?? this.isShortAnswer,
      correctShortAnswer: correctShortAnswer ?? this.correctShortAnswer,
    );
  }

  String get factText => questionText;
  List<String> get possibilities => options;
  int get verifiedIndex => correctAnswerIndex;
}
