import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:picnic_app/util/deepl_translate_service.dart';
import 'package:pool/pool.dart';
import 'package:watcher/watcher.dart';

// Constants
const String deeplApiKey = 'ef2715c3-89d7-4b1b-a95b-e1fd3b7d734e:fx';
const String manualTranslationKey = 'manualTranslation';
const bool kDebugMode = !bool.fromEnvironment('dart.vm.product');

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('all',
        abbr: 'a', defaultsTo: false, help: 'Retranslate all strings')
    ..addFlag('watch', abbr: 'w', defaultsTo: false, help: 'Watch for changes');

  final args = parser.parse(arguments);
  final retranslateAll = args['all'] as bool;
  final watch = args['watch'] as bool;

  try {
    final translationService = DeepLTranslationService(
      apiKey: deeplApiKey,
      debugMode: kDebugMode,
    );

    if (kDebugMode) print('Starting translation process...');
    if (kDebugMode) print('API Key: $deeplApiKey');

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

    if (retranslateAll) {
      if (kDebugMode) print('Retranslating all languages...');
      await translateAllLanguages(translationService, inputFile, outputFiles);
    } else {
      if (kDebugMode) print('Marking languages for manual translation...');
      for (final outputFile in outputFiles) {
        await markForManualTranslation(
            translationService, inputFile, outputFile);
      }
      if (kDebugMode) print('All languages processed for manual translation.');
    }

    if (watch) {
      if (kDebugMode) print('Watching for changes...');
      await watchForChanges(translationService, inputFile, outputFiles);
    }
  } catch (e, s) {
    if (kDebugMode) print('Error occurred during translation process: $e');
    if (kDebugMode) print('Stack trace:\n$s');
  }
}

Future<void> translateAllLanguages(DeepLTranslationService translationService,
    String inputFile, List<String> outputFiles) async {
  for (final outputFile in outputFiles) {
    final targetLanguage =
        outputFile.split('.').first.split('/').last.split('_')[1].toUpperCase();
    if (kDebugMode) print('Translating to $targetLanguage...');
    await translateArbFile(
        translationService, inputFile, outputFile, targetLanguage,
        retranslateAll: true);
  }
  if (kDebugMode) print('All languages translated.');
}

Future<void> translateArbFile(DeepLTranslationService translationService,
    String inputFile, String outputFile, String targetLanguage,
    {bool retranslateAll = false}) async {
  if (kDebugMode) {
    print(
        'Starting translation for $outputFile (Target language: $targetLanguage)');
  }

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
          if (kDebugMode) {
            print(
                "Warning: Key '$key' does not match naming rules and will be ignored.");
          }
          continue;
        }

        final metaKey = '@$key';
        final originalText = originalArbContent[key];
        final isManualTranslation = translatedArbContent.containsKey(metaKey) &&
            translatedArbContent[metaKey]['manualTranslation'] == true;

        if (translationService.containsPlaceholders(originalText)) {
          if (translatedArbContent.containsKey(key)) {
            updatedArbContent[key] = translatedArbContent[key];
          } else {
            updatedArbContent[key] = originalText;
          }
          updatedArbContent[metaKey] = {
            ...translatedArbContent[metaKey] ?? {},
            'manualTranslation': true,
          };
          if (kDebugMode) print('Preserved text with placeholders: $key');
        } else if (isManualTranslation && !retranslateAll) {
          updatedArbContent[key] = translatedArbContent[key];
          updatedArbContent[metaKey] = translatedArbContent[metaKey];
          if (kDebugMode) print('Preserved manually translated text: $key');
        } else if (retranslateAll ||
            !translatedArbContent.containsKey(key) ||
            translatedArbContent[key] == originalText ||
            translatedArbContent[key].isEmpty ||
            translationService
                .containsKoreanOrEmpty(translatedArbContent[key])) {
          translationFutures.add(pool.withResource(() async {
            final translatedText = await translationService.translateText(
                originalText, 'ko', targetLanguage);
            if (!translationService.containsKoreanOrEmpty(translatedText) &&
                translationService.isCorrectLanguage(
                    translatedText, targetLanguage)) {
              updatedArbContent[key] = translatedText;
              updatedArbContent[metaKey] = {
                ...updatedArbContent[metaKey] ?? {},
                'manualTranslation': false,
              };
            } else {
              if (kDebugMode) {
                print(
                    'Warning: Incorrect translation for key: $key. Using original text.');
              }
              updatedArbContent[key] = originalText;
              updatedArbContent[metaKey] = {
                ...updatedArbContent[metaKey] ?? {},
                'manualTranslation': true,
              };
            }
          }));
        } else {
          updatedArbContent[key] = translatedArbContent[key];
          updatedArbContent[metaKey] = translatedArbContent[metaKey];
          if (kDebugMode) print('Kept existing translation for key: $key');
        }
      }
    }

    await Future.wait(translationFutures);
    await saveJsonFile(outputFile, updatedArbContent);
    if (kDebugMode) print('$outputFile translation completed and saved');
  } catch (e) {
    if (kDebugMode) print('Error occurred while translating $outputFile: $e');
  }
}

Future<void> watchForChanges(DeepLTranslationService translationService,
    String inputFile, List<String> outputFiles) async {
  if (kDebugMode) print('Watching for changes...');
  final watcher = FileWatcher(inputFile);

  await for (final event in watcher.events) {
    if (event.type == ChangeType.MODIFY) {
      if (kDebugMode) print('Detected changes in $inputFile, updating...');
      for (final outputFile in outputFiles) {
        final targetLanguage = outputFile
            .split('.')
            .first
            .split('/')
            .last
            .split('_')[1]
            .toUpperCase();
        await translateArbFile(
            translationService, inputFile, outputFile, targetLanguage);
      }
      if (kDebugMode) print('Updates completed');
    }
  }
}

Future<void> sortAndUpdateArbFile(String filePath) async {
  final file = File(filePath);

  if (!await file.exists()) {
    if (kDebugMode) print('File not found: $filePath');
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
    if (kDebugMode) print('File sorted, updated, and saved to $filePath');
  } catch (e) {
    if (kDebugMode) print('Error sorting and updating file $filePath: $e');
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

            if (kDebugMode) print('Added new key to $outputFile: $key');
          }
        }
      }

      await saveJsonFile(outputFile, updatedArbContent);
      if (kDebugMode) print('Synchronized and saved to $outputFile');
    }
  } catch (e) {
    if (kDebugMode) print('Error synchronizing keys: $e');
  }
}

Future<void> markForManualTranslation(
    DeepLTranslationService translationService,
    String inputFile,
    String outputFile) async {
  if (kDebugMode) {
    print('Starting manual translation marking process for $outputFile');
  }

  try {
    final originalArbContent = await readJsonFile(inputFile);
    final existingTranslations = await readJsonFile(outputFile);
    final updatedArbContent = Map<String, dynamic>.from(existingTranslations);
    final keys = List<String>.from(originalArbContent.keys);

    for (var key in keys) {
      if (!key.startsWith('@')) {
        if (!isValidKey(key)) {
          if (kDebugMode) {
            print(
                "Warning: Key '$key' does not match naming rules and will be ignored.");
          }
          continue;
        }

        final metaKey = '@$key';
        final originalText = originalArbContent[key];

        if (translationService.containsPlaceholders(originalText)) {
          updatedArbContent[key] = existingTranslations.containsKey(key)
              ? existingTranslations[key]
              : originalText;
          updatedArbContent[metaKey] = {
            ...existingTranslations[metaKey] ?? {},
            'manualTranslation': true,
          };
          if (kDebugMode) print('Preserved text with placeholders: $key');
        } else if (!existingTranslations.containsKey(key) ||
            !existingTranslations.containsKey(metaKey) ||
            existingTranslations[metaKey]['manualTranslation'] != true) {
          updatedArbContent[key] = originalText;
          updatedArbContent[metaKey] = {
            ...updatedArbContent[metaKey] ?? {},
            'manualTranslation': true,
          };
          if (kDebugMode) {
            print(
                'Set to original text and marked for manual translation: $key');
          }
        } else {
          updatedArbContent[key] = existingTranslations[key];
          updatedArbContent[metaKey] = existingTranslations[metaKey];
          if (kDebugMode) print('Preserved existing translation: $key');
        }
      }
    }

    updatedArbContent.removeWhere((key, value) =>
        !originalArbContent.containsKey(key) && !key.startsWith('@'));

    await saveJsonFile(outputFile, updatedArbContent);
    if (kDebugMode) {
      print('$outputFile manual translation marking completed and saved');
    }
  } catch (e) {
    if (kDebugMode) {
      print(
          'Error occurred while marking for manual translation in $outputFile: $e');
    }
  }
}

// saveJsonFile 함수도 수정
Future<void> saveJsonFile(String path, Map<String, dynamic> content,
    {DeepLTranslationService? translationService}) async {
  try {
    final file = File(path);
    const encoder = JsonEncoder.withIndent('  ');
    final formattedJson = encoder.convert(content);

    if (path.contains('_en.arb') &&
        translationService?.containsKoreanOrEmpty(formattedJson) == true) {
      if (kDebugMode) {
        print(
            'Warning: Korean text found in English translation file. Please check the content.');
      }
    }

    await file.writeAsString(formattedJson);
    if (kDebugMode) print('File saved: $path');
  } catch (e) {
    if (kDebugMode) print('Error saving file $path: $e');
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
    if (kDebugMode) print('Error reading $path: $e');
  }

  return <String, dynamic>{};
}

bool isValidKey(String key) {
  final validKeyPattern = RegExp(r'^[a-zA-Z0-9_]+$');
  return validKeyPattern.hasMatch(key);
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

Future<void> translateChangedKeys(DeepLTranslationService translationService,
    String inputFile, List<String> outputFiles, Set<String> changedKeys) async {
  final List<Future<void>> translations = [];

  for (final outputFile in outputFiles) {
    if (kDebugMode) {
      print(
          'Translating changed keys for ${outputFile.split('.').first.split('/').last.split('_')[1].toUpperCase()}...');
    }

    translations.add(translateArbFilePartial(
      translationService,
      inputFile,
      outputFile,
      outputFile.split('.').first.split('/').last.split('_')[1].toUpperCase(),
      changedKeys,
    ));
  }

  await Future.wait(translations);
}

Future<void> translateArbFilePartial(
    DeepLTranslationService translationService,
    String inputFile,
    String outputFile,
    String targetLanguage,
    Set<String> keysToTranslate) async {
  if (kDebugMode) {
    print(
        'Starting partial translation for $outputFile (Target language: $targetLanguage)');
  }

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
        if (kDebugMode) {
          print(
              "Manual translation key found in original file: $key, skipping translation.");
        }
        updatedArbContent[key] = originalArbContent[key];
        updatedArbContent[metaKey] = originalArbContent[metaKey];
        continue;
      }

      if (translationService.containsPlaceholders(originalArbContent[key])) {
        translationFutures.add(pool.withResource(() async {
          final translatedText =
              await translationService.translateTextWithPlaceholders(
                  originalArbContent[key], targetLanguage);
          updatedArbContent[key] = translatedText;

          if (!updatedArbContent.containsKey(metaKey)) {
            updatedArbContent[metaKey] = {};
          }
        }));
      } else if (translationService.containsKorean(originalArbContent[key])) {
        translationFutures.add(pool.withResource(() async {
          final translatedText = await translationService.translateText(
              originalArbContent[key], 'ko', targetLanguage);
          if (translationService.isCorrectLanguage(
              translatedText, targetLanguage)) {
            updatedArbContent[key] = translatedText;

            if (!updatedArbContent.containsKey(metaKey)) {
              updatedArbContent[metaKey] = {};
            }
          } else {
            if (kDebugMode) {
              print(
                  'Warning: Incorrect language detected for key: $key. Skipping.');
            }
          }
        }));
      } else {
        updatedArbContent[key] = originalArbContent[key];
        if (kDebugMode) print('Skipping non-Korean text for key: $key');
      }
    }

    await Future.wait(translationFutures);
    await saveJsonFile(outputFile, updatedArbContent);

    if (kDebugMode) {
      print('$outputFile partial translation completed and saved');
    }
  } catch (e) {
    if (kDebugMode) print('Error occurred while translating $outputFile: $e');
  }
}
