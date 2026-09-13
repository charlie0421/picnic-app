import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/startup_readiness.dart';

void main() {
  group('RetryableStartupStages', () {
    test('retry reruns only the failed stage', () async {
      final stages = RetryableStartupStages();
      var databaseCalls = 0;
      var authCalls = 0;
      var authShouldFail = true;

      Future<void> initialize() => Future.wait<void>([
        stages.run('database', () async {
          databaseCalls++;
        }),
        stages.run('auth', () async {
          authCalls++;
          if (authShouldFail) throw StateError('auth unavailable');
        }),
      ]);

      await expectLater(initialize(), throwsA(isA<StateError>()));
      authShouldFail = false;
      await initialize();

      expect(databaseCalls, 1);
      expect(authCalls, 2);
      expect(stages.isSuccessful('database'), isTrue);
      expect(stages.isSuccessful('auth'), isTrue);
    });

    test('concurrent callers share the same in-flight stage future', () async {
      final stages = RetryableStartupStages();
      final completion = Completer<void>();
      var calls = 0;

      Future<void> initialize() {
        calls++;
        return completion.future;
      }

      final first = stages.run('supabase', initialize);
      final second = stages.run('supabase', initialize);

      expect(identical(first, second), isTrue);
      expect(calls, 1);
      completion.complete();
      await first;
      await second;
    });

    testWidgets(
      'an observation timeout preserves the raw future for a late join',
      (tester) async {
        final stages = RetryableStartupStages();
        final completion = Completer<void>();
        var calls = 0;

        Future<void> initialize() {
          calls++;
          return completion.future;
        }

        final observation = stages.observe(
          'firebase',
          initialize,
          timeout: const Duration(seconds: 5),
        );
        final timeout = expectLater(
          observation,
          throwsA(isA<TimeoutException>()),
        );
        await tester.pump(const Duration(seconds: 5));
        await timeout;

        final joined = stages.run('firebase', initialize);
        expect(calls, 1);
        completion.complete();
        await tester.pump();
        await joined;

        await stages.run('firebase', initialize);
        expect(calls, 1);
      },
    );
  });

  group('StartupReadinessController', () {
    test('exposes failure and allows a later successful retry', () async {
      final controller = StartupReadinessController();
      var calls = 0;

      final first = controller.run(() async {
        calls++;
        throw StateError('sdk failed');
      });
      final firstResult = await first;

      expect(firstResult.isReady, isFalse);
      expect(firstResult.error, isA<StateError>());
      expect((await controller.ready).isReady, isFalse);

      final retryResult = await controller.run(() async {
        calls++;
      });

      expect(retryResult.isReady, isTrue);
      expect((await controller.ready).isReady, isTrue);
      expect(calls, 2);
    });

    test('concurrent retry callers share one attempt', () async {
      final controller = StartupReadinessController();
      final completion = Completer<void>();
      var calls = 0;

      Future<void> initialize() {
        calls++;
        return completion.future;
      }

      final first = controller.run(initialize);
      final second = controller.run(initialize);

      expect(identical(first, second), isTrue);
      expect(calls, 1);
      completion.complete();
      expect((await first).isReady, isTrue);
      expect((await second).isReady, isTrue);
    });
  });

  group('StartupConnectionChecks', () {
    testWidgets(
      'a late raw completion after timeout cannot publish without a retry',
      (tester) async {
        final checks = StartupConnectionChecks<String>();
        final ban = Completer<bool>();
        final published = <StartupConnectionResult<String>>[];

        final first = checks.run(
          timeout: const Duration(seconds: 5),
          checkNetwork: () async => true,
          checkUpdate: () async => 'up-to-date',
          checkBan: () => ban.future,
          publish: published.add,
        );
        final timeout = expectLater(first, throwsA(isA<TimeoutException>()));
        await tester.pump(const Duration(seconds: 5));
        await timeout;

        ban.complete(false);
        await tester.pump();
        expect(published, isEmpty);
      },
    );

    testWidgets('timed-out checks retry fresh and ignore the old ban result', (
      tester,
    ) async {
      final checks = StartupConnectionChecks<String>();
      final oldBan = Completer<bool>();
      final published = <StartupConnectionResult<String>>[];
      var networkCalls = 0;
      var updateCalls = 0;
      var banCalls = 0;
      Future<StartupConnectionResult<String>> run() => checks.run(
        timeout: const Duration(seconds: 5),
        checkNetwork: () async {
          networkCalls++;
          return true;
        },
        checkUpdate: () async {
          updateCalls++;
          return 'up-to-date';
        },
        checkBan: () {
          banCalls++;
          return banCalls == 1 ? oldBan.future : Future.value(false);
        },
        publish: published.add,
      );
      final firstTimeout = expectLater(run(), throwsA(isA<TimeoutException>()));
      await tester.pump(const Duration(seconds: 5));
      await firstTimeout;
      final retry = run();
      expect(identical(retry, run()), isTrue);
      await tester.pump();
      expect(networkCalls, 2);
      expect(updateCalls, 2);
      expect(banCalls, 2);
      final recovered = await retry;
      expect(recovered.isBanned, isFalse);
      expect(published, [same(recovered)]);
      oldBan.complete(true);
      await tester.pump();
      expect(published, [same(recovered)]);
    });

    testWidgets(
      'publishes online state only after update and ban checks finish',
      (tester) async {
        final checks = StartupConnectionChecks<String>();
        final update = Completer<String>();
        final ban = Completer<bool>();
        final published = <StartupConnectionResult<String>>[];
        var isOnline = false;
        var networkCalls = 0;
        var updateCalls = 0;
        var banCalls = 0;

        Future<StartupConnectionResult<String>> run() => checks.run(
          checkNetwork: () async {
            networkCalls++;
            return isOnline;
          },
          checkUpdate: () {
            updateCalls++;
            return update.future;
          },
          checkBan: () {
            banCalls++;
            return ban.future;
          },
          publish: published.add,
        );

        final offline = await run();
        expect(offline.hasNetwork, isFalse);
        expect(published.single.hasNetwork, isFalse);
        expect(updateCalls, 0);
        expect(banCalls, 0);

        isOnline = true;
        final first = run();
        final duplicate = run();
        expect(identical(first, duplicate), isTrue);
        await tester.pump();

        expect(networkCalls, 2);
        expect(updateCalls, 1);
        expect(banCalls, 1);
        expect(
          published.where((result) => result.hasNetwork),
          isEmpty,
          reason:
              'network=true must not be published before both checks finish',
        );

        update.complete('force-update');
        await tester.pump();
        expect(published, hasLength(1));

        ban.complete(true);
        await tester.pump();
        final online = await first;
        expect(await duplicate, same(online));
        expect(online.hasNetwork, isTrue);
        expect(online.updateInfo, 'force-update');
        expect(online.isBanned, isTrue);
        expect(published.last, same(online));
      },
    );

    test(
      'a failed required check publishes nothing and can be retried',
      () async {
        final checks = StartupConnectionChecks<String>();
        final published = <StartupConnectionResult<String>>[];
        var updateCalls = 0;

        Future<StartupConnectionResult<String>> run() => checks.run(
          checkNetwork: () async => true,
          checkUpdate: () async {
            updateCalls++;
            if (updateCalls == 1) throw StateError('server unavailable');
            return 'up-to-date';
          },
          checkBan: () async => false,
          publish: published.add,
        );

        await expectLater(run(), throwsA(isA<StateError>()));
        expect(published, isEmpty);

        final recovered = await run();
        expect(recovered.updateInfo, 'up-to-date');
        expect(published, [same(recovered)]);
        expect(updateCalls, 2);
      },
    );
  });

  group('BoundedNonAuthStartupGate', () {
    testWidgets('auth remains a mandatory readiness gate', (tester) async {
      final auth = Completer<void>();
      var ready = false;
      final gate = BoundedNonAuthStartupGate(
        nonAuthWaitLimit: const Duration(seconds: 5),
      );

      gate
          .wait(
            initializeAuth: () => auth.future,
            initializeNonAuth: () async {},
          )
          .then((_) => ready = true);

      await tester.pump(const Duration(seconds: 30));
      expect(ready, isFalse);

      auth.complete();
      await tester.pump();
      expect(ready, isTrue);
    });

    testWidgets(
      'non-auth SDKs hold readiness at most five seconds after auth',
      (tester) async {
        final nonAuth = Completer<void>();
        var ready = false;
        final gate = BoundedNonAuthStartupGate(
          nonAuthWaitLimit: const Duration(seconds: 5),
        );

        gate
            .wait(
              initializeAuth: () async {},
              initializeNonAuth: () => nonAuth.future,
            )
            .then((_) => ready = true);

        await tester.pump(const Duration(seconds: 4));
        expect(ready, isFalse);
        await tester.pump(const Duration(seconds: 1));
        expect(ready, isTrue);

        nonAuth.complete();
        await tester.pump();
      },
    );

    testWidgets('a late non-auth error is observed after the splash timeout', (
      tester,
    ) async {
      final nonAuth = Completer<void>();
      final errors = <Object>[];
      final gate = BoundedNonAuthStartupGate(
        nonAuthWaitLimit: const Duration(seconds: 5),
        onNonAuthError: (error, _) => errors.add(error),
      );

      final readiness = gate.wait(
        initializeAuth: () async {},
        initializeNonAuth: () => nonAuth.future,
      );
      await tester.pump(const Duration(seconds: 5));
      await expectLater(readiness, completes);

      nonAuth.completeError(StateError('late SDK failure'));
      await tester.pump();
      expect(errors.single, isA<StateError>());
    });
  });

  group('RetryableAdMobInitializer', () {
    test('concurrent initialization callers share one raw future', () async {
      final result = Completer<bool>();
      var calls = 0;
      final initializer = RetryableAdMobInitializer(
        initialize: () {
          calls++;
          return result.future;
        },
      );

      final first = initializer.initialize();
      final second = initializer.initialize();

      expect(identical(first, second), isTrue);
      expect(calls, 1);
      result.complete(true);
      expect(await first, isTrue);
      expect(await second, isTrue);
    });

    test(
      'a false attempt can be retried and does not become permanent',
      () async {
        var calls = 0;
        final initializer = RetryableAdMobInitializer(
          initialize: () async {
            calls++;
            return calls > 1;
          },
        );

        expect(await initializer.initialize(), isFalse);
        expect(await initializer.initialize(), isTrue);
        expect(await initializer.initialize(), isTrue);
        expect(calls, 2);
      },
    );
  });

  group('AdRequestReadinessGate', () {
    testWidgets('reads consent after SDK readiness completes', (tester) async {
      final readiness = Completer<bool>();
      var consentGranted = false;
      var consentReads = 0;
      final gate = AdRequestReadinessGate(
        waitForAdMob: ({required timeout}) => readiness.future,
        canRequestAds: () async {
          consentReads++;
          return consentGranted;
        },
      );
      final request = gate.run(request: () async => 'loaded');
      final result = expectLater(request, completion('loaded'));
      await tester.pump();
      final readsBeforeReady = consentReads;
      consentGranted = true;
      readiness.complete(true);
      await tester.pump();
      await result;
      expect(readsBeforeReady, 0);
      expect(consentReads, 1);
    });

    testWidgets('closing a surface during readiness prevents its request', (
      tester,
    ) async {
      final readiness = Completer<bool>();
      var isActive = true;
      var requests = 0;
      final gate = AdRequestReadinessGate(
        waitForAdMob: ({required timeout}) => readiness.future,
        canRequestAds: () async => true,
      );
      final request = gate.run(
        isRequestActive: () => isActive,
        request: () async => requests++,
      );
      final failure = expectLater(request, throwsA(isA<AdsUnavailable>()));
      await tester.pump();
      isActive = false;
      readiness.complete(true);
      await tester.pump();
      await failure;
      expect(requests, 0);
    });

    testWidgets('readiness and consent share one request deadline', (
      tester,
    ) async {
      final readiness = Completer<bool>();
      final consent = Completer<bool>();
      var requests = 0;
      final gate = AdRequestReadinessGate(
        waitForAdMob: ({required timeout}) => readiness.future,
        canRequestAds: () => consent.future,
      );
      final request = gate.run(request: () async => requests++);
      final failure = expectLater(request, throwsA(isA<AdsUnavailable>()));
      await tester.pump(const Duration(seconds: 4));
      readiness.complete(true);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await failure;
      consent.complete(true);
      await tester.pump();
      expect(requests, 0);
    });

    testWidgets('closing while consent is read also cancels the request', (
      tester,
    ) async {
      final consent = Completer<bool>();
      var isActive = true;
      var requests = 0;
      final gate = AdRequestReadinessGate(
        waitForAdMob: ({required timeout}) async => true,
        canRequestAds: () => consent.future,
      );
      final request = gate.run(
        isRequestActive: () => isActive,
        request: () async => requests++,
      );
      final failure = expectLater(request, throwsA(isA<AdsUnavailable>()));
      await tester.pump();
      isActive = false;
      consent.complete(true);
      await tester.pump();
      await failure;
      expect(requests, 0);
    });

    testWidgets('late readiness does not start a consent read after timeout', (
      tester,
    ) async {
      final readiness = Completer<bool>();
      var consentReads = 0;
      final gate = AdRequestReadinessGate(
        waitForAdMob: ({required timeout}) => readiness.future,
        canRequestAds: () async {
          consentReads++;
          return true;
        },
      );
      final request = gate.run(request: () async => 'loaded');
      final failure = expectLater(request, throwsA(isA<AdsUnavailable>()));
      await tester.pump(const Duration(seconds: 5));
      await failure;
      readiness.complete(true);
      await tester.pump();
      expect(consentReads, 0);
    });

    testWidgets(
      'a timed-out request never starts and late readiness recovers',
      (tester) async {
        final rawInitialization = Completer<bool>();
        final initializer = RetryableAdMobInitializer(
          initialize: () => rawInitialization.future,
        );
        var requests = 0;
        final gate = AdRequestReadinessGate(
          waitForAdMob: initializer.waitForReady,
          canRequestAds: () async => true,
        );

        final firstRequest = gate.run(
          timeout: const Duration(seconds: 5),
          request: () async {
            requests++;
            return 'loaded';
          },
        );
        final failure = expectLater(
          firstRequest,
          throwsA(isA<AdsUnavailable>()),
        );
        await tester.pump(const Duration(seconds: 5));
        await failure;
        expect(requests, 0);

        rawInitialization.complete(true);
        await tester.pump();
        expect(
          await gate.run(
            timeout: const Duration(seconds: 5),
            request: () async {
              requests++;
              return 'loaded';
            },
          ),
          'loaded',
        );
        expect(requests, 1);
      },
    );

    testWidgets('a stalled consent check cannot start an ad request', (
      tester,
    ) async {
      var requests = 0;
      final gate = AdRequestReadinessGate(
        waitForAdMob: ({required timeout}) async => true,
        canRequestAds: () => Completer<bool>().future,
      );

      final request = gate.run(
        timeout: const Duration(seconds: 5),
        request: () async {
          requests++;
        },
      );
      final failure = expectLater(request, throwsA(isA<AdsUnavailable>()));
      await tester.pump(const Duration(seconds: 5));
      await failure;

      expect(requests, 0);
    });

    test('consent refusal prevents an ad request', () async {
      var requests = 0;
      final gate = AdRequestReadinessGate(
        waitForAdMob: ({required timeout}) async => true,
        canRequestAds: () async => false,
      );

      await expectLater(
        gate.run(
          request: () async {
            requests++;
          },
        ),
        throwsA(isA<AdsUnavailable>()),
      );
      expect(requests, 0);
    });
  });
}
