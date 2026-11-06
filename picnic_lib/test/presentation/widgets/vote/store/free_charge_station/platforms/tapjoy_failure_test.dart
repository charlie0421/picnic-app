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
        'tapjoy_cause': 'network',
        'tapjoy_retryable': 'yes',
        'network': 'mobile',
      });
      expect(failure.fingerprint, [
        'tapjoy-failure',
        'setUserId',
        'sdkFailure',
        'network',
      ]);

      final exception = failure.toSentryException().toString();
      expect(exception, contains('setUserId'));
      expect(exception, contains('sdkFailure'));
      expect(exception, isNot(contains('network connection')));
      expect(exception, isNot(contains('1234')));
    });

    test('derives a closed cause from the SDK text without keeping it', () {
      TapjoyFailure classify(Object? sdkError) => TapjoyFailure.classify(
        stage: TapjoyFailureStage.placementRequest,
        kind: TapjoyFailureKind.sdkFailure,
        sdkError: sdkError,
      );

      expect(classify(null).cause, TapjoyFailureCause.none);
      expect(classify('').cause, TapjoyFailureCause.none);
      expect(
        classify('The network connection was lost.').cause,
        TapjoyFailureCause.network,
      );
      expect(
        classify('The Internet connection appears to be offline.').cause,
        TapjoyFailureCause.network,
      );
      expect(
        classify('The request timed out.').cause,
        TapjoyFailureCause.network,
      );
      expect(
        classify('{"code":500,"reason":"Internal server error"}').cause,
        TapjoyFailureCause.server,
      );
      expect(
        classify('{"error":"Internal error occured."}').cause,
        TapjoyFailureCause.server,
      );
      expect(classify('<html>').cause, TapjoyFailureCause.server);
      expect(
        classify('SDK not connected -- connect must be called first').cause,
        TapjoyFailureCause.sdkNotReady,
      );
      expect(classify('something else').cause, TapjoyFailureCause.unknown);
    });

    test('keeps only a 3-digit server code from a JSON body', () {
      String? code(String text) => TapjoyFailure.classify(
        stage: TapjoyFailureStage.placementRequest,
        kind: TapjoyFailureKind.sdkFailure,
        sdkError: text,
      ).serverCode;

      expect(code('{"code":500,"reason":"Internal server error"}'), '500');
      expect(code('{"code": 503}'), '503');
      expect(code('{"code":99}'), isNull);
      expect(code('{"code":700}'), isNull);
      expect(code('{"error":"Internal error occured."}'), isNull);
      expect(code('<html>'), isNull);
    });

    test('a network or server cause is retryable', () {
      String retryable(String text) => TapjoyFailure.classify(
        stage: TapjoyFailureStage.placementRequest,
        kind: TapjoyFailureKind.sdkFailure,
        sdkError: text,
      ).retryable;

      expect(retryable('The network connection was lost.'), 'yes');
      expect(retryable('{"code":500}'), 'yes');
      expect(retryable('something else'), 'unknown');
    });

    test('tags carry the cause and the server code, never the text', () {
      final failure = TapjoyFailure.classify(
        stage: TapjoyFailureStage.placementRequest,
        kind: TapjoyFailureKind.sdkFailure,
        sdkError: '{"code":500,"reason":"Internal server error"}',
      );

      expect(failure.tags['tapjoy_cause'], 'server');
      expect(failure.tags['tapjoy_server_code'], '500');
      expect(failure.fingerprint, [
        'tapjoy-failure',
        'placementRequest',
        'sdkFailure',
        'server',
      ]);
      expect(
        failure.tags.values.join(' '),
        isNot(contains('Internal server error')),
      );
    });

    test('the old global filter decision is preserved', () {
      expect(
        TapjoyFailure.droppedByGlobalFilter('Failed host lookup: x'),
        isTrue,
      );
      expect(
        TapjoyFailure.droppedByGlobalFilter('Connection reset by peer'),
        isTrue,
      );
      expect(
        TapjoyFailure.droppedByGlobalFilter('The network connection was lost.'),
        isFalse,
      );
      expect(TapjoyFailure.droppedByGlobalFilter('{"code":500}'), isFalse);
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
