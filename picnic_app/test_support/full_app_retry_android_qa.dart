// Run only through scripts/qa/run_full_app_retry_android.py. The runner copies
// this file to integration_test/full_app_retry_test.dart (and full_app_retry/
// next to it) in a generated QA app, io.picnic.qa.full.picnic_app, that holds
// the product picnic_app lib (without main.dart and firebase_options.dart)
// and no google-services, config, Shorebird, env or signing file. The runner
// builds and inspects the APK, then runs it with `flutter drive
// --use-application-binary` and test_driver/full_app_retry_driver.dart; the
// result and binding.reportData reach the runner through that driver.
//
// One scenario per process. It runs the actual product chain:
//   MainInitializer.initializeApp -> real App (startupAttempt is null)
//   -> InitializationErrorScreen -> retry button
//   -> MainInitializer.retrySdkInitialization -> AppInitializer.initializeApp
//   -> PushTokenService.initialize.
//
// Controlled boundaries (and nothing else):
// - Firebase: the first Firebase.initializeApp is rejected by a wrapper before
//   any native call; the second is forwarded to the real native platform with
//   demo options that identify no real Firebase project.
// - Configuration: only the config/local.json and config/prod.json asset
//   reads are answered with synthetic values; every other asset is forwarded.
// - Backend: Supabase, storage, CDN and the Sentry DSN point at an in-process
//   loopback HTTP server that answers a small set of known startup requests.
// - Push: PushTokenService.debugUseCoordinatorFactory supplies the real
//   coordinator with controlled permission, token, registration and streams.
//   The registered token is a fixed string: NOT proof of FCM registration.
// - portalBuilder shows a marker instead of the Portal. It runs only after
//   App readiness, so it does not bypass the App startup or AppInitializer.
//   This test gives no Portal UI coverage.
//
// Not controlled: real DNS (google.com connectivity check), UMP/AdMob sample
// SDK, Branch, Tapjoy, Billing and native Sentry may run and use the network.
// This test does not claim zero native SDK traffic.
//
// Process ownership: the native Firebase app, Supabase auth timers and other
// static SDK state live in the app process on the device. They are not
// deleted here; they end when the runner force-stops and uninstalls the QA
// package after the run.
//
// The runner copies this file to integration_test/, where it is test code;
// the analyzer does not treat test_support/ as a test directory.
// ignore_for_file: invalid_use_of_visible_for_testing_member, avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
// picnic_lib's logger; only its log listener is used here.
// ignore: depend_on_referenced_packages
import 'package:logger/logger.dart';
import 'package:picnic_app/app.dart';
import 'package:picnic_lib/core/services/push_token_initialization_coordinator.dart';
import 'package:picnic_lib/core/services/push_token_service.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/utils/main_initializer.dart';
import 'package:picnic_lib/presentation/dialogs/force_update_overlay.dart';
import 'package:picnic_lib/presentation/screens/ban_screen.dart';
import 'package:picnic_lib/presentation/screens/initialization_error_screen.dart';
import 'package:picnic_lib/presentation/screens/network_error_screen.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'full_app_retry/loopback_backend.dart';
import 'full_app_retry/rejecting_firebase_platform.dart';

/// Demo values only. The API key is the reviewed synthetic, format-valid key
/// of the iOS probe; it is not a credential and names no real project.
const _demoOptions = FirebaseOptions(
  apiKey: 'AqaDemoApiKeyNotAValidCredential0000000',
  appId: '1:000000000000:android:0000000000000000',
  messagingSenderId: '000000000000',
  projectId: 'picnic-qa-demo',
);

const _controlledToken = 'qa-controlled-token-not-fcm';
const _readyKey = Key('qa-full-app-ready');
const _errorScreenKey = Key('initialization-error-screen');
const _retryButtonKey = Key('initialization-retry-button');

/// Product log messages observed as a cross-check only; counters and UI
/// decide every checkpoint.
const _zoneFatalMessage = '치명적 오류 발생';
const _appInitFailedMessage = '앱 초기화 중 오류 발생';

bool _hasDefaultApp() =>
    Firebase.apps.any((app) => app.name == defaultFirebaseAppName);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'full App: rejected first Firebase init, failure UI, retry, '
    'AppInitializer push initialize, resume recheck',
    (tester) async {
      final originalOnError = FlutterError.onError;
      final originalPlatformOnError = PlatformDispatcher.instance.onError;
      final originalDebugPrint = debugPrint;
      final originalZoneErrorsAreFatal = BindingBase.debugZoneErrorsAreFatal;
      final messenger = binding.defaultBinaryMessenger;
      final logs = _ProductLogWatch();
      final lifecycle = _LifecycleRecorder();
      final push = _PushProbe();
      LoopbackBackend? backend;
      RejectingFirebaseInstall? firebase;
      SyntheticConfigAssets? assets;
      var appStarted = false;
      final checkpoints = <String>[];
      final checkpointFacts = <String, Object?>{};
      var bodyCompleted = false;

      // The runner reads checkpoints from reportData through the driver;
      // this console line is a diagnostic copy only.
      void checkpoint(String name, Map<String, Object?> facts) {
        checkpoints.add(name);
        checkpointFacts[name] = facts;
        print('QA_FULL_APP_CHECKPOINT $name ${jsonEncode(facts)}');
      }

      Future<void> pumpFrame() =>
          tester.pump(const Duration(milliseconds: 100)).timeout(
                const Duration(seconds: 10),
                onTimeout: () => fail(
                  'no frame within 10 s (the device screen must stay on)',
                ),
              );

      Future<void> pumpUntil(
        bool Function() done,
        String what, {
        Duration timeout = const Duration(seconds: 60),
        String? Function()? blocker,
      }) async {
        final clock = Stopwatch()..start();
        while (!done()) {
          final blocked = blocker?.call();
          if (blocked != null) fail('$what: blocked by $blocked');
          if (clock.elapsed > timeout) {
            fail(
              'timed out after ${timeout.inSeconds} s waiting for $what; '
              'firebase=${firebase?.wrapper.initializeAppCalls}/'
              '${firebase?.wrapper.forwardedCalls} push=${push.describe()} '
              'loopback=${backend?.requests} '
              'unexpected=${backend?.unexpected} '
              'zoneFatal=${logs.zoneFatalTypes}',
            );
          }
          await pumpFrame();
        }
      }

      void resumeApp() {
        binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      }

      try {
        Logger.addLogListener(logs.onLog);
        binding.addObserver(lifecycle);

        backend = await LoopbackBackend.start(log: print);
        final configAssets = assets = SyntheticConfigAssets(
          local: syntheticLocalConfig(
            backend.base,
            sentryDsn: backend.sentryDsn,
          ),
          production: syntheticProductionConfig(),
        );
        messenger.setMockMessageHandler(
          'flutter/assets',
          (message) => configAssets.handle(
            message,
            (forwarded) => messenger.delegate.send('flutter/assets', forwarded),
          ),
        );
        firebase = installRejectingFirebasePlatform();
        PushTokenService.debugUseCoordinatorFactory(push.build);

        expect(Firebase.apps, isEmpty, reason: 'no Firebase app before start');

        // The production entry point with the product App. startupAttempt is
        // null, so App runs MainInitializer.sdkReady, then on retry
        // retrySdkInitialization and AppInitializer.initializeApp itself.
        appStarted = true;
        await MainInitializer.initializeApp(
          environment: 'local',
          firebaseOptions: _demoOptions,
          appBuilder: () => Phoenix(
            child: App(portalBuilder: (_) => const _ReadyMarker()),
          ),
        ).timeout(const Duration(seconds: 60));

        // A1 - the rejected Firebase stage shows the real failure UI.
        await pumpUntil(
          () => find.byKey(_errorScreenKey).evaluate().isNotEmpty,
          'the initialization error screen',
        );
        expect(configAssets.served, {
          'config/local.json': 1,
          'config/prod.json': 1,
        });
        expect(firebase.wrapper.initializeAppCalls, 1);
        expect(firebase.wrapper.forwardedCalls, 0);
        expect(_hasDefaultApp(), isFalse);
        expect(push.factoryCalls, 0);
        expect(
          logs.appInitErrors.whereType<FirebaseException>().map((e) => e.code),
          contains('unavailable'),
          reason: 'the failure shown is the rejected Firebase stage',
        );
        checkpoint('A1', {
          'firebaseCalls': firebase.wrapper.initializeAppCalls,
          'forwarded': firebase.wrapper.forwardedCalls,
          'defaultApp': _hasDefaultApp(),
          'factoryCalls': push.factoryCalls,
        });

        // A2 - a foreground before Firebase exists starts no push setup.
        final zoneFatalBeforeA2 = logs.zoneFatal;
        resumeApp();
        for (var i = 0; i < 10; i++) {
          await pumpFrame();
        }
        expect(push.factoryCalls, 0, reason: 'no coordinator before Firebase');
        expect(tester.takeException(), isNull);
        expect(
          logs.zoneFatal,
          zoneFatalBeforeA2,
          reason: 'no uncaught error in the product zone: '
              '${logs.zoneFatalTypes}',
        );
        expect(firebase.wrapper.initializeAppCalls, 1);
        expect(_hasDefaultApp(), isFalse);
        expect(find.byKey(_errorScreenKey), findsOneWidget);
        checkpoint('A2', {'factoryCalls': push.factoryCalls});

        // A3 - the real retry button runs the second Firebase call natively.
        lifecycle.states.clear();
        final zoneFatalBeforeRetry = logs.zoneFatal;
        await tester.tap(find.byKey(_retryButtonKey));
        await pumpUntil(
          () => firebase!.wrapper.forwardedCalls == 1 && _hasDefaultApp(),
          'the forwarded native Firebase initialization',
        );
        expect(firebase.wrapper.initializeAppCalls, 2);
        expect(Firebase.app().options.projectId, _demoOptions.projectId);
        expect(
          FirebaseMessaging.instance.isAutoInitEnabled,
          isFalse,
          reason: 'the manifest disables Messaging auto-init',
        );
        checkpoint('A3', {
          'firebaseCalls': firebase.wrapper.initializeAppCalls,
          'forwarded': firebase.wrapper.forwardedCalls,
          'defaultApp': _hasDefaultApp(),
          'messagingAutoInit': FirebaseMessaging.instance.isAutoInitEnabled,
        });

        // A4 - with no resume since the retry, the App reaches readiness and
        // AppInitializer's background push initialize runs exactly once.
        await pumpUntil(
          () =>
              find.byKey(_readyKey).evaluate().isNotEmpty &&
              push.factoryCalls == 1 &&
              push.registered.length == 1,
          'App readiness and AppInitializer push initialize',
          timeout: const Duration(seconds: 120),
          blocker: _blockingScreen,
        );
        expect(
          lifecycle.states,
          isNot(contains(AppLifecycleState.resumed)),
          reason: 'a platform resume would make this resume-origin evidence',
        );
        expect(push.permissionRequests, 1, reason: 'only initialize prompts');
        expect(push.permissionChecks, 0, reason: 'no resume reached push');
        expect(push.registered, [_controlledToken]);
        checkpoint('A4', {
          'ready': true,
          'factoryCalls': push.factoryCalls,
          'permissionRequests': push.permissionRequests,
          'permissionChecks': push.permissionChecks,
          'registered': push.registered.length,
          'platformLifecycle': lifecycle.states.map((s) => s.name).toList(),
        });

        // A5 - a foreground re-checks permission on the same coordinator.
        resumeApp();
        await pumpUntil(
          () => push.permissionChecks == 1 && push.registered.length == 2,
          'the resume permission check',
        );
        expect(push.factoryCalls, 1, reason: 'the coordinator is reused');
        expect(push.permissionRequests, 1);
        expect(push.registered, everyElement(_controlledToken));

        // No late third Firebase initialization and no new failure UI.
        for (var i = 0; i < 20; i++) {
          await pumpFrame();
        }
        expect(firebase.wrapper.initializeAppCalls, 2);
        expect(firebase.wrapper.forwardedCalls, 1);
        expect(find.byKey(_readyKey), findsOneWidget);
        expect(find.byKey(_errorScreenKey), findsNothing);
        expect(tester.takeException(), isNull);
        checkpoint('A5', {
          'factoryCalls': push.factoryCalls,
          'permissionRequests': push.permissionRequests,
          'permissionChecks': push.permissionChecks,
          'registered': push.registered.length,
          'firebaseCalls': firebase.wrapper.initializeAppCalls,
          'zoneFatalSinceRetry': logs.zoneFatal - zoneFatalBeforeRetry,
        });

        // Unmounting App disposes the push owner and its subscriptions.
        await tester.pumpWidget(const SizedBox.shrink());
        appStarted = false;
        await pumpUntil(
          () => push.cancelledStreams == 4,
          'push subscription cleanup after App dispose',
          timeout: const Duration(seconds: 10),
        );
        checkpoint('cleanup', {'cancelledStreams': push.cancelledStreams});
        expect(checkpoints, ['A1', 'A2', 'A3', 'A4', 'A5', 'cleanup']);
        bodyCompleted = true;
      } finally {
        if (appStarted) {
          try {
            await tester.pumpWidget(const SizedBox.shrink());
          } catch (error) {
            print('QA_FULL_APP_TEARDOWN unmount ${error.runtimeType}');
          }
        }
        await PushTokenService.debugResetForTest();
        AppInitializer.resetSupabaseAuthListenerForTest();
        try {
          await Supabase.instance.dispose().timeout(const Duration(seconds: 5));
        } catch (error) {
          print('QA_FULL_APP_TEARDOWN supabase ${error.runtimeType}');
        }
        try {
          await Sentry.close().timeout(const Duration(seconds: 5));
        } catch (error) {
          print('QA_FULL_APP_TEARDOWN sentry ${error.runtimeType}');
        }
        firebase?.restore();
        messenger.setMockMessageHandler('flutter/assets', null);
        final summary = <String, Object?>{
          'loopbackRequests': backend?.requests,
          'loopbackUnexpected': backend?.unexpected,
          'configServed': assets?.served,
          'configRefused': assets?.refused,
          'zoneFatalTypes': logs.zoneFatalTypes,
          'firebaseApps': Firebase.apps.map((app) => app.name).toList(),
        };
        // Delivered to the host driver with the test result (also on
        // failure). The overall pass/fail is the binding's, not this map's.
        binding.reportData = <String, dynamic>{
          'checkpoints': checkpoints,
          'facts': checkpointFacts,
          'summary': summary,
          'bodyCompleted': bodyCompleted,
        };
        print('QA_FULL_APP_SUMMARY ${jsonEncode(summary)}');
        await backend?.close();
        Logger.removeLogListener(logs.onLog);
        binding.removeObserver(lifecycle);
        push.close();
        // Product startup and Sentry replace these process-wide handlers.
        FlutterError.onError = originalOnError;
        PlatformDispatcher.instance.onError = originalPlatformOnError;
        debugPrint = originalDebugPrint;
        BindingBase.debugZoneErrorsAreFatal = originalZoneErrorsAreFatal;
      }
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

/// A screen that ends the wait with a classified, non-Firebase cause.
String? _blockingScreen() {
  if (find.byType(NetworkErrorScreen).evaluate().isNotEmpty) {
    return 'the network error screen (connectivity check, not Firebase)';
  }
  if (find.byType(ForceUpdateOverlay).evaluate().isNotEmpty) {
    return 'the force update screen (loopback version policy)';
  }
  if (find.byType(BanScreen).evaluate().isNotEmpty) {
    return 'the ban screen';
  }
  if (find.byType(InitializationErrorScreen).evaluate().isNotEmpty) {
    return 'the initialization error screen again after the retry';
  }
  return null;
}

class _ReadyMarker extends StatelessWidget {
  const _ReadyMarker();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('qa-ready', key: _readyKey)));
}

/// Observes picnic_lib log events. Only error types are kept, not messages.
class _ProductLogWatch {
  int zoneFatal = 0;
  final List<String> zoneFatalTypes = <String>[];
  final List<Object> appInitErrors = <Object>[];

  void onLog(LogEvent event) {
    final message = event.message;
    if (message == _zoneFatalMessage) {
      zoneFatal++;
      zoneFatalTypes.add('${event.error.runtimeType}');
    } else if (message == _appInitFailedMessage && event.error != null) {
      appInitErrors.add(event.error!);
    }
  }
}

class _LifecycleRecorder with WidgetsBindingObserver {
  final List<AppLifecycleState> states = <AppLifecycleState>[];

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => states.add(state);
}

/// Replaces only the permission, FCM token, message stream and backend
/// registration boundaries. The coordinator logic itself is the real one.
class _PushProbe {
  int factoryCalls = 0;
  int permissionRequests = 0;
  int permissionChecks = 0;
  int cancelledStreams = 0;
  final List<String> registered = <String>[];
  final List<StreamController<Object>> _controllers = [];

  String describe() => 'factory=$factoryCalls requests=$permissionRequests '
      'checks=$permissionChecks registered=${registered.length}';

  Stream<T> _stream<T extends Object>() {
    final controller = StreamController<T>(
      onCancel: () => cancelledStreams++,
    );
    _controllers.add(controller);
    return controller.stream;
  }

  void close() {
    for (final controller in _controllers) {
      unawaited(controller.close());
    }
  }

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
        tokenRefreshes: _stream<String>(),
        foregroundMessages: _stream<Object>(),
        openedMessages: _stream<Object>(),
        authChanges: _stream<Object>(),
        isSignedIn: () => true,
        isSignedInEvent: (_) => false,
        onForegroundMessage: (_) {},
        onOpenedMessage: (_) {},
        getInitialMessage: () async => null,
      ),
    );
  }
}
