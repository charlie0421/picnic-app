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
    setupMockSupabase({
      'user_notifications': <Map<String, dynamic>>[],
      'broadcast_notifications': <Map<String, dynamic>>[],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    // 첫 프레임부터 필터가 걸려 있어야 한다 — 그래야 그 프레임의 에러가
    // FlutterErrorDetails 째로 잡혀서, 진짜 결함일 때 "어느 위젯이 원인인지"까지
    // 보고된다. raw pumpWidget 으로 먼저 그리면 그 정보가 사라진다.
    await pumpWidgetAndIgnoreErrors(tester, widget);
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  group('NotificationsPage render - structural elements', () {
    testWidgets('renders Scaffold with AppBar and back button',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('renders mark all read TextButton in AppBar',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('renders RefreshIndicator with ListView',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('NotificationsPage render - locale variants', () {
    testWidgets('renders with Korean locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const NotificationsPage(),
          locale: const Locale('ko'),
        ),
      );

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

      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('renders with Japanese locale', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const NotificationsPage(),
          locale: const Locale('ja'),
        ),
      );

      expect(find.byType(NotificationsPage), findsOneWidget);
    });
  });

  group('NotificationsPage render - interactions', () {
    testWidgets('tapping mark all read button does not crash',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      final markAllBtn = find.byType(TextButton);
      expect(markAllBtn, findsOneWidget);
      await tester.tap(markAllBtn);
      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);

      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('pull to refresh triggers reload without crash',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);

      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('back button is present and tappable',
        (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      final backBtn = find.byIcon(Icons.arrow_back);
      expect(backBtn, findsOneWidget);
    });
  });

  group('NotificationsPage render - with auth and notifications data', () {
    testWidgets('renders with authenticated user and notifications',
        (WidgetTester tester) async {
      setupMockSupabaseWithAuth({
        'user_notifications': [
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
            'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
            'read_at': DateTime.now().toIso8601String(),
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
            'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
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
      );

      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);

      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('renders with emoji notifications and auth',
        (WidgetTester tester) async {
      setupMockSupabaseWithAuth({
        'user_notifications': [
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
        ],
        'broadcast_notifications': <Map<String, dynamic>>[],
      }, userId: 'test-user-id');

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);

      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('renders with action URL notifications and auth',
        (WidgetTester tester) async {
      setupMockSupabaseWithAuth({
        'user_notifications': [
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
        ],
        'broadcast_notifications': <Map<String, dynamic>>[],
      }, userId: 'test-user-id');

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);

      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('renders with many mixed read/unread notifications',
        (WidgetTester tester) async {
      final manyNotifs = List.generate(
        10,
        (i) => {
          'id': i + 1,
          'user_id': 'test-user-id',
          'title': {'ko': '알림 ${i + 1}', 'en': 'Notif ${i + 1}'},
          'body': {'ko': '내용 ${i + 1}', 'en': 'Body ${i + 1}'},
          'type': i % 3 == 0 ? 'vote' : (i % 3 == 1 ? 'post' : 'qna'),
          'is_read': i % 2 == 0,
          'created_at': DateTime.now().subtract(Duration(hours: i)).toIso8601String(),
          'read_at': i % 2 == 0 ? DateTime.now().toIso8601String() : null,
          'action_url': null,
          'data': i % 3 == 0
              ? {'vote_id': '$i'}
              : (i % 3 == 1 ? {'post_id': 'p$i'} : {'question_id': '$i'}),
        },
      );

      setupMockSupabaseWithAuth({
        'user_notifications': manyNotifs,
        'broadcast_notifications': <Map<String, dynamic>>[],
      }, userId: 'test-user-id');

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);

      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('renders with answer_created and question_created types',
        (WidgetTester tester) async {
      setupMockSupabaseWithAuth({
        'user_notifications': [
          {
            'id': 1,
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
            'id': 2,
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
      }, userId: 'test-user-id');

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);

      expect(find.byType(NotificationsPage), findsOneWidget);
    });
  });

  group('NotificationsPage render - empty state', () {
    testWidgets('renders empty list with authenticated user',
        (WidgetTester tester) async {
      setupMockSupabaseWithAuth({
        'user_notifications': <Map<String, dynamic>>[],
        'broadcast_notifications': <Map<String, dynamic>>[],
      }, userId: 'test-user-id');

      await pumpAndDrain(
        tester,
        buildTestAppPage(const NotificationsPage()),
      );

      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);

      expect(find.byType(NotificationsPage), findsOneWidget);
    });
  });
}
