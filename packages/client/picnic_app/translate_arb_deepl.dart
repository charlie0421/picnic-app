import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:crypto/crypto.dart';
import 'package:deepl_dart/deepl_dart.dart';
import 'package:watcher/watcher.dart';

const deeplApiKey = 'ef2715c3-89d7-4b1b-a95b-e1fd3b7d734e:fx';
const timestampKey = 'translationTimestamp';
const manualTranslationKey = 'manualTranslation';
final koreanRegex = RegExp(r'[가-힣]+');

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

Future<void> translateArbFile(Translator translator, String inputFile,
    String outputFile, String targetLanguage,
    {bool translateAll = false, bool manualTranslation = false}) async {
  final originalArbContent = await readJsonFile(inputFile);
  final translatedArbContent = await readJsonFile(outputFile);

  final updatedArbContent = Map<String, dynamic>.from(translatedArbContent);
  final currentTimestamp = DateTime.now().toIso8601String();

  final keys = List<String>.from(originalArbContent.keys);

  for (var key in keys) {
    if (!key.startsWith('@')) {
      if (!isValidKey(key)) {
        print(
            "WARNING: The '$key' key will be ignored as its name does not follow naming convention.");
        continue;
      }

      final metaKey = '@$key';
      final hasTimestamp = originalArbContent.containsKey(metaKey) &&
          originalArbContent[metaKey][timestampKey] != null;
      final isManualTranslation = translatedArbContent.containsKey(metaKey) &&
          translatedArbContent[metaKey][manualTranslationKey] == true;

      if (isManualTranslation) {
        continue; // Skip manual translations
      }

      if (translateAll ||
          !hasTimestamp ||
          originalArbContent[metaKey][timestampKey] !=
              translatedArbContent[metaKey][timestampKey]) {
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

  final encoder = JsonEncoder.withIndent('  ');
  final formattedJson = encoder.convert({
    "@@locale": targetLanguage.toLowerCase(),
    ...sortedContent,
  });
  await File(outputFile).writeAsString(formattedJson);
  print('Translation completed and saved to $outputFile');
}

Future<void> synchronizeKeys(String inputFile, List<String> outputFiles) async {
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
          updatedArbContent[metaKey][timestampKey] = currentTimestamp;
          print('Added new key to $outputFile: $key');
        }
      }
    }

    final sortedContent = sortKeys(updatedArbContent);
    sortedContent.remove("@@locale");

    final encoder = JsonEncoder.withIndent('  ');
    final formattedJson = encoder.convert({
      "@@locale": outputFile.split('_').last.split('.').first.toLowerCase(),
      ...sortedContent,
    });
    await File(outputFile).writeAsString(formattedJson);
    print('Synchronized and saved to $outputFile');
  }
}

Future<void> addTimestampToArbFile(String filePath) async {
  final file = File(filePath);
  if (!await file.exists()) {
    print('File not found: $filePath');
    return;
  }

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

  final encoder = JsonEncoder.withIndent('  ');
  final formattedJson = encoder.convert({
    "@@locale": arbContent["@@locale"],
    ...sortedContent,
  });
  await file.writeAsString(formattedJson);
  print('Timestamps added and saved to $filePath');
}

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('all',
        abbr: 'a', defaultsTo: false, help: 'Translate all strings')
    ..addFlag('watch', abbr: 'w', defaultsTo: false, help: 'Watch for changes')
    ..addFlag('manual',
        abbr: 'm', defaultsTo: false, help: 'Respect manual translations');

  final args = parser.parse(arguments);
  final translateAll = args['all'] as bool;
  final watch = args['watch'] as bool;
  final manualTranslation = args['manual'] as bool;

  try {
    final translator = Translator(authKey: deeplApiKey);
    print('apiKey: $deeplApiKey');
    print('Translating...');

    final inputFile = 'lib/l10n/intl_ko.arb';
    final outputFiles = [
      'lib/l10n/intl_en.arb',
      'lib/l10n/intl_ja.arb',
      'lib/l10n/intl_zh_CN.arb'
    ];

    await addTimestampToArbFile(inputFile);
    await synchronizeKeys(inputFile, outputFiles);

    // print('Translating en...');
    // await translateArbFile(translator, inputFile, 'lib/l10n/intl_en.arb', 'EN',
    //     translateAll: translateAll, manualTranslation: manualTranslation);
    //
    // print('Translating ja...');
    // await translateArbFile(translator, inputFile, 'lib/l10n/intl_ja.arb', 'JA',
    //     translateAll: translateAll, manualTranslation: manualTranslation);
    //
    // print('Translating zh_CN...');
    // await translateArbFile(
    //     translator, inputFile, 'lib/l10n/intl_zh_CN.arb', 'ZH',
    //     translateAll: translateAll, manualTranslation: manualTranslation);
    //
    // print('Translation completed');

    if (watch) {
      print('Watching for changes...');
      final watcher = FileWatcher(inputFile);
      watcher.events.listen((event) async {
        if (event.type == ChangeType.MODIFY) {
          print('Detected changes in $inputFile, translating...');

          await synchronizeKeys(inputFile, outputFiles);

          await translateArbFile(
              translator, inputFile, 'lib/l10n/intl_en.arb', 'EN',
              translateAll: translateAll, manualTranslation: manualTranslation);
          await translateArbFile(
              translator, inputFile, 'lib/l10n/intl_ja.arb', 'JA',
              translateAll: translateAll, manualTranslation: manualTranslation);
          await translateArbFile(
              translator, inputFile, 'lib/l10n/intl_zh_CN.arb', 'ZH',
              translateAll: translateAll, manualTranslation: manualTranslation);
        }
      });
    }
  } catch (e, s) {
    print(e);
    print(s);
  }
}
