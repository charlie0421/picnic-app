import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/notification_inbox_pager.dart';
import 'package:picnic_lib/core/services/notification_inbox_service.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/user_notification.dart';
import 'package:picnic_lib/data/storage/broadcast_notification_read_store.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/navigation_stack.dart';
import 'package:picnic_lib/presentation/pages/notifications/notifications_page.dart';
import 'package:picnic_lib/presentation/screens/mypage_screen.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

class _MemoryStorage implements LocalStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> loadData(String key, String? defaultValue) async =>
      values[key] ?? defaultValue;

  @override
  Future<void> saveData(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> removeData(String key) async {
    values.remove(key);
  }

  @override
  Future<void> clearStorage() async {
    values.clear();
  }
}

class _BlockingMarkAllSource implements NotificationInboxDataSource {
  final Completer<List<int>> markAllCompleter = Completer<List<int>>();
  int markAllCalls = 0;
  bool _personalFetched = false;

  @override
  String? get currentUserId => 'account-a';

  @override
  Future<List<UserNotification>> fetchPersonal({
    required String userId,
    required NotificationCursor? cursor,
    required int limit,
  }) async {
    if (_personalFetched) return const [];
    _personalFetched = true;
    return [
      UserNotification(
        id: 1,
        userId: userId,
        title: const {'ko': '읽지 않은 알림'},
        body: const {'ko': '알림 본문'},
        type: 'default',
        isRead: false,
        createdAt: DateTime.utc(2026, 9, 14).toIso8601String(),
      ),
    ];
  }

  @override
  Future<List<UserNotification>> fetchBroadcast({
    required NotificationCursor? cursor,
    required int limit,
  }) async => const [];

  @override
  Future<List<int>> updatePersonalRead({required String userId, int? id}) {
    if (id != null) return Future.value([id]);
    markAllCalls++;
    return markAllCompleter.future;
  }

  @override
  Future<int?> fetchBroadcastMaxId() async => null;

  @override
  Future<List<int>> fetchBroadcastIds({
    required int afterId,
    required int maxId,
    required int limit,
  }) async => const [];
}

NotificationInboxService _service(_BlockingMarkAllSource source) =>
    NotificationInboxService(
      source: source,
      readStore: BroadcastNotificationReadStore(storage: _MemoryStorage()),
    );

class _NotificationsLauncher extends StatelessWidget {
  const _NotificationsLauncher({required this.service});

  final NotificationInboxService service;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        key: const ValueKey('open-notifications'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => NotificationsPage(service: service),
          ),
        ),
        child: const Text('알림 열기'),
      ),
    );
  }
}

void main() {
  setUp(initTestColors);

  testWidgets(
    'standalone mode owns one header and its back action pops the route',
    (tester) async {
      final source = _BlockingMarkAllSource();
      await tester.pumpWidget(
        buildTestApp(_NotificationsLauncher(service: _service(source))),
      );

      await tester.tap(find.byKey(const ValueKey('open-notifications')));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('알림함'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      final markAll = find.byKey(const ValueKey('notifications-mark-all'));
      expect(markAll, findsOneWidget);
      expect(tester.getSize(markAll).height, greaterThanOrEqualTo(48));
      expect(markAll.hitTestable(), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('open-notifications')), findsOneWidget);
      expect(find.byType(NotificationsPage), findsNothing);
    },
  );

  testWidgets(
    'embedded mode leaves one MyPage header, keeps mark-all reachable and guards duplicate taps',
    (tester) async {
      final source = _BlockingMarkAllSource();
      final stack = NavigationStack()
        ..push(const SizedBox(key: ValueKey('my-page-root')))
        ..push(
          NotificationsPage(
            mode: NotificationsPageMode.embedded,
            service: _service(source),
          ),
        );

      await tester.pumpWidget(
        buildTestApp(
          const MyPageScreen(),
          navigation: Navigation(
            drawerNavigationStack: stack,
            myPageTitle: '알림함',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('알림함'), findsOneWidget);

      final markAll = find.byKey(const ValueKey('notifications-mark-all'));
      expect(markAll, findsOneWidget);
      expect(markAll.hitTestable(), findsOneWidget);
      expect(tester.getSize(markAll).height, greaterThanOrEqualTo(48));

      await tester.tap(markAll);
      await tester.pump();
      await tester.tap(markAll, warnIfMissed: false);
      await tester.pump();
      expect(source.markAllCalls, 1);

      source.markAllCompleter.complete([1]);
      await tester.pumpAndSettle();

      final shellBack = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(InkWell),
      );
      expect(shellBack, findsOneWidget);
      await tester.tap(shellBack);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('my-page-root')), findsOneWidget);
      expect(find.byType(NotificationsPage), findsNothing);
    },
  );
}
