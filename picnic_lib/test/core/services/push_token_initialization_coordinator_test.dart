import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/push_token_initialization_coordinator.dart';

void main() {
  test(
    'handlers are active while a slow permission dialog is unresolved',
    () async {
      final permission = Completer<PushPermissionStatus>();
      final foreground = StreamController<Object>.broadcast();
      final opened = StreamController<Object>.broadcast();
      final tokens = StreamController<String>.broadcast();
      final auth = StreamController<Object>.broadcast();
      final seen = <Object>[];
      final coordinator = PushTokenInitializationCoordinator(
        PushInitializationDependencies(
          initializeLocalNotifications: () async {},
          requestPermission: () => permission.future,
          checkPermission: () async => PushPermissionStatus.denied,
          getToken: () async => 'token',
          subscribeToBroadcastTopic: () async {},
          registerToken: (_) async {},
          tokenRefreshes: tokens.stream,
          foregroundMessages: foreground.stream,
          openedMessages: opened.stream,
          authChanges: auth.stream,
          isSignedIn: () => true,
          isSignedInEvent: (_) => true,
          onForegroundMessage: seen.add,
          onOpenedMessage: seen.add,
          getInitialMessage: () async => null,
        ),
      );

      final initializing = coordinator.initialize();
      foreground.add('foreground');
      opened.add('opened');
      await Future<void>.delayed(Duration.zero);
      expect(seen, ['foreground', 'opened']);

      permission.complete(PushPermissionStatus.granted);
      await initializing;
      await coordinator.dispose();
      await Future.wait([
        foreground.close(),
        opened.close(),
        tokens.close(),
        auth.close(),
      ]);
    },
  );

  test('duplicate initialize and resume join one permission request', () async {
    final permission = Completer<PushPermissionStatus>();
    var permissionCalls = 0;
    var tokenCalls = 0;
    final dependencies = _dependencies(
      requestPermission: () {
        permissionCalls++;
        return permission.future;
      },
      getToken: () async {
        tokenCalls++;
        return 'token';
      },
    );
    final coordinator = PushTokenInitializationCoordinator(dependencies);

    final first = coordinator.initialize();
    final second = coordinator.initialize();
    final resumed = coordinator.resume();
    await Future<void>.delayed(Duration.zero);
    expect(permissionCalls, 1);
    permission.complete(PushPermissionStatus.granted);
    await Future.wait([first, second, resumed]);
    expect(tokenCalls, 1);
    await coordinator.dispose();
  });

  test('dispose invalidates permission continuation and callbacks', () async {
    final permission = Completer<PushPermissionStatus>();
    final foreground = StreamController<Object>.broadcast();
    var tokenCalls = 0;
    var messageCalls = 0;
    final coordinator = PushTokenInitializationCoordinator(
      _dependencies(
        requestPermission: () => permission.future,
        getToken: () async {
          tokenCalls++;
          return 'token';
        },
        foregroundMessages: foreground.stream,
        onForegroundMessage: (_) => messageCalls++,
      ),
    );

    final initializing = coordinator.initialize();
    await coordinator.dispose();
    permission.complete(PushPermissionStatus.granted);
    await initializing;
    foreground.add('late');
    await Future<void>.delayed(Duration.zero);
    expect(tokenCalls, 0);
    expect(messageCalls, 0);
    await foreground.close();
  });

  test(
    'denial completes safely and a later granted resume retries token setup',
    () async {
      var tokenCalls = 0;
      final coordinator = PushTokenInitializationCoordinator(
        _dependencies(
          requestPermission: () async => PushPermissionStatus.denied,
          getToken: () async {
            tokenCalls++;
            return 'token';
          },
        ),
      );

      await coordinator.initialize();
      expect(tokenCalls, 0);
      await coordinator.resume();
      expect(tokenCalls, 1);
      await coordinator.dispose();
    },
  );

  test('token/topic failures do not remove message and tap hooks', () async {
    final foreground = StreamController<Object>.broadcast();
    final opened = StreamController<Object>.broadcast();
    final seen = <Object>[];
    final coordinator = PushTokenInitializationCoordinator(
      _dependencies(
        getToken: () async => throw StateError('token'),
        subscribeToBroadcastTopic: () async => throw StateError('topic'),
        foregroundMessages: foreground.stream,
        openedMessages: opened.stream,
        onForegroundMessage: seen.add,
        onOpenedMessage: seen.add,
      ),
    );
    await coordinator.initialize();
    foreground.add('message');
    opened.add('tap');
    await Future<void>.delayed(Duration.zero);
    expect(seen, ['message', 'tap']);
    await coordinator.dispose();
    await foreground.close();
    await opened.close();
  });

  test(
    'registers the latest token when authentication later signs in',
    () async {
      final auth = StreamController<Object>.broadcast();
      final registered = <String>[];
      var signedIn = false;
      final coordinator = PushTokenInitializationCoordinator(
        PushInitializationDependencies(
          initializeLocalNotifications: () async {},
          requestPermission: () async => PushPermissionStatus.granted,
          checkPermission: () async => PushPermissionStatus.granted,
          getToken: () async => 'pending-token',
          subscribeToBroadcastTopic: () async {},
          registerToken: (token) async => registered.add(token),
          tokenRefreshes: const Stream.empty(),
          foregroundMessages: const Stream.empty(),
          openedMessages: const Stream.empty(),
          authChanges: auth.stream,
          isSignedIn: () => signedIn,
          isSignedInEvent: (event) => event == 'signed-in',
          onForegroundMessage: (_) {},
          onOpenedMessage: (_) {},
          getInitialMessage: () async => null,
        ),
      );
      await coordinator.initialize();
      expect(registered, isEmpty);

      signedIn = true;
      auth.add('signed-in');
      await Future<void>.delayed(Duration.zero);
      expect(registered, ['pending-token']);
      await coordinator.dispose();
      await auth.close();
    },
  );
}

PushInitializationDependencies _dependencies({
  Future<PushPermissionStatus> Function()? requestPermission,
  Future<String?> Function()? getToken,
  Future<void> Function()? subscribeToBroadcastTopic,
  Stream<Object>? foregroundMessages,
  Stream<Object>? openedMessages,
  void Function(Object)? onForegroundMessage,
  void Function(Object)? onOpenedMessage,
}) {
  return PushInitializationDependencies(
    initializeLocalNotifications: () async {},
    requestPermission:
        requestPermission ?? () async => PushPermissionStatus.granted,
    checkPermission: () async => PushPermissionStatus.granted,
    getToken: getToken ?? () async => 'token',
    subscribeToBroadcastTopic: subscribeToBroadcastTopic ?? () async {},
    registerToken: (_) async {},
    tokenRefreshes: const Stream.empty(),
    foregroundMessages: foregroundMessages ?? const Stream.empty(),
    openedMessages: openedMessages ?? const Stream.empty(),
    authChanges: const Stream.empty(),
    isSignedIn: () => true,
    isSignedInEvent: (_) => true,
    onForegroundMessage: onForegroundMessage ?? (_) {},
    onOpenedMessage: onOpenedMessage ?? (_) {},
    getInitialMessage: () async => null,
  );
}
