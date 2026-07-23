import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/startup_future_guard.dart';

void main() {
  test('non-critical startup work stops blocking after its deadline', () async {
    final pending = Completer<void>();
    var timedOut = false;

    await waitForNonCriticalStartup(
      pending.future,
      timeout: const Duration(milliseconds: 10),
      onTimeout: () => timedOut = true,
    );

    expect(timedOut, isTrue);
  });

  test(
    'non-critical startup work completes normally before its deadline',
    () async {
      var timedOut = false;

      await waitForNonCriticalStartup(
        Future<void>.value(),
        timeout: const Duration(seconds: 1),
        onTimeout: () => timedOut = true,
      );

      expect(timedOut, isFalse);
    },
  );
}
