// Host tests for the Firebase wrapper used by the full App retry QA harness.
// They use a recording in-memory platform; no native Firebase runs here.
import 'package:firebase_core/firebase_core.dart';
// The platform interface that firebase_core resolves to (pinned by the lock).
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_support/full_app_retry/rejecting_firebase_platform.dart';

const _options = FirebaseOptions(
  apiKey: 'AqaDemoApiKeyNotAValidCredential0000000',
  appId: '1:000000000000:android:0000000000000000',
  messagingSenderId: '000000000000',
  projectId: 'picnic-qa-demo',
);

void main() {
  late _RecordingPlatform real;
  late FirebasePlatform? original;

  setUp(() {
    original = Firebase.delegatePackingProperty;
    real = _RecordingPlatform();
    Firebase.delegatePackingProperty = real;
  });

  tearDown(() => Firebase.delegatePackingProperty = original);

  test(
      'the first initializeApp is rejected without reaching the platform, '
      'later calls forward name and options unchanged', () async {
    final install = installRejectingFirebasePlatform();
    addTearDown(install.restore);

    await expectLater(
      Firebase.initializeApp(options: _options),
      throwsA(
        isA<FirebaseException>()
            .having((e) => e.plugin, 'plugin', 'core')
            .having((e) => e.code, 'code', 'unavailable'),
      ),
    );
    expect(install.wrapper.initializeAppCalls, 1);
    expect(install.wrapper.forwardedCalls, 0);
    expect(real.calls, isEmpty, reason: 'rejected before the platform call');
    expect(Firebase.apps, isEmpty);

    final app = await Firebase.initializeApp(options: _options);
    expect(app.name, defaultFirebaseAppName);
    expect(real.calls, [(name: null, options: _options)]);

    await Firebase.initializeApp(name: 'secondary', options: _options);
    expect(real.calls.last, (name: 'secondary', options: _options));
    expect(install.wrapper.initializeAppCalls, 3);
    expect(install.wrapper.forwardedCalls, 2);
    expect(
      Firebase.apps.map((app) => app.name),
      [defaultFirebaseAppName, 'secondary'],
      reason: 'apps come from the wrapped platform',
    );
    expect(Firebase.app().options, _options);
  });

  test('an error of a forwarded call reaches the caller unchanged', () async {
    final install = installRejectingFirebasePlatform();
    addTearDown(install.restore);
    final failure = FirebaseException(plugin: 'core', code: 'native-failure');
    real.nextError = failure;

    await expectLater(
        Firebase.initializeApp(options: _options), throwsA(anything));
    await expectLater(
      Firebase.initializeApp(options: _options),
      throwsA(same(failure)),
    );
    expect(real.calls, hasLength(1));
    expect(
      () => Firebase.app(),
      throwsA(isA<FirebaseException>().having((e) => e.code, 'code', 'no-app')),
    );
  });

  test('restore puts back the previous delegate only while it is installed',
      () {
    final install = installRejectingFirebasePlatform();
    expect(Firebase.delegatePackingProperty, same(install.wrapper));

    install.restore();
    expect(Firebase.delegatePackingProperty, same(real));

    // A later owner is never replaced by a stale restore.
    final later = _RecordingPlatform();
    Firebase.delegatePackingProperty = later;
    install.restore();
    expect(Firebase.delegatePackingProperty, same(later));
  });
}

class _RecordingPlatform extends FirebasePlatform {
  final Map<String, FirebaseAppPlatform> _apps = {};
  final List<({String? name, FirebaseOptions? options})> calls = [];
  Object? nextError;

  @override
  List<FirebaseAppPlatform> get apps => List.unmodifiable(_apps.values);

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    final app = _apps[name];
    if (app != null) return app;
    throw FirebaseException(plugin: 'core', code: 'no-app');
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    calls.add((name: name, options: options));
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    final appName = name ?? defaultFirebaseAppName;
    return _apps[appName] ??= FirebaseAppPlatform(appName, options!);
  }
}
