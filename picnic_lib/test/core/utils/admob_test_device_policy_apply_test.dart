import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/admob_test_device_policy.dart';

/// Verifies the applier half of [AdMobTestDevicePolicy] against a mocked
/// google_mobile_ads method channel: it must forward exactly the resolved ids
/// (and nothing else) so native-side merging keeps every other
/// RequestConfiguration field (tags, content rating) untouched.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/google_mobile_ads');
  const raw = String.fromEnvironment(AdMobTestDevicePolicy.environmentKey);

  late List<MethodCall> calls;

  List<MethodCall> configCalls() => calls
      .where((call) => call.method == 'MobileAds#updateRequestConfiguration')
      .toList();

  setUp(() {
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('AdMobTestDevicePolicy.applyIds', () {
    test(
      'does not touch the request configuration when ids are null',
      () async {
        await AdMobTestDevicePolicy.applyIds(null);

        expect(configCalls(), isEmpty);
      },
    );

    test('registers exactly the given ids, in order and case', () async {
      await AdMobTestDevicePolicy.applyIds(const ['abc123', 'DEF456']);

      final updates = configCalls();
      expect(updates, hasLength(1));
      final args = Map<String, dynamic>.from(updates.single.arguments as Map);
      expect(args['testDeviceIds'], equals(['abc123', 'DEF456']));
    });

    test(
      'leaves every other RequestConfiguration field unset (null)',
      () async {
        await AdMobTestDevicePolicy.applyIds(const ['abc123']);

        final args = Map<String, dynamic>.from(
          configCalls().single.arguments as Map,
        );
        expect(args['maxAdContentRating'], isNull);
        expect(args['tagForChildDirectedTreatment'], isNull);
        expect(args['tagForUnderAgeOfConsent'], isNull);
      },
    );
  });

  group('AdMobTestDevicePolicy.apply', () {
    test(
      'is a no-op when ADMOB_TEST_DEVICE_IDS is absent (default test run)',
      () async {
        await AdMobTestDevicePolicy.apply();

        expect(configCalls(), isEmpty);
      },
      skip: raw.isNotEmpty
          ? 'ADMOB_TEST_DEVICE_IDS is set in this run; see wiring test'
          : false,
    );

    test(
      'forwards the resolved define ids to the request configuration',
      () async {
        await AdMobTestDevicePolicy.apply();

        final expected = AdMobTestDevicePolicy.testDeviceIds;
        final updates = configCalls();
        if (expected == null) {
          expect(updates, isEmpty);
        } else {
          expect(updates, hasLength(1));
          final args = Map<String, dynamic>.from(
            updates.single.arguments as Map,
          );
          expect(args['testDeviceIds'], equals(expected));
        }
      },
    );
  });
}
