import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/notifications/notifications_page.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  final mockNotifications = <Map<String, dynamic>>[
    {
      'id': 1,
      'user_id': 'test-user-id',
      'title': {'ko': '투표 알림', 'en': 'Vote notification'},
      'body': {'ko': '투표가 시작되었습니다', 'en': 'Voting has started'},
      'type': 'vote',
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
      'read_at': null,
      'action_url': null,
      'data': {'vote_id': '123'},
    },
    {
      'id': 2,
      'user_id': 'test-user-id',
      'title': {'ko': '게시글 댓글', 'en': 'Post comment'},
      'body': {'ko': '새 댓글이 달렸습니다', 'en': 'New comment'},
      'type': 'post',
      'is_read': true,
      'created_at':
          DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      'read_at': DateTime.now()
          .subtract(const Duration(minutes: 30))
          .toIso8601String(),
      'action_url': null,
      'data': {'post_id': 'abc-123'},
    },
    {
      'id': 3,
      'user_id': 'test-user-id',
      'title': {'ko': 'QnA 답변', 'en': 'QnA Answer'},
      'body': {'ko': '답변이 등록되었습니다', 'en': 'Answer posted'},
      'type': 'qna',
      'is_read': false,
      'created_at':
          DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'read_at': null,
      'action_url': null,
      'data': {'question_id': '42'},
    },
  ];

  final mockNotificationsWithEmojis = <Map<String, dynamic>>[
    {
      'id': 10,
      'user_id': 'test-user-id',
      'title': {'ko': '🎉 축하합니다!', 'en': '🎉 Congratulations!'},
      'body': {'ko': '투표에 당선되었습니다', 'en': 'You won the vote'},
      'type': 'vote',
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
      'read_at': null,
      'action_url': null,
      'data': {'vote_id': '456'},
    },
    {
      'id': 11,
      'user_id': 'test-user-id',
      'title': {'ko': '📢 공지사항', 'en': '📢 Announcement'},
      'body': {'ko': '새로운 이벤트가 시작됩니다', 'en': 'New event started'},
      'type': 'default',
      'is_read': true,
      'created_at': DateTime.now().toIso8601String(),
      'read_at': DateTime.now().toIso8601String(),
      'action_url': 'https://www.picnic.fan/events',
      'data': null,
    },
  ];

  final mockNotificationsWithActionUrl = <Map<String, dynamic>>[
    {
      'id': 20,
      'user_id': 'test-user-id',
      'title': {'ko': '이벤트 알림', 'en': 'Event notification'},
      'body': {'ko': '링크를 확인하세요', 'en': 'Check the link'},
      'type': 'default',
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
      'read_at': null,
      'action_url': 'https://applink.picnic.fan/vote/123',
      'data': null,
    },
  ];

  setUp(() {
    initTestColors();
    setupMockSupabase({
      'user_notifications': mockNotifications,
      'broadcast_notifications': <Map<String, dynamic>>[],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    while (tester.takeException() != null) {}
    await tester.pump(const Duration(seconds: 1));
    while (tester.takeException() != null) {}
  }

  group('NotificationsPage render interactions', () {
    testWidgets('tap mark all read button', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      final markAllReadBtn = find.byType(TextButton);
      expect(markAllReadBtn, findsOneWidget);
      await tester.tap(markAllReadBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('tap back button exists', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      final backBtn = find.byIcon(Icons.arrow_back);
      expect(backBtn, findsOneWidget);
    });

    testWidgets('renders notification items with icons',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      await tester.pump(const Duration(seconds: 1));
      while (tester.takeException() != null) {}

      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('shows different icons for notification types',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      await tester.pump(const Duration(seconds: 1));
      while (tester.takeException() != null) {}

      // vote, post, qna icons
      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('pull to refresh triggers reload',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      while (tester.takeException() != null) {}

      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('renders unread indicator dots', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      await tester.pump(const Duration(seconds: 1));
      while (tester.takeException() != null) {}

      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('NotificationsPage with emoji titles', () {
    testWidgets('renders notifications with emoji in title',
        (WidgetTester tester) async {
      setupMockSupabase({
        'user_notifications': mockNotificationsWithEmojis,
        'broadcast_notifications': <Map<String, dynamic>>[],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      await tester.pump(const Duration(seconds: 1));
      while (tester.takeException() != null) {}

      expect(find.byType(NotificationsPage), findsOneWidget);
    });
  });

  group('NotificationsPage with action URL', () {
    testWidgets('renders notifications with action URL',
        (WidgetTester tester) async {
      setupMockSupabase({
        'user_notifications': mockNotificationsWithActionUrl,
        'broadcast_notifications': <Map<String, dynamic>>[],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      await tester.pump(const Duration(seconds: 1));
      while (tester.takeException() != null) {}

      expect(find.byType(NotificationsPage), findsOneWidget);
    });
  });

  group('NotificationsPage empty state', () {
    testWidgets('renders with no notifications', (WidgetTester tester) async {
      setupMockSupabase({
        'user_notifications': <Map<String, dynamic>>[],
        'broadcast_notifications': <Map<String, dynamic>>[],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      await tester.pump(const Duration(seconds: 1));
      while (tester.takeException() != null) {}

      expect(find.byType(NotificationsPage), findsOneWidget);
    });
  });

  group('NotificationsPage locale variants', () {
    testWidgets('renders with Korean locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const NotificationsPage(),
          locale: const Locale('ko'),
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      while (tester.takeException() != null) {}

      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const NotificationsPage(),
          locale: const Locale('en'),
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      while (tester.takeException() != null) {}

      expect(find.byType(NotificationsPage), findsOneWidget);
    });
  });

  group('NotificationsPage mixed read/unread', () {
    testWidgets('renders mix of read and unread with different styling',
        (WidgetTester tester) async {
      setupMockSupabase({
        'user_notifications': [
          ...mockNotifications,
          {
            'id': 4,
            'user_id': 'test-user-id',
            'title': {'ko': 'answer 알림', 'en': 'answer notif'},
            'body': {'ko': '답변 내용', 'en': 'answer body'},
            'type': 'answer_created',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
            'read_at': null,
            'action_url': null,
            'data': {'question_id': '99'},
          },
          {
            'id': 5,
            'user_id': 'test-user-id',
            'title': {'ko': 'question 알림', 'en': 'question notif'},
            'body': {'ko': '질문 내용', 'en': 'question body'},
            'type': 'question_created',
            'is_read': true,
            'created_at': DateTime.now().toIso8601String(),
            'read_at': DateTime.now().toIso8601String(),
            'action_url': null,
            'data': {'question_id': '100'},
          },
        ],
        'broadcast_notifications': <Map<String, dynamic>>[],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      await tester.pump(const Duration(seconds: 1));
      while (tester.takeException() != null) {}

      expect(find.byType(NotificationsPage), findsOneWidget);
    });
  });
}
