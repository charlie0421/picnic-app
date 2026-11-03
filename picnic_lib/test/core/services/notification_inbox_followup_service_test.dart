import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/core/services/notification_inbox_pager.dart';
import 'package:picnic_lib/core/services/notification_inbox_service.dart';
import 'package:picnic_lib/data/models/inbox_notification.dart';
import 'package:picnic_lib/data/models/user_notification.dart';
import 'package:picnic_lib/data/storage/broadcast_notification_read_store.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthClientOptions, SupabaseClient;

class _MemoryStorage implements LocalStorage {
  final Map<String, String> values = {};
  bool failSave = false;
  @override
  Future<String?> loadData(String key, String? defaultValue) async =>
      values[key] ?? defaultValue;
  @override
  Future<void> saveData(String key, String value) async {
    if (failSave) throw StateError('save failed');
    values[key] = value;
  }

  @override
  Future<void> removeData(String key) async => values.remove(key);
  @override
  Future<void> clearStorage() async => values.clear();
}

class _ServiceSource implements NotificationInboxDataSource {
  @override
  String? currentUserId = 'user-a';
  final List<int> broadcastIds = [];
  final List<String> personalCalls = [];
  bool failPersonalUpdate = false;
  bool returnPersonalRow = true;
  bool insertAfterFirstBroadcastChunk = false;
  int broadcastChunkCalls = 0;
  int broadcastMaxCalls = 0;
  Future<List<int>>? pendingPersonalUpdate;

  @override
  Future<List<UserNotification>> fetchPersonal({
    required String userId,
    required NotificationCursor? cursor,
    required int limit,
  }) async => [];
  @override
  Future<List<UserNotification>> fetchBroadcast({
    required NotificationCursor? cursor,
    required int limit,
  }) async => [];

  @override
  Future<List<int>> updatePersonalRead({
    required String userId,
    int? id,
  }) async {
    personalCalls.add('$userId:${id ?? 'all'}');
    if (pendingPersonalUpdate != null) return pendingPersonalUpdate!;
    if (failPersonalUpdate) throw StateError('personal update failed');
    if (id != null && !returnPersonalRow) return [];
    return id == null ? const [] : [id];
  }

  @override
  Future<int?> fetchBroadcastMaxId() async {
    broadcastMaxCalls++;
    return broadcastIds.isEmpty
        ? null
        : broadcastIds.reduce((a, b) => a > b ? a : b);
  }

  @override
  Future<List<int>> fetchBroadcastIds({
    required int afterId,
    required int maxId,
    required int limit,
  }) async {
    broadcastChunkCalls++;
    final page =
        (broadcastIds.where((id) => id > afterId && id <= maxId).toList()
              ..sort())
            .take(limit)
            .toList();
    if (insertAfterFirstBroadcastChunk && broadcastChunkCalls == 1) {
      broadcastIds.add(maxId + 1);
    }
    return page;
  }
}

InboxNotification _inbox(NotificationSource source, int id) =>
    InboxNotification(
      source: source,
      notification: UserNotification(
        id: id,
        userId: source == NotificationSource.personal ? 'user-a' : null,
        title: const {'en': 'title'},
        body: const {'en': 'body'},
        createdAt: '2026-09-13T00:00:00Z',
      ),
    );

void main() {
  test(
    'same numeric id routes personal and broadcast reads independently',
    () async {
      final storage = _MemoryStorage();
      final source = _ServiceSource();
      final service = NotificationInboxService(
        source: source,
        readStore: BroadcastNotificationReadStore(storage: storage),
      );

      expect(
        await service.markNotificationRead(
          _inbox(NotificationSource.broadcast, 7),
        ),
        isTrue,
      );
      expect(
        await service.markNotificationRead(
          _inbox(NotificationSource.personal, 7),
        ),
        isTrue,
      );

      expect(source.personalCalls, ['user-a:7']);
      expect(await service.readStore.readIds('user-a'), {7});
    },
  );

  test('personal zero-row update is not reported as read', () async {
    final source = _ServiceSource()..returnPersonalRow = false;
    final service = NotificationInboxService(
      source: source,
      readStore: BroadcastNotificationReadStore(storage: _MemoryStorage()),
    );

    expect(
      await service.markNotificationRead(
        _inbox(NotificationSource.personal, 99),
      ),
      isFalse,
    );
  });

  test('broadcast storage failure remains unread and can be retried', () async {
    final storage = _MemoryStorage()..failSave = true;
    final service = NotificationInboxService(
      source: _ServiceSource(),
      readStore: BroadcastNotificationReadStore(storage: storage),
    );

    expect(
      await service.markNotificationRead(
        _inbox(NotificationSource.broadcast, 3),
      ),
      isFalse,
    );
    storage.failSave = false;
    expect(await service.readStore.readIds('user-a'), isEmpty);
    expect(
      await service.markNotificationRead(
        _inbox(NotificationSource.broadcast, 3),
      ),
      isTrue,
    );
  });

  test(
    'account switch prevents a completed old-account read from reaching UI',
    () async {
      final pending = Completer<List<int>>();
      final source = _ServiceSource()..pendingPersonalUpdate = pending.future;
      final service = NotificationInboxService(
        source: source,
        readStore: BroadcastNotificationReadStore(storage: _MemoryStorage()),
      );

      final marking = service.markNotificationRead(
        _inbox(NotificationSource.personal, 7),
      );
      await Future<void>.delayed(Duration.zero);
      source.currentUserId = 'user-b';
      pending.complete([7]);

      expect(await marking, isFalse);
      expect(source.personalCalls, ['user-a:7']);
    },
  );

  test('mark all reports per-source partial success', () async {
    final source = _ServiceSource()
      ..failPersonalUpdate = true
      ..broadcastIds.addAll([1, 2, 3]);
    final service = NotificationInboxService(
      source: source,
      readStore: BroadcastNotificationReadStore(storage: _MemoryStorage()),
    );

    final result = await service.markAllNotificationsRead();

    expect(result.personalSucceeded, isFalse);
    expect(result.broadcastSucceeded, isTrue);
    expect(await service.readStore.readIds('user-a'), {1, 2, 3});
  });

  test('broadcast mark-all failure does not erase personal success', () async {
    final storage = _MemoryStorage()..failSave = true;
    final service = NotificationInboxService(
      source: _ServiceSource(),
      readStore: BroadcastNotificationReadStore(storage: storage),
    );

    final result = await service.markAllNotificationsRead();

    expect(result.personalSucceeded, isTrue);
    expect(result.broadcastSucceeded, isFalse);
  });

  test(
    'mark all scans more than 400 broadcasts and excludes later insertion',
    () async {
      final source = _ServiceSource()
        ..broadcastIds.addAll(List.generate(450, (index) => index + 1))
        ..insertAfterFirstBroadcastChunk = true;
      final service = NotificationInboxService(
        source: source,
        readStore: BroadcastNotificationReadStore(storage: _MemoryStorage()),
        broadcastScanPageSize: 200,
      );

      final result = await service.markAllNotificationsRead();
      final ids = await service.readStore.readIds('user-a');

      expect(result.broadcastSucceeded, isTrue);
      expect(ids.length, 450);
      expect(ids, isNot(contains(451)));
      expect(source.broadcastChunkCalls, 3);
    },
  );

  test(
    'mark all captures the broadcast max before a slow personal update',
    () async {
      final personalUpdate = Completer<List<int>>();
      final source = _ServiceSource()
        ..broadcastIds.add(1)
        ..pendingPersonalUpdate = personalUpdate.future;
      final service = NotificationInboxService(
        source: source,
        readStore: BroadcastNotificationReadStore(storage: _MemoryStorage()),
      );

      final marking = service.markAllNotificationsRead();
      await Future<void>.delayed(Duration.zero);
      final maxCallsBeforePersonalCompletes = source.broadcastMaxCalls;
      source.broadcastIds.add(2);
      personalUpdate.complete(const []);
      final result = await marking;

      expect(maxCallsBeforePersonalCompletes, 1);
      expect(result.broadcastReadIds, {1});
      expect(await service.readStore.readIds('user-a'), {1});
    },
  );

  test(
    'Supabase data source sends captured user and id filters and returns zero rows',
    () async {
      late http.Request captured;
      final client = SupabaseClient(
        'https://example.invalid',
        'anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode(<Object>[]),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final source = SupabaseNotificationInboxDataSource(client: client);

      final rows = await source.updatePersonalRead(userId: 'user-a', id: 42);

      expect(rows, isEmpty);
      expect(captured.method, 'PATCH');
      expect(captured.url.queryParameters['user_id'], 'eq.user-a');
      expect(captured.url.queryParameters['id'], 'eq.42');
      expect(captured.url.queryParameters['select'], 'id');
    },
  );

  test(
    'Supabase fetch uses timestamp/id cursor and matching tie order',
    () async {
      late Uri captured;
      final client = SupabaseClient(
        'https://example.invalid',
        'anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          captured = request.url;
          return http.Response(
            jsonEncode(<Object>[]),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await SupabaseNotificationInboxDataSource(client: client).fetchPersonal(
        userId: 'user-a',
        cursor: const NotificationCursor(
          createdAt: '2026-09-13T01:02:03.000Z',
          id: 42,
        ),
        limit: 20,
      );

      expect(captured.queryParameters['user_id'], 'eq.user-a');
      expect(
        captured.queryParameters['order'],
        'created_at.desc.nullslast,id.desc.nullslast',
      );
      expect(captured.queryParameters['or'], contains('id.lt.42'));
    },
  );
}
