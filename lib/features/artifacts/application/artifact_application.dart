import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/artifact_domain.dart';
import '../infrastructure/artifact_infrastructure.dart';

final artifactLocalDataSourceProvider =
    Provider<ArtifactLocalDataSource>((ref) {
  return ArtifactLocalDataSource();
});

final artifactRemoteDataSourceProvider =
    Provider<ArtifactRemoteDataSource>((ref) {
  return const ArtifactRemoteDataSource();
});

final artifactRepositoryProvider = Provider<IArtifactRepository>((ref) {
  return ArtifactRepositoryImpl(
    localDataSource: ref.watch(artifactLocalDataSourceProvider),
    remoteDataSource: ref.watch(artifactRemoteDataSourceProvider),
  );
});

final allArtifactsProvider = StreamProvider<List<Artifact>>((ref) {
  return ref.watch(artifactRepositoryProvider).getAllArtifacts();
});

final approvedArtifactsProvider = StreamProvider<List<Artifact>>((ref) {
  return ref.watch(artifactRepositoryProvider).getApprovedArtifacts();
});

final approvedArtifactsByClassificationProvider =
    StreamProvider.family<List<Artifact>, String>((ref, classification) {
  return ref
      .watch(artifactRepositoryProvider)
      .getApprovedArtifactsByClassification(classification);
});

final contributorArtifactsProvider =
    StreamProvider.family<List<Artifact>, String>((ref, contributorId) {
  return ref
      .watch(artifactRepositoryProvider)
      .getContributorArtifacts(contributorId);
});

final analysisResultsProvider =
    StreamProvider.family<List<AnalysisResult>, String>((ref, artifactId) {
  return ref.watch(artifactRepositoryProvider).getAnalysisResults(artifactId);
});

final artifactResultsProvider = analysisResultsProvider;

final viewerResultsProvider =
    StreamProvider.family<List<AnalysisResult>, String>((ref, userId) {
  return ref.watch(artifactRepositoryProvider).getViewerResults(userId);
});

final viewerArtifactProgressProvider =
    StreamProvider.family<UserProgress?, (String, String)>((ref, args) {
  final (userId, artifactId) = args;
  return ref
      .watch(artifactRepositoryProvider)
      .getViewerArtifactProgress(userId, artifactId);
});

final artifactThumbnailProvider =
    FutureProvider.family<Uint8List?, String>((ref, artifactId) async {
  final bytes =
      await ref.watch(artifactRepositoryProvider).getArtifactThumbnail(artifactId);
  return bytes == null ? null : Uint8List.fromList(bytes);
});

final artifactControllerProvider =
    NotifierProvider<ArtifactController, AsyncValue<void>>(
      ArtifactController.new,
    );

class ArtifactController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  IArtifactRepository get _repository => ref.read(artifactRepositoryProvider);

  Future<void> createArtifact(
    Artifact artifact, {
    Uint8List? thumbnailBytes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createArtifact(
        artifact,
        thumbnailBytes: thumbnailBytes,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateArtifactStatus(
    String artifactId,
    String status, {
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateArtifactStatus(
        artifactId,
        status,
        reason: reason,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> trackViewer(String artifactId, String viewerId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.trackViewer(artifactId, viewerId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> submitAnalysisResult(AnalysisResult result) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveAnalysisResult(result);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> saveUserProgress(UserProgress progress) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveUserProgress(progress);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
