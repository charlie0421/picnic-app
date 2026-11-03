// Run only through scripts/qa/run_firebase_device_android.py, which copies
// this file into a disposable QA package (io.picnic.qa.firebase_readiness)
// that has no google-services configuration.
//
// Scope: real native Firebase Core on an Android device, the real
// PushTokenService readiness guard, and the real MainInitializer core SDK
// stage group. Permission, FCM token and backend registration are replaced
// by a controlled test coordinator: the registered token is a fixed string,
// NOT proof of FCM server registration. This test does not run
// MainInitializer.retrySdkInitialization, App or AppInitializer.
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
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:picnic_lib/core/services/push_token_initialization_coordinator.dart';
import 'package:picnic_lib/core/services/push_token_service.dart';
import 'package:picnic_lib/core/utils/main_initializer.dart';
import 'package:picnic_lib/core/utils/startup_readiness.dart';

/// Demo values only. They identify no real Firebase project.
const _demoOptions = FirebaseOptions(
  apiKey: 'qa-demo-api-key-not-valid',
  appId: '1:000000000000:android:0000000000000000',
  messagingSenderId: '000000000000',
  projectId: 'picnic-qa-demo',
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
    'native Firebase readiness: deferred push setup, failed Core stage '
    'retry, and resume-only recovery',
    (tester) async {
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

      // Phase 2 - a Core stage that fails on the real native platform.
      // Without options and without google-services resources, Android
      // Firebase cannot load default options. This is the missing-config
      // error path; production passes fixed options, so its transient
      // failure modes are not reproduced here.
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
      expect(stageError, isNotNull, reason: 'the native Core call must fail');
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
      stageOptions = _demoOptions;
      await runCoreGroup();
      expect(firebaseStageCalls, 2);
      expect(independentStageCalls, 1);
      expect(stages.isSuccessful('firebase'), isTrue);
      expect(_hasDefaultApp(), isTrue);
      expect(Firebase.app().options.projectId, _demoOptions.projectId);
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
