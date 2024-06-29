import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:crypto/crypto.dart';
import 'package:deepl_dart/deepl_dart.dart';
import 'package:watcher/watcher.dart';

// Constants
const String deeplApiKey = 'ef2715c3-89d7-4b1b-a95b-e1fd3b7d734e:fx';
const String timestampKey = 'translationTimestamp';
const String manualTranslationKey = 'manualTranslation';
final RegExp koreanRegex = RegExp(r'[가-힣]+');

// Entry point
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
    print('apiKey: $deeplApiKey');
    print('Translating...');

    const String inputFile = 'lib/l10n/intl_ko.arb';
    final List<String> outputFiles = [
      'lib/l10n/intl_en.arb',
      'lib/l10n/intl_ja.arb',
      'lib/l10n/intl_zh_CN.arb'
    ];

    if (!watch) {
      await addTimestampToArbFile(inputFile);
    }

    await synchronizeKeys(inputFile, outputFiles, modifyTimestamps: !watch);

    if (translateAll || !watch) {
      await translateAllLanguages(
          translator, inputFile, outputFiles, translateAll);
    }

    if (watch) {
      await watchForChanges(translator, inputFile, outputFiles);
    }
  } catch (e, s) {
    print('Error: $e');
    print('Stack trace:\n$s');
  }
}

// Translate all languages
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

// Watch for changes
Future<void> watchForChanges(
    Translator translator, String inputFile, List<String> outputFiles) async {
  print('Watching for changes...');
  final watcher = FileWatcher(inputFile);

  await for (final event in watcher.events) {
    if (event.type == ChangeType.MODIFY) {
      print('Detected changes in $inputFile, translating...');

      await synchronizeKeys(inputFile, outputFiles, modifyTimestamps: false);
      await translateAllLanguages(translator, inputFile, outputFiles, true);

      print('Translation completed');
    }
  }
}

// Add timestamp to ARB file
Future<void> addTimestampToArbFile(String filePath) async {
  final file = File(filePath);

  if (!await file.exists()) {
    print('File not found: $filePath');
    return;
  }

  try {
    final contents = await file.readAsString();
    final arbContent = json.decode(contents) as Map<String, dynamic>;

    final currentTimestamp = DateTime.now().toIso8601String();
    final updatedArbContent = <String, dynamic>{};

    for (var key in arbContent.keys) {
      updatedArbContent[key] = arbContent[key];

      if (!key.startsWith('@')) {
        final metaKey = '@$key';

        if (!arbContent.containsKey(metaKey)) {
          updatedArbContent[metaKey] = {};
        } else {
          updatedArbContent[metaKey] = arbContent[metaKey];
        }

        updatedArbContent[metaKey][timestampKey] = currentTimestamp;
        print('Added timestamp to key: $key');
      }
    }

    final sortedContent = sortKeys(updatedArbContent);
    sortedContent.remove("@@locale");

    const encoder = JsonEncoder.withIndent('  ');
    final formattedJson = encoder.convert({
      "@@locale": arbContent["@@locale"],
      ...sortedContent,
    });

    await file.writeAsString(formattedJson);
    print('Timestamps added and saved to $filePath');
  } catch (e) {
    print('Error adding timestamp to $filePath: $e');
  }
}

// Synchronize keys
Future<void> synchronizeKeys(String inputFile, List<String> outputFiles,
    {bool modifyTimestamps = true}) async {
  try {
    final originalArbContent = await readJsonFile(inputFile);

    for (final outputFile in outputFiles) {
      final translatedArbContent = await readJsonFile(outputFile);
      final updatedArbContent = Map<String, dynamic>.from(translatedArbContent);

      final keys = List<String>.from(originalArbContent.keys);
      final currentTimestamp = DateTime.now().toIso8601String();

      for (var key in keys) {
        if (!key.startsWith('@')) {
          final metaKey = '@$key';

          if (!translatedArbContent.containsKey(key)) {
            updatedArbContent[key] = originalArbContent[key];
            updatedArbContent[metaKey] = originalArbContent.containsKey(metaKey)
                ? Map<String, dynamic>.from(originalArbContent[metaKey])
                : {};

            if (modifyTimestamps) {
              updatedArbContent[metaKey][timestampKey] = currentTimestamp;
            }

            print('Added new key to $outputFile: $key');
          }
        }
      }

      final sortedContent = sortKeys(updatedArbContent);
      sortedContent.remove("@@locale");

      const encoder = JsonEncoder.withIndent('  ');
      final formattedJson = encoder.convert({
        "@@locale": outputFile.split('_').last.split('.').first.toLowerCase(),
        ...sortedContent,
      });

      await File(outputFile).writeAsString(formattedJson);
      print('Synchronized and saved to $outputFile');
    }
  } catch (e) {
    print('Error synchronizing keys: $e');
  }
}

// ARB 파일 번역
Future<void> translateArbFile(Translator translator, String inputFile,
    String outputFile, String targetLanguage,
    {bool translateAll = false}) async {
  try {
    final originalArbContent = await readJsonFile(inputFile);
    final translatedArbContent = await readJsonFile(outputFile);
    final updatedArbContent = Map<String, dynamic>.from(translatedArbContent);
    final currentTimestamp = DateTime.now().toIso8601String();
    final keys = List<String>.from(originalArbContent.keys);

    for (var key in keys) {
      if (!key.startsWith('@')) {
        if (!isValidKey(key)) {
          print("경고: '$key' 키는 네이밍 규칙에 맞지 않아 무시됩니다.");
          continue;
        }

        final metaKey = '@$key';
        final hasTimestamp = originalArbContent.containsKey(metaKey) &&
            originalArbContent[metaKey][timestampKey] != null;
        final isManualTranslation = translatedArbContent.containsKey(metaKey) &&
            translatedArbContent[metaKey][manualTranslationKey] == true;

        if (isManualTranslation) {
          continue; // 수동 번역은 건너뜁니다.
        }

        if (translateAll ||
            !hasTimestamp ||
            originalArbContent[metaKey][timestampKey] !=
                translatedArbContent[metaKey][timestampKey]) {
          // {}로 둘러싸인 텍스트는 번역하지 않고 그대로 유지
          if (!originalArbContent[key].startsWith('{') &&
              !originalArbContent[key].endsWith('}')) {
            if (containsKorean(originalArbContent[key])) {
              final translatedText = await translateText(
                  translator, originalArbContent[key], targetLanguage);
              updatedArbContent[key] = translatedText;

              if (!originalArbContent.containsKey(metaKey)) {
                updatedArbContent[metaKey] = {};
              } else {
                updatedArbContent[metaKey] = originalArbContent[metaKey];
              }

              updatedArbContent[metaKey][timestampKey] = currentTimestamp;
            } else {
              updatedArbContent[key] = originalArbContent[key];

              if (originalArbContent.containsKey(metaKey)) {
                updatedArbContent[metaKey] = originalArbContent[metaKey];
              }
            }
          } else {
            updatedArbContent[key] = originalArbContent[key];

            if (translatedArbContent.containsKey(metaKey)) {
              updatedArbContent[metaKey] = translatedArbContent[metaKey];
            }
          }
        } else {
          if (translatedArbContent.containsKey(key)) {
            updatedArbContent[key] = translatedArbContent[key];
          }

          if (translatedArbContent.containsKey(metaKey)) {
            updatedArbContent[metaKey] = translatedArbContent[metaKey];
          }
        }
      } else {
        updatedArbContent[key] = originalArbContent[key];
      }
    }

    final sortedContent = sortKeys(updatedArbContent);
    sortedContent.remove("@@locale");

    const encoder = JsonEncoder.withIndent('  ');
    final formattedJson = encoder.convert({
      "@@locale": targetLanguage.toLowerCase(),
      ...sortedContent,
    });

    await File(outputFile).writeAsString(formattedJson);
    print('$outputFile 번역 완료 및 저장 완료');
  } catch (e) {
    print('$outputFile 번역 중 오류 발생: $e');
  }
}

// Helper functions
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
  final validKeyPattern = RegExp(r'^[a-z_]+$');
  return validKeyPattern.hasMatch(key);
}

bool containsKorean(String text) {
  return koreanRegex.hasMatch(text);
}

Map<String, dynamic> sortKeys(Map<String, dynamic> map) {
  final sortedKeys = map.keys.toList()
    ..sort((a, b) {
      if (a.startsWith('@') && !b.startsWith('@')) return 1;
      if (!a.startsWith('@') && b.startsWith('@')) return -1;
      return a.compareTo(b);
    });

  final sortedMap = <String, dynamic>{};

  for (var key in sortedKeys) {
    sortedMap[key] = map[key];
  }

  return sortedMap;
}

String generateUniqueMethodName(String key, String value) {
  final bytes = utf8.encode('$key$value');
  final digest = sha1.convert(bytes);
  return 'm${digest.toString().substring(0, 8)}';
}

Future<String> translateText(
    Translator translator, String text, String targetLang) async {
  final translation = await translator.translateTextSingular(text, targetLang);
  return translation.text;
}
