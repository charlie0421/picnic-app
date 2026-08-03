import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/controllers/admin_gdpr_reset_controller.dart';

void main() {
  group('AdminGdprResetController', () {
    test('returns success when the consent reset succeeds', () async {
      var logCalls = 0;
      final controller = AdminGdprResetController(
        resetAndReinitialize: () async => true,
        logCurrentState: () async => logCalls++,
      );

      final result = await controller.reset();

      expect(result, AdminGdprResetResult.success);
      expect(logCalls, 2);
      expect(controller.isRunning, isFalse);
    });

    test('returns failure when the consent reset returns false', () async {
      final controller = AdminGdprResetController(
        resetAndReinitialize: () async => false,
        logCurrentState: () async {},
      );

      final result = await controller.reset();

      expect(result, AdminGdprResetResult.failure);
      expect(controller.isRunning, isFalse);
    });

    test('returns failure when the consent reset throws', () async {
      final controller = AdminGdprResetController(
        resetAndReinitialize: () async => throw StateError('platform error'),
        logCurrentState: () async {},
      );

      final result = await controller.reset();

      expect(result, AdminGdprResetResult.failure);
      expect(controller.isRunning, isFalse);
    });

    test('continues when best-effort state logging fails', () async {
      final controller = AdminGdprResetController(
        resetAndReinitialize: () async => true,
        logCurrentState: () async => throw StateError('logging error'),
      );

      final result = await controller.reset();

      expect(result, AdminGdprResetResult.success);
    });

    test('suppresses a duplicate reset while one is in progress', () async {
      final resetCompleter = Completer<bool>();
      var resetCalls = 0;
      final controller = AdminGdprResetController(
        resetAndReinitialize: () {
          resetCalls++;
          return resetCompleter.future;
        },
        logCurrentState: () async {},
      );

      final firstReset = controller.reset();
      final duplicateReset = await controller.reset();

      expect(controller.isRunning, isTrue);
      expect(duplicateReset, AdminGdprResetResult.inProgress);
      expect(resetCalls, 1);

      resetCompleter.complete(true);

      expect(await firstReset, AdminGdprResetResult.success);
      expect(controller.isRunning, isFalse);
    });
  });
}
