import 'package:picnic_lib/core/services/app_badge_service.dart';
import 'package:picnic_lib/core/services/notification_inbox_pager.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/inbox_notification.dart';
import 'package:picnic_lib/data/models/user_notification.dart';
import 'package:picnic_lib/data/storage/broadcast_notification_read_store.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseNotificationInboxDataSource
    implements NotificationInboxDataSource {
  SupabaseNotificationInboxDataSource({SupabaseClient? client})
    : _client = client ?? supabase;

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<UserNotification>> fetchPersonal({
    required String userId,
    required NotificationCursor? cursor,
    required int limit,
  }) async {
    var query = _client
        .from('user_notifications')
        .select('*')
        .eq('user_id', userId);
    if (cursor != null) query = query.or(_cursorFilter(cursor));
    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);
    return rows
        .map((row) => UserNotification.fromJson(row))
        .toList(growable: false);
  }

  @override
  Future<List<UserNotification>> fetchBroadcast({
    required NotificationCursor? cursor,
    required int limit,
  }) async {
    var query = _client.from('broadcast_notifications').select('*');
    if (cursor != null) query = query.or(_cursorFilter(cursor));
    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);
    return rows
        .map((row) => UserNotification.fromJson(row))
        .toList(growable: false);
  }

  String _cursorFilter(NotificationCursor cursor) =>
      'created_at.lt.${cursor.createdAt},and(created_at.eq.${cursor.createdAt},id.lt.${cursor.id})';

  @override
  Future<List<int>> updatePersonalRead({
    required String userId,
    int? id,
  }) async {
    var query = _client
        .from('user_notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('is_read', false);
    if (id != null) query = query.eq('id', id);
    final rows = await query.select('id');
    return rows
        .map((row) => row['id'])
        .whereType<int>()
        .toList(growable: false);
  }

  @override
  Future<int?> fetchBroadcastMaxId() async {
    final rows = await _client
        .from('broadcast_notifications')
        .select('id')
        .order('id', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return rows.first['id'] as int?;
  }

  @override
  Future<List<int>> fetchBroadcastIds({
    required int afterId,
    required int maxId,
    required int limit,
  }) async {
    final rows = await _client
        .from('broadcast_notifications')
        .select('id')
        .gt('id', afterId)
        .lte('id', maxId)
        .order('id', ascending: true)
        .limit(limit);
    return rows
        .map((row) => row['id'])
        .whereType<int>()
        .toList(growable: false);
  }
}

class MarkAllNotificationsReadResult {
  const MarkAllNotificationsReadResult({
    required this.accountId,
    required this.personalSucceeded,
    required this.broadcastSucceeded,
    required this.accountStillCurrent,
    this.personalReadIds = const {},
    this.broadcastReadIds = const {},
  });

  final String? accountId;
  final bool personalSucceeded;
  final bool broadcastSucceeded;
  final bool accountStillCurrent;
  final Set<int> personalReadIds;
  final Set<int> broadcastReadIds;

  bool get fullySucceeded =>
      personalSucceeded && broadcastSucceeded && accountStillCurrent;
}

class NotificationInboxService {
  NotificationInboxService({
    NotificationInboxDataSource? source,
    BroadcastNotificationReadStore? readStore,
    this.broadcastScanPageSize = 200,
  }) : source = source ?? SupabaseNotificationInboxDataSource(),
       readStore = readStore ?? BroadcastNotificationReadStore();

  final NotificationInboxDataSource source;
  final BroadcastNotificationReadStore readStore;
  final int broadcastScanPageSize;

  String? get currentAccountId => source.currentUserId;

  NotificationInboxPager createPager({String? accountId}) =>
      NotificationInboxPager(
        source: source,
        readStore: readStore,
        accountId: accountId ?? currentAccountId,
      );

  Future<bool> markNotificationRead(InboxNotification notification) async {
    final accountId = currentAccountId;
    try {
      if (notification.source == NotificationSource.personal) {
        if (accountId == null) return false;
        final rows = await source.updatePersonalRead(
          userId: accountId,
          id: notification.id,
        );
        if (rows.isEmpty || currentAccountId != accountId) return false;
        // ignore: unawaited_futures
        AppBadgeService.syncBadgeWithUnreadCount();
        return true;
      }

      await readStore.markRead(accountId, notification.id);
      return currentAccountId == accountId;
    } catch (error, stackTrace) {
      logger.e(
        'mark notification read failed',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<MarkAllNotificationsReadResult> markAllNotificationsRead() async {
    final accountId = currentAccountId;
    var personalSucceeded = accountId == null;
    var broadcastSucceeded = false;
    var personalReadIds = <int>{};
    var broadcastReadIds = <int>{};
    final Future<({Object? error, int? maxId, StackTrace? stackTrace})>
    broadcastMaxSnapshot = () async {
      try {
        return (
          error: null,
          maxId: await source.fetchBroadcastMaxId(),
          stackTrace: null,
        );
      } catch (error, stackTrace) {
        return (error: error, maxId: null, stackTrace: stackTrace);
      }
    }();

    if (accountId != null) {
      try {
        personalReadIds = (await source.updatePersonalRead(
          userId: accountId,
        )).toSet();
        personalSucceeded = true;
      } catch (error, stackTrace) {
        logger.e(
          'mark all personal notifications read failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    try {
      final maxSnapshot = await broadcastMaxSnapshot;
      if (maxSnapshot.error != null) {
        Error.throwWithStackTrace(maxSnapshot.error!, maxSnapshot.stackTrace!);
      }
      final maxId = maxSnapshot.maxId;
      final ids = <int>{};
      if (maxId != null) {
        var afterId = 0;
        while (true) {
          final page = await source.fetchBroadcastIds(
            afterId: afterId,
            maxId: maxId,
            limit: broadcastScanPageSize,
          );
          ids.addAll(page);
          if (page.length < broadcastScanPageSize) break;
          final nextAfterId = page.reduce(
            (left, right) => left > right ? left : right,
          );
          if (nextAfterId <= afterId) {
            throw StateError(
              'Broadcast notification ID cursor did not advance',
            );
          }
          afterId = nextAfterId;
        }
      }
      await readStore.markAllRead(accountId, ids);
      broadcastReadIds = ids;
      broadcastSucceeded = true;
    } catch (error, stackTrace) {
      logger.e(
        'mark all broadcast notifications read failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final accountStillCurrent = currentAccountId == accountId;
    if (accountId != null && personalSucceeded && accountStillCurrent) {
      // Keep the badge contract personal-only. A broadcast failure must not
      // unconditionally clear the badge.
      // ignore: unawaited_futures
      AppBadgeService.syncBadgeWithUnreadCount();
    }
    return MarkAllNotificationsReadResult(
      accountId: accountId,
      personalSucceeded: personalSucceeded,
      broadcastSucceeded: broadcastSucceeded,
      accountStillCurrent: accountStillCurrent,
      personalReadIds: personalReadIds,
      broadcastReadIds: broadcastReadIds,
    );
  }

  static NotificationInboxService get _default => NotificationInboxService();

  /// Legacy offset wrapper. New UI code uses [NotificationInboxPager].
  static Future<List<UserNotification>> fetch({
    int from = 0,
    int limit = 20,
  }) async {
    try {
      final service = _default;
      final pager = service.createPager(accountId: service.currentAccountId);
      final all = <InboxNotification>[];
      while (pager.hasMore && all.length < from + limit) {
        final page = await pager.nextPage(limit: limit);
        all.addAll(page.items);
      }
      final start = from.clamp(0, all.length);
      final end = (from + limit).clamp(start, all.length);
      return all
          .sublist(start, end)
          .map((item) => item.notification)
          .toList(growable: false);
    } catch (error, stackTrace) {
      logger.e(
        'legacy notification fetch failed',
        error: error,
        stackTrace: stackTrace,
      );
      return const [];
    }
  }

  static Future<bool> markRead(int id) => _default.markNotificationRead(
    InboxNotification(
      source: NotificationSource.personal,
      notification: UserNotification(id: id, title: const {}, body: const {}),
    ),
  );

  static Future<bool> markAllRead() async =>
      (await _default.markAllNotificationsRead()).fullySucceeded;
}
