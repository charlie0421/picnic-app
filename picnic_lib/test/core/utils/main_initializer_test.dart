import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/consent_service.dart';
import 'package:picnic_lib/core/utils/main_initializer.dart';
import 'package:picnic_lib/core/utils/startup_readiness.dart';

void main() {
  group('MainInitializer', () {
    testWidgets(
      'core SDK timeout keeps raw work for retry and caches success',
      (tester) async {
        final stages = RetryableStartupStages();
        final database = Completer<void>();
        var databaseCalls = 0;
        var firebaseCalls = 0;
        Future<void> initialize() => MainInitializer.initializeCoreSdkGroup(
          stages: stages,
          machineStages: {
            'supabase': () {
              databaseCalls++;
              return database.future;
            },
            'firebase': () async {
              firebaseCalls++;
            },
          },
        );
        Object? firstResult;
        final first = initialize().then<void>(
          (_) => firstResult = 'ready',
          onError: (Object error) {
            firstResult = error;
          },
        );
        await tester.pump(const Duration(seconds: 10));
        expect(firstResult, isA<TimeoutException>());
        await first;
        final second = initialize();
        expect(databaseCalls, 1);
        expect(firebaseCalls, 1);
        database.complete();
        await tester.pump();
        await second;
        await initialize();
        expect(databaseCalls, 1);
        expect(firebaseCalls, 1);
      },
    );

    testWidgets('user consent wait has no machine deadline', (tester) async {
      final consent = Completer<void>();
      var finished = false;
      final ready = MainInitializer.initializeCoreSdkGroup(
        stages: RetryableStartupStages(),
        machineStages: {'supabase': () async {}},
        initializePrivacyConsent: () => consent.future,
      ).then((_) => finished = true);
      await tester.pump(const Duration(seconds: 60));
      expect(finished, isFalse);
      consent.complete();
      await tester.pump();
      await ready;
      expect(finished, isTrue);
    });

    testWidgets('hung consent does not hide a core SDK timeout', (
      tester,
    ) async {
      final database = Completer<void>();
      final consent = Completer<void>();
      Object? result;
      final ready =
          MainInitializer.initializeCoreSdkGroup(
            stages: RetryableStartupStages(),
            machineStages: {'supabase': () => database.future},
            initializePrivacyConsent: () => consent.future,
          ).then<void>(
            (_) => result = 'ready',
            onError: (Object error) {
              result = error;
            },
          );
      await tester.pump(const Duration(seconds: 10));
      expect(result, isA<TimeoutException>());
      await ready;
      database.complete();
      consent.complete();
      await tester.pump();
    });

    test('initializeApp entrypoint remains callable', () {
      expect(MainInitializer.initializeApp, isA<Function>());
    });

    test('SDK readiness exposes an explicit success or failure result', () {
      expect(MainInitializer.sdkReady, isA<Future<StartupReadinessResult>>());
      expect(MainInitializer.retrySdkInitialization, isA<Function>());
    });

    test('ad requests expose the readiness-gated entrypoint', () {
      expect(MainInitializer.runAdRequestWhenReady<void>, isA<Function>());
    });

    test(
      'startup does not repeat failed UMP but a later ad attempt retries',
      () async {
        var statusReads = 0;
        final consent = ConsentService.withSdk(
          sdk: ConsentSdk(
            requestConsentInfoUpdate: (_, onSuccess, _) => onSuccess(),
            getConsentStatus: () async {
              statusReads++;
              if (statusReads == 1) {
                throw StateError('transient UMP failure');
              }
              return ConsentStatus.notRequired;
            },
            isConsentFormAvailable: () async => false,
            loadConsentForm: (_, _) {},
            canRequestAds: () async => true,
            reset: () async {},
            getPrivacyOptionsRequirementStatus: () async =>
                PrivacyOptionsRequirementStatus.notRequired,
          ),
        );
        expect(await consent.initialize(), isFalse);
        expect(consent.lastAttemptFailed, isTrue);

        var adMobAttempts = 0;
        final adMob = RetryableAdMobInitializer(
          initialize: () async {
            adMobAttempts++;
            return consent.initialize();
          },
        );
        final startup = StartupAdMobInitializationGuard(
          didConsentInitializationFail: () => consent.lastAttemptFailed,
          initializeAdMob: adMob.initialize,
        );

        expect(await startup.initialize(), isFalse);
        expect(statusReads, 1);
        expect(adMobAttempts, 0);

        expect(await adMob.initialize(), isTrue);
        expect(statusReads, 2);
        expect(adMobAttempts, 1);
        expect(consent.lastAttemptFailed, isFalse);
      },
    );
  });
}
