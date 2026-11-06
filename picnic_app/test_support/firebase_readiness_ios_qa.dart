// Run only through scripts/qa/run_firebase_device_ios.py, which copies this
// file into a disposable QA app (io.picnic.qa.firebaseReadiness) on an owned
// iOS simulator. The app has no GoogleService-Info.plist, no entitlements,
// and Firebase Messaging auto-init and data collection are off in Info.plist.
//
// Scope: real native Firebase Core on an iOS simulator, the real
// PushTokenService readiness guard, and the real MainInitializer core SDK
// stage group. Permission, FCM token and backend registration are replaced
// by a controlled test coordinator: the registered token is a fixed string,
// NOT proof of FCM or APNs registration. This test does not run
// MainInitializer.retrySdkInitialization, App or AppInitializer.
//
// Failure boundary (differs from Android): on iOS the failing Core stage
// calls Firebase.initializeApp() without options. In the installed sources
// (firebase_core 5.1.0, firebase_core_platform_interface 8.1.1) the native
// plugin configures a default app at launch only if default plist options
// exist, and the native initializeCore call only lists existing apps. So
// Dart makes a real native initializeCore call, which must report no apps,
// and then throws coreNotInitialized() (core/not-initialized) itself. That
// error is raised by Dart, not by a native configure call. A native
// configure with invalid options is not used, because the native SDK can
// raise an Objective-C exception there and stop the process.
//
// APNs: the installed firebase_messaging 17.0.1 iOS plugin requests APNs
// registration only when a native default app exists AND Messaging auto-init
// is enabled. The runner sets FirebaseMessagingAutoInitEnabled=false, and
// phase 3 asserts that auto-init is off once the default app exists. The
// controlled coordinator makes no real permission, token, or registration
// call.
//
// The native Firebase app is never deleted. It stays until the process
// exits, so no Firebase Installations deletion can race the test.
//
// The runner copies this file to integration_test/, where it is test code;
// the analyzer does not treat test_support/ as a test directory.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:picnic_lib/core/services/push_token_initialization_coordinator.dart';
import 'package:picnic_lib/core/services/push_token_service.dart';
import 'package:picnic_lib/core/utils/main_initializer.dart';
import 'package:picnic_lib/core/utils/startup_readiness.dart';

/// Demo values only. They identify no real Firebase project.
const _demoOptions = FirebaseOptions(
  // Synthetic. It only matches the format that native Firebase Installations
  // checks at configure time (39 characters, leading "A", [A-Za-z0-9_-]);
  // it is not a usable credential.
  apiKey: 'AqaDemoApiKeyNotAValidCredential0000000',
  appId: '1:000000000000:ios:0000000000000000',
  messagingSenderId: '000000000000',
  projectId: 'picnic-qa-demo',
  iosBundleId: 'io.picnic.qa.firebaseReadiness',
);

const _controlledToken = 'qa-controlled-token-not-fcm';
const _localLaunchUrl = 'https://applink.picnic.fan/vote/detail/9001';
const _initialMessageUrl = 'https://applink.picnic.fan/vote/detail/9002';
const _liveTapUrl = 'https://applink.picnic.fan/vote/detail/9003';

bool _hasDefaultApp() =>
    Firebase.apps.any((app) => app.name == defaultFirebaseAppName);

Future<void> _waitUntil(bool Function() condition, String what) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue, reason: 'timed out waiting for $what');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'iOS native Firebase readiness: deferred push setup, failed Core stage '
    'retry, and resume-only recovery',
    (tester) async {
      expect(defaultTargetPlatform, TargetPlatform.iOS);
      addTearDown(PushTokenService.debugResetForTest);
      final delivered = <String>[];
      void onTap(RemoteMessage message) =>
          delivered.add(message.data['action_url'] as String);
      var launchReads = 0;
      PushTokenService.debugUseLaunchPayloadReader(() async {
        launchReads++;
        return (
          didNotificationLaunchApp: true,
          payload: 'action_url: $_localLaunchUrl',
        );
      });

      // Phase 1 - no Firebase call has run yet. No coordinator factory is
      // installed, so a broken readiness guard reaches the production
      // coordinator and `FirebaseMessaging.instance` throws [core/no-app].
      expect(Firebase.apps, isEmpty);
      await PushTokenService.resume();
      await PushTokenService.resume();
      await PushTokenService.initialize(
        onNotificationTap: onTap,
        onActionUrlTap: delivered.add,
      );
      await PushTokenService.initialize(
        onNotificationTap: onTap,
        onActionUrlTap: delivered.add,
      );
      await PushTokenService.resume();
      expect(
        delivered,
        [_localLaunchUrl],
        reason: 'the local launch destination needs no Firebase, once',
      );
      expect(launchReads, 1);

      // Phase 2 - a Core stage that fails. See "Failure boundary" above: the
      // native app list is real, the rejection itself is raised in Dart.
      final stages = RetryableStartupStages();
      FirebaseOptions? stageOptions;
      var firebaseStageCalls = 0;
      var independentStageCalls = 0;
      Object? stageError;
      Future<void> runCoreGroup() => MainInitializer.initializeCoreSdkGroup(
            stages: stages,
            machineStages: {
              'qa-independent': () async {
                independentStageCalls++;
              },
              'firebase': () async {
                firebaseStageCalls++;
                try {
                  await Firebase.initializeApp(options: stageOptions);
                } catch (error) {
                  stageError = error;
                  rethrow;
                }
              },
            },
          );

      Object? groupError;
      try {
        await runCoreGroup();
      } catch (error) {
        groupError = error;
      }
      await _waitUntil(
        () => stages.isSuccessful('qa-independent'),
        'the independent stage',
      );
      expect(stageError, isA<FirebaseException>());
      final failure = stageError! as FirebaseException;
      debugPrint('QA_IOS_CORE_FAILURE=${failure.plugin}/${failure.code}');
      expect(failure.plugin, 'core');
      expect(failure.code, 'not-initialized', reason: 'coreNotInitialized()');
      expect(groupError, same(stageError), reason: 'the error is not hidden');
      expect(
        _hasDefaultApp(),
        isFalse,
        reason: 'native Core reported no default app after initializeCore',
      );
      expect(() => Firebase.app(), throwsA(isA<FirebaseException>()));
      expect(stages.isSuccessful('firebase'), isFalse);

      // Still not ready: the controlled factory must not be used yet.
      final probe = _CoordinatorProbe(
        initialMessage: RemoteMessage(data: {'action_url': _initialMessageUrl}),
      );
      addTearDown(probe.close);
      PushTokenService.debugUseCoordinatorFactory(probe.build);
      await PushTokenService.resume();
      await PushTokenService.initialize(
        onNotificationTap: onTap,
        onActionUrlTap: delivered.add,
      );
      expect(probe.factoryCalls, 0);

      // Phase 3 - retry the same stage group; only the Firebase stage runs.
      // This configures the real native default app with demo options.
      stageOptions = _demoOptions;
      await runCoreGroup();
      expect(firebaseStageCalls, 2);
      expect(independentStageCalls, 1);
      expect(stages.isSuccessful('firebase'), isTrue);
      expect(_hasDefaultApp(), isTrue);
      expect(Firebase.app().options.projectId, _demoOptions.projectId);
      expect(Firebase.app().options.appId, _demoOptions.appId);
      // The plugin's APNs gate. This reads the AUTO_INIT_ENABLED constant
      // that the native plugin reported when the app was configured; it
      // requests no token and no permission.
      expect(
        FirebaseMessaging.instance.isAutoInitEnabled,
        isFalse,
        reason: 'auto-init off keeps the plugin from requesting APNs',
      );
      await runCoreGroup();
      expect(firebaseStageCalls, 2, reason: 'a ready stage is not re-run');

      // Phase 4 - resume alone brings push up on the native default app.
      // The callbacks are the ones the earlier initialize installed.
      await PushTokenService.resume();
      await _waitUntil(
        () => delivered.contains(_initialMessageUrl),
        'the initial message',
      );
      expect(probe.factoryCalls, 1);
      expect(probe.permissionRequests, 0, reason: 'resume never prompts');
      expect(probe.permissionChecks, 1);
      expect(
        probe.registered,
        [_controlledToken],
        reason: 'controlled registration, not FCM server registration',
      );

      // Repeated calls keep one owner, and one-shot sources are not replayed.
      await PushTokenService.resume();
      await PushTokenService.resume();
      await PushTokenService.initialize(
        onNotificationTap: onTap,
        onActionUrlTap: delivered.add,
      );
      probe.openTap(RemoteMessage(data: {'action_url': _liveTapUrl}));
      await _waitUntil(
        () => delivered.contains(_liveTapUrl),
        'the live opened tap',
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(probe.factoryCalls, 1);
      expect(probe.initialMessageReads, 1);
      expect(launchReads, 1);
      expect(probe.registered, everyElement(_controlledToken));
      expect(delivered, [_localLaunchUrl, _initialMessageUrl, _liveTapUrl]);
    },
  );
}

/// Replaces only the permission, FCM token, message stream and backend
/// registration boundaries. The coordinator logic itself is the real one.
class _CoordinatorProbe {
  _CoordinatorProbe({required this.initialMessage});

  final RemoteMessage initialMessage;
  final StreamController<Object> _opened = StreamController<Object>.broadcast();

  int factoryCalls = 0;
  int permissionRequests = 0;
  int permissionChecks = 0;
  int initialMessageReads = 0;
  final List<String> registered = <String>[];

  void openTap(RemoteMessage message) => _opened.add(message);

  Future<void> close() => _opened.close();

  PushTokenInitializationCoordinator build() {
    factoryCalls++;
    return PushTokenInitializationCoordinator(
      PushInitializationDependencies(
        initializeLocalNotifications: () async {},
        requestPermission: () async {
          permissionRequests++;
          return PushPermissionStatus.granted;
        },
        checkPermission: () async {
          permissionChecks++;
          return PushPermissionStatus.granted;
        },
        getToken: () async => _controlledToken,
        subscribeToBroadcastTopic: () async {},
        registerToken: (token) async => registered.add(token),
        tokenRefreshes: const Stream.empty(),
        foregroundMessages: const Stream.empty(),
        openedMessages: _opened.stream,
        authChanges: const Stream.empty(),
        isSignedIn: () => true,
        isSignedInEvent: (_) => false,
        onForegroundMessage: (_) {},
        onOpenedMessage: (message) =>
            PushTokenService.debugHandleNotificationTap(
          message as RemoteMessage,
        ),
        getInitialMessage: () async {
          initialMessageReads++;
          return initialMessage;
        },
      ),
    );
  }
}
