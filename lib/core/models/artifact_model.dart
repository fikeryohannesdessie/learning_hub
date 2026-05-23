import '../../features/artifacts/domain/artifact_domain.dart' as domain;

class ArtifactModel extends domain.Artifact {
  ArtifactModel({
    required String id,
    required String title,
    required String description,
    required String authorId,
    required String authorName,
    String status = 'pending',
    required List<HeritageSectionModel> sections,
    List<String> viewerIds = const [],
    required DateTime createdAt,
    String? rejectionReason,
    String? thumbnailUrl = '',
    bool? isSequential = true,
    String? classification = 'tangible',
    String? detailedDescription,
    List<String>? heritageSignificance,
  }) : super(
         id: id,
         title: title,
         description: description,
         authorId: authorId,
         authorName: authorName,
         status: status,
         sections: sections,
         viewerIds: viewerIds,
         createdAt: createdAt,
         rejectionReason: rejectionReason,
         thumbnailUrl: thumbnailUrl ?? '',
         isSequential: isSequential ?? true,
         classification: classification ?? 'tangible',
         detailedDescription: detailedDescription,
         heritageSignificance: heritageSignificance,
       );

  factory ArtifactModel.fromDomain(domain.Artifact artifact) {
    return ArtifactModel(
      id: artifact.id,
      title: artifact.title,
      description: artifact.description,
      authorId: artifact.authorId,
      authorName: artifact.authorName,
      status: artifact.status,
      sections: artifact.sections
          .map(HeritageSectionModel.fromDomain)
          .toList(),
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

  @override
  List<HeritageSectionModel> get sections =>
      super.sections.cast<HeritageSectionModel>();

  @override
  ArtifactModel copyWith({
    String? id,
    String? title,
    String? description,
    String? authorId,
    String? authorName,
    String? status,
    List<domain.HeritageSection>? sections,
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
      sections: (sections ?? this.sections)
          .map(HeritageSectionModel.fromDomain)
          .toList(),
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
  List<String>? get HeritageOutcomes => heritageSignificance;
}

class HeritageSectionModel extends domain.HeritageSection {
  HeritageSectionModel({
    required String id,
    required String title,
    required List<HeritagePartModel> parts,
    AnalysisModel? analysis,
  }) : super(id: id, title: title, parts: parts, analysis: analysis);

  factory HeritageSectionModel.fromDomain(domain.HeritageSection section) {
    return HeritageSectionModel(
      id: section.id,
      title: section.title,
      parts: section.parts.map(HeritagePartModel.fromDomain).toList(),
      analysis: section.analysis != null
          ? AnalysisModel.fromDomain(section.analysis!)
          : null,
    );
  }

  @override
  List<HeritagePartModel> get parts => super.parts.cast<HeritagePartModel>();

  @override
  AnalysisModel? get analysis => super.analysis as AnalysisModel?;

  @override
  HeritageSectionModel copyWith({
    String? id,
    String? title,
    List<domain.HeritagePart>? parts,
    domain.Analysis? analysis,
  }) {
    return HeritageSectionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      parts: (parts ?? this.parts).map(HeritagePartModel.fromDomain).toList(),
      analysis: analysis != null ? AnalysisModel.fromDomain(analysis) : this.analysis,
    );
  }

  List<HeritagePartModel> get topics => parts;
  AnalysisModel? get Analysis => analysis;
}

class HeritagePartModel extends domain.HeritagePart {
  HeritagePartModel({
    required String id,
    required String title,
    required List<ArtifactDetailModel> details,
  }) : super(id: id, title: title, details: details);

  factory HeritagePartModel.fromDomain(domain.HeritagePart part) {
    return HeritagePartModel(
      id: part.id,
      title: part.title,
      details: part.details.map(ArtifactDetailModel.fromDomain).toList(),
    );
  }

  @override
  List<ArtifactDetailModel> get details =>
      super.details.cast<ArtifactDetailModel>();

  @override
  HeritagePartModel copyWith({
    String? id,
    String? title,
    List<domain.ArtifactDetail>? details,
  }) {
    return HeritagePartModel(
      id: id ?? this.id,
      title: title ?? this.title,
      details: (details ?? this.details)
          .map(ArtifactDetailModel.fromDomain)
          .toList(),
    );
  }

  List<ArtifactDetailModel> get subtopics => details;
}

class ArtifactDetailModel extends domain.ArtifactDetail {
  ArtifactDetailModel({
    required String id,
    required String title,
    required List<ArtifactContentItem> contents,
  }) : super(id: id, title: title, contents: contents);

  factory ArtifactDetailModel.fromDomain(domain.ArtifactDetail detail) {
    return ArtifactDetailModel(
      id: detail.id,
      title: detail.title,
      contents: detail.contents.map(ArtifactContentItem.fromDomain).toList(),
    );
  }

  @override
  List<ArtifactContentItem> get contents =>
      super.contents.cast<ArtifactContentItem>();

  @override
  ArtifactDetailModel copyWith({
    String? id,
    String? title,
    List<domain.ArtifactContentItem>? contents,
  }) {
    return ArtifactDetailModel(
      id: id ?? this.id,
      title: title ?? this.title,
      contents: (contents ?? this.contents)
          .map(ArtifactContentItem.fromDomain)
          .toList(),
    );
  }
}

class ArtifactContentItem extends domain.ArtifactContentItem {
  ArtifactContentItem({
    required String type,
    String? text,
    String? fileId,
    String? url,
    String? simulationId,
    required String id,
    required String title,
    bool isResource = false,
    String? resourceCategory,
  }) : super(
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

  factory ArtifactContentItem.fromDomain(domain.ArtifactContentItem item) {
    return ArtifactContentItem(
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

  @override
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
      simulationId: simulationId ?? this.simulationId,
      id: id ?? this.id,
      title: title ?? this.title,
      isResource: isResource ?? this.isResource,
      resourceCategory: resourceCategory ?? this.resourceCategory,
    );
  }
}

class AnalysisModel extends domain.Analysis {
  AnalysisModel({
    required String id,
    List<EvidenceModel>? evidence,
    List<EvidenceModel>? evidences,
  }) : super(id: id, evidence: evidence ?? evidences ?? const []);

  factory AnalysisModel.fromDomain(domain.Analysis analysis) {
    return AnalysisModel(
      id: analysis.id,
      evidence: analysis.evidence.map(EvidenceModel.fromDomain).toList(),
    );
  }

  @override
  List<EvidenceModel> get evidence => super.evidence.cast<EvidenceModel>();

  @override
  AnalysisModel copyWith({String? id, List<domain.Evidence>? evidence}) {
    return AnalysisModel(
      id: id ?? this.id,
      evidence: (evidence ?? this.evidence).map(EvidenceModel.fromDomain).toList(),
    );
  }

  List<EvidenceModel> get evidences => evidence;
}

class EvidenceModel extends domain.Evidence {
  EvidenceModel({
    String? questionText,
    List<String>? options,
    int? correctAnswerIndex,
    bool isShortAnswer = false,
    String? correctShortAnswer,
    String? factText,
    List<String>? possibilities,
    int? verifiedIndex,
  }) : super(
         questionText: questionText ?? factText ?? '',
         options: options ?? possibilities ?? const [],
         correctAnswerIndex: correctAnswerIndex ?? verifiedIndex ?? 0,
         isShortAnswer: isShortAnswer,
         correctShortAnswer: correctShortAnswer,
       );

  factory EvidenceModel.fromDomain(domain.Evidence evidence) {
    return EvidenceModel(
      questionText: evidence.questionText,
      options: evidence.options,
      correctAnswerIndex: evidence.correctAnswerIndex,
      isShortAnswer: evidence.isShortAnswer,
      correctShortAnswer: evidence.correctShortAnswer,
    );
  }

  @override
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

class AnalysisResultModel extends domain.AnalysisResult {
  AnalysisResultModel({
    required String userId,
    required String userName,
    required String artifactId,
    required String sectionId,
    required int score,
    required int totalQuestions,
    required DateTime completedAt,
  }) : super(
         userId: userId,
         userName: userName,
         artifactId: artifactId,
         sectionId: sectionId,
         score: score,
         totalQuestions: totalQuestions,
         completedAt: completedAt,
       );

  factory AnalysisResultModel.fromDomain(domain.AnalysisResult result) {
    return AnalysisResultModel(
      userId: result.userId,
      userName: result.userName,
      artifactId: result.artifactId,
      sectionId: result.sectionId,
      score: result.score,
      totalQuestions: result.totalQuestions,
      completedAt: result.completedAt,
    );
  }

  AnalysisResultModel copyWith({
    String? userId,
    String? userName,
    String? artifactId,
    String? sectionId,
    int? score,
    int? totalQuestions,
    DateTime? completedAt,
  }) {
    return AnalysisResultModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      artifactId: artifactId ?? this.artifactId,
      sectionId: sectionId ?? this.sectionId,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
