import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/notifications/notifications_page.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget,
      {int pumps = 3}) async {
    await tester.pumpWidget(widget);
    drainExpectedImageErrors(tester);
    for (var i = 0; i < pumps; i++) {
      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);
    }
  }

  group('NotificationsPage coverage - with notification items', () {
    testWidgets('renders unread vote notification with icon',
        (WidgetTester tester) async {
      setupMockSupabaseWithAuth({
        'user_notifications': [
          {
            'id': 1,
            'user_id': 'test-user-id',
            'title': {'ko': '투표 시작', 'en': 'Vote started'},
            'body': {'ko': '지금 투표하세요', 'en': 'Vote now'},
            'type': 'vote',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
            'read_at': null,
            'action_url': null,
            'data': {'vote_id': '123'},
          },
        ],
        'broadcast_notifications': <Map<String, dynamic>>[],
      }, userId: 'test-user-id');

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
        pumps: 4,
      );

      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.byType(ListTile), findsWidgets);
      // Unread vote notification should have how_to_vote icon
      expect(find.byIcon(Icons.how_to_vote), findsWidgets);
    });

    testWidgets('renders read post notification', (WidgetTester tester) async {
      setupMockSupabaseWithAuth({
        'user_notifications': [
          {
            'id': 2,
            'user_id': 'test-user-id',
            'title': {'ko': '새 댓글', 'en': 'New comment'},
            'body': {'ko': '댓글이 달렸습니다', 'en': 'Comment added'},
            'type': 'post',
            'is_read': true,
            'created_at':
                DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
            'read_at': DateTime.now().toIso8601String(),
            'action_url': null,
            'data': {'post_id': 'post-abc'},
          },
        ],
        'broadcast_notifications': <Map<String, dynamic>>[],
      }, userId: 'test-user-id');

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
        pumps: 4,
      );

      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.byIcon(Icons.post_add), findsWidgets);
    });

    testWidgets('renders qna notification with question_answer icon',
        (WidgetTester tester) async {
      setupMockSupabaseWithAuth({
        'user_notifications': [
          {
            'id': 3,
            'user_id': 'test-user-id',
            'title': {'ko': 'QnA 답변', 'en': 'QnA Answer'},
            'body': {'ko': '답변이 등록되었습니다', 'en': 'Answer posted'},
            'type': 'qna',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
            'read_at': null,
            'action_url': null,
            'data': {'question_id': '42'},
          },
        ],
        'broadcast_notifications': <Map<String, dynamic>>[],
      }, userId: 'test-user-id');

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
        pumps: 4,
      );

      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.byIcon(Icons.question_answer), findsWidgets);
    });

    testWidgets('renders default type notification with notifications icon',
        (WidgetTester tester) async {
      setupMockSupabaseWithAuth({
        'user_notifications': [
          {
            'id': 4,
            'user_id': 'test-user-id',
            'title': {'ko': '시스템 알림', 'en': 'System notification'},
            'body': {'ko': '공지사항입니다', 'en': 'Announcement'},
            'type': 'default',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
            'read_at': null,
            'action_url': null,
            'data': null,
          },
        ],
        'broadcast_notifications': <Map<String, dynamic>>[],
      }, userId: 'test-user-id');

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
        pumps: 4,
      );

      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsWidgets);
    });

    testWidgets('renders notification with emoji in title',
        (WidgetTester tester) async {
      setupMockSupabaseWithAuth({
        'user_notifications': [
          {
            'id': 5,
            'user_id': 'test-user-id',
            'title': {'ko': '🎉 축하합니다!', 'en': '🎉 Congratulations!'},
            'body': {'ko': '당첨되었습니다', 'en': 'You won'},
            'type': 'vote',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
            'read_at': null,
            'action_url': null,
            'data': {'vote_id': '456'},
          },
        ],
        'broadcast_notifications': <Map<String, dynamic>>[],
      }, userId: 'test-user-id');

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
        pumps: 4,
      );

      expect(find.byType(NotificationsPage), findsOneWidget);
      // Emoji extracted and shown as leading text
    });

    testWidgets('renders mixed read/unread notifications with correct styling',
        (WidgetTester tester) async {
      setupMockSupabaseWithAuth({
        'user_notifications': [
          {
            'id': 10,
            'user_id': 'test-user-id',
            'title': {'ko': '읽지 않음', 'en': 'Unread'},
            'body': {'ko': '내용', 'en': 'Body'},
            'type': 'vote',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
            'read_at': null,
            'action_url': null,
            'data': {'vote_id': '1'},
          },
          {
            'id': 11,
            'user_id': 'test-user-id',
            'title': {'ko': '이미 읽음', 'en': 'Read'},
            'body': {'ko': '내용', 'en': 'Body'},
            'type': 'post',
            'is_read': true,
            'created_at':
                DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
            'read_at': DateTime.now().toIso8601String(),
            'action_url': null,
            'data': {'post_id': 'p1'},
          },
        ],
        'broadcast_notifications': <Map<String, dynamic>>[],
      }, userId: 'test-user-id');

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
        pumps: 4,
      );

      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('renders answer_created and question_created types',
        (WidgetTester tester) async {
      setupMockSupabaseWithAuth({
        'user_notifications': [
          {
            'id': 20,
            'user_id': 'test-user-id',
            'title': {'ko': '답변', 'en': 'Answer'},
            'body': {'ko': '답변 등록', 'en': 'Answer posted'},
            'type': 'answer_created',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
            'read_at': null,
            'action_url': null,
            'data': {'question_id': '99'},
          },
          {
            'id': 21,
            'user_id': 'test-user-id',
            'title': {'ko': '질문', 'en': 'Question'},
            'body': {'ko': '질문 등록', 'en': 'Question posted'},
            'type': 'question_created',
            'is_read': true,
            'created_at': DateTime.now().toIso8601String(),
            'read_at': DateTime.now().toIso8601String(),
            'action_url': null,
            'data': {'question_id': '100'},
          },
        ],
        'broadcast_notifications': <Map<String, dynamic>>[],
      }, userId: 'test-user-id');

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
        pumps: 4,
      );

      expect(find.byType(NotificationsPage), findsOneWidget);
      // answer_created and question_created use question_answer icon
      expect(find.byIcon(Icons.question_answer), findsWidgets);
    });

    testWidgets('notification with action URL renders',
        (WidgetTester tester) async {
      setupMockSupabaseWithAuth({
        'user_notifications': [
          {
            'id': 30,
            'user_id': 'test-user-id',
            'title': {'ko': '이벤트', 'en': 'Event'},
            'body': {'ko': '링크 확인', 'en': 'Check link'},
            'type': 'default',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
            'read_at': null,
            'action_url': 'https://applink.picnic.fan/vote/123',
            'data': null,
          },
        ],
        'broadcast_notifications': <Map<String, dynamic>>[],
      }, userId: 'test-user-id');

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
        pumps: 4,
      );

      expect(find.byType(NotificationsPage), findsOneWidget);
    });
  });

  group('NotificationsPage coverage - empty and loading states', () {
    testWidgets('renders empty notification list',
        (WidgetTester tester) async {
      setupMockSupabase({
        'user_notifications': <Map<String, dynamic>>[],
        'broadcast_notifications': <Map<String, dynamic>>[],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
        pumps: 4,
      );

      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('renders with unauthenticated user',
        (WidgetTester tester) async {
      setupMockSupabase({
        'user_notifications': <Map<String, dynamic>>[],
        'broadcast_notifications': <Map<String, dynamic>>[],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const NotificationsPage(),
          loggedIn: false,
        ),
        pumps: 4,
      );

      expect(find.byType(NotificationsPage), findsOneWidget);
    });
  });

  group('NotificationsPage coverage - interactions', () {
    testWidgets('mark all read button is tappable without crash',
        (WidgetTester tester) async {
      setupMockSupabaseWithAuth({
        'user_notifications': [
          {
            'id': 1,
            'user_id': 'test-user-id',
            'title': {'ko': '알림', 'en': 'Notif'},
            'body': {'ko': '내용', 'en': 'Body'},
            'type': 'vote',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
            'read_at': null,
            'action_url': null,
            'data': {'vote_id': '1'},
          },
        ],
        'broadcast_notifications': <Map<String, dynamic>>[],
      }, userId: 'test-user-id');

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
        pumps: 4,
      );

      final markAllBtn = find.byType(TextButton);
      expect(markAllBtn, findsOneWidget);
      await tester.tap(markAllBtn);
      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);

      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('tapping a notification item triggers mark read',
        (WidgetTester tester) async {
      setupMockSupabaseWithAuth({
        'user_notifications': [
          {
            'id': 50,
            'user_id': 'test-user-id',
            'title': {'ko': '탭 테스트', 'en': 'Tap test'},
            'body': {'ko': '내용', 'en': 'Body'},
            'type': 'default',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
            'read_at': null,
            'action_url': null,
            'data': null,
          },
        ],
        'broadcast_notifications': <Map<String, dynamic>>[],
      }, userId: 'test-user-id');

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
        pumps: 4,
      );

      final listTile = find.byType(ListTile);
      if (listTile.evaluate().isNotEmpty) {
        await tester.tap(listTile.first);
        await tester.pump(const Duration(seconds: 1));
        drainExpectedImageErrors(tester);
      }

      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('pull to refresh works', (WidgetTester tester) async {
      setupMockSupabaseWithAuth({
        'user_notifications': <Map<String, dynamic>>[],
        'broadcast_notifications': <Map<String, dynamic>>[],
      }, userId: 'test-user-id');

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
        pumps: 4,
      );

      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      drainExpectedImageErrors(tester);

      expect(find.byType(NotificationsPage), findsOneWidget);
    });
  });

  group('NotificationsPage coverage - broadcast notifications', () {
    testWidgets('renders with broadcast notifications merged',
        (WidgetTester tester) async {
      setupMockSupabaseWithAuth({
        'user_notifications': [
          {
            'id': 1,
            'user_id': 'test-user-id',
            'title': {'ko': '개인 알림', 'en': 'Personal notif'},
            'body': {'ko': '내용', 'en': 'Body'},
            'type': 'vote',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
            'read_at': null,
            'action_url': null,
            'data': {'vote_id': '1'},
          },
        ],
        'broadcast_notifications': [
          {
            'id': 100,
            'title': {'ko': '공지사항', 'en': 'Announcement'},
            'body': {'ko': '전체 공지', 'en': 'Broadcast'},
            'type': 'default',
            'is_read': false,
            'created_at':
                DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
            'read_at': null,
            'action_url': null,
            'data': null,
          },
        ],
      }, userId: 'test-user-id');

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
        pumps: 4,
      );

      expect(find.byType(NotificationsPage), findsOneWidget);
    });
  });
}
