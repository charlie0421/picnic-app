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

  test('시간 안에 끝나지 않는 시작 작업은 fallback 값으로 계속 진행한다', () async {
    final result = await waitForStartupValue<bool>(
      Completer<bool>().future,
      timeout: const Duration(milliseconds: 10),
      fallback: false,
      onTimeout: () {},
    );

    expect(result, isFalse);
  });

  test('시간 안에 끝난 시작 작업은 실제 결과를 반환한다', () async {
    final result = await waitForStartupValue<bool>(
      Future.value(true),
      timeout: const Duration(seconds: 1),
      fallback: false,
      onTimeout: () {},
    );

    expect(result, isTrue);
  });
}
