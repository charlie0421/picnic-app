import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/tapjoy_failure.dart';

/// PICNIC-APP-5KT / 5KN / 5KA: Tapjoy failures reached Sentry as raw
/// strings ("String", "String: The network connection was lost.",
/// "String: 10s 안에 응답이 오지 않음"). A raw string has no stage, no kind and
/// no retry hint, and the SDK text is not a closed value.
///
/// The plugin passes only a message string for these callbacks (Android
/// `TJError.message`, iOS `localizedDescription`); it drops the SDK error
/// code. A report therefore carries closed values only: stage, kind, whether
/// the SDK gave a message, a channel error code when there is one, a retry
/// hint and the network type.
void main() {
  group('TapjoyFailure.classify', () {
    test('records only whether the SDK gave a message', () {
      TapjoyFailure classify(Object? sdkError) => TapjoyFailure.classify(
        stage: TapjoyFailureStage.setUserId,
        kind: TapjoyFailureKind.sdkFailure,
        sdkError: sdkError,
      );

      expect(classify(null).sdkMessage, 'none');
      expect(classify('').sdkMessage, 'empty');
      expect(classify('   ').sdkMessage, 'empty');
      expect(
        classify('The network connection was lost.').sdkMessage,
        'present',
      );
    });

    test('keeps a channel error code only in a closed form', () {
      TapjoyFailure classify(Object error) => TapjoyFailure.classify(
        stage: TapjoyFailureStage.setUserId,
        kind: TapjoyFailureKind.channelFailure,
        sdkError: error,
      );

      expect(
        classify(PlatformException(code: 'channel-error')).code,
        'platform:channel-error',
      );
      expect(
        classify(PlatformException(code: 'user 1234 https://x.y/?a=b')).code,
        'platform:invalid',
      );
      expect(
        classify(MissingPluginException('no impl')).code,
        'missing_plugin',
      );
      expect(classify(StateError('x')).code, isNull);
      expect(
        TapjoyFailure.classify(
          stage: TapjoyFailureStage.placementRequest,
          kind: TapjoyFailureKind.sdkFailure,
          sdkError: 'some text',
        ).code,
        isNull,
      );
    });

    test('derives the retry hint from the kind', () {
      String retryable(TapjoyFailureKind kind) => TapjoyFailure.classify(
        stage: TapjoyFailureStage.setUserId,
        kind: kind,
      ).retryable;

      expect(retryable(TapjoyFailureKind.timeout), 'yes');
      expect(retryable(TapjoyFailureKind.busy), 'yes');
      expect(retryable(TapjoyFailureKind.noUser), 'no');
      expect(retryable(TapjoyFailureKind.otherAccountPending), 'no');
      expect(retryable(TapjoyFailureKind.sdkFailure), 'unknown');
      expect(retryable(TapjoyFailureKind.channelFailure), 'unknown');
      expect(retryable(TapjoyFailureKind.missingPlacement), 'unknown');
    });

    test('tags and the Sentry exception hold no SDK text', () {
      const text = 'The network connection was lost. user 1234';
      final failure = TapjoyFailure.classify(
        stage: TapjoyFailureStage.setUserId,
        kind: TapjoyFailureKind.sdkFailure,
        sdkError: text,
        connectivity: const [ConnectivityResult.mobile],
      );

      expect(failure.tags, {
        'platform': 'Tapjoy',
        'tapjoy_stage': 'setUserId',
        'tapjoy_kind': 'sdkFailure',
        'tapjoy_sdk_message': 'present',
        'tapjoy_retryable': 'unknown',
        'network': 'mobile',
      });
      expect(failure.fingerprint, [
        'tapjoy-failure',
        'setUserId',
        'sdkFailure',
      ]);

      final exception = failure.toSentryException().toString();
      expect(exception, contains('setUserId'));
      expect(exception, contains('sdkFailure'));
      expect(exception, isNot(contains('network connection')));
      expect(exception, isNot(contains('1234')));
    });

    test('adds the code tag only when there is a code', () {
      final failure = TapjoyFailure.classify(
        stage: TapjoyFailureStage.setUserId,
        kind: TapjoyFailureKind.channelFailure,
        sdkError: PlatformException(code: 'channel-error'),
      );

      expect(failure.tags['tapjoy_code'], 'platform:channel-error');
      expect(
        TapjoyFailure.classify(
          stage: TapjoyFailureStage.setUserId,
          kind: TapjoyFailureKind.timeout,
        ).tags.containsKey('tapjoy_code'),
        isFalse,
      );
    });
  });

  group('sendTapjoyFailureReport', () {
    final failure = TapjoyFailure.classify(
      stage: TapjoyFailureStage.setUserId,
      kind: TapjoyFailureKind.timeout,
    );

    test('adds the network type before it sends', () async {
      final sent = <TapjoyFailure>[];
      await sendTapjoyFailureReport(
        failure,
        checkConnectivity: () async => const [ConnectivityResult.none],
        send: (f) async => sent.add(f),
      );

      expect(sent.single.network, 'none');
      expect(sent.single.kind, TapjoyFailureKind.timeout);
    });

    test('sends with an unknown network when the lookup fails', () async {
      final sent = <TapjoyFailure>[];
      await sendTapjoyFailureReport(
        failure,
        checkConnectivity: () async => throw StateError('no plugin'),
        send: (f) async => sent.add(f),
      );

      expect(sent.single.network, 'unknown');
    });

    test('never throws when sending fails', () async {
      await expectLater(
        sendTapjoyFailureReport(
          failure,
          checkConnectivity: () async => const [ConnectivityResult.wifi],
          send: (_) async => throw StateError('sentry down'),
        ),
        completes,
      );
    });
  });
}
