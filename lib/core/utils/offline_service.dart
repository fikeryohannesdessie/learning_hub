import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../features/content/domain/content_domain.dart';
import '../../../core/storage/database_helper.dart';

/// Manages offline caching of remote PDF files.
///
/// Uses the [offline_cache] SQLite table: content_id → local file path.
class OfflineService {
  static Future<void> init() async {
    if (kIsWeb) return;
    // DatabaseHelper is already initialised in main(); nothing extra needed.
    debugPrint('SQLite OfflineService ready.');
  }

  /// Download a PDF from [content.url] and store it locally.
  /// Returns the local file path, or null on failure.
  static Future<String?> downloadAndCachePDF(LearningContent content) async {
    if (kIsWeb || content.url == null) return null;

    try {
      final response = await http.get(Uri.parse(content.url!));
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${content.id}.pdf');

      await file.writeAsBytes(response.bodyBytes);

      // Persist path in offline_cache table
      await db.upsertOfflineCache(content.id, file.path);

      debugPrint('SQLite offline: cached ${content.id} → ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('SQLite offline error caching ${content.id}: $e');
      return null;
    }
  }

  /// Returns the cached local path for [contentId], or null if not cached.
  static Future<String?> getLocalPath(String contentId) async {
    if (kIsWeb) return null;
    return db.getOfflinePath(contentId);
  }

  /// Checks whether the cached file still exists on disk.
  static Future<bool> isOffline(String contentId) async {
    if (kIsWeb) return false;
    final path = await getLocalPath(contentId);
    if (path == null) return false;
    return File(path).existsSync();
  }
}
