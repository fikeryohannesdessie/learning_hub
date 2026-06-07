import 'package:flutter_riverpod/flutter_riverpod.dart';
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
// Cached in a dedicated translations cache using DatabaseHelper.
// The table is created lazily on first use.

bool _tableReady = false;

Future<void> initTranslations() async {
  await _ensureTable();
}

Future<void> _ensureTable() async {
  if (_tableReady) return;
  await db.initTranslationsTable();
  _tableReady = true;
}

final _googleTranslator = GoogleTranslator();

/// Translates [text] to [targetLang] using Google Translate.
/// Returns the original text on failure.
Future<String> translateText(String text, String targetLang) async {
  if (targetLang == 'en') return text;

  final key = '$targetLang:$text';
  await _ensureTable();

  // Check the translations cache first.
  final cached = await db.getCachedTranslation(key);
  if (cached != null) {
    return cached;
  }

  try {
    final result = await _googleTranslator.translate(text, to: targetLang);

    // Save to the translations cache.
    await db.cacheTranslation(key, result.text);

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
