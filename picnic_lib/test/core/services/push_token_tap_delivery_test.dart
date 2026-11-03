import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/push_token_initialization_coordinator.dart';
import 'package:picnic_lib/core/services/push_token_service.dart';

/// Regression coverage for PICNIC-2693.
///
/// A push tapped from a terminated app is delivered through
/// `FirebaseMessaging.getInitialMessage()`, which is a one-shot read. If the
/// coordinator consumes it before `PushTokenService.initialize()` installs the
/// navigation callbacks, the destination is dropped for good and the user is
/// left on the start screen.
void main() {
  tearDown(() async {
    await PushTokenService.debugResetForTest();
  });

  /// Builds a coordinator whose only meaningful behaviour is the one-shot
  /// initial-message read, counted through [onInitialMessageRead].
  PushTokenInitializationCoordinator buildCoordinator({
    required void Function() onInitialMessageRead,
    Object? initialMessage,
  }) {
    return PushTokenInitializationCoordinator(
      PushInitializationDependencies(
        initializeLocalNotifications: () async {},
        requestPermission: () async => PushPermissionStatus.denied,
        checkPermission: () async => PushPermissionStatus.denied,
        getToken: () async => null,
        subscribeToBroadcastTopic: () async {},
        registerToken: (_) async {},
        tokenRefreshes: const Stream.empty(),
        foregroundMessages: const Stream.empty(),
        openedMessages: const Stream.empty(),
        authChanges: const Stream.empty(),
        isSignedIn: () => false,
        isSignedInEvent: (_) => false,
        onForegroundMessage: (_) {},
        onOpenedMessage: (_) {},
        getInitialMessage: () async {
          onInitialMessageRead();
          return initialMessage;
        },
      ),
    );
  }

  RemoteMessage tapFor(String actionUrl) =>
      RemoteMessage(data: {'action_url': actionUrl});

  test(
    'resume before initialize brings push up and still preserves the tap',
    () async {
      // A process whose background launch never ran initialize() must still
      // recover its token registration on the next foreground - and the
      // one-shot launch tap consumed on the way must not be lost.
      final registered = <String>[];
      PushTokenService.debugUseCoordinatorFactory(
        () => PushTokenInitializationCoordinator(
          PushInitializationDependencies(
            initializeLocalNotifications: () async {},
            requestPermission: () async => PushPermissionStatus.granted,
            checkPermission: () async => PushPermissionStatus.granted,
            getToken: () async => 'token-1',
            subscribeToBroadcastTopic: () async {},
            registerToken: (token) async => registered.add(token),
            tokenRefreshes: const Stream.empty(),
            foregroundMessages: const Stream.empty(),
            openedMessages: const Stream.empty(),
            authChanges: const Stream.empty(),
            isSignedIn: () => true,
            isSignedInEvent: (_) => false,
            onForegroundMessage: (_) {},
            onOpenedMessage: (message) =>
                PushTokenService.debugHandleNotificationTap(
              message as RemoteMessage,
            ),
            getInitialMessage: () async =>
                tapFor('https://applink.picnic.fan/vote/detail/321'),
          ),
        ),
      );

      await PushTokenService.resume();
      await Future<void>.delayed(Duration.zero);

      expect(
        registered,
        ['token-1'],
        reason: 'resume is the only recovery path when initialize never ran',
      );
      expect(
        PushTokenService.debugPendingNotificationTapCount,
        1,
        reason: 'the launch tap must be held, not dropped',
      );

      final delivered = <String>[];
      await PushTokenService.initialize(
        onNotificationTap: (message) =>
            delivered.add(message.data['action_url'] as String),
      );

      expect(delivered, ['https://applink.picnic.fan/vote/detail/321']);
    },
  );

  test('resume after initialize still refreshes the existing coordinator',
      () async {
    var factoryCalls = 0;
    var checkPermissionCalls = 0;
    PushTokenService.debugUseCoordinatorFactory(() {
      factoryCalls++;
      return PushTokenInitializationCoordinator(
        PushInitializationDependencies(
          initializeLocalNotifications: () async {},
          requestPermission: () async => PushPermissionStatus.denied,
          checkPermission: () async {
            checkPermissionCalls++;
            return PushPermissionStatus.denied;
          },
          getToken: () async => null,
          subscribeToBroadcastTopic: () async {},
          registerToken: (_) async {},
          tokenRefreshes: const Stream.empty(),
          foregroundMessages: const Stream.empty(),
          openedMessages: const Stream.empty(),
          authChanges: const Stream.empty(),
          isSignedIn: () => false,
          isSignedInEvent: (_) => false,
          onForegroundMessage: (_) {},
          onOpenedMessage: (_) {},
          getInitialMessage: () async => null,
        ),
      );
    });

    await PushTokenService.initialize(onNotificationTap: (_) {});
    await PushTokenService.resume();

    expect(factoryCalls, 1);
    expect(checkPermissionCalls, 1);
  });

  test('a tap arriving before the callback is installed is replayed once',
      () async {
    PushTokenService.debugUseCoordinatorFactory(
      () => buildCoordinator(onInitialMessageRead: () {}),
    );

    PushTokenService.debugHandleNotificationTap(
      tapFor('https://applink.picnic.fan/vote/detail/123'),
    );
    expect(PushTokenService.debugPendingNotificationTapCount, 1);

    final delivered = <String>[];
    await PushTokenService.initialize(
      onNotificationTap: (message) =>
          delivered.add(message.data['action_url'] as String),
    );

    expect(delivered, ['https://applink.picnic.fan/vote/detail/123']);
    expect(PushTokenService.debugPendingNotificationTapCount, 0);
  });

  test('two different pending destinations are both replayed in order',
      () async {
    PushTokenService.debugUseCoordinatorFactory(
      () => buildCoordinator(onInitialMessageRead: () {}),
    );

    PushTokenService.debugHandleNotificationTap(
      tapFor('https://applink.picnic.fan/vote/detail/1'),
    );
    PushTokenService.debugHandleNotificationTap(
      tapFor('https://applink.picnic.fan/vote/detail/2'),
    );

    final delivered = <String>[];
    await PushTokenService.initialize(
      onNotificationTap: (message) =>
          delivered.add(message.data['action_url'] as String),
    );

    expect(delivered, [
      'https://applink.picnic.fan/vote/detail/1',
      'https://applink.picnic.fan/vote/detail/2',
    ]);
  });

  test('the same pending destination is never queued twice', () async {
    PushTokenService.debugUseCoordinatorFactory(
      () => buildCoordinator(onInitialMessageRead: () {}),
    );

    PushTokenService.debugHandleNotificationTap(
      tapFor('https://applink.picnic.fan/vote/detail/7'),
    );
    PushTokenService.debugHandleNotificationTap(
      tapFor('https://applink.picnic.fan/vote/detail/7'),
    );
    expect(PushTokenService.debugPendingNotificationTapCount, 1);

    final delivered = <String>[];
    await PushTokenService.initialize(
      onNotificationTap: (message) =>
          delivered.add(message.data['action_url'] as String),
    );

    expect(delivered, ['https://applink.picnic.fan/vote/detail/7']);
  });

  test('a tap arriving after initialize is delivered without queueing',
      () async {
    PushTokenService.debugUseCoordinatorFactory(
      () => buildCoordinator(onInitialMessageRead: () {}),
    );

    final delivered = <String>[];
    await PushTokenService.initialize(
      onNotificationTap: (message) =>
          delivered.add(message.data['action_url'] as String),
    );

    PushTokenService.debugHandleNotificationTap(
      tapFor('https://applink.picnic.fan/vote/detail/9'),
    );

    expect(delivered, ['https://applink.picnic.fan/vote/detail/9']);
    expect(PushTokenService.debugPendingNotificationTapCount, 0);
  });

  test('disposal discards pending taps so a new owner never replays them',
      () async {
    PushTokenService.debugUseCoordinatorFactory(
      () => buildCoordinator(onInitialMessageRead: () {}),
    );

    PushTokenService.debugHandleNotificationTap(
      tapFor('https://applink.picnic.fan/vote/detail/404'),
    );
    expect(PushTokenService.debugPendingNotificationTapCount, 1);

    await PushTokenService.dispose();
    expect(PushTokenService.debugPendingNotificationTapCount, 0);

    PushTokenService.debugUseCoordinatorFactory(
      () => buildCoordinator(onInitialMessageRead: () {}),
    );
    final delivered = <String>[];
    await PushTokenService.initialize(
      onNotificationTap: (message) =>
          delivered.add(message.data['action_url'] as String),
    );

    expect(delivered, isEmpty);
  });

  test('a tap without an action_url is never queued', () {
    PushTokenService.debugHandleNotificationTap(
      RemoteMessage(data: const {'type': 'vote_progress'}),
    );

    expect(PushTokenService.debugPendingNotificationTapCount, 0);
  });

  test('a local notification tapped before initialize is replayed', () async {
    // The notification the app posted in the foreground can be tapped after
    // the process is gone; the destination must survive until the callbacks
    // are installed (PICNIC-2693).
    PushTokenService.debugUseCoordinatorFactory(
      () => buildCoordinator(onInitialMessageRead: () {}),
    );

    PushTokenService.debugHandleLocalNotificationResponse(
      'action_url: https://applink.picnic.fan/vote/detail/55',
    );
    expect(PushTokenService.debugPendingNotificationTapCount, 1);

    final delivered = <String>[];
    await PushTokenService.initialize(onActionUrlTap: delivered.add);

    expect(delivered, ['https://applink.picnic.fan/vote/detail/55']);
    expect(PushTokenService.debugPendingNotificationTapCount, 0);
  });

  test('a local notification tapped after initialize is not queued', () async {
    PushTokenService.debugUseCoordinatorFactory(
      () => buildCoordinator(onInitialMessageRead: () {}),
    );

    final delivered = <String>[];
    await PushTokenService.initialize(onActionUrlTap: delivered.add);

    PushTokenService.debugHandleLocalNotificationResponse(
      'action_url: https://applink.picnic.fan/vote/detail/56',
    );

    expect(delivered, ['https://applink.picnic.fan/vote/detail/56']);
    expect(PushTokenService.debugPendingNotificationTapCount, 0);
  });

  test('a local notification payload without a url is never queued', () {
    PushTokenService.debugHandleLocalNotificationResponse('{title: hello}');

    expect(PushTokenService.debugPendingNotificationTapCount, 0);
  });

  group('notification that launched the app', () {
    test('its destination is delivered after initialize', () async {
      PushTokenService.debugUseCoordinatorFactory(
        () => buildCoordinator(onInitialMessageRead: () {}),
      );
      PushTokenService.debugUseLaunchPayloadReader(
        () async => (
          didNotificationLaunchApp: true,
          payload: 'action_url: https://applink.picnic.fan/vote/detail/77',
        ),
      );

      final delivered = <String>[];
      await PushTokenService.initialize(onActionUrlTap: delivered.add);

      expect(delivered, ['https://applink.picnic.fan/vote/detail/77']);
    });

    test('its destination is read only once per process', () async {
      var reads = 0;
      PushTokenService.debugUseCoordinatorFactory(
        () => buildCoordinator(onInitialMessageRead: () {}),
      );
      PushTokenService.debugUseLaunchPayloadReader(() async {
        reads++;
        return (
          didNotificationLaunchApp: true,
          payload: 'action_url: https://applink.picnic.fan/vote/detail/78',
        );
      });

      final delivered = <String>[];
      await PushTokenService.initialize(onActionUrlTap: delivered.add);
      await PushTokenService.initialize(onActionUrlTap: delivered.add);

      expect(reads, 1);
      expect(delivered, ['https://applink.picnic.fan/vote/detail/78']);
    });

    test('nothing is delivered when no notification launched the app',
        () async {
      PushTokenService.debugUseCoordinatorFactory(
        () => buildCoordinator(onInitialMessageRead: () {}),
      );
      PushTokenService.debugUseLaunchPayloadReader(
        () async => (didNotificationLaunchApp: false, payload: null),
      );

      final delivered = <String>[];
      await PushTokenService.initialize(onActionUrlTap: delivered.add);

      expect(delivered, isEmpty);
    });

    test('a failed read is retried on the next initialize', () async {
      var reads = 0;
      PushTokenService.debugUseCoordinatorFactory(
        () => buildCoordinator(onInitialMessageRead: () {}),
      );
      PushTokenService.debugUseLaunchPayloadReader(() async {
        reads++;
        if (reads == 1) throw StateError('plugin not ready yet');
        return (
          didNotificationLaunchApp: true,
          payload: 'action_url: https://applink.picnic.fan/vote/detail/88',
        );
      });

      final delivered = <String>[];
      await PushTokenService.initialize(onActionUrlTap: delivered.add);
      expect(delivered, isEmpty);

      await PushTokenService.initialize(onActionUrlTap: delivered.add);

      expect(reads, 2, reason: 'a throw must not latch the read away');
      expect(delivered, ['https://applink.picnic.fan/vote/detail/88']);
    });

    test('concurrent initializes read the launch details once', () async {
      var reads = 0;
      PushTokenService.debugUseCoordinatorFactory(
        () => buildCoordinator(onInitialMessageRead: () {}),
      );
      PushTokenService.debugUseLaunchPayloadReader(() async {
        reads++;
        await Future<void>.delayed(Duration.zero);
        return (
          didNotificationLaunchApp: true,
          payload: 'action_url: https://applink.picnic.fan/vote/detail/99',
        );
      });

      final delivered = <String>[];
      await Future.wait([
        PushTokenService.initialize(onActionUrlTap: delivered.add),
        PushTokenService.initialize(onActionUrlTap: delivered.add),
      ]);

      expect(reads, 1);
      expect(delivered, ['https://applink.picnic.fan/vote/detail/99']);
    });

    test('it is delivered while the coordinator is still initializing',
        () async {
      // The coordinator's permission step is an OS sheet: unbounded user
      // input. Serializing the launch read behind it would keep a user who
      // tapped a local notification on the start screen for exactly as long
      // as they take to answer it - the symptom this ticket is about.
      final permissionSheet = Completer<PushPermissionStatus>();
      final launchDetails =
          Completer<({bool didNotificationLaunchApp, String? payload})>();

      PushTokenService.debugUseCoordinatorFactory(
        () => PushTokenInitializationCoordinator(
          PushInitializationDependencies(
            initializeLocalNotifications: () async {},
            requestPermission: () => permissionSheet.future,
            checkPermission: () => permissionSheet.future,
            getToken: () async => null,
            subscribeToBroadcastTopic: () async {},
            registerToken: (_) async {},
            tokenRefreshes: const Stream.empty(),
            foregroundMessages: const Stream.empty(),
            openedMessages: const Stream.empty(),
            authChanges: const Stream.empty(),
            isSignedIn: () => false,
            isSignedInEvent: (_) => false,
            onForegroundMessage: (_) {},
            onOpenedMessage: (_) {},
            getInitialMessage: () async => null,
          ),
        ),
      );
      PushTokenService.debugUseLaunchPayloadReader(() => launchDetails.future);

      final delivered = <String>[];
      var initializeCompleted = false;
      final initializing = PushTokenService.initialize(
        onActionUrlTap: delivered.add,
      ).whenComplete(() => initializeCompleted = true);

      launchDetails.complete((
        didNotificationLaunchApp: true,
        payload: 'action_url: https://applink.picnic.fan/vote/detail/500',
      ));
      await Future<void>.delayed(Duration.zero);

      expect(
        delivered,
        ['https://applink.picnic.fan/vote/detail/500'],
        reason: 'the destination must not wait on the permission sheet',
      );
      expect(
        initializeCompleted,
        isFalse,
        reason: 'precondition: the coordinator is still parked on permission',
      );

      permissionSheet.complete(PushPermissionStatus.denied);
      await initializing;
    });

    test('a failing platform read never breaks initialization', () async {
      PushTokenService.debugUseCoordinatorFactory(
        () => buildCoordinator(onInitialMessageRead: () {}),
      );
      PushTokenService.debugUseLaunchPayloadReader(
        () async => throw StateError('plugin unavailable'),
      );

      await expectLater(
        PushTokenService.initialize(onActionUrlTap: (_) {}),
        completes,
      );
    });
  });
}
