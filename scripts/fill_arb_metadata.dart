import 'dart:convert';
import 'dart:io';

/// Fills missing ARB metadata entries ("@key") with a default description.
///
/// Targets ARB files commonly used in this repo:
/// - picnic_lib/lib/l10n/*.arb
/// - picnic_app/lib/l10n/*.arb
/// - ttja_app/lib/l10n/*.arb
///
/// Usage:
///   dart scripts/fill_arb_metadata.dart
Future<void> main() async {
  final repoRoot = Directory.current.path;
  final targets = <String>[
    'picnic_lib/lib/l10n',
    'picnic_app/lib/l10n',
    'ttja_app/lib/l10n',
  ].map((p) => Directory('$repoRoot/$p')).where((d) => d.existsSync()).toList();

  int filesProcessed = 0;
  int totalAdded = 0;

  for (final dir in targets) {
    for (final entity in dir.listSync(recursive: false)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.arb')) continue;

      final added = _processArbFile(entity);
      if (added != null) {
        filesProcessed++;
        totalAdded += added;
      }
    }
  }

  stdout.writeln(
    'ARB metadata fill complete. Files processed: ' +
        filesProcessed.toString() +
        ', metadata entries added: ' +
        totalAdded.toString(),
  );
}

int? _processArbFile(File file) {
  try {
    final content = file.readAsStringSync();
    final decodedDynamic = json.decode(content);
    if (decodedDynamic is! Map<String, dynamic>) {
      stderr.writeln('Skip (not a JSON object): ' + file.path);
      return null;
    }

    // Use a LinkedHashMap to preserve decode order
    final Map<String, dynamic> original = Map<String, dynamic>.from(
      decodedDynamic,
    );

    int addedCount = 0;

    // Build an ordered map: keep original order, and ensure every normal key has '@key'
    final Map<String, dynamic> out = <String, dynamic>{};
    final Set<String> insertedMeta = <String>{};

    void addDefaultMetaFor(String key) {
      final metaKey = '@' + key;
      out[metaKey] = <String, dynamic>{
        'description': 'Auto-generated metadata for key \'' + key + '\'.',
      };
      insertedMeta.add(metaKey);
      addedCount++;
    }

    for (final entry in original.entries) {
      final key = entry.key;
      final value = entry.value;

      if (!key.startsWith('@')) {
        // Normal resource or '@@' key
        out[key] = value;

        if (key != '@@locale') {
          final metaKey = '@' + key;
          if (original.containsKey(metaKey)) {
            // Place the existing metadata right after the normal key
            out[metaKey] = original[metaKey];
            insertedMeta.add(metaKey);
          } else {
            addDefaultMetaFor(key);
          }
        }
      } else {
        // Metadata keys will be inserted when we encounter their base key above.
        // However, in some ARBs metadata may appear before the base key.
        // If we haven't inserted it yet and the base key was already processed, keep it.
        final base = key.substring(1);
        if (out.containsKey(base) && !insertedMeta.contains(key)) {
          out[key] = value;
          insertedMeta.add(key);
        }
      }
    }

    // It's possible some metadata appeared first and its base key never existed (edge case).
    // Keep any remaining metadata entries that were not inserted to avoid data loss.
    for (final entry in original.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key.startsWith('@') && !insertedMeta.contains(key)) {
        out[key] = value;
        insertedMeta.add(key);
      }
    }

    // Write back with 2-space indentation
    final encoded = const JsonEncoder.withIndent('  ').convert(out);
    file.writeAsStringSync(encoded + '\n');

    stdout.writeln(
      'Updated: ' + file.path + ' (+' + addedCount.toString() + ' @metadata)',
    );
    return addedCount;
  } catch (e) {
    stderr.writeln('Error processing ' + file.path + ': ' + e.toString());
    return null;
  }
}
