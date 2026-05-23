class Artifact {
  final String id;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final String status; // pending, approved, rejected
  final List<HeritageSection> sections;
  final List<String> viewerIds;
  final DateTime createdAt;
  final String? rejectionReason;
  final String? thumbnailUrl;
  final bool isSequential;
  final String classification;
  final String? detailedDescription;
  final List<String>? heritageSignificance;

  const Artifact({
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

  Artifact copyWith({
    String? id,
    String? title,
    String? description,
    String? authorId,
    String? authorName,
    String? status,
    List<HeritageSection>? sections,
    List<String>? viewerIds,
    DateTime? createdAt,
    String? rejectionReason,
    String? thumbnailUrl,
    bool? isSequential,
    String? classification,
    String? detailedDescription,
    List<String>? heritageSignificance,
  }) {
    return Artifact(
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
}

class ArtifactTitle {
  ArtifactTitle._(this.value);

  final String value;

  static bool isValid(String input) {
    return input.trim().isNotEmpty;
  }

  factory ArtifactTitle(String input) {
    final normalized = input.trim();
    if (!isValid(normalized)) {
      throw const InvalidArtifactFieldFailure('Title is required');
    }
    return ArtifactTitle._(normalized);
  }
}

class ArtifactDescription {
  ArtifactDescription._(this.value);

  final String value;

  static bool isValid(String input) {
    return input.trim().isNotEmpty;
  }

  factory ArtifactDescription(String input) {
    final normalized = input.trim();
    if (!isValid(normalized)) {
      throw const InvalidArtifactFieldFailure('Description is required');
    }
    return ArtifactDescription._(normalized);
  }
}

class ArtifactNarrative {
  ArtifactNarrative._(this.value);

  final String value;

  static bool isValid(String input) {
    return input.trim().isNotEmpty;
  }

  factory ArtifactNarrative(String input) {
    final normalized = input.trim();
    if (!isValid(normalized)) {
      throw const InvalidArtifactFieldFailure('Narrative is required');
    }
    return ArtifactNarrative._(normalized);
  }
}

class HeritageSignificanceList {
  HeritageSignificanceList._(this.value);

  final List<String> value;

  static List<String> normalize(String input) {
    return input
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static bool isValid(String input) {
    return normalize(input).isNotEmpty;
  }

  factory HeritageSignificanceList(String input) {
    final normalized = normalize(input);
    if (normalized.isEmpty) {
      throw const InvalidArtifactFieldFailure('Significance is required');
    }
    return HeritageSignificanceList._(normalized);
  }
}

Artifact createArtifactDraft({
  required String id,
  required String title,
  required String description,
  required String authorId,
  required String authorName,
  required List<HeritageSection> sections,
  required DateTime createdAt,
  required String detailedDescription,
  required String heritageSignificanceText,
  String status = 'pending',
  List<String> viewerIds = const [],
  String? rejectionReason,
  String? thumbnailUrl = '',
  bool isSequential = true,
  String classification = 'tangible',
}) {
  final validatedTitle = ArtifactTitle(title);
  final validatedDescription = ArtifactDescription(description);
  final validatedNarrative = ArtifactNarrative(detailedDescription);
  final validatedSignificance = HeritageSignificanceList(heritageSignificanceText);

  return Artifact(
    id: id,
    title: validatedTitle.value,
    description: validatedDescription.value,
    authorId: authorId,
    authorName: authorName,
    status: status,
    sections: sections,
    viewerIds: viewerIds,
    createdAt: createdAt,
    rejectionReason: rejectionReason,
    thumbnailUrl: thumbnailUrl?.trim() ?? '',
    isSequential: isSequential,
    classification: classification,
    detailedDescription: validatedNarrative.value,
    heritageSignificance: validatedSignificance.value,
  );
}

class HeritageSection {
  final String id;
  final String title;
  final List<HeritagePart> parts;
  final Analysis? analysis;

  const HeritageSection({
    required this.id,
    required this.title,
    required this.parts,
    this.analysis,
  });

  HeritageSection copyWith({
    String? id,
    String? title,
    List<HeritagePart>? parts,
    Analysis? analysis,
  }) {
    return HeritageSection(
      id: id ?? this.id,
      title: title ?? this.title,
      parts: parts ?? this.parts,
      analysis: analysis ?? this.analysis,
    );
  }
}

class HeritagePart {
  final String id;
  final String title;
  final List<ArtifactDetail> details;

  const HeritagePart({
    required this.id,
    required this.title,
    required this.details,
  });

  HeritagePart copyWith({
    String? id,
    String? title,
    List<ArtifactDetail>? details,
  }) {
    return HeritagePart(
      id: id ?? this.id,
      title: title ?? this.title,
      details: details ?? this.details,
    );
  }
}

class ArtifactDetail {
  final String id;
  final String title;
  final List<ArtifactContentItem> contents;

  const ArtifactDetail({
    required this.id,
    required this.title,
    required this.contents,
  });

  ArtifactDetail copyWith({
    String? id,
    String? title,
    List<ArtifactContentItem>? contents,
  }) {
    return ArtifactDetail(
      id: id ?? this.id,
      title: title ?? this.title,
      contents: contents ?? this.contents,
    );
  }
}

class ArtifactContentItem {
  final String type; // text, pdf, video, simulation
  final String? text;
  final String? fileId;
  final String? url;
  final String? simulationId;
  final String id;
  final String title;
  final bool isResource;
  final String? resourceCategory;

  const ArtifactContentItem({
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

  ArtifactContentItem copyWith({
    String? type,
    String? text,
    String? fileId,
    String? url,
    String? simulationId,
    String? id,
    String? title,
    bool? isResource,
    String? resourceCategory,
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

class Analysis {
  final String id;
  final List<Evidence> evidence;

  const Analysis({
    required this.id,
    List<Evidence>? evidence,
  }) : evidence = evidence ?? const [];

  Analysis copyWith({
    String? id,
    List<Evidence>? evidence,
  }) {
    return Analysis(
      id: id ?? this.id,
      evidence: evidence ?? this.evidence,
    );
  }
}

class Evidence {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final bool isShortAnswer;
  final String? correctShortAnswer;

  const Evidence({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    this.isShortAnswer = false,
    this.correctShortAnswer,
  });

  Evidence copyWith({
    String? questionText,
    List<String>? options,
    int? correctAnswerIndex,
    bool? isShortAnswer,
    String? correctShortAnswer,
  }) {
    return Evidence(
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      isShortAnswer: isShortAnswer ?? this.isShortAnswer,
      correctShortAnswer: correctShortAnswer ?? this.correctShortAnswer,
    );
  }
}

class AnalysisResult {
  final String userId;
  final String artifactId;
  final String sectionId;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;
  final String userName;

  const AnalysisResult({
    required this.userId,
    required this.userName,
    required this.artifactId,
    required this.sectionId,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
  });
}

class UserProgress {
  final String userId;
  final String artifactId;
  final List<String> completedContentIds;
  final Map<String, int> analysisScores;
  final String? lastAccessedItemId;
  final DateTime lastAccessedAt;
  final int timeSpentSeconds;

  const UserProgress({
    required this.userId,
    required this.artifactId,
    this.completedContentIds = const [],
    this.analysisScores = const {},
    this.lastAccessedItemId,
    required this.lastAccessedAt,
    this.timeSpentSeconds = 0,
  });

  UserProgress copyWith({
    String? userId,
    String? artifactId,
    List<String>? completedContentIds,
    Map<String, int>? analysisScores,
    String? lastAccessedItemId,
    DateTime? lastAccessedAt,
    int? timeSpentSeconds,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      artifactId: artifactId ?? this.artifactId,
      completedContentIds: completedContentIds ?? this.completedContentIds,
      analysisScores: analysisScores ?? this.analysisScores,
      lastAccessedItemId: lastAccessedItemId ?? this.lastAccessedItemId,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
    );
  }

  double calculateOverallProgress(int totalItems) {
    if (totalItems == 0) return 0.0;
    return (completedContentIds.length / totalItems) * 100;
  }

  bool hasPassedArtifact(int totalAnalyses) {
    if (totalAnalyses == 0) return true;
    if (analysisScores.length < totalAnalyses) return false;
    final totalScore = analysisScores.values.fold(0, (sum, score) => sum + score);
    return (totalScore / totalAnalyses) >= 70;
  }

  double calculateAverageScore() {
    if (analysisScores.isEmpty) return 0.0;
    final totalScore = analysisScores.values.fold(0, (sum, score) => sum + score);
    return totalScore / analysisScores.length;
  }
}

sealed class ArtifactFailure implements Exception {
  const ArtifactFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class ArtifactNotFoundFailure extends ArtifactFailure {
  const ArtifactNotFoundFailure() : super('Artifact not found.');
}

class InvalidArtifactFieldFailure extends ArtifactFailure {
  const InvalidArtifactFieldFailure(super.message);
}

abstract class IArtifactRepository {
  Stream<List<Artifact>> getAllArtifacts();

  Stream<List<Artifact>> getApprovedArtifacts();

  Stream<List<Artifact>> getApprovedArtifactsByClassification(
    String classification,
  );

  Stream<List<Artifact>> getContributorArtifacts(String contributorId);

  Future<void> createArtifact(
    Artifact artifact, {
    List<int>? thumbnailBytes,
  });

  Future<void> updateArtifactStatus(
    String artifactId,
    String status, {
    String? reason,
  });

  Future<void> trackViewer(String artifactId, String viewerId);

  Future<void> saveAnalysisResult(AnalysisResult result);

  Stream<List<AnalysisResult>> getAnalysisResults(String artifactId);

  Stream<List<AnalysisResult>> getViewerResults(String userId);

  Future<void> saveUserProgress(UserProgress progress);

  Stream<UserProgress?> getViewerArtifactProgress(
    String userId,
    String artifactId,
  );

  Future<List<int>?> getArtifactThumbnail(String artifactId);
}
