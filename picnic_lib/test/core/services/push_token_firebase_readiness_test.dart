import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/push_token_initialization_coordinator.dart';
import 'package:picnic_lib/core/services/push_token_service.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/fake_firebase_platform.dart';

/// Push setup that runs before `Firebase.initializeApp()` has created the
/// `[DEFAULT]` app must not touch `FirebaseMessaging.instance`, which throws
/// `[core/no-app]` (Sentry: `PushTokenService.resume` on app resume).
///
/// Every test gets its own empty Firebase platform, so the tests do not
/// depend on their order (`--test-randomize-ordering-seed`, `--name`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(installFakeFirebasePlatform);
  tearDown(PushTokenService.debugResetForTest);

  group('without a default Firebase app', () {
    // Catches: a coordinator that is created before the readiness check, so
    // `FirebaseMessaging.instance` throws `[core/no-app]` (the Sentry crash).
    test('resume does not reach Firebase Messaging', () async {
      await expectLater(PushTokenService.resume(), completes);
      await expectLater(PushTokenService.resume(), completes);
    });

    // Catches: the same crash from the `initialize` path.
    test('initialize does not reach Firebase Messaging', () async {
      PushTokenService.debugUseLaunchPayloadReader(
        () async => (didNotificationLaunchApp: false, payload: null),
      );

      await expectLater(
        PushTokenService.initialize(onActionUrlTap: (_) {}),
        completes,
      );
    });

    // Catches: a readiness check that is skipped when a test factory is set.
    test(
      'a test coordinator factory does not bypass the readiness check',
      () async {
        final probe = _CoordinatorProbe();
        PushTokenService.debugUseCoordinatorFactory(probe.build);
        PushTokenService.debugUseLaunchPayloadReader(
          () async => (didNotificationLaunchApp: false, payload: null),
        );

        await PushTokenService.resume();
        await PushTokenService.initialize(onActionUrlTap: (_) {});

        expect(probe.factoryCalls, 0);
      },
    );

    // Catches: a readiness check of `Firebase.apps.isNotEmpty`.
    test(
      'a secondary app alone is not the default app Messaging needs',
      () async {
        await Firebase.initializeApp(name: 'secondary', options: _options);
        expect(Firebase.apps.map((app) => app.name), ['secondary']);
        final probe = _CoordinatorProbe();
        PushTokenService.debugUseCoordinatorFactory(probe.build);
        PushTokenService.debugUseLaunchPayloadReader(
          () async => (didNotificationLaunchApp: false, payload: null),
        );

        await PushTokenService.resume();
        await PushTokenService.initialize(onActionUrlTap: (_) {});
        expect(probe.factoryCalls, 0);

        await PushTokenService.debugResetForTest();
        await expectLater(PushTokenService.resume(), completes);
      },
    );
  });

  group('once the default Firebase app is created later', () {
    // Catches: a not-ready call that latches push setup off, and one-shot
    // destinations that are lost or delivered twice across the transition.
    test('the next initialize starts push setup', () async {
      final probe = _CoordinatorProbe()
        ..initialMessage = _tapFor('https://applink.picnic.fan/vote/detail/3');
      PushTokenService.debugUseCoordinatorFactory(probe.build);
      var launchReads = 0;
      PushTokenService.debugUseLaunchPayloadReader(() async {
        launchReads++;
        return (
          didNotificationLaunchApp: true,
          payload: 'action_url: https://applink.picnic.fan/vote/detail/1',
        );
      });
      final delivered = <String>[];
      void deliverTap(RemoteMessage message) =>
          delivered.add(message.data['action_url'] as String);

      // A remote tap that arrives before the navigation callbacks exist.
      PushTokenService.debugHandleNotificationTap(
        _tapFor('https://applink.picnic.fan/vote/detail/2'),
      );

      // Foregrounds and the first initialize all run before Firebase.
      await PushTokenService.resume();
      await PushTokenService.resume();
      await PushTokenService.initialize(
        onNotificationTap: deliverTap,
        onActionUrlTap: delivered.add,
      );
      expect(probe.factoryCalls, 0);
      expect(
        delivered,
        [
          'https://applink.picnic.fan/vote/detail/2',
          'https://applink.picnic.fan/vote/detail/1',
        ],
        reason: 'pending and local launch destinations need no Firebase',
      );

      await Firebase.initializeApp(options: _options);

      await PushTokenService.initialize(
        onNotificationTap: deliverTap,
        onActionUrlTap: delivered.add,
      );
      await Future<void>.delayed(Duration.zero);
      expect(probe.factoryCalls, 1);
      expect(probe.permissionRequests, 1);
      expect(probe.registered, ['fcm-token']);

      await PushTokenService.resume();
      await PushTokenService.initialize(
        onNotificationTap: deliverTap,
        onActionUrlTap: delivered.add,
      );
      await Future<void>.delayed(Duration.zero);
      expect(probe.factoryCalls, 1);
      expect(probe.permissionChecks, 1);
      expect(probe.registered, ['fcm-token', 'fcm-token', 'fcm-token']);
      expect(probe.initialMessageReads, 1);
      expect(launchReads, 1);
      expect(delivered, [
        'https://applink.picnic.fan/vote/detail/2',
        'https://applink.picnic.fan/vote/detail/1',
        'https://applink.picnic.fan/vote/detail/3',
      ]);
    });

    // Catches: a `resume` that only refreshes an existing coordinator and
    // never creates one. On device, `initialize` runs once per App startup;
    // if it ran before Firebase was ready, the next foreground is the only
    // path that brings push up.
    test('a resume alone starts push setup', () async {
      final probe = _CoordinatorProbe()
        ..initialMessage = _tapFor('https://applink.picnic.fan/vote/detail/4');
      PushTokenService.debugUseCoordinatorFactory(probe.build);
      PushTokenService.debugUseLaunchPayloadReader(
        () async => (didNotificationLaunchApp: false, payload: null),
      );
      final delivered = <String>[];

      await PushTokenService.initialize(
        onNotificationTap: (message) =>
            delivered.add(message.data['action_url'] as String),
      );
      await PushTokenService.resume();
      expect(probe.factoryCalls, 0);

      await Firebase.initializeApp(options: _options);
      await PushTokenService.resume();
      await Future<void>.delayed(Duration.zero);

      expect(probe.factoryCalls, 1);
      expect(probe.permissionRequests, 0, reason: 'resume never prompts');
      expect(probe.permissionChecks, 1);
      expect(probe.registered, ['fcm-token']);
      expect(
        delivered,
        ['https://applink.picnic.fan/vote/detail/4'],
        reason: 'the callbacks from the earlier initialize stay installed',
      );
    });
  });

  group('with the default Firebase app', () {
    setUp(() => Firebase.initializeApp(options: _options));

    // Catches: duplicate coordinators or permission prompts for overlapping
    // calls, and late work that survives `dispose`.
    test(
      'a pending permission prompt is shared and disposal stops late work',
      () async {
        final permissionSheet = Completer<PushPermissionStatus>();
        final foreground = StreamController<Object>.broadcast();
        addTearDown(foreground.close);
        final probe = _CoordinatorProbe(
          permissionResult: () => permissionSheet.future,
          foregroundMessages: foreground.stream,
        );
        PushTokenService.debugUseCoordinatorFactory(probe.build);
        PushTokenService.debugUseLaunchPayloadReader(
          () async => (didNotificationLaunchApp: false, payload: null),
        );

        final calls = [
          PushTokenService.initialize(onActionUrlTap: (_) {}),
          PushTokenService.resume(),
          PushTokenService.resume(),
        ];
        foreground.add('live');
        await Future<void>.delayed(Duration.zero);
        expect(probe.factoryCalls, 1);
        expect(probe.permissionRequests, 1);
        expect(probe.permissionChecks, 0);
        expect(probe.foregroundMessages, 1);

        await PushTokenService.dispose();
        permissionSheet.complete(PushPermissionStatus.granted);
        await Future.wait(calls);
        foreground.add('late');
        await Future<void>.delayed(Duration.zero);
        expect(probe.tokenReads, 0);
        expect(probe.registered, isEmpty);
        expect(probe.foregroundMessages, 1);

        final next = _CoordinatorProbe();
        PushTokenService.debugUseCoordinatorFactory(next.build);
        await PushTokenService.initialize(onActionUrlTap: (_) {});
        expect(next.registered, ['fcm-token']);
      },
    );

    // Catches: a broad catch around coordinator creation.
    test('a coordinator factory failure is not swallowed', () async {
      PushTokenService.debugUseCoordinatorFactory(
        () => throw StateError('factory failed'),
      );
      PushTokenService.debugUseLaunchPayloadReader(
        () async => (didNotificationLaunchApp: false, payload: null),
      );

      await expectLater(PushTokenService.resume(), throwsStateError);
      await expectLater(
        PushTokenService.initialize(onActionUrlTap: (_) {}),
        throwsStateError,
      );
    });
  });

  // The production coordinator also needs the Supabase client: it subscribes
  // to `supabase.auth.onAuthStateChange`, and `supabase` throws a StateError
  // until `initializeSupabase()` has created the client.
  group('with the default Firebase app but no Supabase client', () {
    setUp(() async {
      await Firebase.initializeApp(options: _options);
      expect(testSupabaseClient, isNull);
      expect(() => supabase, throwsStateError);
    });

    // Catches: Firebase readiness alone entering the production coordinator
    // (supabase_options.dart:46 <- authChanges <- _ensureCoordinator <-
    // resume). No coordinator factory, message source or Supabase mock.
    test('resume and initialize defer the production coordinator', () async {
      var launchReads = 0;
      PushTokenService.debugUseLaunchPayloadReader(() async {
        launchReads++;
        return (
          didNotificationLaunchApp: true,
          payload: 'action_url: https://applink.picnic.fan/vote/detail/5',
        );
      });
      final delivered = <String>[];

      await expectLater(PushTokenService.resume(), completes);
      await expectLater(
        PushTokenService.initialize(onActionUrlTap: delivered.add),
        completes,
      );
      await expectLater(PushTokenService.resume(), completes);

      expect(
        delivered,
        ['https://applink.picnic.fan/vote/detail/5'],
        reason: 'the local launch destination needs neither SDK',
      );
      expect(launchReads, 1);
    });

    // Catches: a deferral that latches push setup off, a check that treats a
    // logged-out client as unready, and a second coordinator per resume.
    test('a ready logged-out client lets the next resume start it', () async {
      var initialReads = 0;
      PushTokenService.debugUseMessageSources(
        PushMessageSources(
          tokenRefreshes: const Stream.empty(),
          foregroundMessages: const Stream.empty(),
          openedMessages: const Stream.empty(),
          getInitialMessage: () async {
            initialReads++;
            return _tapFor('https://applink.picnic.fan/vote/detail/6');
          },
        ),
      );
      PushTokenService.debugUseLaunchPayloadReader(
        () async => (didNotificationLaunchApp: false, payload: null),
      );
      final delivered = <String>[];

      await PushTokenService.initialize(
        onNotificationTap: (message) =>
            delivered.add(message.data['action_url'] as String),
      );
      await PushTokenService.resume();
      expect(initialReads, 0, reason: 'no coordinator without a client');

      final client = SupabaseClient('http://localhost:54321', 'test-anon-key');
      testSupabaseClient = client;
      addTearDown(() async {
        testSupabaseClient = null;
        await client.dispose();
      });
      expect(client.auth.currentSession, isNull, reason: 'logged out');

      await PushTokenService.resume();
      await Future<void>.delayed(Duration.zero);
      expect(initialReads, 1);
      expect(delivered, ['https://applink.picnic.fan/vote/detail/6']);

      await PushTokenService.resume();
      await Future<void>.delayed(Duration.zero);
      expect(initialReads, 1, reason: 'the coordinator is reused');
    });
  });
}

const _options = testFirebaseOptions;

RemoteMessage _tapFor(String actionUrl) =>
    RemoteMessage(data: {'action_url': actionUrl});

/// A coordinator whose side effects are counted, for asserting that push
/// setup really ran - or really did not.
class _CoordinatorProbe {
  _CoordinatorProbe({
    Future<PushPermissionStatus> Function()? permissionResult,
    Stream<Object>? foregroundMessages,
  }) : _permissionResult = permissionResult,
       _foregroundMessages = foregroundMessages;

  final Future<PushPermissionStatus> Function()? _permissionResult;
  final Stream<Object>? _foregroundMessages;
  Object? initialMessage;

  int factoryCalls = 0;
  int permissionRequests = 0;
  int permissionChecks = 0;
  int tokenReads = 0;
  int initialMessageReads = 0;
  int foregroundMessages = 0;
  final List<String> registered = <String>[];

  PushTokenInitializationCoordinator build() {
    factoryCalls++;
    return PushTokenInitializationCoordinator(
      PushInitializationDependencies(
        initializeLocalNotifications: () async {},
        requestPermission: () {
          permissionRequests++;
          return _permissionResult?.call() ??
              Future.value(PushPermissionStatus.granted);
        },
        checkPermission: () async {
          permissionChecks++;
          return PushPermissionStatus.granted;
        },
        getToken: () async {
          tokenReads++;
          return 'fcm-token';
        },
        subscribeToBroadcastTopic: () async {},
        registerToken: (token) async => registered.add(token),
        tokenRefreshes: const Stream.empty(),
        foregroundMessages: _foregroundMessages ?? const Stream.empty(),
        openedMessages: const Stream.empty(),
        authChanges: const Stream.empty(),
        isSignedIn: () => true,
        isSignedInEvent: (_) => false,
        onForegroundMessage: (_) => foregroundMessages++,
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
