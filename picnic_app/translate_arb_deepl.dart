import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:deepl_dart/deepl_dart.dart';
import 'package:pool/pool.dart';
import 'package:watcher/watcher.dart';

// Constants
const String deeplApiKey = 'ef2715c3-89d7-4b1b-a95b-e1fd3b7d734e:fx';
const String manualTranslationKey = 'manualTranslation';
final RegExp koreanRegex = RegExp(r'[가-힣]+');

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('all',
        abbr: 'a', defaultsTo: false, help: 'Translate all strings')
    ..addFlag('watch', abbr: 'w', defaultsTo: false, help: 'Watch for changes');

  final args = parser.parse(arguments);
  final translateAll = args['all'] as bool;
  final watch = args['watch'] as bool;

  try {
    final translator = Translator(authKey: deeplApiKey);
    print('Starting translation process...');
    print('API Key: $deeplApiKey');

    const String inputFile = 'lib/l10n/intl_ko.arb';
    final List<String> outputFiles = [
      'lib/l10n/intl_en.arb',
      'lib/l10n/intl_ja.arb',
      'lib/l10n/intl_zh.arb'
    ];

    if (!watch) {
      await sortAndUpdateArbFile(inputFile);
      for (final outputFile in outputFiles) {
        await sortAndUpdateArbFile(outputFile);
      }
    }

    await synchronizeKeys(inputFile, outputFiles);

    if (translateAll || !watch) {
      print('Translating all languages...');
      await translateAllLanguages(
          translator, inputFile, outputFiles, translateAll);
      print('All languages translated successfully.');
    }

    if (watch) {
      print('Watching for changes...');
      await watchForChanges(translator, inputFile, outputFiles);
    }
  } catch (e, s) {
    print('Error occurred during translation process: $e');
    print('Stack trace:\n$s');
  }
}

Future<void> sortAndUpdateArbFile(String filePath) async {
  final file = File(filePath);

  if (!await file.exists()) {
    print('File not found: $filePath');
    return;
  }

  try {
    final contents = await file.readAsString();
    final arbContent = json.decode(contents) as Map<String, dynamic>;

    final updatedArbContent = <String, dynamic>{};

    if (arbContent.containsKey("@@locale")) {
      updatedArbContent["@@locale"] = arbContent["@@locale"];
    }

    final sortedKeys = arbContent.keys
        .where((key) => !key.startsWith('@') && key != "@@locale")
        .toList()
      ..sort();

    for (var key in sortedKeys) {
      updatedArbContent[key] = arbContent[key];
      final metaKey = '@$key';

      if (arbContent.containsKey(metaKey)) {
        updatedArbContent[metaKey] = arbContent[metaKey];
      } else {
        updatedArbContent[metaKey] = <String, dynamic>{};
      }
    }

    const encoder = JsonEncoder.withIndent('  ');
    final formattedJson = encoder.convert(updatedArbContent);

    await file.writeAsString(formattedJson);
    print('File sorted, updated, and saved to $filePath');
  } catch (e) {
    print('Error sorting and updating file $filePath: $e');
  }
}

Future<void> synchronizeKeys(String inputFile, List<String> outputFiles) async {
  try {
    final originalArbContent = await readJsonFile(inputFile);

    for (final outputFile in outputFiles) {
      final translatedArbContent = await readJsonFile(outputFile);
      final updatedArbContent = Map<String, dynamic>.from(translatedArbContent);

      final keys = List<String>.from(originalArbContent.keys);

      final keysToRemove = translatedArbContent.keys
          .where((key) =>
              !originalArbContent.containsKey(key) && !key.startsWith("@"))
          .toList();
      for (var key in keysToRemove) {
        updatedArbContent.remove(key);
        updatedArbContent.remove('@$key');
      }

      for (var key in keys) {
        if (!key.startsWith('@')) {
          final metaKey = '@$key';

          if (!translatedArbContent.containsKey(key)) {
            updatedArbContent[key] = originalArbContent[key];
            updatedArbContent[metaKey] = originalArbContent.containsKey(metaKey)
                ? Map<String, dynamic>.from(originalArbContent[metaKey])
                : {};

            print('Added new key to $outputFile: $key');
          }
        }
      }

      await saveJsonFile(outputFile, updatedArbContent);
      print('Synchronized and saved to $outputFile');
    }
  } catch (e) {
    print('Error synchronizing keys: $e');
  }
}

Future<void> translateAllLanguages(Translator translator, String inputFile,
    List<String> outputFiles, bool translateAll) async {
  final List<Future<void>> translations = [];

  for (final outputFile in outputFiles) {
    print(
        'Translating ${outputFile.split('.').first.split('/').last.split('_')[1].toUpperCase()}...');

    translations.add(translateArbFile(
      translator,
      inputFile,
      outputFile,
      outputFile.split('.').first.split('/').last.split('_')[1].toUpperCase(),
      translateAll: translateAll,
    ));
  }

  await Future.wait(translations);
  print('Translation completed');
}

Future<void> watchForChanges(
    Translator translator, String inputFile, List<String> outputFiles) async {
  print('Watching for changes...');
  final watcher = FileWatcher(inputFile);

  Map<String, dynamic> previousContent = await readJsonFile(inputFile);

  await for (final event in watcher.events) {
    if (event.type == ChangeType.MODIFY) {
      print('Detected changes in $inputFile, translating...');

      final currentContent = await readJsonFile(inputFile);
      final changedKeys = getChangedKeys(previousContent, currentContent);

      await synchronizeKeys(inputFile, outputFiles);
      await translateChangedKeys(
          translator, inputFile, outputFiles, changedKeys);

      previousContent = currentContent;
      print('Translation of changed keys completed');
    }
  }
}

Set<String> getChangedKeys(
    Map<String, dynamic> oldContent, Map<String, dynamic> newContent) {
  Set<String> changedKeys = {};

  for (var key in newContent.keys) {
    if (!key.startsWith('@') &&
        (!oldContent.containsKey(key) || oldContent[key] != newContent[key])) {
      changedKeys.add(key);
    }
  }

  return changedKeys;
}

Future<void> translateChangedKeys(Translator translator, String inputFile,
    List<String> outputFiles, Set<String> changedKeys) async {
  final List<Future<void>> translations = [];

  for (final outputFile in outputFiles) {
    print(
        'Translating changed keys for ${outputFile.split('.').first.split('/').last.split('_')[1].toUpperCase()}...');

    translations.add(translateArbFilePartial(
      translator,
      inputFile,
      outputFile,
      outputFile.split('.').first.split('/').last.split('_')[1].toUpperCase(),
      changedKeys,
    ));
  }

  await Future.wait(translations);
}

Future<void> translateArbFilePartial(
    Translator translator,
    String inputFile,
    String outputFile,
    String targetLanguage,
    Set<String> keysToTranslate) async {
  print(
      'Starting partial translation for $outputFile (Target language: $targetLanguage)');

  final pool = Pool(5);

  try {
    final originalArbContent = await readJsonFile(inputFile);
    final translatedArbContent = await readJsonFile(outputFile);
    final updatedArbContent = Map<String, dynamic>.from(translatedArbContent);

    final List<Future<void>> translationFutures = [];

    for (var key in keysToTranslate) {
      if (!originalArbContent.containsKey(key)) continue;

      final metaKey = '@$key';
      final isManualTranslation = originalArbContent.containsKey(metaKey) &&
          originalArbContent[metaKey][manualTranslationKey] == true;

      if (isManualTranslation) {
        print(
            "Manual translation key found in original file: $key, skipping translation.");
        updatedArbContent[key] = originalArbContent[key];
        updatedArbContent[metaKey] = originalArbContent[metaKey];
        continue;
      }

      if (containsPlaceholders(originalArbContent[key])) {
        translationFutures.add(pool.withResource(() async {
          final translatedText = await translateTextWithPlaceholders(
              translator, originalArbContent[key], targetLanguage);
          updatedArbContent[key] = translatedText;

          if (!updatedArbContent.containsKey(metaKey)) {
            updatedArbContent[metaKey] = {};
          }
        }));
      } else if (containsKorean(originalArbContent[key])) {
        translationFutures.add(pool.withResource(() async {
          final translatedText = await translateText(
              translator, originalArbContent[key], targetLanguage);
          if (isCorrectLanguage(translatedText, targetLanguage)) {
            updatedArbContent[key] = translatedText;

            if (!updatedArbContent.containsKey(metaKey)) {
              updatedArbContent[metaKey] = {};
            }
          } else {
            print(
                'Warning: Incorrect language detected for key: $key. Skipping.');
          }
        }));
      } else {
        updatedArbContent[key] = originalArbContent[key];
        print('Skipping non-Korean text for key: $key');
      }
    }

    await Future.wait(translationFutures);

    // 변경된 내용을 파일에 저장
    await saveJsonFile(outputFile, updatedArbContent);

    print('$outputFile partial translation completed and saved');
  } catch (e) {
    print('Error occurred while translating $outputFile: $e');
  }
}

Future<void> translateArbFile(Translator translator, String inputFile,
    String outputFile, String targetLanguage,
    {bool translateAll = false}) async {
  print(
      'Starting translation for $outputFile (Target language: $targetLanguage)');

  final pool = Pool(5);

  try {
    final originalArbContent = await readJsonFile(inputFile);
    final translatedArbContent = await readJsonFile(outputFile);
    final updatedArbContent = Map<String, dynamic>.from(translatedArbContent);
    final keys = List<String>.from(originalArbContent.keys);

    final List<Future<void>> translationFutures = [];

    for (var key in keys) {
      if (!key.startsWith('@')) {
        if (!isValidKey(key)) {
          print(
              "Warning: Key '$key' does not match naming rules and will be ignored.");
          continue;
        }

        final metaKey = '@$key';
        final isManualTranslation = originalArbContent.containsKey(metaKey) &&
            originalArbContent[metaKey][manualTranslationKey] == true;

        if (isManualTranslation) {
          print(
              "Manual translation key found in original file: $key, skipping translation.");
          updatedArbContent[key] =
              translatedArbContent[key] ?? originalArbContent[key];
          updatedArbContent[metaKey] = originalArbContent[metaKey];
          continue;
        }

        if (translateAll ||
            !translatedArbContent.containsKey(key) ||
            translatedArbContent[key] == originalArbContent[key] ||
            translatedArbContent[key].isEmpty ||
            containsKoreanOrEmpty(translatedArbContent[key])) {
          translationFutures.add(pool.withResource(() async {
            final translatedText = await translateText(
                translator, originalArbContent[key], targetLanguage);
            if (!containsKoreanOrEmpty(translatedText) &&
                isCorrectLanguage(translatedText, targetLanguage)) {
              updatedArbContent[key] = translatedText;
            } else {
              print(
                  'Warning: Incorrect translation or contains Korean for key: $key. Using original text.');
              updatedArbContent[key] = originalArbContent[key];
            }

            if (!updatedArbContent.containsKey(metaKey)) {
              updatedArbContent[metaKey] = {};
            }
          }));
        } else {
          print('Skipping translation for key: $key (Already translated)');
        }
      }
    }

    await Future.wait(translationFutures);

    // 번역된 내용 저장 전 최종 확인
    for (var key in updatedArbContent.keys) {
      if (!key.startsWith('@') &&
          containsKoreanOrEmpty(updatedArbContent[key])) {
        print(
            'Warning: Korean text found in translated content for key: $key. Attempting re-translation.');
        final retranslatedText = await translateText(
            translator, originalArbContent[key], targetLanguage);
        if (!containsKoreanOrEmpty(retranslatedText) &&
            isCorrectLanguage(retranslatedText, targetLanguage)) {
          updatedArbContent[key] = retranslatedText;
        } else {
          print('Failed to re-translate. Using original text for key: $key');
          updatedArbContent[key] = originalArbContent[key];
        }
      }
    }

    await saveJsonFile(outputFile, updatedArbContent);
    print('$outputFile translation completed and saved');
  } catch (e) {
    print('Error occurred while translating $outputFile: $e');
  }
}

Future<void> saveJsonFile(String path, Map<String, dynamic> content) async {
  try {
    final file = File(path);
    const encoder = JsonEncoder.withIndent('  ');
    final formattedJson = encoder.convert(content);

    // 저장 전 최종 확인
    if (path.contains('_en.arb') && containsKoreanOrEmpty(formattedJson)) {
      print(
          'Warning: Korean text found in English translation file. Please check the content.');
    }

    await file.writeAsString(formattedJson);
    print('File saved: $path');
  } catch (e) {
    print('Error saving file $path: $e');
  }
}

Future<Map<String, dynamic>> readJsonFile(String path) async {
  try {
    final file = File(path);

    if (await file.exists()) {
      final contents = await file.readAsString();

      if (contents.isNotEmpty) {
        return json.decode(contents);
      }
    }
  } catch (e) {
    print('Error reading $path: $e');
  }

  return <String, dynamic>{};
}

bool isValidKey(String key) {
  final validKeyPattern = RegExp(r'^[a-zA-Z0-9_]+$');
  return validKeyPattern.hasMatch(key);
}

bool containsKorean(String text) {
  return koreanRegex.hasMatch(text);
}

bool containsPlaceholders(String text) {
  return text.contains(RegExp(r'\{.*?\}'));
}

bool containsKoreanOrEmpty(String text) {
  if (text.isEmpty) return true;
  return koreanRegex.hasMatch(text);
}

Future<String> translateText(
    Translator translator, String text, String targetLang) async {
  print('Translating: "$text" to $targetLang');
  int attempts = 0;
  const maxAttempts = 3;

  while (attempts < maxAttempts) {
    try {
      final translation =
          await translator.translateTextSingular(text, targetLang);
      print('Translated: "$text" -> "${translation.text}"');

      if (!containsKoreanOrEmpty(translation.text)) {
        await Future.delayed(const Duration(milliseconds: 500));
        return translation.text;
      } else {
        print(
            'Warning: Translation still contains Korean or is empty. Retrying...');
        attempts++;
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Error translating text: $e');
      attempts++;
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  print(
      'Failed to translate after $maxAttempts attempts. Using original text.');
  return text; // 여러 번의 시도 후에도 실패하면 원본 텍스트 반환
}

Future<String> translateTextWithPlaceholders(
    Translator translator, String text, String targetLang) async {
  final placeholders =
      RegExp(r'\{[^}]+\}').allMatches(text).map((m) => m.group(0)!).toList();
  final placeholderMap = Map.fromIterables(
      placeholders.map((p) => '__PH${placeholders.indexOf(p)}__'),
      placeholders);

  String tempText = text;
  placeholderMap.forEach((key, value) {
    tempText = tempText.replaceAll(value, key);
  });

  final translatedTempText =
      await translateText(translator, tempText, targetLang);

  String finalText = translatedTempText;
  placeholderMap.forEach((key, value) {
    finalText = finalText.replaceAll(key, value);
  });

  return finalText;
}

bool isCorrectLanguage(String text, String targetLanguage) {
  final languageRegexMap = {
    'EN': RegExp(r'^[a-zA-Z0-9\s\p{P}]+$', unicode: true),
    'JA': RegExp(r'[\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Han}]+',
        unicode: true),
    'ZH': RegExp(r'[\p{Script=Han}]+', unicode: true),
  };

  final textWithoutPlaceholders = text.replaceAll(RegExp(r'\{[^}]+\}'), '');

  final regex = languageRegexMap[targetLanguage];
  if (regex == null) {
    print('Warning: No regex defined for language $targetLanguage');
    return true;
  }
  return regex.hasMatch(textWithoutPlaceholders);
}
