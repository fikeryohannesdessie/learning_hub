import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../utils/api_config.dart';

class _WebClient {
  String get baseUrl => ApiConfig.baseUrl;

  Future<Map<String, dynamic>?> _get(String path) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl$path'));
      if (res.statusCode == 200 && res.body != 'null' && res.body.isNotEmpty) {
        return jsonDecode(res.body) as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Web API error: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl$path'));
      if (res.statusCode == 200 && res.body != 'null' && res.body.isNotEmpty) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      print('Web API error: $e');
    }
    return [];
  }

  Future<void> _post(String path, dynamic body) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode != 200) {
        throw StateError('Web API POST $path failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      print('Web API error: $e');
      rethrow;
    }
  }

  Future<void> _put(String path, dynamic body) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode != 200) {
        throw StateError('Web API PUT $path failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      print('Web API error: $e');
      rethrow;
    }
  }

  Future<void> _delete(String path) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl$path'));
      if (res.statusCode != 200) {
        throw StateError('Web API DELETE $path failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      print('Web API error: $e');
      rethrow;
    }
  }

  Future<void> uploadFile(String type, String id, Uint8List bytes) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/files/$type/$id'),
        headers: const {'Content-Type': 'application/octet-stream'},
        body: bytes,
      );
      if (res.statusCode != 200) {
        throw StateError(
          'Web API upload file $type/$id failed: ${res.statusCode} ${res.body}',
        );
      }
    } catch (e) {
      print('Web API upload error: $e');
      rethrow;
    }
  }

  Future<Uint8List?> downloadFile(String type, String id) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/files/$type/$id'));
      if (res.statusCode == 200) {
        return res.bodyBytes;
      }
    } catch (e) {
      print('Web API download error: $e');
    }
    return null;
  }

  Future<void> deleteFile(String type, String id) async {
    try {
      await http.delete(Uri.parse('$baseUrl/files/$type/$id'));
    } catch (e) {
      print('Web API delete file error: $e');
    }
  }
}

/// Central SQLite database for CHPA (fallback to REST backend on Web).
class DatabaseHelper {
  DatabaseHelper._();

  static Database? _db;
  final _WebClient _web = _WebClient();

  static Future<String> get _filesDir async {
    if (kIsWeb) return '';
    final root = await getDatabasesPath();
    final dir = Directory(p.join(root, 'chpa_files'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  // ─────────────────────────────────────────────────────────── init ──────────

  static Future<void> init() async {
    if (kIsWeb) return;
    if (_db != null) return;
    final dbPath = p.join(await getDatabasesPath(), 'chpa.db');
    _db = await openDatabase(
      dbPath,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await _runDataMigrations();
  }

  static Future<void> _runDataMigrations() async {
    if (kIsWeb) return;
    // Solid fix for legacy audio items saved with incorrect grade_level
    await _db!.execute('''
      UPDATE content
      SET grade_level = 'intangible'
      WHERE type = 'audio' AND grade_level != 'intangible'
    ''');

    // Fix bookmarks referencing legacy audio
    final audioBookmarks = await _db!.query('bookmarks', where: 'type = ?', whereArgs: ['audio']);
    for (final b in audioBookmarks) {
      final extraRaw = b['extra_data'] as String?;
      if (extraRaw != null) {
        try {
          final extraData = Map<String, dynamic>.from(jsonDecode(extraRaw));
          if (extraData['gradeLevel'] != 'intangible' || extraData['classification'] != 'intangible') {
            extraData['gradeLevel'] = 'intangible';
            extraData['classification'] = 'intangible';
            await _db!.update(
              'bookmarks',
              {'extra_data': jsonEncode(extraData)},
              where: 'id = ?',
              whereArgs: [b['id']],
            );
          }
        } catch (_) {}
      }
    }
  }


  static Database get db {
    if (kIsWeb) {
      throw UnsupportedError('DatabaseHelper.db is not supported on Web. Use abstract methods.');
    }
    assert(_db != null, 'DatabaseHelper.init() must be called first.');
    return _db!;
  }

  // ──────────────────────────────────────────────────────── schema ───────────

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        uid               TEXT PRIMARY KEY,
        email             TEXT NOT NULL UNIQUE,
        display_name      TEXT,
        role              TEXT NOT NULL DEFAULT 'viewer',
        is_verified       INTEGER NOT NULL DEFAULT 0,
        verification_submitted INTEGER NOT NULL DEFAULT 0,
        institution       TEXT,
        id_number         TEXT,
        credential_file_id TEXT,
        is_rejected       INTEGER NOT NULL DEFAULT 0,
        verification_comment TEXT,
        bio               TEXT,
        security_answers  TEXT,
        created_at        TEXT NOT NULL
      )
    ''');

    // Separate table for credentials — cleaner than mixing into users.
    await db.execute('''
      CREATE TABLE user_passwords (
        email    TEXT PRIMARY KEY,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE content (
        id                TEXT PRIMARY KEY,
        title             TEXT NOT NULL,
        type              TEXT NOT NULL,
        author_id         TEXT NOT NULL,
        author_name       TEXT NOT NULL,
        status            TEXT NOT NULL DEFAULT 'pending',
        url               TEXT,
        grade_level       TEXT,
        subject           TEXT,
        description       TEXT,
        extra_data        TEXT,
        rejection_reason  TEXT,
        uploaded_at       TEXT NOT NULL,
        approved_at       TEXT
      )
    ''');

    // Binary file bytes for offline content (PDFs, images, etc.)
    await db.execute('''
      CREATE TABLE content_files (
        content_id TEXT PRIMARY KEY,
        bytes      BLOB NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE artifacts (
        id                   TEXT PRIMARY KEY,
        title                TEXT NOT NULL,
        description          TEXT NOT NULL,
        author_id            TEXT NOT NULL,
        author_name          TEXT NOT NULL,
        status               TEXT NOT NULL DEFAULT 'pending',
        sections_json        TEXT NOT NULL,
        viewer_ids_json      TEXT NOT NULL DEFAULT '[]',
        rejection_reason     TEXT,
        thumbnail_url        TEXT,
        is_sequential        INTEGER NOT NULL DEFAULT 1,
        classification       TEXT NOT NULL DEFAULT 'tangible',
        detailed_description TEXT,
        heritage_significance_json TEXT,
        created_at           TEXT NOT NULL
      )
    ''');

    // Thumbnail binary data stored separately
    await db.execute('''
      CREATE TABLE artifact_files (
        artifact_id TEXT PRIMARY KEY,
        bytes       BLOB NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bookmarks (
        id            TEXT PRIMARY KEY,
        title         TEXT NOT NULL,
        type          TEXT NOT NULL,
        extra_data    TEXT NOT NULL DEFAULT '{}',
        bookmarked_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE analysis_results (
        id               TEXT PRIMARY KEY,
        user_id          TEXT NOT NULL,
        user_name        TEXT NOT NULL,
        artifact_id      TEXT NOT NULL,
        section_id       TEXT NOT NULL,
        score            INTEGER NOT NULL,
        total_questions  INTEGER NOT NULL,
        completed_at     TEXT NOT NULL
      )
    ''');

    // Indexes for frequent query patterns
    await db.execute(
      'CREATE INDEX idx_analysis_artifact ON analysis_results(artifact_id)',
    );
    await db.execute(
      'CREATE INDEX idx_analysis_user ON analysis_results(user_id)',
    );

    await db.execute('''
      CREATE TABLE user_progress (
        user_id                TEXT NOT NULL,
        artifact_id            TEXT NOT NULL,
        completed_content_ids  TEXT NOT NULL DEFAULT '[]',
        analysis_scores        TEXT NOT NULL DEFAULT '{}',
        last_accessed_item_id  TEXT,
        last_accessed_at       TEXT NOT NULL,
        time_spent_seconds     INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (user_id, artifact_id)
      )
    ''');

    // Offline cache: maps content_id → local file path
    await db.execute('''
      CREATE TABLE offline_cache (
        content_id TEXT PRIMARY KEY,
        file_path  TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kIsWeb) return;
    // Future migration logic goes here.
    if (oldVersion < 2) {
      // Drop legacy key-value table if it exists from a previous install.
      await db.execute('DROP TABLE IF EXISTS storage_entries');
    }
  }

  // ─────────────────────────────────────────────────────── users ────────────

  Future<void> upsertUser(Map<String, dynamic> row) async {
    if (kIsWeb) {
      await _web._post('/users', row);
      return;
    }
    await db.insert('users', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    if (kIsWeb) {
      return _web._get('/users/by-email/${Uri.encodeComponent(email)}');
    }
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, dynamic>?> getUserByUid(String uid) async {
    if (kIsWeb) {
      return _web._get('/users/by-uid/$uid');
    }
    final rows = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    if (kIsWeb) {
      return _web._getList('/users');
    }
    return db.query('users', orderBy: 'created_at ASC');
  }

  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    if (kIsWeb) {
      await _web._put('/users/$uid', fields);
      return;
    }
    await db.update('users', fields, where: 'uid = ?', whereArgs: [uid]);
  }

  Future<void> deleteUser(String email) async {
    if (kIsWeb) {
      await _web._delete('/users/${Uri.encodeComponent(email)}');
      return;
    }
    await db.delete(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
  }

  // ──────────────────────────────────────────────── user passwords ───────────

  Future<void> upsertPassword(String email, String password) async {
    if (kIsWeb) {
      await _web._post('/passwords', {'email': email, 'password': password});
      return;
    }
    await db.insert(
      'user_passwords',
      {'email': email.trim().toLowerCase(), 'password': password},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getPassword(String email) async {
    if (kIsWeb) {
      final url = '${ApiConfig.baseUrl}/passwords/${Uri.encodeComponent(email)}';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200 && res.body != 'null' && res.body.isNotEmpty) {
        return jsonDecode(res.body) as String?;
      }
      return null;
    }
    final rows = await db.query(
      'user_passwords',
      columns: ['password'],
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['password'] as String?;
  }

  Future<void> deletePassword(String email) async {
    if (kIsWeb) {
      await _web._delete('/passwords/${Uri.encodeComponent(email)}');
      return;
    }
    await db.delete(
      'user_passwords',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
  }

  // ──────────────────────────────────────────────────── content ─────────────

  Future<void> upsertContent(Map<String, dynamic> row) async {
    if (kIsWeb) {
      await _web._post('/content', row);
      return;
    }
    await db.insert('content', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getContentById(String id) async {
    if (kIsWeb) {
      return _web._get('/content/$id');
    }
    final rows = await db.query(
      'content',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getAllContent() async {
    if (kIsWeb) {
      return _web._getList('/content');
    }
    return db.query('content', orderBy: 'uploaded_at DESC');
  }

  Future<List<Map<String, dynamic>>> getContentByStatus(String status) async {
    if (kIsWeb) {
      return _web._getList('/content?status=${Uri.encodeComponent(status)}');
    }
    return db.query(
      'content',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'uploaded_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getContentByAuthor(String authorId) async {
    if (kIsWeb) {
      return _web._getList('/content?author_id=$authorId');
    }
    return db.query(
      'content',
      where: 'author_id = ?',
      whereArgs: [authorId],
      orderBy: 'uploaded_at DESC',
    );
  }

  Future<void> updateContentStatus(
    String id,
    String status, {
    String? rejectionReason,
    String? approvedAt,
  }) async {
    if (kIsWeb) {
      await _web._put('/content/$id/status', {
        'status': status,
        'rejection_reason': rejectionReason,
        'approved_at': approvedAt,
      });
      return;
    }
    final fields = <String, dynamic>{'status': status};
    if (rejectionReason != null) fields['rejection_reason'] = rejectionReason;
    if (approvedAt != null) fields['approved_at'] = approvedAt;
    await db.update('content', fields, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteContentByAuthor(String authorId) async {
    if (kIsWeb) {
      await _web._delete('/content/by-author/$authorId');
      return;
    }
    final ids = (await getContentByAuthor(authorId))
        .map((r) => r['id'] as String)
        .toList();
    for (final id in ids) {
      await db.delete('content', where: 'id = ?', whereArgs: [id]);
      await db.delete('content_files', where: 'content_id = ?', whereArgs: [id]);
    }
  }

  Future<void> deleteContentById(String id) async {
    if (kIsWeb) {
      await _web._delete('/content/$id');
      return;
    }
    await db.delete('content', where: 'id = ?', whereArgs: [id]);
  }

  // ─────────────────────────────────────────── content files (blobs) ─────────

  Future<void> upsertContentFile(String contentId, Uint8List bytes) async {
    if (kIsWeb) {
      await _web.uploadFile('content', contentId, bytes);
      return;
    }
    final dir = await _filesDir;
    final file = File(p.join(dir, 'content_$contentId.bin'));
    await file.writeAsBytes(bytes);

    await db.delete('content_files', where: 'content_id = ?', whereArgs: [contentId]);
  }

  Future<Uint8List?> getContentFile(String contentId) async {
    if (kIsWeb) {
      return _web.downloadFile('content', contentId);
    }
    final dir = await _filesDir;
    final file = File(p.join(dir, 'content_$contentId.bin'));

    if (await file.exists()) {
      return await file.readAsBytes();
    }

    try {
      final rows = await db.query(
        'content_files',
        columns: ['bytes'],
        where: 'content_id = ?',
        whereArgs: [contentId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final raw = rows.first['bytes'];
      if (raw is Uint8List) return raw;
      if (raw is List<int>) return Uint8List.fromList(raw);
    } catch (e) {
      print('Legacy SQLite blob read failed for content $contentId: $e');
    }
    return null;
  }

  Future<void> deleteContentFile(String contentId) async {
    if (kIsWeb) {
      await _web.deleteFile('content', contentId);
      return;
    }
    final dir = await _filesDir;
    final file = File(p.join(dir, 'content_$contentId.bin'));
    if (await file.exists()) await file.delete();

    await db.delete(
      'content_files',
      where: 'content_id = ?',
      whereArgs: [contentId],
    );
  }

  // ────────────────────────────────────────────────────── artifacts ──────────

  Future<void> upsertArtifact(Map<String, dynamic> row) async {
    if (kIsWeb) {
      await _web._post('/artifacts', row);
      return;
    }
    await db.insert('artifacts', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getArtifactById(String id) async {
    if (kIsWeb) {
      return _web._get('/artifacts/$id');
    }
    final rows = await db.query(
      'artifacts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getAllArtifacts() async {
    if (kIsWeb) {
      return _web._getList('/artifacts');
    }
    return db.query('artifacts', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getArtifactsByStatus(String status) async {
    if (kIsWeb) {
      return _web._getList('/artifacts?status=${Uri.encodeComponent(status)}');
    }
    return db.query(
      'artifacts',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getArtifactsByAuthor(
    String authorId,
  ) async {
    if (kIsWeb) {
      return _web._getList('/artifacts?author_id=$authorId');
    }
    return db.query(
      'artifacts',
      where: 'author_id = ?',
      whereArgs: [authorId],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getArtifactsByStatusAndClassification(
    String status,
    String classification,
  ) async {
    if (kIsWeb) {
      return _web._getList('/artifacts?status=${Uri.encodeComponent(status)}&classification=${Uri.encodeComponent(classification)}');
    }
    return db.query(
      'artifacts',
      where: 'status = ? AND classification = ?',
      whereArgs: [status, classification],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> updateArtifactStatus(
    String id,
    String status, {
    String? rejectionReason,
  }) async {
    if (kIsWeb) {
      await _web._put('/artifacts/$id/status', {
        'status': status,
        'rejection_reason': rejectionReason,
      });
      return;
    }
    final fields = <String, dynamic>{'status': status};
    if (rejectionReason != null) fields['rejection_reason'] = rejectionReason;
    await db.update('artifacts', fields, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateArtifactViewerIds(String id, String viewerIdsJson) async {
    if (kIsWeb) {
      await _web._put('/artifacts/$id/viewer-ids', {
        'viewer_ids_json': viewerIdsJson,
      });
      return;
    }
    await db.update(
      'artifacts',
      {'viewer_ids_json': viewerIdsJson},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ──────────────────────────────────────── artifact files (thumbnails) ───────

  Future<void> upsertArtifactFile(String artifactId, Uint8List bytes) async {
    if (kIsWeb) {
      await _web.uploadFile('artifact', artifactId, bytes);
      return;
    }
    final dir = await _filesDir;
    final file = File(p.join(dir, 'artifact_$artifactId.bin'));
    await file.writeAsBytes(bytes);

    await db.delete('artifact_files', where: 'artifact_id = ?', whereArgs: [artifactId]);
  }

  Future<Uint8List?> getArtifactFile(String artifactId) async {
    if (kIsWeb) {
      return _web.downloadFile('artifact', artifactId);
    }
    final dir = await _filesDir;
    final file = File(p.join(dir, 'artifact_$artifactId.bin'));

    if (await file.exists()) {
      return await file.readAsBytes();
    }

    try {
      final rows = await db.query(
        'artifact_files',
        columns: ['bytes'],
        where: 'artifact_id = ?',
        whereArgs: [artifactId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final raw = rows.first['bytes'];
      if (raw is Uint8List) return raw;
      if (raw is List<int>) return Uint8List.fromList(raw);
    } catch (e) {
      print('Legacy SQLite blob read failed for artifact $artifactId: $e');
    }
    return null;
  }

  // ────────────────────────────────────────────────────── bookmarks ──────────

  Future<void> upsertBookmark(Map<String, dynamic> row) async {
    if (kIsWeb) {
      await _web._post('/bookmarks', row);
      return;
    }
    await db.insert(
      'bookmarks',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllBookmarks() async {
    if (kIsWeb) {
      return _web._getList('/bookmarks');
    }
    return db.query('bookmarks', orderBy: 'bookmarked_at DESC');
  }

  Future<void> deleteBookmark(String id) async {
    if (kIsWeb) {
      await _web._delete('/bookmarks/$id');
      return;
    }
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> bookmarkExists(String id) async {
    if (kIsWeb) {
      final url = '${ApiConfig.baseUrl}/bookmarks/${Uri.encodeComponent(id)}/exists';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as bool;
      }
      return false;
    }
    final rows = await db.query(
      'bookmarks',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // ─────────────────────────────────────────── analysis results ─────────────

  Future<void> insertAnalysisResult(Map<String, dynamic> row) async {
    if (kIsWeb) {
      await _web._post('/analysis-results', row);
      return;
    }
    await db.insert(
      'analysis_results',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAnalysisResultsByArtifact(
    String artifactId,
  ) async {
    if (kIsWeb) {
      return _web._getList('/analysis-results/by-artifact/$artifactId');
    }
    return db.query(
      'analysis_results',
      where: 'artifact_id = ?',
      whereArgs: [artifactId],
      orderBy: 'completed_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAnalysisResultsByUser(
    String userId,
  ) async {
    if (kIsWeb) {
      return _web._getList('/analysis-results/by-user/$userId');
    }
    return db.query(
      'analysis_results',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'completed_at DESC',
    );
  }

  // ─────────────────────────────────────────────── user progress ────────────

  Future<void> upsertUserProgress(Map<String, dynamic> row) async {
    if (kIsWeb) {
      await _web._post('/user-progress', row);
      return;
    }
    await db.insert(
      'user_progress',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUserProgress(
    String userId,
    String artifactId,
  ) async {
    if (kIsWeb) {
      return _web._get('/user-progress/$userId/$artifactId');
    }
    final rows = await db.query(
      'user_progress',
      where: 'user_id = ? AND artifact_id = ?',
      whereArgs: [userId, artifactId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  // ─────────────────────────────────────────────── offline cache ────────────

  Future<void> upsertOfflineCache(String contentId, String filePath) async {
    if (kIsWeb) return;
    await db.insert(
      'offline_cache',
      {'content_id': contentId, 'file_path': filePath},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getOfflinePath(String contentId) async {
    if (kIsWeb) return null;
    final rows = await db.query(
      'offline_cache',
      columns: ['file_path'],
      where: 'content_id = ?',
      whereArgs: [contentId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['file_path'] as String?;
  }

  // ─────────────────────────────────────────────── translations cache ────────

  Future<void> initTranslationsTable() async {
    if (kIsWeb) return;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS translations (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<String?> getCachedTranslation(String key) async {
    if (kIsWeb) {
      final url = '${ApiConfig.baseUrl}/translations/${Uri.encodeComponent(key)}';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200 && res.body != 'null' && res.body.isNotEmpty) {
        return jsonDecode(res.body) as String?;
      }
      return null;
    }
    final cached = await db.query(
      'translations',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return cached.isEmpty ? null : cached.first['value'] as String?;
  }

  Future<void> cacheTranslation(String key, String value) async {
    if (kIsWeb) {
      await _web._post('/translations', {'key': key, 'value': value});
      return;
    }
    await db.insert('translations', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

/// Singleton instance used across all repositories.
final db = DatabaseHelper._();
