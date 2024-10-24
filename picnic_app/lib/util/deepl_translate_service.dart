import 'package:deepl_dart/deepl_dart.dart';

class DeepLTranslationService {
  final Translator _translator;
  final bool debugMode;
  static const int _maxAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 1);
  static const Duration _defaultDelay = Duration(milliseconds: 500);

  final Map<String, RegExp> _languageRegexMap = {
    'EN': RegExp(r'^[a-zA-Z0-9\s\p{P}]+$', unicode: true),
    'JA': RegExp(r'[\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Han}]+',
        unicode: true),
    'ZH': RegExp(r'[\p{Script=Han}]+', unicode: true),
  };

  final RegExp _koreanRegex = RegExp(r'[가-힣]+');
  final RegExp _placeholderRegex = RegExp(r'\{[^}]+\}');

  DeepLTranslationService({
    required String apiKey,
    this.debugMode = true,
  }) : _translator = Translator(authKey: apiKey);

  /// Translates text to target language
  Future<String> translateText(
      String text, String sourceLang, String targetLang) async {
    if (debugMode) print('Translating: "$text" to $targetLang');
    int attempts = 0;

    while (attempts < _maxAttempts) {
      try {
        final translation = await _translator
            .translateTextSingular(text, targetLang, sourceLang: sourceLang);
        if (debugMode) print('Translated: "$text" -> "${translation.text}"');

        return translation.text;
        // if (!containsKoreanOrEmpty(translation.text)) {
        //   await Future.delayed(_defaultDelay);
        //   return translation.text;
        // } else {
        //   if (debugMode) {
        //     print(
        //         'Warning: Translation still contains Korean or is empty. Retrying...');
        //   }
        //   attempts++;
        //   await Future.delayed(_retryDelay);
        // }
      } catch (e) {
        if (debugMode) print('Error translating text: $e');
        attempts++;
        await Future.delayed(_retryDelay);
      }
    }

    if (debugMode) {
      print(
          'Failed to translate after $_maxAttempts attempts. Using original text.');
    }
    return text;
  }

  /// Translates text while preserving placeholders
  Future<String> translateTextWithPlaceholders(
      String text, String targetLang) async {
    final placeholders =
        _placeholderRegex.allMatches(text).map((m) => m.group(0)!).toList();
    final placeholderMap = Map.fromIterables(
      placeholders.map((p) => '__PH${placeholders.indexOf(p)}__'),
      placeholders,
    );

    String tempText = text;
    placeholderMap.forEach((key, value) {
      tempText = tempText.replaceAll(value, key);
    });

    final translatedTempText = await translateText(tempText, 'ko', targetLang);

    String finalText = translatedTempText;
    placeholderMap.forEach((key, value) {
      finalText = finalText.replaceAll(key, value);
    });

    return finalText;
  }

  /// Checks if text contains Korean characters
  bool containsKorean(String text) => _koreanRegex.hasMatch(text);

  /// Checks if text is empty or contains Korean characters
  bool containsKoreanOrEmpty(String text) {
    if (text.isEmpty) return true;
    return containsKorean(text);
  }

  /// Checks if text contains placeholders
  bool containsPlaceholders(String text) => _placeholderRegex.hasMatch(text);

  /// Validates if translated text matches target language pattern
  bool isCorrectLanguage(String text, String targetLanguage) {
    final textWithoutPlaceholders = text.replaceAll(_placeholderRegex, '');

    final regex = _languageRegexMap[targetLanguage];
    if (regex == null) {
      if (debugMode) {
        print('Warning: No regex defined for language $targetLanguage');
      }
      return true;
    }
    return regex.hasMatch(textWithoutPlaceholders);
  }
}
