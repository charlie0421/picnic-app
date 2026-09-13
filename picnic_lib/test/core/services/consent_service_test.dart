import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ump/user_messaging_channel.dart';
import 'package:google_mobile_ads/src/ump/user_messaging_codec.dart';
import 'package:picnic_lib/core/services/consent_service.dart';

void main() {
  group('ConsentService', () {
    test('factory returns the same singleton', () {
      expect(identical(ConsentService(), ConsentService()), isTrue);
    });

    test('a consent status failure settles initialization as false', () async {
      final service = _service(
        getConsentStatus: () =>
            Future<ConsentStatus>.error(StateError('status unavailable')),
      );

      await expectLater(service.initialize(), completion(isFalse));
    });

    test(
      'a form availability failure settles initialization as false',
      () async {
        final service = _service(
          isConsentFormAvailable: () =>
              Future<bool>.error(StateError('availability unavailable')),
        );

        await expectLater(service.initialize(), completion(isFalse));
      },
    );

    testWidgets('a missing update callback ends at the machine deadline', (
      tester,
    ) async {
      final service = _service(
        requestConsentInfoUpdate: (_, _, _) {},
        machineOperationTimeout: const Duration(seconds: 5),
      );
      bool? result;
      service.initialize().then((value) => result = value);

      await tester.pump(const Duration(seconds: 4));
      expect(result, isNull);

      await tester.pump(const Duration(seconds: 1));
      expect(result, isFalse);
    });

    testWidgets('concurrent callers join one initialization attempt', (
      tester,
    ) async {
      late void Function() succeed;
      var updateRequests = 0;
      final service = _service(
        requestConsentInfoUpdate: (_, onSuccess, _) {
          updateRequests++;
          succeed = onSuccess;
        },
      );

      final first = service.initialize();
      final second = service.initialize();

      expect(identical(first, second), isTrue);
      expect(updateRequests, 1);

      succeed();
      await tester.pump();

      await expectLater(first, completion(isTrue));
      await expectLater(second, completion(isTrue));
    });

    testWidgets('reset settles old callers and isolates the next attempt', (
      tester,
    ) async {
      final successes = <void Function()>[];
      var statusReads = 0;
      final service = _service(
        requestConsentInfoUpdate: (_, onSuccess, _) {
          successes.add(onSuccess);
        },
        getConsentStatus: () async {
          statusReads++;
          return ConsentStatus.notRequired;
        },
      );

      final oldAttempt = service.initialize();
      await service.reset();
      await expectLater(oldAttempt, completion(isFalse));

      final freshAttempt = service.initialize();
      var freshSettled = false;
      freshAttempt.then((_) => freshSettled = true);

      successes.first();
      await tester.pump();
      expect(statusReads, 0);
      expect(freshSettled, isFalse);

      successes.last();
      await tester.pump();
      await expectLater(freshAttempt, completion(isTrue));
      expect(statusReads, 1);
    });

    testWidgets(
      'a form arriving after its load timeout is disposed, not shown',
      (tester) async {
        late void Function(ConsentForm) finishLoading;
        final form = _FakeConsentForm();
        final service = _service(
          getConsentStatus: () async => ConsentStatus.required,
          isConsentFormAvailable: () async => true,
          loadConsentForm: (onSuccess, _) {
            finishLoading = onSuccess;
          },
          machineOperationTimeout: const Duration(seconds: 5),
        );

        final result = service.initialize();
        final resultExpectation = expectLater(result, completion(isFalse));
        await tester.pump(const Duration(seconds: 5));
        await resultExpectation;

        finishLoading(form);
        await tester.pump();

        expect(form.wasShown, isFalse);
        expect(form.wasDisposed, isTrue);
      },
    );

    test('slow UMP stages share one machine-operation budget', () {
      fakeAsync((async) {
        final events = <String>[];
        final service = _service(
          requestConsentInfoUpdate: (_, onSuccess, _) {
            events.add('update');
            Future<void>.delayed(const Duration(seconds: 2), onSuccess);
          },
          getConsentStatus: () async {
            events.add('status');
            await Future<void>.delayed(const Duration(seconds: 2));
            return ConsentStatus.notRequired;
          },
          isConsentFormAvailable: () async {
            events.add('availability');
            await Future<void>.delayed(const Duration(seconds: 2));
            return false;
          },
          machineOperationTimeout: const Duration(seconds: 5),
          machineClock: () => async.elapsed,
        );
        bool? result;

        service.initialize().then((value) => result = value);
        async.elapse(const Duration(milliseconds: 4999));
        expect(result, isNull);

        async.elapse(const Duration(milliseconds: 1));
        expect(result, isFalse);
        expect(events, ['update', 'status', 'availability']);

        // Drain the availability result ignored after the shared timeout.
        async.elapse(const Duration(seconds: 1));
      });
    });

    test('a form loaded after the cumulative budget is never displayed', () {
      fakeAsync((async) {
        final form = _FakeConsentForm();
        final service = _service(
          requestConsentInfoUpdate: (_, onSuccess, _) {
            Future<void>.delayed(const Duration(seconds: 1), onSuccess);
          },
          getConsentStatus: () async {
            await Future<void>.delayed(const Duration(seconds: 1));
            return ConsentStatus.required;
          },
          isConsentFormAvailable: () async {
            await Future<void>.delayed(const Duration(seconds: 1));
            return true;
          },
          loadConsentForm: (onSuccess, _) {
            Future<void>.delayed(
              const Duration(seconds: 3),
              () => onSuccess(form),
            );
          },
          machineOperationTimeout: const Duration(seconds: 5),
          machineClock: () => async.elapsed,
        );
        bool? result;

        service.initialize().then((value) => result = value);
        async.elapse(const Duration(seconds: 5));

        expect(result, isFalse);
        expect(form.wasShown, isFalse);
        expect(form.wasDisposed, isFalse);

        async.elapse(const Duration(seconds: 1));
        expect(form.wasShown, isFalse);
        expect(form.wasDisposed, isTrue);
      });
    });

    testWidgets('a visible form waits for dismissal without a UI timeout', (
      tester,
    ) async {
      final form = _FakeConsentForm();
      final service = _service(
        getConsentStatus: () async => ConsentStatus.required,
        isConsentFormAvailable: () async => true,
        loadConsentForm: (onSuccess, _) => onSuccess(form),
        machineOperationTimeout: const Duration(seconds: 5),
      );
      bool? result;
      service.initialize().then((value) => result = value);

      await tester.pump();
      expect(form.wasShown, isTrue);
      expect(result, isNull);

      await tester.pump(const Duration(seconds: 61));
      expect(result, isNull);

      form.dismiss();
      await tester.pump();
      expect(result, isTrue);
      expect(form.wasDisposed, isTrue);
    });

    testWidgets('form disposal after dismissal cannot hold initialization', (
      tester,
    ) async {
      final disposeCompleter = Completer<void>();
      final form = _FakeConsentForm(disposeCompleter: disposeCompleter);
      final service = _service(
        getConsentStatus: () async => ConsentStatus.required,
        isConsentFormAvailable: () async => true,
        loadConsentForm: (onSuccess, _) => onSuccess(form),
      );
      bool? result;
      service.initialize().then((value) => result = value);

      await tester.pump();
      form.dismiss();
      await tester.pump();

      expect(form.wasDisposed, isTrue);
      expect(result, isTrue);
      disposeCompleter.complete();
      await tester.pump();
    });

    testWidgets('initialization waits for an in-flight native reset', (
      tester,
    ) async {
      final nativeReset = Completer<void>();
      var updateRequests = 0;
      final service = _service(
        requestConsentInfoUpdate: (_, onSuccess, _) {
          updateRequests++;
          onSuccess();
        },
        reset: () => nativeReset.future,
      );

      final resetFuture = service.reset();
      final initialization = service.initialize();
      await tester.pump();
      expect(updateRequests, 0);

      nativeReset.complete();
      await tester.pump();
      await expectLater(resetFuture, completes);
      await expectLater(initialization, completion(isTrue));
      expect(updateRequests, 1);
    });

    test('a failed attempt can be retried', () async {
      var statusReads = 0;
      final service = _service(
        getConsentStatus: () async {
          statusReads++;
          if (statusReads == 1) {
            throw StateError('transient status failure');
          }
          return ConsentStatus.notRequired;
        },
      );

      expect(await service.initialize(), isFalse);
      expect(await service.initialize(), isTrue);
      expect(statusReads, 2);
    });
  });

  group('ConsentService production UMP channel wiring', () {
    const channelName = 'picnic.test.ump.consent-service';
    final channel = MethodChannel(
      channelName,
      StandardMethodCodec(UserMessagingCodec()),
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    late UserMessagingChannel originalChannel;

    setUp(() {
      originalChannel = UserMessagingChannel.instance;
      UserMessagingChannel.instance = UserMessagingChannel(channel);
    });

    tearDown(() async {
      await ConsentService().reset();
      messenger.setMockMethodCallHandler(channel, null);
      UserMessagingChannel.instance = originalChannel;
    });

    testWidgets(
      'status channel failure settles false without an uncaught zone error',
      (tester) async {
        final zoneErrors = <Object>[];
        final calls = <String>[];
        messenger.setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          if (call.method == 'ConsentInformation#getConsentStatus') {
            throw PlatformException(code: 'test-status-failure');
          }
          return null;
        });
        bool? result;

        runZonedGuarded(() {
          ConsentService().initialize().then((value) => result = value);
        }, (error, _) => zoneErrors.add(error));
        await tester.pump();

        expect(calls, contains('ConsentInformation#getConsentStatus'));
        expect(zoneErrors, isEmpty);
        expect(result, isFalse);
      },
    );
  });
}

ConsentService _service({
  ConsentInfoUpdateRequester? requestConsentInfoUpdate,
  Future<ConsentStatus> Function()? getConsentStatus,
  Future<bool> Function()? isConsentFormAvailable,
  ConsentFormLoader? loadConsentForm,
  Future<void> Function()? reset,
  Duration machineOperationTimeout = const Duration(seconds: 1),
  Duration Function()? machineClock,
}) {
  return ConsentService.withSdk(
    sdk: ConsentSdk(
      requestConsentInfoUpdate:
          requestConsentInfoUpdate ??
          (_, onSuccess, _) {
            onSuccess();
          },
      getConsentStatus:
          getConsentStatus ?? (() async => ConsentStatus.notRequired),
      isConsentFormAvailable: isConsentFormAvailable ?? (() async => false),
      loadConsentForm:
          loadConsentForm ??
          (_, _) {
            throw StateError('loadConsentForm should not be called');
          },
      canRequestAds: () async => true,
      reset: reset ?? (() async {}),
      getPrivacyOptionsRequirementStatus: () async =>
          PrivacyOptionsRequirementStatus.notRequired,
    ),
    machineOperationTimeout: machineOperationTimeout,
    machineClock: machineClock,
  );
}

class _FakeConsentForm implements ConsentForm {
  _FakeConsentForm({this.disposeCompleter});

  final Completer<void>? disposeCompleter;
  bool wasShown = false;
  bool wasDisposed = false;
  OnConsentFormDismissedListener? _onDismissed;

  @override
  void show(OnConsentFormDismissedListener onConsentFormDismissedListener) {
    wasShown = true;
    _onDismissed = onConsentFormDismissedListener;
  }

  void dismiss([FormError? error]) {
    _onDismissed?.call(error);
  }

  @override
  Future<void> dispose() async {
    wasDisposed = true;
    await disposeCompleter?.future;
  }
}
