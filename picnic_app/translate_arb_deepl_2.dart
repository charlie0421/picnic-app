import 'dart:convert';
import 'dart:io';

const timestampKey = 'translationTimestamp';

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
    if (!key.startsWith('@')) {
      updatedArbContent[key] = arbContent[key];
      final metaKey = '@$key';
      if (!arbContent.containsKey(metaKey)) {
        updatedArbContent[metaKey] = {};
      } else {
        updatedArbContent[metaKey] = arbContent[metaKey];
      }
      updatedArbContent[metaKey][timestampKey] = currentTimestamp;
    }
  }

  final encoder = JsonEncoder.withIndent('  ');
  final formattedJson = encoder.convert(updatedArbContent);
  await file.writeAsString(formattedJson);
  print('Timestamps added and saved to $filePath');
}

void main() async {
  final filePath = './lib/l10n/intl_ko.arb';
  await addTimestampToArbFile(filePath);
}
