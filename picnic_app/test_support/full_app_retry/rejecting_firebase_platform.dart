// QA-only Firebase platform wrapper for the full App retry harness
// (scripts/qa/run_full_app_retry_android.py). It is never part of the product.
// The runner copies it next to the integration test, where it is test code;
// the analyzer does not treat test_support/ as a test directory.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:firebase_core/firebase_core.dart';
// The platform interface that firebase_core resolves to (pinned by the lock).
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';

/// Rejects the first `Firebase.initializeApp` call before the wrapped
/// platform sees it, then forwards every later call unchanged.
///
/// `apps` and `app()` always come from the wrapped platform. On a device that
/// is the method channel platform, so a forwarded call is the real native
/// Firebase Core call and the rejected call never reaches native code.
class RejectingFirstInitializeFirebasePlatform extends FirebasePlatform {
  RejectingFirstInitializeFirebasePlatform(this.wrapped);

  final FirebasePlatform wrapped;

  /// Every `initializeApp` call, including the rejected one.
  int initializeAppCalls = 0;

  /// Calls that reached [wrapped].
  int forwardedCalls = 0;

  static FirebaseException rejection() => FirebaseException(
        plugin: 'core',
        code: 'unavailable',
        message: 'QA: the first Firebase.initializeApp is rejected before the '
            'native call',
      );

  @override
  List<FirebaseAppPlatform> get apps => wrapped.apps;

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) =>
      wrapped.app(name);

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) {
    initializeAppCalls++;
    if (initializeAppCalls == 1) {
      return Future<FirebaseAppPlatform>.error(rejection());
    }
    forwardedCalls++;
    return wrapped.initializeApp(name: name, options: options);
  }
}

/// The installed wrapper and the delegate it replaced.
class RejectingFirebaseInstall {
  RejectingFirebaseInstall._(this._previous, this.wrapper);

  final FirebasePlatform? _previous;
  final RejectingFirstInitializeFirebasePlatform wrapper;

  /// Puts back the previous delegate if the wrapper is still installed.
  ///
  /// Native Firebase apps are never deleted here; they stay until the
  /// process ends.
  void restore() {
    if (identical(Firebase.delegatePackingProperty, wrapper)) {
      Firebase.delegatePackingProperty = _previous;
    }
  }
}

/// Installs the wrapper around the current Firebase delegate.
RejectingFirebaseInstall installRejectingFirebasePlatform() {
  final previous = Firebase.delegatePackingProperty;
  final wrapper = RejectingFirstInitializeFirebasePlatform(
    previous ?? FirebasePlatform.instance,
  );
  Firebase.delegatePackingProperty = wrapper;
  return RejectingFirebaseInstall._(previous, wrapper);
}
