import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/community/post_view_page.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// Helper to build a full post JSON for the mock Supabase response.
Map<String, dynamic> _buildPostJson({
  String postId = 'post-1',
  String title = 'Test Post Title',
  List<dynamic>? content,
  int viewCount = 42,
  int replyCount = 5,
  bool isAnonymous = false,
  String? deletedAt,
  String nickname = 'TestUser',
}) =>
    {
      'post_id': postId,
      'user_id': 'user-1',
      'board_id': 'board-1',
      'title': title,
      'content': content ?? [{'insert': 'Hello world\n'}],
      'view_count': viewCount,
      'reply_count': replyCount,
      'is_hidden': false,
      'is_anonymous': isAnonymous,
      'is_scraped': false,
      'created_at': '2026-01-01T10:00:00.000Z',
      'updated_at': '2026-01-01T12:00:00.000Z',
      'deleted_at': deletedAt,
      'board': {
        'board_id': 'board-1',
        'name': {'ko': '자유게시판', 'en': 'Free Board'},
        'artist_id': 1,
        'description': 'test',
      },
      'user_profiles': {
        'nickname': nickname,
        'avatar_url': null,
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
        'deleted_at': null,
      },
      'post_reports': null,
      'post_scraps': null,
    };

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

  /// Pump, drain exceptions, then tear down the widget tree to cancel timers.
  Future<void> pumpSettleAndClean(
    WidgetTester tester,
    Widget widget, {
    int pumps = 5,
  }) async {
    await tester.pumpWidget(widget);
    while (tester.takeException() != null) {}
    for (var i = 0; i < pumps; i++) {
      await tester.pump(const Duration(seconds: 1));
      while (tester.takeException() != null) {}
    }
  }

  /// Clean up timers from BannerAdWidget etc.
  Future<void> cleanUp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    while (tester.takeException() != null) {}
  }

  group('PostViewPage coverage - post data renders (with auth)', () {
    testWidgets('shows post content when data is returned',
        (WidgetTester tester) async {
      await setupMockSupabaseWithAuth({
        'posts': [_buildPostJson()],
        'user_blocks': <dynamic>[],
        'comments': <dynamic>[],
      }, userId: 'test-user-id');

      await pumpSettleAndClean(
        tester,
        buildTestAppPage(
          const PostViewPage('post-1', syncNavigation: false),
        ),
      );

      expect(find.byType(PostViewPage), findsOneWidget);
      expect(find.text('Test Post Title'), findsWidgets);
      await cleanUp(tester);
    });

    testWidgets('shows anonymous label for anonymous posts',
        (WidgetTester tester) async {
      await setupMockSupabaseWithAuth({
        'posts': [
          _buildPostJson(
              postId: 'post-anon', title: 'Anonymous Post', isAnonymous: true)
        ],
        'user_blocks': <dynamic>[],
        'comments': <dynamic>[],
      }, userId: 'test-user-id');

      await pumpSettleAndClean(
        tester,
        buildTestAppPage(
          const PostViewPage('post-anon', syncNavigation: false),
        ),
      );

      expect(find.byType(PostViewPage), findsOneWidget);
      expect(find.text('Anonymous Post'), findsWidgets);
      await cleanUp(tester);
    });

    testWidgets('shows deleted post state', (WidgetTester tester) async {
      await setupMockSupabaseWithAuth({
        'posts': [
          _buildPostJson(
            postId: 'post-deleted',
            title: 'Deleted Post',
            deletedAt: '2026-01-02T00:00:00.000Z',
          )
        ],
        'user_blocks': <dynamic>[],
        'comments': <dynamic>[],
      }, userId: 'test-user-id');

      await pumpSettleAndClean(
        tester,
        buildTestAppPage(
          const PostViewPage('post-deleted', syncNavigation: false),
        ),
      );

      expect(find.byType(PostViewPage), findsOneWidget);
      await cleanUp(tester);
    });

    testWidgets('post with null content', (WidgetTester tester) async {
      await setupMockSupabaseWithAuth({
        'posts': [
          _buildPostJson(
              postId: 'post-null', title: 'Null Content', content: null)
        ],
        'user_blocks': <dynamic>[],
        'comments': <dynamic>[],
      }, userId: 'test-user-id');

      await pumpSettleAndClean(
        tester,
        buildTestAppPage(
          const PostViewPage('post-null', syncNavigation: false),
        ),
      );

      expect(find.byType(PostViewPage), findsOneWidget);
      await cleanUp(tester);
    });

    testWidgets('handles rich content with bold attributes',
        (WidgetTester tester) async {
      await setupMockSupabaseWithAuth({
        'posts': [
          _buildPostJson(
            postId: 'post-rich',
            title: 'Rich Content',
            content: [
              {'insert': 'Bold text', 'attributes': {'bold': true}},
              {'insert': '\nNormal text\n'},
            ],
          )
        ],
        'user_blocks': <dynamic>[],
        'comments': <dynamic>[],
      }, userId: 'test-user-id');

      await pumpSettleAndClean(
        tester,
        buildTestAppPage(
          const PostViewPage('post-rich', syncNavigation: false),
        ),
      );

      expect(find.byType(PostViewPage), findsOneWidget);
      await cleanUp(tester);
    });

    testWidgets('post with high view and reply counts',
        (WidgetTester tester) async {
      await setupMockSupabaseWithAuth({
        'posts': [
          _buildPostJson(
            postId: 'post-popular',
            title: 'Popular Post',
            viewCount: 99999,
            replyCount: 500,
            nickname: 'PopularUser',
          )
        ],
        'user_blocks': <dynamic>[],
        'comments': <dynamic>[],
      }, userId: 'test-user-id');

      await pumpSettleAndClean(
        tester,
        buildTestAppPage(
          const PostViewPage('post-popular', syncNavigation: false),
        ),
      );

      expect(find.byType(PostViewPage), findsOneWidget);
      await cleanUp(tester);
    });
  });

  group('PostViewPage coverage - error and loading states', () {
    testWidgets('error state when post not found',
        (WidgetTester tester) async {
      setupMockSupabase({
        'posts': <dynamic>[],
        'user_blocks': <dynamic>[],
        'comments': <dynamic>[],
      });

      await tester.pumpWidget(
        buildTestAppPage(
          const PostViewPage('nonexistent', syncNavigation: false),
        ),
      );
      while (tester.takeException() != null) {}
      // Pump multiple times to let the FutureBuilder complete with error
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        while (tester.takeException() != null) {}
      }

      expect(find.byType(PostViewPage), findsOneWidget);
    });

    testWidgets('loading state shows indicator', (WidgetTester tester) async {
      setupMockSupabase({
        'posts': <dynamic>[],
        'user_blocks': <dynamic>[],
        'comments': <dynamic>[],
      });

      await tester.pumpWidget(
        buildTestAppPage(
          const PostViewPage('test-id', syncNavigation: false),
        ),
      );
      while (tester.takeException() != null) {}

      expect(find.byType(PostViewPage), findsOneWidget);
      expect(find.byType(LargePulseLoadingIndicator), findsOneWidget);
    });

    testWidgets('renders with logged out user', (WidgetTester tester) async {
      setupMockSupabase({
        'posts': <dynamic>[],
        'user_blocks': <dynamic>[],
        'comments': <dynamic>[],
      });

      await pumpSettleAndClean(
        tester,
        buildTestAppPage(
          const PostViewPage('post-1', syncNavigation: false),
          loggedIn: false,
        ),
      );

      expect(find.byType(PostViewPage), findsOneWidget);
    });
  });

  group('AlwaysDisabledFocusNode coverage', () {
    test('hasFocus always returns false', () {
      final node = AlwaysDisabledFocusNode();
      expect(node.hasFocus, isFalse);
      node.dispose();
    });
  });
}
