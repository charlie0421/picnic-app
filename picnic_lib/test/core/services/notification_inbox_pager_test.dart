import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/notification_inbox_pager.dart';
import 'package:picnic_lib/data/models/inbox_notification.dart';
import 'package:picnic_lib/data/models/user_notification.dart';
import 'package:picnic_lib/data/storage/broadcast_notification_read_store.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';

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

class _FakeSource implements NotificationInboxDataSource {
  _FakeSource({
    List<UserNotification>? personal,
    List<UserNotification>? broadcast,
  }) : personal = personal ?? [],
       broadcast = broadcast ?? [];

  @override
  String? currentUserId = 'user-a';
  final List<UserNotification> personal;
  final List<UserNotification> broadcast;
  int personalFetches = 0;
  int broadcastFetches = 0;
  int failPersonal = 0;
  int failBroadcast = 0;
  bool controlPersonal = false;
  final List<Completer<List<UserNotification>>> personalRequests = [];

  List<UserNotification> _page(
    List<UserNotification> rows,
    NotificationCursor? cursor,
    int limit,
  ) {
    final eligible =
        rows.where((row) {
          if (cursor == null) return true;
          final created = row.createdAt!;
          return created.compareTo(cursor.createdAt) < 0 ||
              (created == cursor.createdAt && row.id < cursor.id);
        }).toList()..sort((a, b) {
          final time = b.createdAt!.compareTo(a.createdAt!);
          return time != 0 ? time : b.id.compareTo(a.id);
        });
    return eligible.take(limit).toList();
  }

  @override
  Future<List<UserNotification>> fetchPersonal({
    required String userId,
    required NotificationCursor? cursor,
    required int limit,
  }) async {
    personalFetches++;
    if (controlPersonal) {
      final request = Completer<List<UserNotification>>();
      personalRequests.add(request);
      return request.future;
    }
    if (failPersonal-- > 0) throw StateError('personal failed');
    return _page(personal, cursor, limit);
  }

  @override
  Future<List<UserNotification>> fetchBroadcast({
    required NotificationCursor? cursor,
    required int limit,
  }) async {
    broadcastFetches++;
    if (failBroadcast-- > 0) throw StateError('broadcast failed');
    return _page(broadcast, cursor, limit);
  }

  @override
  Future<List<int>> updatePersonalRead({
    required String userId,
    int? id,
  }) async => id == null ? personal.map((row) => row.id).toList() : [id];

  @override
  Future<int?> fetchBroadcastMaxId() async => broadcast.isEmpty
      ? null
      : broadcast.map((row) => row.id).reduce((a, b) => a > b ? a : b);

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

UserNotification _notification(int id, DateTime createdAt) => UserNotification(
  id: id,
  title: {'en': 'n$id'},
  body: {'en': 'b$id'},
  createdAt: createdAt.toUtc().toIso8601String(),
);

NotificationInboxPager _pager(_FakeSource source, {int sourcePageSize = 20}) =>
    NotificationInboxPager(
      source: source,
      readStore: BroadcastNotificationReadStore(storage: _MemoryStorage()),
      accountId: source.currentUserId,
      sourcePageSize: sourcePageSize,
    );

void main() {
  test(
    'overlapping nextPage calls coalesce without consuming page one',
    () async {
      final now = DateTime.utc(2026, 9, 13);
      final source = _FakeSource()..controlPersonal = true;
      final pager = _pager(source);

      final first = pager.nextPage(limit: 20);
      final second = pager.nextPage(limit: 20);
      await Future<void>.delayed(Duration.zero);

      expect(source.personalRequests, hasLength(1));
      source.personalRequests.single.complete([_notification(1, now)]);
      final pages = await Future.wait([first, second]);

      expect(pages[0].items.map((item) => item.identity), ['personal:1']);
      expect(pages[1].items.map((item) => item.identity), ['personal:1']);
      expect(source.personalFetches, 1);
    },
  );

  test('returns correct boundaries for 0, 1, 20, and 21 rows', () async {
    for (final count in [0, 1, 20, 21]) {
      final now = DateTime.utc(2026, 9, 13);
      final source = _FakeSource(
        personal: List.generate(
          count,
          (i) => _notification(count - i, now.subtract(Duration(minutes: i))),
        ),
      );
      final pager = _pager(source);
      final seen = <int>[];
      while (pager.hasMore) {
        final page = await pager.nextPage(limit: 20);
        seen.addAll(page.items.map((item) => item.id));
      }
      expect(seen.length, count, reason: 'count=$count');
    }
  });

  test('merges globally, including the newest forty from one source', () async {
    final now = DateTime.utc(2026, 9, 13);
    final source = _FakeSource(
      personal: List.generate(
        50,
        (i) => _notification(1000 - i, now.subtract(Duration(minutes: i))),
      ),
      broadcast: List.generate(
        20,
        (i) => _notification(
          2000 - i,
          now.subtract(Duration(days: 1, minutes: i)),
        ),
      ),
    );
    final pager = _pager(source);

    final first = await pager.nextPage(limit: 20);
    final second = await pager.nextPage(limit: 20);

    expect(
      [
        ...first.items,
        ...second.items,
      ].every((item) => item.source == NotificationSource.personal),
      isTrue,
    );
  });

  test(
    'timestamp ties are ordered by id descending and source ids do not collide',
    () async {
      final time = DateTime.utc(2026, 9, 13);
      final source = _FakeSource(
        personal: [_notification(2, time), _notification(1, time)],
        broadcast: [_notification(2, time), _notification(1, time)],
      );

      final page = await _pager(source).nextPage(limit: 20);

      expect(page.items.map((item) => item.id), [2, 2, 1, 1]);
      expect(page.items.map((item) => item.identity).toSet().length, 4);
    },
  );

  test(
    'a partial first-page failure retains success and retries only failed source',
    () async {
      final now = DateTime.utc(2026, 9, 13);
      final source = _FakeSource(
        personal: [_notification(1, now)],
        broadcast: [_notification(2, now.subtract(const Duration(minutes: 1)))],
      )..failBroadcast = 1;
      final pager = _pager(source);

      await expectLater(
        pager.nextPage(limit: 20),
        throwsA(isA<NotificationPageLoadException>()),
      );
      expect(source.personalFetches, 1);
      final recovered = await pager.nextPage(limit: 20);

      expect(source.personalFetches, 1);
      expect(source.broadcastFetches, 2);
      expect(recovered.items.map((item) => item.identity).toSet().length, 2);
    },
  );

  test(
    'an append failure retains the other source buffer and retries without gaps',
    () async {
      final now = DateTime.utc(2026, 9, 13);
      final source = _FakeSource(
        personal: List.generate(
          25,
          (i) => _notification(100 - i, now.subtract(Duration(minutes: i))),
        ),
        broadcast: List.generate(
          20,
          (i) => _notification(
            200 - i,
            now.subtract(Duration(days: 1, minutes: i)),
          ),
        ),
      );
      final pager = _pager(source);
      final first = await pager.nextPage(limit: 20);
      source.failPersonal = 1;

      await expectLater(
        pager.nextPage(limit: 20),
        throwsA(isA<NotificationPageLoadException>()),
      );
      final recovered = await pager.nextPage(limit: 20);

      expect(first.items, hasLength(20));
      expect(recovered.items, hasLength(20));
      expect(
        [
          ...first.items,
          ...recovered.items,
        ].map((item) => item.identity).toSet().length,
        40,
      );
    },
  );

  test(
    'pages beyond four hundred without duplicates and stops fetching at end',
    () async {
      final now = DateTime.utc(2026, 9, 13);
      final source = _FakeSource(
        personal: List.generate(
          451,
          (i) => _notification(1000 - i, now.subtract(Duration(minutes: i))),
        ),
      );
      final pager = _pager(source);
      final identities = <String>{};
      while (pager.hasMore) {
        final page = await pager.nextPage(limit: 20);
        identities.addAll(page.items.map((item) => item.identity));
      }
      final fetchesAtEnd = source.personalFetches + source.broadcastFetches;

      final extra = await pager.nextPage(limit: 20);

      expect(identities.length, 451);
      expect(extra.items, isEmpty);
      expect(source.personalFetches + source.broadcastFetches, fetchesAtEnd);
    },
  );

  test(
    'an insertion newer than the cursor is not duplicated into later pages',
    () async {
      final now = DateTime.utc(2026, 9, 13);
      final source = _FakeSource(
        personal: List.generate(
          25,
          (i) => _notification(100 - i, now.subtract(Duration(minutes: i))),
        ),
      );
      final pager = _pager(source);
      final first = await pager.nextPage(limit: 20);
      source.personal.add(
        _notification(999, now.add(const Duration(minutes: 1))),
      );
      final second = await pager.nextPage(limit: 20);

      final all = [...first.items, ...second.items];
      expect(all.length, 25);
      expect(all.any((item) => item.id == 999), isFalse);
      expect(all.map((item) => item.identity).toSet().length, 25);
    },
  );

  test(
    'mark-all read overlay applies to later buffered and fetched broadcasts',
    () async {
      final now = DateTime.utc(2026, 9, 13);
      final source = _FakeSource(
        broadcast: List.generate(
          40,
          (i) => _notification(40 - i, now.subtract(Duration(minutes: i))),
        ),
      );
      final storage = _MemoryStorage();
      final store = BroadcastNotificationReadStore(storage: storage);
      final pager = NotificationInboxPager(
        source: source,
        readStore: store,
        accountId: source.currentUserId,
      );
      await pager.nextPage(limit: 20);
      final ids = Set<int>.from(List.generate(40, (index) => index + 1));
      await store.markAllRead('user-a', ids);
      pager.applyReadIds(broadcastIds: ids);

      final next = await pager.nextPage(limit: 20);

      expect(next.items, hasLength(20));
      expect(next.items.every((item) => item.isRead), isTrue);
    },
  );

  test(
    'personal mark-all overlays only the buffered snapshot when update ids truncate',
    () async {
      final now = DateTime.utc(2026, 9, 13);
      final source = _FakeSource(
        personal: List.generate(
          40,
          (i) => _notification(40 - i, now.subtract(Duration(minutes: i))),
        ),
      );
      final pager = _pager(source, sourcePageSize: 40);
      await pager.nextPage(limit: 20);
      final targeted = pager.snapshotBufferedPersonalIds();

      pager.applyReadIds(personalIds: targeted);
      final next = await pager.nextPage(limit: 20);

      expect(next.items, hasLength(20));
      expect(next.items.every((item) => item.isRead), isTrue);
    },
  );
}
