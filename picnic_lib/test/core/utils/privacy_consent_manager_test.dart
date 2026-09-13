import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/core/services/consent_service.dart';
import 'package:picnic_lib/core/utils/privacy_consent_manager.dart';
import 'package:picnic_lib/core/utils/startup_machine_budget.dart';

void main() {
  group('PrivacyConsentFlow', () {
    test('Android performs UMP without reading or requesting ATT', () async {
      final events = <String>[];
      final flow = _flow(isIOS: false, events: events);

      await flow.initialize();

      expect(events, ['ump']);
    });

    test('an already-authorized iOS status skips presentation delay', () async {
      final events = <String>[];
      final flow = _flow(
        isIOS: true,
        events: events,
        trackingStatus: TrackingStatus.authorized,
      );

      await flow.initialize();

      expect(events, ['att-status', 'ump']);
    });

    test(
      'an undecided iOS status waits for a frame before prompting',
      () async {
        final events = <String>[];
        final flow = _flow(
          isIOS: true,
          events: events,
          trackingStatus: TrackingStatus.notDetermined,
          requestedStatus: TrackingStatus.authorized,
        );

        await flow.initialize();

        expect(events, [
          'att-status',
          'att-presentation',
          'att-request',
          'ump',
        ]);
      },
    );

    test(
      'ATT refusal still configures non-personalized ads and runs UMP',
      () async {
        final events = <String>[];
        final flow = _flow(
          isIOS: true,
          events: events,
          trackingStatus: TrackingStatus.denied,
        );

        await flow.initialize();

        expect(events, ['att-status', 'non-personalized-config', 'ump']);
      },
    );

    test('a failed non-personalized config does not skip UMP', () async {
      final events = <String>[];
      final flow = _flow(
        isIOS: true,
        events: events,
        trackingStatus: TrackingStatus.denied,
        configureNonPersonalizedAds: () async {
          events.add('non-personalized-config');
          throw StateError('configuration unavailable');
        },
      );

      await expectLater(flow.initialize(), completes);
      expect(events, ['att-status', 'non-personalized-config', 'ump']);
    });

    test('an ATT status error still runs UMP', () async {
      final events = <String>[];
      final flow = _flow(
        isIOS: true,
        events: events,
        readTrackingStatus: () async {
          events.add('att-status');
          throw StateError('ATT channel unavailable');
        },
      );

      await expectLater(flow.initialize(), completes);
      expect(events, ['att-status', 'non-personalized-config', 'ump']);
    });

    testWidgets('a stalled ATT status read is bounded and still runs UMP', (
      tester,
    ) async {
      final events = <String>[];
      final flow = _flow(
        isIOS: true,
        events: events,
        readTrackingStatus: () {
          events.add('att-status');
          return Completer<TrackingStatus>().future;
        },
        machineOperationTimeout: const Duration(seconds: 5),
      );
      var completed = false;
      flow.initialize().then((_) => completed = true);

      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      expect(completed, isTrue);
      expect(events, ['att-status', 'non-personalized-config', 'ump']);
    });

    testWidgets('a stalled request configuration is bounded before UMP', (
      tester,
    ) async {
      final events = <String>[];
      final flow = _flow(
        isIOS: true,
        events: events,
        trackingStatus: TrackingStatus.denied,
        configureNonPersonalizedAds: () {
          events.add('non-personalized-config');
          return Completer<void>().future;
        },
        machineOperationTimeout: const Duration(seconds: 5),
      );
      var completed = false;
      flow.initialize().then((_) => completed = true);

      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      expect(completed, isTrue);
      expect(events, ['att-status', 'non-personalized-config', 'ump']);
    });

    testWidgets('an active ATT prompt waits beyond the machine deadline', (
      tester,
    ) async {
      final events = <String>[];
      final prompt = Completer<TrackingStatus>();
      final flow = PrivacyConsentFlow(
        isIOS: true,
        readTrackingStatus: () async => TrackingStatus.notDetermined,
        waitForAttPresentation: () async {},
        requestTrackingAuthorization: () => prompt.future,
        configureNonPersonalizedAds: () async {},
        initializeUmp: (_) async {
          events.add('ump');
          return true;
        },
        machineOperationTimeout: const Duration(seconds: 5),
      );
      var completed = false;
      flow.initialize().then((_) => completed = true);

      await tester.pump(const Duration(seconds: 61));
      expect(completed, isFalse);
      expect(events, isEmpty);

      prompt.complete(TrackingStatus.authorized);
      await tester.pump();
      expect(completed, isTrue);
      expect(events, ['ump']);
    });

    test('ATT and UMP stages stop at one cumulative machine budget', () {
      fakeAsync((async) {
        final events = <String>[];
        final budget = StartupMachineBudget(
          limit: const Duration(seconds: 5),
          elapsed: () => async.elapsed,
        );
        final consent = _consentService(
          events: events,
          requestConsentInfoUpdate: (_, onSuccess, _) {
            events.add('ump-update');
            Future<void>.delayed(const Duration(seconds: 2), onSuccess);
          },
        );
        final flow = PrivacyConsentFlow(
          isIOS: true,
          readTrackingStatus: () async {
            events.add('att-status');
            await Future<void>.delayed(const Duration(seconds: 2));
            return TrackingStatus.denied;
          },
          waitForAttPresentation: () async {
            throw StateError('presentation delay should not run');
          },
          requestTrackingAuthorization: () async {
            throw StateError('ATT prompt should not run');
          },
          configureNonPersonalizedAds: () async {
            events.add('non-personalized-config');
            await Future<void>.delayed(const Duration(seconds: 2));
          },
          initializeUmp: (sharedBudget) {
            events.add('ump');
            return consent.initialize(machineOperationBudget: sharedBudget);
          },
          machineOperationBudget: budget,
        );
        var completed = false;

        flow.initialize().then((_) => completed = true);
        async.elapse(const Duration(milliseconds: 4999));
        expect(completed, isFalse);

        async.elapse(const Duration(milliseconds: 1));
        expect(completed, isTrue);
        expect(events, [
          'att-status',
          'non-personalized-config',
          'ump',
          'ump-update',
        ]);

        // Drain the ignored update callback.
        async.elapse(const Duration(seconds: 1));
      });
    });

    test('a slow successful ATT status still presents the first prompt', () {
      fakeAsync((async) {
        final events = <String>[];
        final prompt = Completer<TrackingStatus>();
        final budget = StartupMachineBudget(elapsed: () => async.elapsed);
        final flow = PrivacyConsentFlow(
          isIOS: true,
          readTrackingStatus: () async {
            await Future<void>.delayed(const Duration(milliseconds: 4500));
            return TrackingStatus.notDetermined;
          },
          waitForAttPresentation: () =>
              Future<void>.delayed(const Duration(seconds: 1)),
          requestTrackingAuthorization: () {
            events.add('att-request');
            return prompt.future;
          },
          configureNonPersonalizedAds: () async {},
          initializeUmp: (sharedBudget) async {
            events.add('ump');
            expect(sharedBudget.remaining, const Duration(milliseconds: 500));
            return true;
          },
          machineOperationBudget: budget,
        );
        var completed = false;
        flow.initialize().then((_) => completed = true);

        async.elapse(const Duration(milliseconds: 5500));
        // Complete even when this regression fails so no pending prompt leaks.
        final promptWasRequested = events.contains('att-request');
        final completedBeforeDecision = completed;
        async.elapse(const Duration(minutes: 1));
        prompt.complete(TrackingStatus.authorized);
        async.flushMicrotasks();

        expect(promptWasRequested, isTrue);
        expect(completedBeforeDecision, isFalse);
        expect(completed, isTrue);
        expect(events, ['att-request', 'ump']);
      });
    });

    test('an unresponsive ATT channel completes without a fallback prompt', () {
      fakeAsync((async) {
        final events = <String>[];
        final budget = StartupMachineBudget(elapsed: () => async.elapsed);
        final consent = _consentService(
          events: events,
          requestConsentInfoUpdate: (_, onSuccess, _) {
            events.add('ump-update');
            onSuccess();
          },
        );
        final flow = PrivacyConsentFlow(
          isIOS: true,
          readTrackingStatus: () => Completer<TrackingStatus>().future,
          waitForAttPresentation: () async => events.add('att-presentation'),
          requestTrackingAuthorization: () {
            events.add('att-request');
            return Completer<TrackingStatus>().future;
          },
          configureNonPersonalizedAds: () async => events.add('config'),
          initializeUmp: (sharedBudget) =>
              consent.initialize(machineOperationBudget: sharedBudget),
          machineOperationBudget: budget,
        );
        var completed = false;
        flow.initialize().then((_) => completed = true);

        async.elapse(const Duration(seconds: 5));

        expect(completed, isTrue);
        expect(events, isEmpty);
        expect(consent.lastAttemptFailed, isTrue);
        expect(budget.remaining, Duration.zero);
      });
    });

    test('a long ATT decision is excluded before UMP uses the remainder', () {
      fakeAsync((async) {
        final events = <String>[];
        final prompt = Completer<TrackingStatus>();
        final budget = StartupMachineBudget(
          limit: const Duration(seconds: 5),
          elapsed: () => async.elapsed,
        );
        final consent = _consentService(
          events: events,
          requestConsentInfoUpdate: (_, onSuccess, _) {
            events.add('ump-update');
            Future<void>.delayed(const Duration(seconds: 2), onSuccess);
          },
          getConsentStatus: () async {
            events.add('ump-status');
            await Future<void>.delayed(const Duration(seconds: 2));
            return ConsentStatus.notRequired;
          },
        );
        final flow = PrivacyConsentFlow(
          isIOS: true,
          readTrackingStatus: () async {
            events.add('att-status');
            await Future<void>.delayed(const Duration(seconds: 1));
            return TrackingStatus.notDetermined;
          },
          waitForAttPresentation: () async {
            events.add('att-presentation');
            await Future<void>.delayed(const Duration(seconds: 1));
          },
          requestTrackingAuthorization: () {
            events.add('att-request');
            return prompt.future;
          },
          configureNonPersonalizedAds: () async {},
          initializeUmp: (sharedBudget) {
            events.add('ump');
            return consent.initialize(machineOperationBudget: sharedBudget);
          },
          machineOperationBudget: budget,
        );
        var completed = false;

        flow.initialize().then((_) => completed = true);
        async.elapse(const Duration(seconds: 2));
        expect(events, ['att-status', 'att-presentation', 'att-request']);

        async.elapse(const Duration(minutes: 1));
        expect(completed, isFalse);
        expect(events, ['att-status', 'att-presentation', 'att-request']);

        prompt.complete(TrackingStatus.authorized);
        async.flushMicrotasks();
        expect(budget.remaining, const Duration(seconds: 4));
        expect(events, [
          'att-status',
          'att-presentation',
          'att-request',
          'ump',
          'ump-update',
        ]);

        async.elapse(const Duration(seconds: 2));
        expect(events.last, 'ump-status');
        expect(completed, isFalse);

        async.elapse(const Duration(seconds: 2));
        expect(completed, isTrue);
        expect(events, [
          'att-status',
          'att-presentation',
          'att-request',
          'ump',
          'ump-update',
          'ump-status',
        ]);

        // The last SDK operation reaches the four-second remaining deadline.
        expect(consent.lastAttemptFailed, isTrue);
      });
    });
  });

  group('PrivacyConsentManager', () {
    test('non-mobile initialization returns without platform calls', () async {
      await expectLater(PrivacyConsentManager.initialize(), completes);
      expect(await PrivacyConsentManager.canShowPersonalizedAds(), isFalse);
    });
  });
}

PrivacyConsentFlow _flow({
  required bool isIOS,
  required List<String> events,
  TrackingStatus trackingStatus = TrackingStatus.authorized,
  TrackingStatus requestedStatus = TrackingStatus.authorized,
  Future<TrackingStatus> Function()? readTrackingStatus,
  Future<void> Function()? configureNonPersonalizedAds,
  Duration machineOperationTimeout = const Duration(seconds: 1),
}) {
  return PrivacyConsentFlow(
    isIOS: isIOS,
    readTrackingStatus:
        readTrackingStatus ??
        () async {
          events.add('att-status');
          return trackingStatus;
        },
    waitForAttPresentation: () async {
      events.add('att-presentation');
    },
    requestTrackingAuthorization: () async {
      events.add('att-request');
      return requestedStatus;
    },
    configureNonPersonalizedAds:
        configureNonPersonalizedAds ??
        () async {
          events.add('non-personalized-config');
        },
    initializeUmp: (_) async {
      events.add('ump');
      return true;
    },
    machineOperationTimeout: machineOperationTimeout,
  );
}

ConsentService _consentService({
  required List<String> events,
  required ConsentInfoUpdateRequester requestConsentInfoUpdate,
  Future<ConsentStatus> Function()? getConsentStatus,
}) {
  return ConsentService.withSdk(
    sdk: ConsentSdk(
      requestConsentInfoUpdate: requestConsentInfoUpdate,
      getConsentStatus:
          getConsentStatus ??
          () async {
            events.add('ump-status');
            return ConsentStatus.notRequired;
          },
      isConsentFormAvailable: () async {
        events.add('ump-availability');
        return false;
      },
      loadConsentForm: (_, _) {
        events.add('ump-form-load');
      },
      canRequestAds: () async => true,
      reset: () async {},
      getPrivacyOptionsRequirementStatus: () async =>
          PrivacyOptionsRequirementStatus.notRequired,
    ),
  );
}
