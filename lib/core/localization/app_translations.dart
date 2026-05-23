import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:translator/translator.dart';

import '../storage/database_helper.dart';

/// Holds the currently selected language code ('en' or 'am').
final languageProvider = NotifierProvider<LanguageController, String>(
  LanguageController.new,
);

class LanguageController extends Notifier<String> {
  @override
  String build() => 'en';

  void setLanguage(String languageCode) => state = languageCode;
}

// ─── Translation cache ────────────────────────────────────────────────────────
//
// Cached in a dedicated SQLite table: translations(key TEXT PK, value TEXT).
// The table is created lazily on first use.

bool _tableReady = false;

Future<void> initTranslations() async {
  await _ensureTable();
}

Future<void> _ensureTable() async {
  if (_tableReady) return;
  await DatabaseHelper.db.execute('''
    CREATE TABLE IF NOT EXISTS translations (
      key   TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''');
  _tableReady = true;
}

final _googleTranslator = GoogleTranslator();

/// Translates [text] to [targetLang] using Google Translate.
/// Returns the original text on failure.
Future<String> translateText(String text, String targetLang) async {
  if (targetLang == 'en') return text;

  final key = '$targetLang:$text';
  await _ensureTable();

  // Check the SQLite translations cache first.
  final cached = await DatabaseHelper.db.query(
    'translations',
    columns: ['value'],
    where: 'key = ?',
    whereArgs: [key],
    limit: 1,
  );
  if (cached.isNotEmpty) {
    return cached.first['value'] as String;
  }

  try {
    final result = await _googleTranslator.translate(text, to: targetLang);

    // Save to the SQLite translations cache.
    await DatabaseHelper.db.insert('translations', {
      'key': key,
      'value': result.text,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    return result.text;
  } catch (_) {
    return text;
  }
}

/// Synchronously attempts to get a translation from an in-memory fallback.
/// Returns the original text if not found — kicks off a background translate.
final _memCache = <String, String>{};

String getTranslatedSync(String text, String targetLang) {
  if (targetLang == 'en') return text;

  final key = '$targetLang:$text';

  if (_memCache.containsKey(key)) return _memCache[key]!;

  // Kick off async lookup; next rebuild will use the cached value.
  translateText(text, targetLang).then((value) {
    _memCache[key] = value;
  });

  return text;
}
