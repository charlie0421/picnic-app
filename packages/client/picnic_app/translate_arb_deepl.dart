import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:crypto/crypto.dart';
import 'package:deepl_dart/deepl_dart.dart';
import 'package:watcher/watcher.dart';

const deeplApiKey = 'ef2715c3-89d7-4b1b-a95b-e1fd3b7d734e:fx';
const timestampKey = 'translationTimestamp';
const manualTranslationKey = 'manualTranslation';

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

Future<void> translateArbFile(Translator translator, String inputFile,
    String outputFile, String targetLanguage,
    {bool translateAll = false}) async {
  final originalArbContent = await readJsonFile(inputFile);
  final translatedArbContent = await readJsonFile(outputFile);

  final updatedArbContent = <String, dynamic>{};
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
        updatedArbContent[key] = translatedArbContent[key];
        updatedArbContent[metaKey] = translatedArbContent[metaKey];
      } else if (translateAll ||
          !hasTimestamp ||
          originalArbContent[metaKey][timestampKey] !=
              translatedArbContent[metaKey][timestampKey]) {
        print('Translating key: $key');
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

  updatedArbContent["@@locale"] = targetLanguage.toLowerCase();

  final encoder = JsonEncoder.withIndent('  ');
  final formattedJson = encoder.convert(updatedArbContent);
  await File(outputFile).writeAsString(formattedJson);
  print('Translation completed and saved to $outputFile');
}

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

    final inputFile = 'lib/l10n/intl_ko.arb';

    print('Translating en...');
    await translateArbFile(translator, inputFile, 'lib/l10n/intl_en.arb', 'EN',
        translateAll: translateAll);

    print('Translating ja...');
    await translateArbFile(translator, inputFile, 'lib/l10n/intl_ja.arb', 'JA',
        translateAll: translateAll);

    print('Translating zh_CN...');
    await translateArbFile(
        translator, inputFile, 'lib/l10n/intl_zh_CN.arb', 'ZH',
        translateAll: translateAll);

    print('Translation completed');

    if (watch) {
      print('Watching for changes...');
      final watcher = FileWatcher(inputFile);
      watcher.events.listen((event) async {
        if (event.type == ChangeType.MODIFY) {
          print('Detected changes in $inputFile, translating...');

          await translateArbFile(
              translator, inputFile, 'lib/l10n/intl_en.arb', 'EN',
              translateAll: translateAll);

          await translateArbFile(
              translator, inputFile, 'lib/l10n/intl_ja.arb', 'JA',
              translateAll: translateAll);

          await translateArbFile(
              translator, inputFile, 'lib/l10n/intl_zh_CN.arb', 'ZH',
              translateAll: translateAll);
        }
      });
    }
  } catch (e, s) {
    print(e);
    print(s);
  }
}
