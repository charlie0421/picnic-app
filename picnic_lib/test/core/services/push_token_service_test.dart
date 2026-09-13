import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/push_token_initialization_coordinator.dart';
import 'package:picnic_lib/core/services/push_token_service.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  tearDown(() async {
    await PushTokenService.debugResetForTest();
    tearDownMockSupabase();
  });

  test(
    'static facade is single-flight and disposal invalidates pending work',
    () async {
      final permission = Completer<PushPermissionStatus>();
      final foreground = StreamController<Object>.broadcast();
      var factoryCalls = 0;
      var permissionCalls = 0;
      var tokenCalls = 0;
      var foregroundCalls = 0;

      PushTokenService.debugUseCoordinatorFactory(() {
        factoryCalls++;
        return PushTokenInitializationCoordinator(
          PushInitializationDependencies(
            initializeLocalNotifications: () async {},
            requestPermission: () {
              permissionCalls++;
              return permission.future;
            },
            checkPermission: () async => PushPermissionStatus.granted,
            getToken: () async {
              tokenCalls++;
              return 'token';
            },
            subscribeToBroadcastTopic: () async {},
            registerToken: (_) async {},
            tokenRefreshes: const Stream.empty(),
            foregroundMessages: foreground.stream,
            openedMessages: const Stream.empty(),
            authChanges: const Stream.empty(),
            isSignedIn: () => false,
            isSignedInEvent: (_) => false,
            onForegroundMessage: (_) => foregroundCalls++,
            onOpenedMessage: (_) {},
            getInitialMessage: () async => null,
          ),
        );
      });

      final first = PushTokenService.initialize();
      final duplicate = PushTokenService.initialize();
      final resumed = PushTokenService.resume();
      foreground.add('live');
      await Future<void>.delayed(Duration.zero);
      expect(factoryCalls, 1);
      expect(permissionCalls, 1);
      expect(foregroundCalls, 1);

      await PushTokenService.dispose();
      permission.complete(PushPermissionStatus.granted);
      await Future.wait([first, duplicate, resumed]);
      foreground.add('late');
      await Future<void>.delayed(Duration.zero);
      expect(tokenCalls, 0);
      expect(foregroundCalls, 1);
      await foreground.close();
    },
  );

  test(
    'failed APNS wait is retried and only successful readiness latches',
    () async {
      var calls = 0;
      Future<String?> unavailableToken() async {
        calls++;
        return null;
      }

      expect(
        await PushTokenService.debugWaitForApnsToken(
          getToken: unavailableToken,
          timeout: const Duration(milliseconds: 1),
          pollInterval: const Duration(milliseconds: 2),
        ),
        isNull,
      );
      final afterFailure = calls;
      Future<String?> readyToken() async {
        calls++;
        return 'apns-ready';
      }

      expect(
        await PushTokenService.debugWaitForApnsToken(
          getToken: readyToken,
          timeout: const Duration(milliseconds: 20),
          pollInterval: Duration.zero,
        ),
        'apns-ready',
      );
      expect(calls, greaterThan(afterFailure));

      final afterSuccess = calls;
      await PushTokenService.debugWaitForApnsToken(
        getToken: readyToken,
        timeout: const Duration(milliseconds: 20),
        pollInterval: Duration.zero,
      );
      expect(
        calls,
        afterSuccess,
        reason: 'successful APNS readiness may be reused',
      );
    },
  );

  test('broadcast topics remain a mobile-only operation', () {
    expect(PushTokenService.debugSupportsBroadcastTopics, isFalse);
  });

  test(
    'registration owner rejects account switch and facade disposal',
    () async {
      await setupMockSupabaseWithAuth({}, userId: 'owner-a');
      final owner = PushTokenService.debugOwnerGeneration;
      expect(
        PushTokenService.debugIsRegistrationOwnerActive(owner, 'owner-a'),
        isTrue,
      );

      await setupMockSupabaseWithAuth({}, userId: 'owner-b');
      expect(
        PushTokenService.debugIsRegistrationOwnerActive(owner, 'owner-a'),
        isFalse,
      );
      expect(
        PushTokenService.debugIsRegistrationOwnerActive(owner, 'owner-b'),
        isTrue,
      );

      await PushTokenService.dispose();
      expect(
        PushTokenService.debugIsRegistrationOwnerActive(owner, 'owner-b'),
        isFalse,
      );
    },
  );
}
