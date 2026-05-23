/// Barrel export for the localization system.
/// Import ONLY this file in any screen to get full translation support:
///
///   import 'package:chpa/core/localization/localization.dart';
///
/// Then use TranslatedText everywhere instead of Text().
///   TranslatedText('Hello') → automatically shows in Amharic when 🇪🇹 is tapped.
///
/// The LanguageSwitcher widget is also exported for AppBars.
export 'app_translations.dart';
export 'language_switcher.dart';
export 'translated_text.dart';
