import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chpa/features/artifacts/domain/artifact_domain.dart';
import 'package:chpa/features/artifacts/application/artifact_application.dart';

class FakeArtifactRepository implements IArtifactRepository {
  final List<Artifact> artifacts = [];
  final List<AnalysisResult> analysisResults = [];
  final Map<String, UserProgress> userProgressMap = {}; // key: userId_artifactId
  final Map<String, List<int>> thumbnails = {};

  final StreamController<List<Artifact>> _artifactsStreamController =
      StreamController<List<Artifact>>.broadcast();

  FakeArtifactRepository() {
    _notifyArtifacts();
  }

  void _notifyArtifacts() {
    _artifactsStreamController.add(List.unmodifiable(artifacts));
  }

  @override
  Stream<List<Artifact>> getAllArtifacts() {
    return _artifactsStreamController.stream;
  }

  @override
  Stream<List<Artifact>> getApprovedArtifacts() {
    return _artifactsStreamController.stream.map(
      (list) => list.where((a) => a.status == 'approved').toList(),
    );
  }

  @override
  Stream<List<Artifact>> getApprovedArtifactsByClassification(String classification) {
    return _artifactsStreamController.stream.map(
      (list) => list
          .where((a) => a.status == 'approved' && a.classification == classification)
          .toList(),
    );
  }

  @override
  Stream<List<Artifact>> getContributorArtifacts(String contributorId) {
    return _artifactsStreamController.stream.map(
      (list) => list.where((a) => a.authorId == contributorId).toList(),
    );
  }

  @override
  Future<void> createArtifact(Artifact artifact, {List<int>? thumbnailBytes}) async {
    if (artifact.id == 'error_id') {
      throw Exception('Database save failed');
    }
    artifacts.add(artifact);
    if (thumbnailBytes != null) {
      thumbnails[artifact.id] = thumbnailBytes;
    }
    _notifyArtifacts();
  }

  @override
  Future<void> updateArtifactStatus(String artifactId, String status, {String? reason}) async {
    final idx = artifacts.indexWhere((a) => a.id == artifactId);
    if (idx != -1) {
      artifacts[idx] = artifacts[idx].copyWith(status: status, rejectionReason: reason);
      _notifyArtifacts();
    }
  }

  @override
  Future<void> trackViewer(String artifactId, String viewerId) async {
    final idx = artifacts.indexWhere((a) => a.id == artifactId);
    if (idx != -1) {
      final updatedViewers = List<String>.from(artifacts[idx].viewerIds);
      if (!updatedViewers.contains(viewerId)) {
        updatedViewers.add(viewerId);
      }
      artifacts[idx] = artifacts[idx].copyWith(viewerIds: updatedViewers);
      _notifyArtifacts();
    }
  }

  @override
  Future<void> saveAnalysisResult(AnalysisResult result) async {
    analysisResults.add(result);
  }

  @override
  Stream<List<AnalysisResult>> getAnalysisResults(String artifactId) {
    return Stream.value(
      analysisResults.where((r) => r.artifactId == artifactId).toList(),
    );
  }

  @override
  Stream<List<AnalysisResult>> getViewerResults(String userId) {
    return Stream.value(
      analysisResults.where((r) => r.userId == userId).toList(),
    );
  }

  @override
  Future<void> saveUserProgress(UserProgress progress) async {
    final key = '${progress.userId}_${progress.artifactId}';
    userProgressMap[key] = progress;
  }

  @override
  Stream<UserProgress?> getViewerArtifactProgress(String userId, String artifactId) {
    final key = '${userId}_${artifactId}';
    return Stream.value(userProgressMap[key]);
  }

  @override
  Future<List<int>?> getArtifactThumbnail(String artifactId) async {
    return thumbnails[artifactId];
  }
}

void main() {
  late FakeArtifactRepository fakeRepository;
  late ProviderContainer container;

  setUp(() {
    fakeRepository = FakeArtifactRepository();
    container = ProviderContainer(
      overrides: [
        artifactRepositoryProvider.overrideWithValue(fakeRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('initial state of controller is AsyncData(null)', () {
    expect(container.read(artifactControllerProvider), equals(const AsyncData<void>(null)));
  });

  test('createArtifact successfully adds artifact and notifies listeners', () async {
    final controller = container.read(artifactControllerProvider.notifier);
    final artifact = Artifact(
      id: 'art_1',
      title: 'Obelisk',
      description: 'Historical marker',
      authorId: 'auth_1',
      authorName: 'Alex',
      createdAt: DateTime.now(),
      sections: [],
    );

    // Read the stream using a provider subscription
    final subscription = container.listen(
      allArtifactsProvider,
      (previous, next) {},
      fireImmediately: true,
    );

    await controller.createArtifact(artifact, thumbnailBytes: Uint8List.fromList([1, 2, 3]));

    // Should return to AsyncData state
    expect(container.read(artifactControllerProvider), isA<AsyncData<void>>());

    // Verify repository content
    expect(fakeRepository.artifacts.length, equals(1));
    expect(fakeRepository.artifacts.first.title, equals('Obelisk'));
    expect(fakeRepository.thumbnails['art_1'], equals([1, 2, 3]));

    // Clean up subscription
    subscription.close();
  });

  test('createArtifact error puts controller into AsyncError state', () async {
    final controller = container.read(artifactControllerProvider.notifier);
    final errorArtifact = Artifact(
      id: 'error_id',
      title: 'Bad Artifact',
      description: 'Error testing',
      authorId: 'auth_1',
      authorName: 'Alex',
      createdAt: DateTime.now(),
      sections: [],
    );

    await controller.createArtifact(errorArtifact);

    expect(container.read(artifactControllerProvider), isA<AsyncError<void>>());
    expect(fakeRepository.artifacts, isEmpty);
  });

  test('updateArtifactStatus updates status in repository', () async {
    final controller = container.read(artifactControllerProvider.notifier);
    final artifact = Artifact(
      id: 'art_2',
      title: 'Palace',
      description: 'Gondar palace',
      authorId: 'auth_1',
      authorName: 'Alex',
      status: 'pending',
      createdAt: DateTime.now(),
      sections: [],
    );

    await fakeRepository.createArtifact(artifact);
    expect(fakeRepository.artifacts.first.status, equals('pending'));

    await controller.updateArtifactStatus('art_2', 'approved');

    expect(fakeRepository.artifacts.first.status, equals('approved'));
  });

  test('trackViewer appends viewer to artifact', () async {
    final controller = container.read(artifactControllerProvider.notifier);
    final artifact = Artifact(
      id: 'art_3',
      title: 'Church',
      description: 'Lalibela',
      authorId: 'auth_1',
      authorName: 'Alex',
      createdAt: DateTime.now(),
      sections: [],
      viewerIds: ['user_abc'],
    );

    await fakeRepository.createArtifact(artifact);

    await controller.trackViewer('art_3', 'user_xyz');
    expect(fakeRepository.artifacts.first.viewerIds, equals(['user_abc', 'user_xyz']));

    // Tries tracking again, shouldn't duplicate
    await controller.trackViewer('art_3', 'user_xyz');
    expect(fakeRepository.artifacts.first.viewerIds, equals(['user_abc', 'user_xyz']));
  });

  test('submitAnalysisResult adds result', () async {
    final controller = container.read(artifactControllerProvider.notifier);
    final result = AnalysisResult(
      userId: 'user_1',
      userName: 'User One',
      artifactId: 'art_3',
      sectionId: 'sec_1',
      score: 3,
      totalQuestions: 5,
      completedAt: DateTime.now(),
    );

    await controller.submitAnalysisResult(result);
    expect(fakeRepository.analysisResults.length, equals(1));
    expect(fakeRepository.analysisResults.first.score, equals(3));
  });

  test('saveUserProgress updates progress mapping', () async {
    final controller = container.read(artifactControllerProvider.notifier);
    final progress = UserProgress(
      userId: 'user_1',
      artifactId: 'art_3',
      completedContentIds: ['c1'],
      analysisScores: {'sec1': 90},
      lastAccessedAt: DateTime.now(),
    );

    await controller.saveUserProgress(progress);
    expect(fakeRepository.userProgressMap['user_1_art_3'], isNotNull);
    expect(fakeRepository.userProgressMap['user_1_art_3']!.analysisScores['sec1'], equals(90));
  });
}
