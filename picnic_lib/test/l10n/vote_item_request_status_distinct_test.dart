import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The vote item request UI decides a status by comparing translated strings
/// (`status == l10n.vote_item_request_status_pending`, see
/// search_result_action_button.dart and vote_item_request_models.dart), so
/// within one language these labels must all differ. Indonesian once had
/// "Menunggu" for both pending and waiting.
const _statusKeys = [
  'vote_item_request_can_apply',
  'vote_item_request_submit',
  'vote_item_request_waiting',
  'vote_item_request_status_pending',
  'vote_item_request_status_approved',
  'vote_item_request_status_rejected',
  'vote_item_request_status_in_progress',
  'vote_item_request_status_cancelled',
  'vote_item_request_status_unknown',
];

void main() {
  final arbs = Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .where((f) => RegExp(r'app_\w+\.arb$').hasMatch(f.path))
      .toList();

  test('arb files are found', () => expect(arbs, isNotEmpty));

  for (final arb in arbs) {
    test(
      'vote item request labels are distinct in ${arb.uri.pathSegments.last}',
      () {
        final strings =
            jsonDecode(arb.readAsStringSync()) as Map<String, dynamic>;
        final labels = {
          for (final key in _statusKeys)
            if (strings[key] is String) key: strings[key] as String,
        };
        final seen = <String, String>{};
        for (final MapEntry(:key, :value) in labels.entries) {
          expect(
            seen.containsKey(value),
            isFalse,
            reason: '$key and ${seen[value]} are both "$value"',
          );
          seen[value] = key;
        }
      },
    );
  }
}
