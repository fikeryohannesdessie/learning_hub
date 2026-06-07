import 'dart:convert';
import 'dart:typed_data';

import 'package:chpa/core/storage/database_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Backend-connected CRUD integration tests', () {
    testWidgets('user CRUD works through the real HTTP backend', (
      WidgetTester tester,
    ) async {
      if (!kIsWeb) {
        return;
      }

      final suffix = DateTime.now().millisecondsSinceEpoch;
      final email = 'integration_user_$suffix@chpa.org';
      final uid = 'integration_user_$suffix';

      await db.deletePassword(email);
      await db.deleteUser(email);

      final userRow = <String, dynamic>{
        'uid': uid,
        'email': email,
        'display_name': 'Integration User',
        'role': 'viewer',
        'is_verified': 1,
        'verification_submitted': 0,
        'institution': null,
        'id_number': null,
        'credential_file_id': null,
        'is_rejected': 0,
        'verification_comment': null,
        'bio': 'Created from integration test',
        'security_answers': jsonEncode(const ['one', 'two', 'three']),
        'created_at': DateTime(2026, 1, 1).toIso8601String(),
      };

      await db.upsertUser(userRow);
      await db.upsertPassword(email, 'password123');

      final createdUser = await db.getUserByEmail(email);
      final createdPassword = await db.getPassword(email);
      expect(createdUser, isNotNull);
      expect(createdUser!['uid'], uid);
      expect(createdUser['display_name'], 'Integration User');
      expect(createdPassword, 'password123');

      await db.updateUser(uid, {
        'display_name': 'Updated Integration User',
        'institution': 'Backend Test Lab',
      });

      final updatedUser = await db.getUserByUid(uid);
      expect(updatedUser, isNotNull);
      expect(updatedUser!['display_name'], 'Updated Integration User');
      expect(updatedUser['institution'], 'Backend Test Lab');

      await db.deletePassword(email);
      await db.deleteUser(email);

      final deletedUser = await db.getUserByEmail(email);
      final deletedPassword = await db.getPassword(email);
      expect(deletedUser, isNull);
      expect(deletedPassword, isNull);
    });

    testWidgets('content CRUD and file operations work through the backend', (
      WidgetTester tester,
    ) async {
      if (!kIsWeb) {
        return;
      }

      final suffix = DateTime.now().millisecondsSinceEpoch;
      final contentId = 'integration_content_$suffix';
      final authorId = 'integration_author_$suffix';
      final uploadedAt = DateTime(2026, 1, 1).toIso8601String();
      final bytes = Uint8List.fromList(const [10, 20, 30, 40]);

      await db.deleteContentFile(contentId);
      await db.deleteContentById(contentId);

      final contentRow = <String, dynamic>{
        'id': contentId,
        'title': 'Integration Content',
        'type': 'document',
        'author_id': authorId,
        'author_name': 'Integration Author',
        'status': 'pending',
        'url': null,
        'grade_level': 'tangible',
        'subject': 'Heritage Studies',
        'description': 'Created during backend CRUD integration testing',
        'extra_data': jsonEncode({'source': 'integration-test'}),
        'rejection_reason': null,
        'uploaded_at': uploadedAt,
        'approved_at': null,
      };

      await db.upsertContent(contentRow);
      await db.upsertContentFile(contentId, bytes);

      final createdContent = await db.getContentById(contentId);
      final createdFile = await db.getContentFile(contentId);
      expect(createdContent, isNotNull);
      expect(createdContent!['title'], 'Integration Content');
      expect(createdContent['status'], 'pending');
      expect(createdFile, isNotNull);
      expect(createdFile, bytes);

      await db.updateContentStatus(
        contentId,
        'approved',
        approvedAt: DateTime(2026, 1, 2).toIso8601String(),
      );

      final approvedContent = await db.getContentById(contentId);
      expect(approvedContent, isNotNull);
      expect(approvedContent!['status'], 'approved');
      expect(approvedContent['approved_at'], isNotNull);

      await db.deleteContentFile(contentId);
      await db.deleteContentById(contentId);

      final deletedContent = await db.getContentById(contentId);
      final deletedFile = await db.getContentFile(contentId);
      expect(deletedContent, isNull);
      expect(deletedFile, isNull);
    });
  });
}
