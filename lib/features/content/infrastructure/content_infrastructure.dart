import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/database_helper.dart';
import '../domain/content_domain.dart';
import 'content_dto.dart';

class ContentLocalDataSource {
  LearningContent mapRowToContent(Map<String, dynamic> row) {
    Map<String, dynamic>? extraData;
    final rawExtra = row['extra_data'] as String?;
    if (rawExtra != null && rawExtra.isNotEmpty) {
      try {
        extraData = Map<String, dynamic>.from(jsonDecode(rawExtra));
      } catch (_) {}
    }

    return ContentDto.fromRow(row, extraData: extraData).toDomain();
  }

  Map<String, dynamic> mapContentToRow(LearningContent content) {
    final row = ContentDto.fromDomain(content).toRow();
    row['extra_data'] =
        content.extraData != null ? jsonEncode(content.extraData) : null;
    return row;
  }

  Future<void> removeLegacySeedContent() async {
    const legacyTitles = {'Introduction to Physics', 'Advanced Mathematics'};
    const legacySubjects = {'Physics', 'Math', 'Mathematics'};

    final allContent = await db.getAllContent();
    for (final row in allContent) {
      final authorId = row['author_id'] as String? ?? '';
      final title = row['title'] as String? ?? '';
      final subject = row['subject'] as String? ?? '';
      if (authorId == 'system' &&
          (legacyTitles.contains(title) || legacySubjects.contains(subject))) {
        final id = row['id'] as String;
        await DatabaseHelper.db.delete('content', where: 'id = ?', whereArgs: [id]);
        await db.deleteContentFile(id);
        debugPrint('SQLite: removed legacy seed content $id');
      }
    }
  }

  Future<List<LearningContent>> getAllContent() async {
    final rows = await db.getAllContent();
    return rows.map(mapRowToContent).toList();
  }

  Future<List<LearningContent>> getPendingContent() async {
    final rows = await db.getContentByStatus(AppConstants.statusPending);
    return rows.map(mapRowToContent).toList();
  }

  Future<List<LearningContent>> getApprovedContent({
    required String gradeLevel,
    String? type,
  }) async {
    final rows = await db.getContentByStatus(AppConstants.statusApproved);
    return rows.map(mapRowToContent).where((content) {
      final matchesType = type == null || content.type == type;
      if (!matchesType) {
        return false;
      }

      if (content.type == AppConstants.contentTypeAnalysis) {
        final normalized = (content.gradeLevel ?? '').trim().toLowerCase();
        final isLegacy = normalized == AppConstants.classificationTangible ||
            normalized == AppConstants.classificationIntangible;
        return !isLegacy || normalized == gradeLevel;
      }

      return content.gradeLevel == gradeLevel;
    }).toList();
  }

  Future<List<LearningContent>> getContributorContent(String contributorId) async {
    final rows = await db.getContentByAuthor(contributorId);
    return rows.map(mapRowToContent).toList();
  }

  Future<void> uploadContent(
    LearningContent content, {
    Uint8List? bytes,
  }) async {
    debugPrint('SQLite: uploadContent id=${content.id}');

    LearningContent contentToSave = content;
    if (content.status != AppConstants.statusApproved &&
        content.subject != 'Contributor Verification') {
      contentToSave = content.copyWith(status: AppConstants.statusPending);
    }

    await db.upsertContent(mapContentToRow(contentToSave));
    if (bytes != null) {
      await db.upsertContentFile(contentToSave.id, bytes);
    }

    debugPrint('SQLite: uploadContent done id=${contentToSave.id}');
  }

  Future<void> updateContentStatus(
    String contentId,
    String status, {
    String? reason,
  }) {
    return db.updateContentStatus(
      contentId,
      status,
      rejectionReason: reason,
      approvedAt:
          status == AppConstants.statusApproved ? DateTime.now().toIso8601String() : null,
    );
  }

  Future<Uint8List?> getFileBytes(String contentId) {
    return db.getContentFile(contentId);
  }

  Future<void> upsertFileBytes(String contentId, Uint8List bytes) {
    return db.upsertContentFile(contentId, bytes);
  }

  Future<void> deleteContentByAuthorId(String authorId) async {
    await db.deleteContentByAuthor(authorId);
    debugPrint('SQLite: deleted all content for author $authorId');
  }
}

class ContentRemoteDataSource {
  const ContentRemoteDataSource();
}

class ContentRepositoryImpl implements IContentRepository {
  ContentRepositoryImpl({
    required ContentLocalDataSource localDataSource,
    required ContentRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource {
    unawaited(_localDataSource.removeLegacySeedContent());
  }

  final ContentLocalDataSource _localDataSource;
  final ContentRemoteDataSource _remoteDataSource;
  final StreamController<void> _controller = StreamController<void>.broadcast();

  void _notify() => _controller.add(null);

  @override
  Stream<List<LearningContent>> getApprovedContent({
    required String gradeLevel,
    String? type,
  }) async* {
    yield await _localDataSource.getApprovedContent(
      gradeLevel: gradeLevel,
      type: type,
    );
    await for (final _ in _controller.stream) {
      yield await _localDataSource.getApprovedContent(
        gradeLevel: gradeLevel,
        type: type,
      );
    }
  }

  @override
  Stream<List<LearningContent>> getAllContent() async* {
    yield await _localDataSource.getAllContent();
    await for (final _ in _controller.stream) {
      yield await _localDataSource.getAllContent();
    }
  }

  @override
  Stream<List<LearningContent>> getContributorContent(
    String contributorId,
  ) async* {
    yield await _localDataSource.getContributorContent(contributorId);
    await for (final _ in _controller.stream) {
      yield await _localDataSource.getContributorContent(contributorId);
    }
  }

  @override
  Stream<List<LearningContent>> getPendingContent() async* {
    yield await _localDataSource.getPendingContent();
    await for (final _ in _controller.stream) {
      final items = await _localDataSource.getPendingContent();
      debugPrint('SQLite content watch: ${items.length} pending items');
      yield items;
    }
  }

  @override
  Future<void> uploadContent(
    LearningContent content, {
    List<int>? bytes,
  }) async {
    await _localDataSource.uploadContent(
      content,
      bytes: bytes == null ? null : Uint8List.fromList(bytes),
    );
    _notify();
  }

  @override
  Future<void> updateContentStatus(
    String contentId,
    String status, {
    String? reason,
  }) async {
    await _localDataSource.updateContentStatus(
      contentId,
      status,
      reason: reason,
    );
    _notify();
  }

  @override
  Future<Uint8List?> getFileBytes(String contentId) async {
    return _localDataSource.getFileBytes(contentId);
  }

  @override
  Future<void> upsertFileBytes(String contentId, Uint8List bytes) async {
    await _localDataSource.upsertFileBytes(contentId, bytes);
    _notify();
  }

  @override
  Future<void> deleteContentByAuthorId(String authorId) async {
    await _localDataSource.deleteContentByAuthorId(authorId);
    _notify();
  }
}
