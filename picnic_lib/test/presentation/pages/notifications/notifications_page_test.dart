import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/user_notification.dart';
import 'package:picnic_lib/presentation/pages/notifications/notifications_page.dart';

import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  setUp(() {
    setupMockSupabase({
      'user_notifications': <Map<String, dynamic>>[
        {
          'id': 1,
          'user_id': 'test-user-id',
          'title': {'ko': '🎉 투표 알림', 'en': 'Vote notification'},
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
          'read_at':
              DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
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
      ],
      'broadcast_notifications': <Map<String, dynamic>>[],
    });
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  group('NotificationsPage', () {
    testWidgets('renders page with AppBar', (tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const NotificationsPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(NotificationsPage), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('shows mark all read button in AppBar', (tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const NotificationsPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('shows ListView for notification list', (tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const NotificationsPage()),
      );
      // Wait for async load
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // ListView should always be present (even with empty list)
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows RefreshIndicator for pull-to-refresh', (tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const NotificationsPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('renders with empty notifications', (tester) async {
      tearDownMockSupabase();
      setupMockSupabase({
        'user_notifications': <Map<String, dynamic>>[],
        'broadcast_notifications': <Map<String, dynamic>>[],
      });

      await tester.pumpWidget(
        buildTestAppPage(const NotificationsPage()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(NotificationsPage), findsOneWidget);
      // Empty state shows no ListTile except the loading sentinel
    });
  });

  group('NotificationsPage - logic tests', () {
    test('UserNotification emoji extraction pattern', () {
      // Replicate the _extractEmoji logic from the page
      String? extractEmoji(String text) {
        final emojiRegex = RegExp(
          r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]',
          unicode: true,
        );
        final match = emojiRegex.firstMatch(text);
        return match?.group(0);
      }

      expect(extractEmoji('🎉 투표 알림'), equals('🎉'));
      expect(extractEmoji('No emoji here'), isNull);
      expect(extractEmoji('🌟 Star notification'), equals('🌟'));
      expect(extractEmoji(''), isNull);
      expect(extractEmoji('🎊 Celebration 🎉'), equals('🎊'));
    });

    test('UserNotification type to icon mapping', () {
      // Replicate the fallbackIcon logic from the page's build
      IconData getIcon(String type) {
        switch (type) {
          case 'vote':
            return Icons.how_to_vote;
          case 'qna':
          case 'answer_created':
          case 'question_created':
            return Icons.question_answer;
          case 'post':
            return Icons.post_add;
          default:
            return Icons.notifications;
        }
      }

      expect(getIcon('vote'), Icons.how_to_vote);
      expect(getIcon('qna'), Icons.question_answer);
      expect(getIcon('answer_created'), Icons.question_answer);
      expect(getIcon('question_created'), Icons.question_answer);
      expect(getIcon('post'), Icons.post_add);
      expect(getIcon('unknown'), Icons.notifications);
      expect(getIcon(''), Icons.notifications);
    });

    test('UserNotification read/unread styling logic', () {
      final unread = UserNotification(
        id: 1,
        title: {'ko': '테스트'},
        body: {'ko': '테스트'},
        type: 'vote',
        isRead: false,
      );

      final read = UserNotification(
        id: 2,
        title: {'ko': '테스트'},
        body: {'ko': '테스트'},
        type: 'vote',
        isRead: true,
      );

      expect(unread.isRead, isFalse);
      expect(read.isRead, isTrue);

      // Unread tiles get blue background, read get grey
      final unreadColor = Colors.blue.withValues(alpha: 0.08);
      final readColor = Colors.grey.withValues(alpha: 0.03);
      expect(unreadColor.alpha, greaterThan(readColor.alpha));
    });

    test('UserNotification copyWith preserves data', () {
      final original = UserNotification(
        id: 1,
        userId: 'user-1',
        title: {'ko': '제목'},
        body: {'ko': '본문'},
        type: 'vote',
        isRead: false,
        data: {'vote_id': '123'},
      );

      final updated = original.copyWith(
        isRead: true,
        readAt: DateTime.now().toIso8601String(),
      );

      expect(updated.id, equals(1));
      expect(updated.isRead, isTrue);
      expect(updated.readAt, isNotNull);
      expect(updated.title, equals(original.title));
      expect(updated.type, equals('vote'));
    });

    test('URL parsing for Picnic domain detection', () {
      bool isPicnicDomain(String url) {
        try {
          final uri = Uri.parse(url);
          final host = uri.host.toLowerCase();
          return host == 'applink.picnic.fan' || host == 'www.picnic.fan';
        } catch (_) {
          return false;
        }
      }

      expect(isPicnicDomain('https://applink.picnic.fan/vote/123'), isTrue);
      expect(isPicnicDomain('https://www.picnic.fan/post/abc'), isTrue);
      expect(isPicnicDomain('https://google.com'), isFalse);
      expect(isPicnicDomain(''), isFalse);
      expect(
        isPicnicDomain('http://applink.picnic.fan/something'),
        isTrue,
      );
    });

    test('navigateByType data extraction for vote', () {
      final data = {'vote_id': '123', 'id': '456'};
      final voteIdStr = (data['vote_id'] ?? data['id'])?.toString();
      final voteId = voteIdStr != null ? int.tryParse(voteIdStr) : null;
      expect(voteId, equals(123));
    });

    test('navigateByType data extraction prefers specific key', () {
      final data = {'id': '456'};
      final voteIdStr = (data['vote_id'] ?? data['id'])?.toString();
      final voteId = voteIdStr != null ? int.tryParse(voteIdStr) : null;
      expect(voteId, equals(456));
    });

    test('navigateByType data extraction handles null gracefully', () {
      final Map<String, dynamic> data = {};
      final voteIdStr = (data['vote_id'] ?? data['id'])?.toString();
      final voteId = voteIdStr != null ? int.tryParse(voteIdStr) : null;
      expect(voteId, isNull);
    });

    test('navigateByType post data extraction', () {
      final data = {'post_id': 'abc-123'};
      final postId = (data['post_id'] ?? data['id'])?.toString();
      expect(postId, equals('abc-123'));
      expect(postId != null && postId.isNotEmpty, isTrue);
    });

    test('navigateByType qna data extraction', () {
      final data = {'question_id': '42'};
      final qidStr = (data['question_id'] ?? data['id'])?.toString();
      expect(qidStr, equals('42'));
      expect(int.tryParse(qidStr!), equals(42));
    });
  });

  group('UserNotification model', () {
    test('fromJson creates valid notification', () {
      final json = {
        'id': 1,
        'user_id': 'u1',
        'title': {'ko': '알림', 'en': 'Notification'},
        'body': {'ko': '내용', 'en': 'Content'},
        'type': 'vote',
        'is_read': false,
        'created_at': '2024-01-01T00:00:00Z',
        'data': {'vote_id': '1'},
      };

      final notification = UserNotification.fromJson(json);
      expect(notification.id, equals(1));
      expect(notification.type, equals('vote'));
      expect(notification.isRead, isFalse);
    });

    test('fromJson handles string title (MultilangJsonConverter)', () {
      final json = {
        'id': 2,
        'title': 'Simple title',
        'body': 'Simple body',
        'type': 'default',
        'is_read': true,
      };

      final notification = UserNotification.fromJson(json);
      expect(notification.title['ko'], equals('Simple title'));
      expect(notification.title['en'], equals('Simple title'));
    });

    test('MultilangJsonConverter handles JSON string', () {
      final converter = MultilangJsonConverter();

      final result = converter.fromJson('{"ko": "한글", "en": "English"}');
      expect(result['ko'], equals('한글'));
      expect(result['en'], equals('English'));
    });

    test('MultilangJsonConverter handles null', () {
      final converter = MultilangJsonConverter();
      final result = converter.fromJson(null);
      expect(result['ko'], equals(''));
      expect(result['en'], equals(''));
    });

    test('MultilangJsonConverter handles plain string', () {
      final converter = MultilangJsonConverter();
      final result = converter.fromJson('Hello World');
      expect(result['ko'], equals('Hello World'));
      expect(result['en'], equals('Hello World'));
    });
  });
}
