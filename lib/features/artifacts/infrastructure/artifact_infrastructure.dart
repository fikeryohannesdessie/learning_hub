import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../core/storage/database_helper.dart';
import '../domain/artifact_domain.dart';
import 'artifact_dto.dart';

class ArtifactLocalDataSource {
  Artifact mapRowToArtifact(Map<String, dynamic> row) {
    final sections = (jsonDecode(row['sections_json'] as String) as List)
        .map<HeritageSectionDto>(
          (entry) => HeritageSectionDto.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList();

    final viewerIds = List<String>.from(
      jsonDecode(row['viewer_ids_json'] as String? ?? '[]'),
    );

    List<String>? significance;
    final rawSignificance = row['heritage_significance_json'] as String?;
    if (rawSignificance != null && rawSignificance.isNotEmpty) {
      significance = List<String>.from(jsonDecode(rawSignificance));
    }

    return ArtifactDto.fromRow(
      row,
      sections: sections,
      viewerIds: viewerIds,
      heritageSignificance: significance,
    ).toDomain();
  }

  Map<String, dynamic> mapArtifactToRow(Artifact artifact) {
    final row = ArtifactDto.fromDomain(artifact).toRow();
    row['sections_json'] = jsonEncode(
      artifact.sections.map((section) => HeritageSectionDto.fromDomain(section).toJson()).toList(),
    );
    row['viewer_ids_json'] = jsonEncode(artifact.viewerIds);
    row['heritage_significance_json'] = artifact.heritageSignificance != null
        ? jsonEncode(artifact.heritageSignificance)
        : null;
    return row;
  }

  AnalysisResult mapRowToResult(Map<String, dynamic> row) {
    return AnalysisResultDto.fromJson(row).toDomain();
  }

  Map<String, dynamic> mapResultToRow(String id, AnalysisResult result) {
    return AnalysisResultDto.fromDomain(result).toRow(id);
  }

  UserProgress mapRowToProgress(Map<String, dynamic> row) {
    return UserProgressDto.fromRow(
      row,
      completedContentIds:
          List<String>.from(jsonDecode(row['completed_content_ids'] as String? ?? '[]')),
      analysisScores:
          Map<String, int>.from(jsonDecode(row['analysis_scores'] as String? ?? '{}')),
    ).toDomain();
  }

  Map<String, dynamic> mapProgressToRow(UserProgress progress) {
    final row = UserProgressDto.fromDomain(progress).toRow();
    row['completed_content_ids'] = jsonEncode(progress.completedContentIds);
    row['analysis_scores'] = jsonEncode(progress.analysisScores);
    return row;
  }

  Future<List<Artifact>> getAllArtifacts() async {
    final rows = await db.getAllArtifacts();
    return rows.map(mapRowToArtifact).toList();
  }

  Future<List<Artifact>> getArtifactsByStatus(String status) async {
    final rows = await db.getArtifactsByStatus(status);
    return rows.map(mapRowToArtifact).toList();
  }

  Future<List<Artifact>> getApprovedArtifactsByClassification(
    String classification,
  ) async {
    final rows = await db.getArtifactsByStatusAndClassification(
      'approved',
      classification,
    );
    return rows.map(mapRowToArtifact).toList();
  }

  Future<List<Artifact>> getArtifactsByAuthor(String authorId) async {
    final rows = await db.getArtifactsByAuthor(authorId);
    return rows.map(mapRowToArtifact).toList();
  }

  Future<void> createArtifact(
    Artifact artifact, {
    Uint8List? thumbnailBytes,
  }) async {
    final artifactToSave = artifact.status == 'approved'
        ? artifact
        : artifact.copyWith(status: 'pending');

    await db.upsertArtifact(mapArtifactToRow(artifactToSave));
    if (thumbnailBytes != null) {
      await db.upsertArtifactFile(artifactToSave.id, thumbnailBytes);
    }
    debugPrint('SQLite: artifact saved id=${artifactToSave.id}');
  }

  Future<void> updateArtifactStatus(
    String artifactId,
    String status, {
    String? reason,
  }) {
    return db.updateArtifactStatus(
      artifactId,
      status,
      rejectionReason: reason,
    );
  }

  Future<void> trackViewer(String artifactId, String viewerId) async {
    final row = await db.getArtifactById(artifactId);
    if (row == null) {
      return;
    }

    final artifact = mapRowToArtifact(row);
    if (!artifact.viewerIds.contains(viewerId)) {
      final updatedViewers = [...artifact.viewerIds, viewerId];
      await db.updateArtifactViewerIds(artifactId, jsonEncode(updatedViewers));
    }
  }

  Future<void> saveAnalysisResult(AnalysisResult result) async {
    final id =
        'res_${result.userId}_${result.artifactId}_${result.sectionId}_${result.completedAt.millisecondsSinceEpoch}';
    await db.insertAnalysisResult(mapResultToRow(id, result));

    final existing = await db.getUserProgress(result.userId, result.artifactId);
    UserProgress progress;

    if (existing != null) {
      progress = mapRowToProgress(existing);
      final updatedScores = Map<String, int>.from(progress.analysisScores);
      updatedScores[result.sectionId] = result.score;
      progress = progress.copyWith(analysisScores: updatedScores);
    } else {
      progress = UserProgress(
        userId: result.userId,
        artifactId: result.artifactId,
        analysisScores: {result.sectionId: result.score},
        lastAccessedAt: DateTime.now(),
      );
    }

    await db.upsertUserProgress(mapProgressToRow(progress));
  }

  Future<List<AnalysisResult>> getAnalysisResults(String artifactId) async {
    final rows = await db.getAnalysisResultsByArtifact(artifactId);
    return rows.map(mapRowToResult).toList();
  }

  Future<List<AnalysisResult>> getViewerResults(String userId) async {
    final rows = await db.getAnalysisResultsByUser(userId);
    return rows.map(mapRowToResult).toList();
  }

  Future<void> saveUserProgress(UserProgress progress) {
    return db.upsertUserProgress(mapProgressToRow(progress));
  }

  Future<UserProgress?> getViewerArtifactProgress(
    String userId,
    String artifactId,
  ) async {
    final row = await db.getUserProgress(userId, artifactId);
    return row == null ? null : mapRowToProgress(row);
  }

  Future<Uint8List?> getArtifactThumbnail(String artifactId) {
    return db.getArtifactFile(artifactId);
  }
}

class ArtifactRemoteDataSource {
  const ArtifactRemoteDataSource();
}

class ArtifactRepositoryImpl implements IArtifactRepository {
  ArtifactRepositoryImpl({
    required ArtifactLocalDataSource localDataSource,
    required ArtifactRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource;

  final ArtifactLocalDataSource _localDataSource;
  final StreamController<void> _artifactsController =
      StreamController<void>.broadcast();
  final StreamController<void> _resultsController =
      StreamController<void>.broadcast();
  final StreamController<void> _progressController =
      StreamController<void>.broadcast();

  void _notifyArtifacts() => _artifactsController.add(null);

  void _notifyResults() => _resultsController.add(null);

  void _notifyProgress() => _progressController.add(null);

  @override
  Stream<List<Artifact>> getAllArtifacts() async* {
    yield await _localDataSource.getAllArtifacts();
    await for (final _ in _artifactsController.stream) {
      yield await _localDataSource.getAllArtifacts();
    }
  }

  @override
  Stream<List<Artifact>> getApprovedArtifacts() async* {
    yield await _localDataSource.getArtifactsByStatus('approved');
    await for (final _ in _artifactsController.stream) {
      yield await _localDataSource.getArtifactsByStatus('approved');
    }
  }

  @override
  Stream<List<Artifact>> getApprovedArtifactsByClassification(
    String classification,
  ) async* {
    yield await _localDataSource.getApprovedArtifactsByClassification(
      classification,
    );
    await for (final _ in _artifactsController.stream) {
      yield await _localDataSource.getApprovedArtifactsByClassification(
        classification,
      );
    }
  }

  @override
  Stream<List<Artifact>> getContributorArtifacts(String contributorId) async* {
    yield await _localDataSource.getArtifactsByAuthor(contributorId);
    await for (final _ in _artifactsController.stream) {
      yield await _localDataSource.getArtifactsByAuthor(contributorId);
    }
  }

  @override
  Future<void> createArtifact(
    Artifact artifact, {
    List<int>? thumbnailBytes,
  }) async {
    await _localDataSource.createArtifact(
      artifact,
      thumbnailBytes:
          thumbnailBytes == null ? null : Uint8List.fromList(thumbnailBytes),
    );
    _notifyArtifacts();
  }

  @override
  Future<void> updateArtifactStatus(
    String artifactId,
    String status, {
    String? reason,
  }) async {
    await _localDataSource.updateArtifactStatus(
      artifactId,
      status,
      reason: reason,
    );
    _notifyArtifacts();
  }

  @override
  Future<void> trackViewer(String artifactId, String viewerId) async {
    await _localDataSource.trackViewer(artifactId, viewerId);
    _notifyArtifacts();
  }

  @override
  Future<void> saveAnalysisResult(AnalysisResult result) async {
    await _localDataSource.saveAnalysisResult(result);
    _notifyResults();
    _notifyProgress();
  }

  @override
  Stream<List<AnalysisResult>> getAnalysisResults(String artifactId) async* {
    try {
      yield await _localDataSource.getAnalysisResults(artifactId);
      await for (final _ in _resultsController.stream) {
        yield await _localDataSource.getAnalysisResults(artifactId);
      }
    } catch (_) {
      yield [];
    }
  }

  @override
  Stream<List<AnalysisResult>> getViewerResults(String userId) async* {
    try {
      yield await _localDataSource.getViewerResults(userId);
      await for (final _ in _resultsController.stream) {
        yield await _localDataSource.getViewerResults(userId);
      }
    } catch (_) {
      yield [];
    }
  }

  @override
  Future<void> saveUserProgress(UserProgress progress) async {
    await _localDataSource.saveUserProgress(progress);
    _notifyProgress();
  }

  @override
  Stream<UserProgress?> getViewerArtifactProgress(
    String userId,
    String artifactId,
  ) async* {
    try {
      yield await _localDataSource.getViewerArtifactProgress(userId, artifactId);
      await for (final _ in _progressController.stream) {
        yield await _localDataSource.getViewerArtifactProgress(
          userId,
          artifactId,
        );
      }
    } catch (_) {
      yield null;
    }
  }

  @override
  Future<List<int>?> getArtifactThumbnail(String artifactId) async {
    return _localDataSource.getArtifactThumbnail(artifactId);
  }
}
