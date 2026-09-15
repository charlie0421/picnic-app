import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/push_token_service.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_page.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/ignore_image_errors.dart';
import '../../helpers/mock_supabase.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

/// End-to-end coverage for PICNIC-2693: a tapped vote-progress push must reach
/// the vote detail page through the real wiring - the coordinator's opened
/// message stream, [PushTokenService]'s tap dispatch and the
/// [AppInitializer] handler that performs the deep link.
///
/// Nothing here calls a debug tap handler: the only test-owned pieces are the
/// Firebase message sources (there is no Firebase app in a widget test) and
/// the launch-details reader (no platform plugin).

Map<String, dynamic> _voteRow({int id = 1}) {
  final now = DateTime.now().toUtc();
  return {
    'id': id,
    'title': {'ko': '테스트 투표', 'en': 'Test Vote'},
    'vote_category': 'birthday',
    'main_image': null,
    'wait_image': null,
    'result_image': null,
    'vote_content': null,
    'vote_item': [_voteItemRow(voteId: id)],
    'created_at': now.toIso8601String(),
    'visible_at': now.subtract(const Duration(days: 2)).toIso8601String(),
    'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
    'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
    'is_ended': false,
    'is_upcoming': false,
    'is_partnership': false,
    'partner': null,
    'reward': null,
  };
}

Map<String, dynamic> _voteItemRow({int voteId = 1}) => {
      'id': 1,
      'vote_id': voteId,
      'vote_total': 5000,
      'artist': {
        'id': 10,
        'name': {'ko': '지민', 'en': 'Jimin'},
        'image': null,
        'artist_group': {
          'id': 1,
          'name': {'ko': 'BTS', 'en': 'BTS'},
          'image': null,
        },
      },
      'artist_group': null,
    };

/// Runs the production push initialization the way `AppInitializer` does, then
/// renders whatever the navigation stack currently points at.
class _PushHarness extends ConsumerStatefulWidget {
  const _PushHarness();

  @override
  ConsumerState<_PushHarness> createState() => _PushHarnessState();
}

class _PushHarnessState extends ConsumerState<_PushHarness> {
  @override
  void initState() {
    super.initState();
    unawaited(
      PushTokenService.initialize(
        onNotificationTap: AppInitializer.buildPushTapHandler(ref, () => true),
        onActionUrlTap:
            AppInitializer.buildActionUrlTapHandler(ref, () => true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stack = ref.watch(navigationInfoProvider).voteNavigationStack;
    if (stack == null || stack.isEmpty) return const SizedBox.shrink();
    return stack.peek();
  }
}

/// Names the top of the stack without building it, for the frame-scheduling
/// test where a real page would keep frames scheduled forever.
class _StackTopProbe extends ConsumerWidget {
  const _StackTopProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stack = ref.watch(navigationInfoProvider).voteNavigationStack;
    final name = stack == null || stack.isEmpty
        ? 'empty'
        : stack.peek().runtimeType.toString();
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(name),
    );
  }
}

class _ProbeHarness extends ConsumerStatefulWidget {
  const _ProbeHarness();

  @override
  ConsumerState<_ProbeHarness> createState() => _ProbeHarnessState();
}

class _ProbeHarnessState extends ConsumerState<_ProbeHarness> {
  @override
  void initState() {
    super.initState();
    unawaited(
      PushTokenService.initialize(
        onNotificationTap: AppInitializer.buildPushTapHandler(ref, () => true),
        onActionUrlTap:
            AppInitializer.buildActionUrlTapHandler(ref, () => true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const _StackTopProbe();
}

/// The real plugin channel. Faking the platform here - and nothing above it -
/// keeps `_initializeLocalNotifications`, the plugin's own dispatch and
/// `_readLaunchPayload` in the path under test.
const MethodChannel _localNotificationsChannel =
    MethodChannel('dexterous.com/flutter/local_notifications');

/// Payload shape the plugin's Android channel mapper expects.
Map<String, dynamic> _launchedBy(String actionUrl) => <String, dynamic>{
      'notificationLaunchedApp': true,
      'notificationResponse': <String, dynamic>{
        'notificationId': 1,
        'actionId': null,
        'input': null,
        'notificationResponseType': 0,
        'payload': 'action_url: $actionUrl',
      },
    };

/// Delivers a notification tap the way the platform does, into the handler
/// the production `_initializeLocalNotifications` registered.
Future<void> _tapLocalNotification(String actionUrl) {
  return TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
    _localNotificationsChannel.name,
    const StandardMethodCodec().encodeMethodCall(
      MethodCall('didReceiveNotificationResponse', <String, dynamic>{
        'notificationId': 1,
        'actionId': null,
        'input': null,
        'notificationResponseType': 0,
        'payload': 'action_url: $actionUrl',
      }),
    ),
    (_) {},
  );
}

void main() {
  late void Function() restoreImages;
  late Map<String, dynamic> launchDetails;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({
      'vote': [
        _voteRow(),
        _voteRow(id: 2693),
        _voteRow(id: 2694),
        _voteRow(id: 2695),
      ],
      'vote_item': [
        _voteItemRow(),
        _voteItemRow(voteId: 2693),
        _voteItemRow(voteId: 2694),
        _voteItemRow(voteId: 2695),
      ],
    });
    restoreImages = suppressImageErrors();
    // Widget tests never run plugin registration, so the platform instance
    // the plugin resolves to has to be installed by hand. This is the real
    // Android implementation talking to the faked channel below.
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    launchDetails = <String, dynamic>{'notificationLaunchedApp': false};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_localNotificationsChannel, (call) async {
      switch (call.method) {
        case 'getNotificationAppLaunchDetails':
          return launchDetails;
        case 'initialize':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() async {
    restoreImages();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_localNotificationsChannel, null);
    await PushTokenService.debugResetForTest();
    tearDownMockSupabase();
  });

  RemoteMessage voteTap(int voteId) => RemoteMessage(
        data: {
          'type': 'vote_progress',
          'vote_id': '$voteId',
          'action_url': 'https://applink.picnic.fan/vote/detail/$voteId',
        },
      );

  testWidgets(
    'a push tapped while the app is idle requests the frame that navigates',
    (tester) async {
      final opened = StreamController<Object>.broadcast();
      addTearDown(opened.close);
      PushTokenService.debugUseMessageSources(
        PushMessageSources(
          tokenRefreshes: const Stream.empty(),
          foregroundMessages: const Stream.empty(),
          openedMessages: opened.stream,
          getInitialMessage: () async => null,
        ),
      );

      await tester.pumpWidget(
        const ProviderScope(child: _ProbeHarness()),
      );
      for (var i = 0; i < 20 && tester.binding.hasScheduledFrame; i++) {
        await tester.pump();
      }
      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason: 'precondition: the app has gone idle',
      );

      opened.add(voteTap(2693));
      await tester.pump();

      expect(
        tester.binding.hasScheduledFrame,
        isTrue,
        reason: 'the tap must request the frame that performs the navigation; '
            'addPostFrameCallback alone never schedules one',
      );

      // Two frames: the requested one performs the deep link, the next one
      // rebuilds the probe from the new stack.
      await tester.pump();
      await tester.pump();
      expect(find.text('VoteDetailPage'), findsOneWidget);
    },
  );

  testWidgets(
    'a push tapped from a terminated app renders the vote detail page',
    (tester) async {
      PushTokenService.debugUseMessageSources(
        PushMessageSources(
          tokenRefreshes: const Stream.empty(),
          foregroundMessages: const Stream.empty(),
          openedMessages: const Stream.empty(),
          getInitialMessage: () async => voteTap(1),  // distinct from the idle test
        ),
      );

      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(
          const _PushHarness(),
          // The real notifier: MockNavigationInfo stubs out the stack rebuild
          // this test is about.
          overrideNavigation: false,
        ),
      );
      // Pump only the frames the app itself asks for. A dispatch that never
      // requests a frame therefore never gets one, exactly as on device.
      var pumps = 0;
      while (tester.binding.hasScheduledFrame && pumps < 60) {
        await tester.pump(const Duration(milliseconds: 16));
        pumps++;
      }
      drainExpectedImageErrors(tester);

      expect(
        find.byType(VoteDetailPage),
        findsOneWidget,
        reason: 'the launch notification must land on the detail page',
      );
    },
  );

  testWidgets(
    'a local notification that launched the app renders the vote detail page',
    (tester) async {
      // No Dart seam: the production `_readLaunchPayload` calls the real
      // plugin, which asks the (faked) platform for the launch details.
      launchDetails =
          _launchedBy('https://applink.picnic.fan/vote/detail/2694');
      PushTokenService.debugUseMessageSources(
        const PushMessageSources(
          tokenRefreshes: Stream.empty(),
          foregroundMessages: Stream.empty(),
          openedMessages: Stream.empty(),
        ),
      );

      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(const _PushHarness(), overrideNavigation: false),
      );
      var pumps = 0;
      while (tester.binding.hasScheduledFrame && pumps < 60) {
        await tester.pump(const Duration(milliseconds: 16));
        pumps++;
      }
      drainExpectedImageErrors(tester);

      expect(
        find.byType(VoteDetailPage),
        findsOneWidget,
        reason: 'a local cold-launch tap must reach the detail page',
      );
    },
  );

  testWidgets(
    'a local notification tapped in the foreground renders the detail page',
    (tester) async {
      PushTokenService.debugUseMessageSources(
        const PushMessageSources(
          tokenRefreshes: Stream.empty(),
          foregroundMessages: Stream.empty(),
          openedMessages: Stream.empty(),
        ),
      );

      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(const _PushHarness(), overrideNavigation: false),
      );
      var pumps = 0;
      while (tester.binding.hasScheduledFrame && pumps < 60) {
        await tester.pump(const Duration(milliseconds: 16));
        pumps++;
      }
      expect(
        find.byType(VoteDetailPage),
        findsNothing,
        reason: 'precondition: nothing has navigated yet',
      );

      // The platform reports the tap through the handler the production
      // `_initializeLocalNotifications` registered with the plugin.
      await _tapLocalNotification(
        'https://applink.picnic.fan/vote/detail/2695',
      );
      pumps = 0;
      while (tester.binding.hasScheduledFrame && pumps < 60) {
        await tester.pump(const Duration(milliseconds: 16));
        pumps++;
      }
      drainExpectedImageErrors(tester);

      expect(find.byType(VoteDetailPage), findsOneWidget);
    },
  );
}
