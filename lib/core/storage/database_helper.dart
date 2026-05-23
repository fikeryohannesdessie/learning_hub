import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Central SQLite database for CHPA.
///
/// Real schema — one table per domain. No key/value box abstraction.
/// All repositories use this helper directly with typed SQL queries.
class DatabaseHelper {
  DatabaseHelper._();

  static Database? _db;

  static Future<String> get _filesDir async {
    final root = await getDatabasesPath();
    final dir = Directory(p.join(root, 'chpa_files'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  // ─────────────────────────────────────────────────────────── init ──────────

  static Future<void> init() async {
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
    // Future migration logic goes here.
    if (oldVersion < 2) {
      // Drop legacy key-value table if it exists from a previous install.
      await db.execute('DROP TABLE IF EXISTS storage_entries');
    }
  }

  // ─────────────────────────────────────────────────────── users ────────────

  Future<void> upsertUser(Map<String, dynamic> row) async {
    await db.insert('users', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, dynamic>?> getUserByUid(String uid) async {
    final rows = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    return db.query('users', orderBy: 'created_at ASC');
  }

  Future<void> updateUser(String uid, Map<String, dynamic> fields) async {
    await db.update('users', fields, where: 'uid = ?', whereArgs: [uid]);
  }

  Future<void> deleteUser(String email) async {
    await db.delete(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
  }

  // ──────────────────────────────────────────────── user passwords ───────────

  Future<void> upsertPassword(String email, String password) async {
    await db.insert(
      'user_passwords',
      {'email': email.trim().toLowerCase(), 'password': password},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getPassword(String email) async {
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
    await db.delete(
      'user_passwords',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
  }

  // ──────────────────────────────────────────────────── content ─────────────

  Future<void> upsertContent(Map<String, dynamic> row) async {
    await db.insert('content', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getContentById(String id) async {
    final rows = await db.query(
      'content',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getAllContent() async {
    return db.query('content', orderBy: 'uploaded_at DESC');
  }

  Future<List<Map<String, dynamic>>> getContentByStatus(String status) async {
    return db.query(
      'content',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'uploaded_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getContentByAuthor(String authorId) async {
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
    final fields = <String, dynamic>{'status': status};
    if (rejectionReason != null) fields['rejection_reason'] = rejectionReason;
    if (approvedAt != null) fields['approved_at'] = approvedAt;
    await db.update('content', fields, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteContentByAuthor(String authorId) async {
    final ids = (await getContentByAuthor(authorId))
        .map((r) => r['id'] as String)
        .toList();
    for (final id in ids) {
      await db.delete('content', where: 'id = ?', whereArgs: [id]);
      await db.delete('content_files', where: 'content_id = ?', whereArgs: [id]);
    }
  }

  // ─────────────────────────────────────────── content files (blobs) ─────────

  Future<void> upsertContentFile(String contentId, Uint8List bytes) async {
    final dir = await _filesDir;
    final file = File(p.join(dir, 'content_$contentId.bin'));
    await file.writeAsBytes(bytes);
    
    await db.delete('content_files', where: 'content_id = ?', whereArgs: [contentId]);
  }

  Future<Uint8List?> getContentFile(String contentId) async {
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
    await db.insert('artifacts', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getArtifactById(String id) async {
    final rows = await db.query(
      'artifacts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getAllArtifacts() async {
    return db.query('artifacts', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getArtifactsByStatus(String status) async {
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
    final fields = <String, dynamic>{'status': status};
    if (rejectionReason != null) fields['rejection_reason'] = rejectionReason;
    await db.update('artifacts', fields, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateArtifactViewerIds(String id, String viewerIdsJson) async {
    await db.update(
      'artifacts',
      {'viewer_ids_json': viewerIdsJson},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ──────────────────────────────────────── artifact files (thumbnails) ───────

  Future<void> upsertArtifactFile(String artifactId, Uint8List bytes) async {
    final dir = await _filesDir;
    final file = File(p.join(dir, 'artifact_$artifactId.bin'));
    await file.writeAsBytes(bytes);

    await db.delete('artifact_files', where: 'artifact_id = ?', whereArgs: [artifactId]);
  }

  Future<Uint8List?> getArtifactFile(String artifactId) async {
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
    await db.insert(
      'bookmarks',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllBookmarks() async {
    return db.query('bookmarks', orderBy: 'bookmarked_at DESC');
  }

  Future<void> deleteBookmark(String id) async {
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> bookmarkExists(String id) async {
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
    await db.insert(
      'analysis_results',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAnalysisResultsByArtifact(
    String artifactId,
  ) async {
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
    return db.query(
      'analysis_results',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'completed_at DESC',
    );
  }

  // ─────────────────────────────────────────────── user progress ────────────

  Future<void> upsertUserProgress(Map<String, dynamic> row) async {
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
    await db.insert(
      'offline_cache',
      {'content_id': contentId, 'file_path': filePath},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getOfflinePath(String contentId) async {
    final rows = await db.query(
      'offline_cache',
      columns: ['file_path'],
      where: 'content_id = ?',
      whereArgs: [contentId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['file_path'] as String?;
  }
}

/// Singleton instance used across all repositories.
final db = DatabaseHelper._();
