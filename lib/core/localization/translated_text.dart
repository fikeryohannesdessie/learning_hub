import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_translations.dart';

/// Renders [text] translated to the active language using Google Translate.
/// Shows original text while translating, then swaps to translated version.
class TranslatedText extends ConsumerStatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  ConsumerState<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends ConsumerState<TranslatedText> {
  String _displayText = '';
  String _lastLang = 'en';
  String _lastOriginal = '';

  @override
  void initState() {
    super.initState();
    _displayText = widget.text;
    _lastOriginal = widget.text;
  }

  void _doTranslate(String lang) {
    _lastLang = lang;
    _lastOriginal = widget.text;
    translateText(widget.text, lang).then((translated) {
      if (mounted &&
          ref.read(languageProvider) == lang &&
          widget.text == _lastOriginal) {
        setState(() => _displayText = translated);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    // Re-translate if language or text changed
    if (lang != _lastLang || widget.text != _lastOriginal) {
      if (lang == 'en') {
        _displayText = widget.text;
        _lastLang = lang;
        _lastOriginal = widget.text;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => _doTranslate(lang));
      }
    }

    return Text(
      _displayText,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
