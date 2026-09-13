import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/update_service.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';

void main() {
  const upToDate = UpdateInfo(
    status: UpdateStatus.upToDate,
    currentVersion: '1.0.0',
    latestVersion: '1.0.0',
    forceVersion: '0.9.0',
  );

  group('ServerUpdateCheckCoordinator', () {
    test(
      'a fresh retry invalidates before reading the server provider',
      () async {
        final coordinator = ServerUpdateCheckCoordinator();
        final events = <String>[];

        final result = await coordinator.check(
          forceRefresh: true,
          timeout: const Duration(seconds: 5),
          invalidate: () => events.add('invalidate'),
          readServer: () async {
            events.add('read');
            return upToDate;
          },
        );

        expect(result, same(upToDate));
        expect(events, ['invalidate', 'read']);
      },
    );

    test('no server result is a retryable startup failure', () async {
      final coordinator = ServerUpdateCheckCoordinator();

      await expectLater(
        coordinator.check(
          timeout: const Duration(seconds: 5),
          invalidate: () {},
          readServer: () async => null,
        ),
        throwsA(isA<StartupUpdateCheckException>()),
      );
    });

    test(
      'a failed fresh read can be invalidated and retried to success',
      () async {
        final coordinator = ServerUpdateCheckCoordinator();
        var reads = 0;
        var invalidations = 0;

        Future<UpdateInfo?> readServer() async {
          reads++;
          if (reads == 1) throw StateError('server unavailable');
          return upToDate;
        }

        Future<UpdateInfo> check() => coordinator.check(
          forceRefresh: true,
          timeout: const Duration(seconds: 5),
          invalidate: () => invalidations++,
          readServer: readServer,
        );

        await expectLater(check(), throwsA(isA<StateError>()));
        expect(await check(), same(upToDate));
        expect(reads, 2);
        expect(invalidations, 2);
      },
    );

    testWidgets(
      'timeout allows a fresh server retry without late interference',
      (tester) async {
        final coordinator = ServerUpdateCheckCoordinator();
        final stalled = Completer<UpdateInfo?>();
        final recovered = Completer<UpdateInfo?>();
        var reads = 0;
        var invalidations = 0;
        Future<UpdateInfo> check() => coordinator.check(
          forceRefresh: true,
          timeout: const Duration(seconds: 5),
          invalidate: () => invalidations++,
          readServer: () {
            reads++;
            return reads == 1 ? stalled.future : recovered.future;
          },
        );
        final firstTimeout = expectLater(
          check(),
          throwsA(isA<TimeoutException>()),
        );
        await tester.pump(const Duration(seconds: 5));
        await firstTimeout;
        final retry = check();
        final joined = check();
        expect(reads, 2);
        expect(invalidations, 2);
        stalled.complete(null);
        await tester.pump();
        final joinedAfterOldCompletion = check();
        expect(
          reads,
          2,
          reason: 'old completion must not release the new read',
        );
        recovered.complete(upToDate);
        await tester.pump();
        expect(await retry, same(upToDate));
        expect(await joined, same(upToDate));
        expect(await joinedAfterOldCompletion, same(upToDate));
      },
    );
  });
}
