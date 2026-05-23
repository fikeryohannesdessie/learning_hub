import '../../features/artifacts/domain/artifact_domain.dart';

class UserProgressModel extends UserProgress {
  UserProgressModel({
    required super.userId,
    required super.artifactId,
    super.completedContentIds,
    super.analysisScores,
    super.lastAccessedItemId,
    required super.lastAccessedAt,
    super.timeSpentSeconds,
  });

  factory UserProgressModel.fromDomain(UserProgress progress) {
    return UserProgressModel(
      userId: progress.userId,
      artifactId: progress.artifactId,
      completedContentIds: progress.completedContentIds,
      analysisScores: progress.analysisScores,
      lastAccessedItemId: progress.lastAccessedItemId,
      lastAccessedAt: progress.lastAccessedAt,
      timeSpentSeconds: progress.timeSpentSeconds,
    );
  }

  @override
  UserProgressModel copyWith({
    String? userId,
    String? artifactId,
    List<String>? completedContentIds,
    Map<String, int>? analysisScores,
    String? lastAccessedItemId,
    DateTime? lastAccessedAt,
    int? timeSpentSeconds,
  }) {
    return UserProgressModel(
      userId: userId ?? this.userId,
      artifactId: artifactId ?? this.artifactId,
      completedContentIds: completedContentIds ?? this.completedContentIds,
      analysisScores: analysisScores ?? this.analysisScores,
      lastAccessedItemId: lastAccessedItemId ?? this.lastAccessedItemId,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
    );
  }
}
