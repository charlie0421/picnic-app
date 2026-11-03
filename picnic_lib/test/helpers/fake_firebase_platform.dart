import 'package:firebase_core/firebase_core.dart';
// The platform interface that firebase_core itself resolves to, so the
// version is the one pubspec.lock already pins.
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gives the current test an empty in-memory Firebase platform and restores
/// the previous platform when the test ends.
///
/// No app is configured natively, so `Firebase.apps` holds only the apps that
/// the test initializes. The first [initializeAppFailures] calls to
/// `Firebase.initializeApp()` throw [FakeFirebasePlatform.failure].
FakeFirebasePlatform installFakeFirebasePlatform({
  int initializeAppFailures = 0,
}) {
  final previous = Firebase.delegatePackingProperty;
  final platform = FakeFirebasePlatform(
    initializeAppFailures: initializeAppFailures,
  );
  Firebase.delegatePackingProperty = platform;
  addTearDown(() => Firebase.delegatePackingProperty = previous);
  return platform;
}

/// `Firebase.apps`, `Firebase.app()` and `Firebase.initializeApp()` behave as
/// the method channel platform does for these calls, including the
/// `[core/no-app]` error that `FirebaseMessaging.instance` raises.
class FakeFirebasePlatform extends FirebasePlatform {
  FakeFirebasePlatform({int initializeAppFailures = 0})
    : _remainingFailures = initializeAppFailures;

  final Map<String, FirebaseAppPlatform> _apps = {};
  int _remainingFailures;

  /// Calls to `Firebase.initializeApp()`, including failed ones.
  int initializeAppCalls = 0;

  /// The error and stack trace that a failing call threw.
  final FirebaseException failure = FirebaseException(
    plugin: 'core',
    code: 'unavailable',
    message: 'Firebase is not available yet',
  );
  final StackTrace failureStackTrace = StackTrace.current;

  @override
  List<FirebaseAppPlatform> get apps => List.unmodifiable(_apps.values);

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    initializeAppCalls++;
    if (_remainingFailures > 0) {
      _remainingFailures--;
      Error.throwWithStackTrace(failure, failureStackTrace);
    }
    final appName = name ?? defaultFirebaseAppName;
    final existing = _apps[appName];
    if (existing != null) return existing;
    if (options == null) throw StateError('options are required');
    return _apps[appName] = FirebaseAppPlatform(appName, options);
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    final app = _apps[name];
    if (app != null) return app;
    throw FirebaseException(
      plugin: 'core',
      code: 'no-app',
      message: "No Firebase App '$name' has been created",
    );
  }
}

const testFirebaseOptions = FirebaseOptions(
  apiKey: 'test-api-key',
  appId: '1:1234567890:android:0000000000000000',
  messagingSenderId: '1234567890',
  projectId: 'picnic-test',
);
