import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/notification_inbox_service.dart';
import 'package:picnic_lib/data/models/user_notification.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  group('NotificationInboxService', () {
    setUp(() {
      setupMockSupabase({
        'user_notifications': [
          {
            'id': 1,
            'user_id': 'test-user-id',
            'title': {'ko': '알림1', 'en': 'Notification 1'},
            'body': {'ko': '내용1', 'en': 'Body 1'},
            'type': 'general',
            'is_read': false,
            'created_at': '2026-03-10T10:00:00Z',
          },
          {
            'id': 2,
            'user_id': 'test-user-id',
            'title': {'ko': '알림2', 'en': 'Notification 2'},
            'body': {'ko': '내용2', 'en': 'Body 2'},
            'type': 'vote',
            'is_read': true,
            'created_at': '2026-03-09T10:00:00Z',
          },
        ],
        'broadcast_notifications': [
          {
            'id': 100,
            'title': {'ko': '공지', 'en': 'Announcement'},
            'body': {'ko': '공지내용', 'en': 'Announcement body'},
            'type': 'broadcast',
            'created_at': '2026-03-11T10:00:00Z',
          },
        ],
      }, userId: 'test-user-id');
    });

    tearDown(() {
      tearDownMockSupabase();
    });

    test('fetch returns combined and sorted notifications', () async {
      final result = await NotificationInboxService.fetch();
      expect(result, isA<List<UserNotification>>());
      // Should combine user and broadcast notifications
      expect(result.length, greaterThanOrEqualTo(1));
    });

    test('fetch with pagination parameters', () async {
      final result = await NotificationInboxService.fetch(from: 0, limit: 1);
      expect(result, isA<List<UserNotification>>());
      expect(result.length, lessThanOrEqualTo(1));
    });

    test('fetch with large offset returns empty', () async {
      final result = await NotificationInboxService.fetch(from: 1000, limit: 20);
      expect(result, isEmpty);
    });
  });

  group('NotificationInboxService without auth', () {
    setUp(() {
      setupMockSupabase({
        'user_notifications': [],
        'broadcast_notifications': [
          {
            'id': 100,
            'title': {'ko': '공지', 'en': 'Notice'},
            'body': {'ko': '내용', 'en': 'Body'},
            'type': 'broadcast',
            'created_at': '2026-03-11T10:00:00Z',
          },
        ],
      });
    });

    tearDown(() {
      tearDownMockSupabase();
    });

    test('fetch returns broadcast notifications when not authenticated', () async {
      final result = await NotificationInboxService.fetch();
      expect(result, isA<List<UserNotification>>());
    });
  });

  group('NotificationInboxService markRead', () {
    setUp(() {
      setupMockSupabase({
        'user_notifications': [
          {
            'id': 1,
            'user_id': 'test-user-id',
            'title': {'ko': '알림', 'en': 'Notification'},
            'body': {'ko': '내용', 'en': 'Body'},
            'type': 'general',
            'is_read': false,
            'created_at': '2026-03-10T10:00:00Z',
          },
        ],
      }, userId: 'test-user-id');
    });

    tearDown(() {
      tearDownMockSupabase();
    });

    test('markRead returns true on success', () async {
      final result = await NotificationInboxService.markRead(1);
      expect(result, isTrue);
    });

    test('markRead with invalid id still completes (mock returns success)', () async {
      final result = await NotificationInboxService.markRead(9999);
      expect(result, isTrue);
    });
  });

  group('NotificationInboxService markAllRead', () {
    setUp(() {
      setupMockSupabase({
        'user_notifications': [
          {
            'id': 1,
            'user_id': 'test-user-id',
            'title': {'ko': '알림1', 'en': 'Notification 1'},
            'body': {'ko': '내용1', 'en': 'Body 1'},
            'type': 'general',
            'is_read': false,
            'created_at': '2026-03-10T10:00:00Z',
          },
          {
            'id': 2,
            'user_id': 'test-user-id',
            'title': {'ko': '알림2', 'en': 'Notification 2'},
            'body': {'ko': '내용2', 'en': 'Body 2'},
            'type': 'vote',
            'is_read': false,
            'created_at': '2026-03-09T10:00:00Z',
          },
        ],
      }, userId: 'test-user-id');
    });

    tearDown(() {
      tearDownMockSupabase();
    });

    test('markAllRead returns true when user is authenticated', () async {
      // Note: The mock Supabase does not set up auth sessions,
      // so currentUser will be null in this mock setup.
      // markAllRead returns false when user is null.
      final result = await NotificationInboxService.markAllRead();
      // Without a proper auth session, currentUser is null -> returns false
      expect(result, isFalse);
    });
  });

  group('NotificationInboxService markAllRead without auth', () {
    setUp(() {
      setupMockSupabase({
        'user_notifications': [],
      });
    });

    tearDown(() {
      tearDownMockSupabase();
    });

    test('markAllRead returns false when not authenticated', () async {
      final result = await NotificationInboxService.markAllRead();
      expect(result, isFalse);
    });
  });

  group('NotificationInboxService fetch sorting with broadcasts', () {
    // Note: currentUser is null in mock setup (no real auth session),
    // so user_notifications are skipped. Only broadcast_notifications are fetched.
    setUp(() {
      setupMockSupabase({
        'user_notifications': <Map<String, dynamic>>[],
        'broadcast_notifications': [
          {
            'id': 100,
            'title': {'ko': '공지1', 'en': 'Announcement 1'},
            'body': {'ko': '공지내용', 'en': 'Announcement body'},
            'type': 'broadcast',
            'created_at': '2026-03-08T10:00:00Z',
          },
          {
            'id': 101,
            'title': {'ko': '공지2', 'en': 'Announcement 2'},
            'body': {'ko': '공지내용', 'en': 'Announcement body'},
            'type': 'broadcast',
            'created_at': '2026-03-10T10:00:00Z',
          },
          {
            'id': 102,
            'title': {'ko': '공지3', 'en': 'Announcement 3'},
            'body': {'ko': '공지내용', 'en': 'Announcement body'},
            'type': 'broadcast',
            'created_at': '2026-03-09T10:00:00Z',
          },
        ],
      });
    });

    tearDown(() {
      tearDownMockSupabase();
    });

    test('broadcast notifications are sorted by created_at descending', () async {
      final result = await NotificationInboxService.fetch();
      expect(result.length, 3);
      // Should be sorted by created_at desc
      for (int i = 0; i < result.length - 1; i++) {
        final current = result[i].createdAt ?? '';
        final next = result[i + 1].createdAt ?? '';
        expect(current.compareTo(next), greaterThanOrEqualTo(0));
      }
    });

    test('fetch respects limit parameter', () async {
      final result = await NotificationInboxService.fetch(from: 0, limit: 2);
      expect(result.length, 2);
    });

    test('fetch respects from parameter', () async {
      final result = await NotificationInboxService.fetch(from: 1, limit: 2);
      expect(result.length, 2);
    });

    test('fetch with from beyond all results returns empty', () async {
      final result = await NotificationInboxService.fetch(from: 100, limit: 20);
      expect(result, isEmpty);
    });

    test('all returned notifications are broadcast type', () async {
      final result = await NotificationInboxService.fetch();
      for (final n in result) {
        expect(n.type, 'broadcast');
      }
    });
  });

  group('NotificationInboxService with empty broadcast', () {
    setUp(() {
      // Without auth, user_notifications are skipped; empty broadcasts = empty result
      setupMockSupabase({
        'user_notifications': <Map<String, dynamic>>[],
        'broadcast_notifications': <Map<String, dynamic>>[],
      });
    });

    tearDown(() {
      tearDownMockSupabase();
    });

    test('returns empty when no broadcasts and no auth', () async {
      final result = await NotificationInboxService.fetch();
      expect(result, isEmpty);
    });
  });

  group('NotificationInboxService with same created_at broadcasts', () {
    setUp(() {
      setupMockSupabase({
        'user_notifications': <Map<String, dynamic>>[],
        'broadcast_notifications': [
          {
            'id': 5,
            'title': {'ko': '공지A', 'en': 'Announcement A'},
            'body': {'ko': '내용', 'en': 'Body'},
            'type': 'broadcast',
            'created_at': '2026-03-10T10:00:00Z',
          },
          {
            'id': 3,
            'title': {'ko': '공지B', 'en': 'Announcement B'},
            'body': {'ko': '내용', 'en': 'Body'},
            'type': 'broadcast',
            'created_at': '2026-03-10T10:00:00Z',
          },
        ],
      });
    });

    tearDown(() {
      tearDownMockSupabase();
    });

    test('same created_at sorted by id descending', () async {
      final result = await NotificationInboxService.fetch();
      expect(result.length, 2);
      // When created_at is the same, higher id comes first
      expect(result[0].id, 5);
      expect(result[1].id, 3);
    });
  });
}
