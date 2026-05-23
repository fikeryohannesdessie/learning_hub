import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/content_domain.dart';
import '../infrastructure/content_infrastructure.dart';

final contentLocalDataSourceProvider = Provider<ContentLocalDataSource>((ref) {
  return ContentLocalDataSource();
});

final contentRemoteDataSourceProvider =
    Provider<ContentRemoteDataSource>((ref) {
  return const ContentRemoteDataSource();
});

final contentRepositoryProvider = Provider<IContentRepository>((ref) {
  return ContentRepositoryImpl(
    localDataSource: ref.watch(contentLocalDataSourceProvider),
    remoteDataSource: ref.watch(contentRemoteDataSourceProvider),
  );
});

final approvedContentProvider = StreamProvider.family<
    List<LearningContent>,
    ({String gradeLevel, String? type})>((ref, params) {
  return ref.watch(contentRepositoryProvider).getApprovedContent(
        gradeLevel: params.gradeLevel,
        type: params.type,
      );
});

final allContentProvider = StreamProvider<List<LearningContent>>((ref) {
  return ref.watch(contentRepositoryProvider).getAllContent();
});

final contributorContentProvider =
    StreamProvider.family<List<LearningContent>, String>(
  (ref, contributorId) {
    return ref
        .watch(contentRepositoryProvider)
        .getContributorContent(contributorId);
  },
);

final pendingContentProvider = StreamProvider<List<LearningContent>>((ref) {
  return ref.watch(contentRepositoryProvider).getPendingContent();
});

final contentFileProvider =
    FutureProvider.family<Uint8List?, String>((ref, id) async {
  final bytes = await ref.watch(contentRepositoryProvider).getFileBytes(id);
  return bytes;
});

final contentControllerProvider =
    NotifierProvider<ContentController, AsyncValue<void>>(ContentController.new);

class ContentController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  IContentRepository get _repository => ref.read(contentRepositoryProvider);

  Future<void> uploadContent(
    LearningContent content, {
    Uint8List? bytes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.uploadContent(content, bytes: bytes);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateContentStatus(
    String contentId,
    String status, {
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateContentStatus(contentId, status, reason: reason);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> saveFileBytes(String contentId, Uint8List bytes) async {
    state = const AsyncValue.loading();
    try {
      await _repository.upsertFileBytes(contentId, bytes);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
