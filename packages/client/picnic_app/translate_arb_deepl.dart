import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:deepl_dart/deepl_dart.dart';
import 'package:pool/pool.dart';
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
    print('Starting translation process...');
    print('API Key: $deeplApiKey');

    const String inputFile = 'lib/l10n/intl_ko.arb';
    final List<String> outputFiles = [
      'lib/l10n/intl_en.arb',
      'lib/l10n/intl_ja.arb',
      'lib/l10n/intl_zh.arb'
    ];

    if (!watch) {
      await addTimestampToArbFile(inputFile);
    }

    await synchronizeKeys(inputFile, outputFiles, modifyTimestamps: !watch);

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

      // Remove keys from target ARB file that don't exist in the original ARB file
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

// Translate ARB file
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
    final currentTimestamp = DateTime.now().toIso8601String();
    final keys = List<String>.from(originalArbContent.keys);

    final Map<String, String> translationCache = {};

    // Remove keys from target ARB file that don't exist in the original ARB file
    final keysToRemove = translatedArbContent.keys
        .where((key) =>
            !originalArbContent.containsKey(key) && !key.startsWith("@"))
        .toList();
    for (var key in keysToRemove) {
      updatedArbContent.remove(key);
      updatedArbContent.remove('@$key');
    }

    final List<Future<void>> translationFutures = [];

    for (var key in keys) {
      if (!key.startsWith('@')) {
        if (!isValidKey(key)) {
          print(
              "Warning: Key '$key' does not match naming rules and will be ignored.");
          continue;
        }

        final metaKey = '@$key';
        final hasTimestamp = originalArbContent.containsKey(metaKey) &&
            originalArbContent[metaKey][timestampKey] != null;
        final isManualTranslation = translatedArbContent.containsKey(metaKey) &&
            translatedArbContent[metaKey][manualTranslationKey] == true;

        if (isManualTranslation) {
          print(
              "Manual translation key found: $targetLanguage $key, skipping translation.");
          continue;
        }

        final originalTimestamp = originalArbContent[metaKey]?[timestampKey];
        final translatedTimestamp =
            translatedArbContent[metaKey]?[timestampKey];

        if (translateAll) {
          print('Translating key: $key (Reason: translateAll is true)');
        } else if (!hasTimestamp) {
          print('Translating key: $key (Reason: no timestamp)');
        } else if (originalTimestamp != translatedTimestamp) {
          print('Translating key: $key (Reason: timestamps do not match)');
          print('  Original timestamp: $originalTimestamp');
          print('  Translated timestamp: $translatedTimestamp');
        } else {
          print(
              'Skipping translation for key: $key (Reason: timestamps match)');
          continue;
        }

        if (!originalArbContent[key].contains('{') &&
            !originalArbContent[key].contains('}')) {
          if (containsKorean(originalArbContent[key])) {
            if (!translationCache.containsKey(originalArbContent[key])) {
              translationFutures.add(pool.withResource(() async {
                final translatedText = await translateText(
                    translator, originalArbContent[key], targetLanguage);
                translationCache[originalArbContent[key]] = translatedText;
                updatedArbContent[key] = translatedText;

                if (!updatedArbContent.containsKey(metaKey)) {
                  updatedArbContent[metaKey] = {};
                }
                updatedArbContent[metaKey][timestampKey] = currentTimestamp;
              }));
            } else {
              updatedArbContent[key] =
                  translationCache[originalArbContent[key]];
              print('Using cached translation for key: $key');
            }
          } else {
            updatedArbContent[key] = originalArbContent[key];
            print('Skipping non-Korean text for key: $key');
          }
        } else {
          updatedArbContent[key] = originalArbContent[key];
          print('Skipping text with placeholders for key: $key');
        }
      } else {
        updatedArbContent[key] = originalArbContent[key];
      }
    }

    await Future.wait(translationFutures);

    final sortedContent = sortKeys(updatedArbContent);
    sortedContent.remove("@@locale");

    const encoder = JsonEncoder.withIndent('  ');
    final formattedJson = encoder.convert({
      "@@locale": targetLanguage.toLowerCase(),
      ...sortedContent,
    });

    await File(outputFile).writeAsString(formattedJson);
    print('$outputFile translation completed and saved');
  } catch (e) {
    print('Error occurred while translating $outputFile: $e');
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
  final validKeyPattern = RegExp(r'^[a-zA-Z0-9_]+$');
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

Future<String> translateText(
    Translator translator, String text, String targetLang) async {
  print('Translating: "$text" to $targetLang');
  final translation = await translator.translateTextSingular(text, targetLang);
  print('Translated: "$text" -> "${translation.text}"');
  await Future.delayed(const Duration(seconds: 1));
  return translation.text;
}
