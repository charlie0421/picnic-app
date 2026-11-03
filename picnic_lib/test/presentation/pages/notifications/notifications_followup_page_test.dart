import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/notification_inbox_pager.dart';
import 'package:picnic_lib/core/services/notification_inbox_service.dart';
import 'package:picnic_lib/data/models/user_notification.dart';
import 'package:picnic_lib/data/storage/broadcast_notification_read_store.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/presentation/pages/notifications/notifications_page.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

class _MemoryStorage implements LocalStorage {
  final Map<String, String> values = {};
  @override
  Future<String?> loadData(String key, String? defaultValue) async =>
      values[key] ?? defaultValue;
  @override
  Future<void> saveData(String key, String value) async => values[key] = value;
  @override
  Future<void> removeData(String key) async => values.remove(key);
  @override
  Future<void> clearStorage() async => values.clear();
}

class _PageSource implements NotificationInboxDataSource {
  _PageSource({this.personal = const [], this.broadcast = const []});

  @override
  String? currentUserId;
  final List<UserNotification> personal;
  final List<UserNotification> broadcast;
  int failPersonal = 0;
  int failBroadcast = 0;
  bool controlBroadcast = false;
  final List<Completer<List<UserNotification>>> broadcastRequests = [];
  Completer<List<UserNotification>>? pendingBroadcast;
  Completer<int?>? pendingBroadcastMaxId;
  List<int>? personalUpdateResult;
  final List<int> personalMarked = [];

  List<UserNotification> _page(
    List<UserNotification> rows,
    NotificationCursor? cursor,
    int limit,
  ) => rows
      .where(
        (row) =>
            cursor == null ||
            row.createdAt!.compareTo(cursor.createdAt) < 0 ||
            (row.createdAt == cursor.createdAt && row.id < cursor.id),
      )
      .take(limit)
      .toList();

  @override
  Future<List<UserNotification>> fetchPersonal({
    required String userId,
    required NotificationCursor? cursor,
    required int limit,
  }) async {
    if (failPersonal-- > 0) throw StateError('personal failed');
    return _page(personal, cursor, limit);
  }

  @override
  Future<List<UserNotification>> fetchBroadcast({
    required NotificationCursor? cursor,
    required int limit,
  }) async {
    if (controlBroadcast) {
      final request = Completer<List<UserNotification>>();
      broadcastRequests.add(request);
      return request.future;
    }
    if (pendingBroadcast != null) {
      final pending = pendingBroadcast!;
      pendingBroadcast = null;
      return pending.future;
    }
    if (failBroadcast-- > 0) throw StateError('broadcast failed');
    return _page(broadcast, cursor, limit);
  }

  @override
  Future<List<int>> updatePersonalRead({
    required String userId,
    int? id,
  }) async {
    if (id != null) personalMarked.add(id);
    return id == null
        ? personalUpdateResult ?? personal.map((item) => item.id).toList()
        : [id];
  }

  @override
  Future<int?> fetchBroadcastMaxId() async {
    final pending = pendingBroadcastMaxId;
    if (pending != null) {
      pendingBroadcastMaxId = null;
      return pending.future;
    }
    return broadcast.isEmpty
        ? null
        : broadcast.map((row) => row.id).reduce((a, b) => a > b ? a : b);
  }

  @override
  Future<List<int>> fetchBroadcastIds({
    required int afterId,
    required int maxId,
    required int limit,
  }) async =>
      (broadcast
              .map((row) => row.id)
              .where((id) => id > afterId && id <= maxId)
              .toList()
            ..sort())
          .take(limit)
          .toList();
}

UserNotification _notification(
  String title,
  int id,
  DateTime time, {
  String? userId,
}) => UserNotification(
  id: id,
  userId: userId,
  title: {'ko': title},
  body: const {'ko': 'body'},
  createdAt: time.toUtc().toIso8601String(),
);

NotificationInboxService _service(_PageSource source, _MemoryStorage storage) =>
    NotificationInboxService(
      source: source,
      readStore: BroadcastNotificationReadStore(storage: storage),
    );

void main() {
  setUpAll(initTestColors);

  testWidgets('shows explicit initial loading and then a true empty state', (
    tester,
  ) async {
    final pending = Completer<List<UserNotification>>();
    final source = _PageSource()..pendingBroadcast = pending;
    await tester.pumpWidget(
      buildTestAppPage(
        NotificationsPage(service: _service(source, _MemoryStorage())),
      ),
    );
    await tester.pump();
    expect(find.byType(MediumPulseLoadingIndicator), findsOneWidget);

    pending.complete([]);
    await tester.pumpAndSettle();

    expect(find.text('이용 가능한 데이터가 없습니다.'), findsOneWidget);
  });

  testWidgets('initial source error exposes retry without raw server text', (
    tester,
  ) async {
    final source = _PageSource(
      broadcast: [_notification('recovered', 1, DateTime.utc(2026, 9, 13))],
    )..failBroadcast = 1;
    await tester.pumpWidget(
      buildTestAppPage(
        NotificationsPage(service: _service(source, _MemoryStorage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('오류가 발생했습니다.'), findsOneWidget);
    expect(find.textContaining('broadcast failed'), findsNothing);
    await tester.tap(find.text('재시도'));
    await tester.pumpAndSettle();

    expect(find.text('recovered'), findsOneWidget);
  });

  testWidgets('double initial retry coalesces and renders page one once', (
    tester,
  ) async {
    final source = _PageSource()..failBroadcast = 1;
    await tester.pumpWidget(
      buildTestAppPage(
        NotificationsPage(service: _service(source, _MemoryStorage())),
      ),
    );
    await tester.pumpAndSettle();
    source.controlBroadcast = true;

    await tester.tap(find.text('재시도'));
    await tester.tap(find.text('재시도'));
    await tester.pump();

    expect(source.broadcastRequests, hasLength(1));
    source.broadcastRequests.single.complete([
      _notification('recovered-once', 1, DateTime.utc(2026, 9, 13)),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('recovered-once'), findsOneWidget);
    expect(find.byKey(const ValueKey('broadcast:1')), findsOneWidget);
  });

  testWidgets(
    'same numeric id keeps distinct keys and broadcast tap targets local read only',
    (tester) async {
      final time = DateTime.utc(2026, 9, 13);
      final storage = _MemoryStorage();
      final source = _PageSource(
        personal: [_notification('personal-7', 7, time, userId: 'user-a')],
        broadcast: [_notification('broadcast-7', 7, time)],
      )..currentUserId = 'user-a';
      await tester.pumpWidget(
        buildTestAppPage(NotificationsPage(service: _service(source, storage))),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('personal:7')), findsOneWidget);
      expect(find.byKey(const ValueKey('broadcast:7')), findsOneWidget);
      await tester.tap(find.text('broadcast-7'));
      await tester.pumpAndSettle();

      expect(source.personalMarked, isEmpty);
      expect(
        await BroadcastNotificationReadStore(
          storage: storage,
        ).readIds('user-a'),
        {7},
      );
    },
  );

  testWidgets('append error keeps rows and retries from the same cursor', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 9, 13);
    final source = _PageSource(
      personal: List.generate(
        21,
        (i) => _notification(
          'personal-${21 - i}',
          21 - i,
          now.subtract(Duration(minutes: i)),
          userId: 'user-a',
        ),
      ),
    )..currentUserId = 'user-a';
    await tester.pumpWidget(
      buildTestAppPage(
        NotificationsPage(service: _service(source, _MemoryStorage())),
      ),
    );
    await tester.pumpAndSettle();
    source.failPersonal = 1;

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(find.text('personal-2'), findsOneWidget);
    expect(find.text('재시도'), findsOneWidget);
    await tester.tap(find.text('재시도'));
    await tester.pumpAndSettle();

    expect(find.text('personal-1'), findsOneWidget);
    expect(find.text('재시도'), findsNothing);
  });

  testWidgets('refresh replaces data when an older append completes last', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 9, 13);
    final source = _PageSource()..controlBroadcast = true;
    await tester.pumpWidget(
      buildTestAppPage(
        NotificationsPage(service: _service(source, _MemoryStorage())),
      ),
    );
    await tester.pump();
    expect(source.broadcastRequests, hasLength(1));
    source.broadcastRequests.first.complete(
      List.generate(
        20,
        (i) => _notification(
          'old-${20 - i}',
          20 - i,
          now.subtract(Duration(minutes: i)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pump();
    expect(source.broadcastRequests, hasLength(2));

    final refreshState = tester.state<RefreshIndicatorState>(
      find.byType(RefreshIndicator),
    );
    unawaited(refreshState.show());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(source.broadcastRequests, hasLength(3));
    source.broadcastRequests[2].complete([
      _notification('fresh', 100, now.add(const Duration(minutes: 1))),
    ]);
    await tester.pumpAndSettle();

    source.broadcastRequests[1].complete([
      _notification('stale-append', 1, now.subtract(const Duration(days: 1))),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('fresh'), findsOneWidget);
    expect(find.text('stale-append'), findsNothing);
  });

  testWidgets('append cannot start while refreshed page one is pending', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 9, 13);
    final source = _PageSource()..controlBroadcast = true;
    await tester.pumpWidget(
      buildTestAppPage(
        NotificationsPage(service: _service(source, _MemoryStorage())),
      ),
    );
    await tester.pump();
    source.broadcastRequests.single.complete(
      List.generate(
        20,
        (i) => _notification(
          'old-${20 - i}',
          20 - i,
          now.subtract(Duration(minutes: i)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final refreshFuture = tester
        .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
        .show();
    while (source.broadcastRequests.length < 2) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final controller = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    final requestsWhileRefreshing = source.broadcastRequests.length;

    source.broadcastRequests[1].complete([
      _notification('fresh-page-one', 100, now.add(const Duration(minutes: 1))),
    ]);
    if (source.broadcastRequests.length > 2) {
      source.broadcastRequests[2].complete([
        _notification(
          'stale-concurrent-append',
          1,
          now.subtract(const Duration(days: 1)),
        ),
      ]);
    }
    await tester.pumpAndSettle();
    await refreshFuture;

    expect(requestsWhileRefreshing, 2);
    expect(find.text('fresh-page-one'), findsOneWidget);
    expect(find.text('stale-concurrent-append'), findsNothing);
  });

  testWidgets('failed refresh keeps rows and exposes compact retry feedback', (
    tester,
  ) async {
    final source = _PageSource()..controlBroadcast = true;
    await tester.pumpWidget(
      buildTestAppPage(
        NotificationsPage(service: _service(source, _MemoryStorage())),
      ),
    );
    await tester.pump();
    final now = DateTime.utc(2026, 9, 13);
    source.broadcastRequests.single.complete(
      List.generate(
        20,
        (index) => _notification(
          'kept-row-${20 - index}',
          20 - index,
          now.subtract(Duration(minutes: index)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final refreshFuture = tester
        .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
        .show();
    while (source.broadcastRequests.length < 2) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    source.broadcastRequests[1].completeError(StateError('raw server error'));
    await tester.pumpAndSettle();
    await refreshFuture;

    expect(find.text('kept-row-20'), findsOneWidget);
    expect(find.text('오류가 발생했습니다.'), findsOneWidget);
    expect(find.text('재시도'), findsOneWidget);
    expect(find.textContaining('raw server error'), findsNothing);

    await tester.tap(find.text('재시도'));
    while (source.broadcastRequests.length < 3) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    source.broadcastRequests[2].complete([
      _notification('recovered-row', 100, now.add(const Duration(minutes: 1))),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('recovered-row'), findsOneWidget);
    expect(find.text('오류가 발생했습니다.'), findsNothing);
  });

  testWidgets(
    'mark all keeps personal rows fetched after the server update unread',
    (tester) async {
      final now = DateTime.utc(2026, 9, 13, 12);
      final initialPersonal = List.generate(
        20,
        (i) => _notification(
          'initial-personal-${20 - i}',
          200 - i,
          now.subtract(Duration(minutes: i)),
          userId: 'user-a',
        ),
      );
      final broadcast = List.generate(
        20,
        (i) => _notification(
          'broadcast-${20 - i}',
          400 - i,
          now.subtract(Duration(hours: 1, minutes: i)),
        ),
      );
      final maxId = Completer<int?>();
      final source =
          _PageSource(personal: initialPersonal, broadcast: broadcast)
            ..currentUserId = 'user-a'
            ..personalUpdateResult = const []
            ..pendingBroadcastMaxId = maxId;
      await tester.pumpWidget(
        buildTestAppPage(
          NotificationsPage(service: _service(source, _MemoryStorage())),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextButton));
      await tester.pump();
      source.personal.addAll(
        List.generate(
          20,
          (i) => _notification(
            'inserted-personal-${20 - i}',
            100 - i,
            now.subtract(Duration(hours: 2, minutes: i)),
            userId: 'user-a',
          ),
        ),
      );
      final controller = tester
          .widget<ListView>(find.byType(ListView))
          .controller!;
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(find.text('broadcast-20'), findsOneWidget);

      maxId.complete(400);
      await tester.pumpAndSettle();
      final initialTile = find.byKey(const ValueKey('personal:181'));
      expect(initialTile, findsOneWidget);
      expect(
        find.descendant(of: initialTile, matching: find.byType(Stack)),
        findsNothing,
      );
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();

      final insertedTile = find.byKey(const ValueKey('personal:81'));
      expect(insertedTile, findsOneWidget);
      expect(
        find.descendant(of: insertedTile, matching: find.byType(Stack)),
        findsOneWidget,
      );
    },
  );
}
