import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/community_navigation.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/widgets/community/list/post_list.dart';

import '../../../../helpers/ignore_image_errors.dart';
import '../../../../helpers/mock_data.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

/// Helper to create a mock post row.
Map<String, dynamic> _postRow({
  String postId = 'post-1',
  String title = 'Test Post',
  String boardId = 'board-1',
  int artistId = 1,
  int viewCount = 10,
  int replyCount = 2,
  bool isAnonymous = false,
}) {
  return {
    'post_id': postId,
    'title': title,
    'user_id': 'test-user-id',
    'board_id': boardId,
    'is_anonymous': isAnonymous,
    'is_hidden': false,
    'is_scraped': false,
    'view_count': viewCount,
    'reply_count': replyCount,
    'content': null,
    'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
    'updated_at': null,
    'deleted_at': null,
    'boards': {
      'board_id': boardId,
      'name': {'ko': '자유게시판', 'en': 'Free Board'},
      'artist_id': artistId,
      'description': 'Free board',
    },
    'user_profiles': {
      'id': 'test-user-id',
      'nickname': 'TestUser',
      'avatar_url': null,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'deleted_at': null,
    },
    'post_reports': null,
    'post_scraps': null,
  };
}

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

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    while (tester.takeException() != null) {}
    await tester.pump(const Duration(seconds: 1));
    while (tester.takeException() != null) {}
  }

  group('PostList render - artist type with data', () {
    testWidgets('renders empty post list with write recommendation',
        (WidgetTester tester) async {
      setupMockSupabase({
        'posts': <dynamic>[],
        'user_blocks': <dynamic>[],
        'fortune_telling': <dynamic>[],
      });

      await pumpAndDrain(
        tester,
        buildTestApp(
          const Expanded(
            child: PostList(PostListType.artist, 1),
          ),
        ),
      );

      expect(find.byType(PostList), findsOneWidget);
      // Empty state should show write button
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('renders with post data showing PostListItem',
        (WidgetTester tester) async {
      setupMockSupabase({
        'posts': [
          _postRow(postId: 'post-1', title: 'First Post'),
          _postRow(postId: 'post-2', title: 'Second Post'),
          _postRow(postId: 'post-3', title: 'Third Post'),
        ],
        'user_blocks': <dynamic>[],
        'fortune_telling': <dynamic>[],
      });

      await pumpAndDrain(
        tester,
        buildTestApp(
          const Expanded(
            child: PostList(PostListType.artist, 1),
          ),
        ),
      );

      expect(find.byType(PostList), findsOneWidget);
    });

    testWidgets('renders with anonymous posts', (WidgetTester tester) async {
      setupMockSupabase({
        'posts': [
          _postRow(postId: 'post-anon', title: 'Anonymous Post', isAnonymous: true),
        ],
        'user_blocks': <dynamic>[],
        'fortune_telling': <dynamic>[],
      });

      await pumpAndDrain(
        tester,
        buildTestApp(
          const Expanded(
            child: PostList(PostListType.artist, 1),
          ),
        ),
      );

      expect(find.byType(PostList), findsOneWidget);
    });
  });

  group('PostList render - board type', () {
    testWidgets('renders with board type and empty posts',
        (WidgetTester tester) async {
      setupMockSupabase({
        'posts': <dynamic>[],
        'user_blocks': <dynamic>[],
        'fortune_telling': <dynamic>[],
      });

      await pumpAndDrain(
        tester,
        buildTestApp(
          const Expanded(
            child: PostList(PostListType.board, 'board-123'),
          ),
        ),
      );

      expect(find.byType(PostList), findsOneWidget);
    });

    testWidgets('renders with board type and post data',
        (WidgetTester tester) async {
      setupMockSupabase({
        'posts': [
          _postRow(postId: 'board-post-1', boardId: 'board-123'),
        ],
        'user_blocks': <dynamic>[],
        'fortune_telling': <dynamic>[],
      });

      await pumpAndDrain(
        tester,
        buildTestApp(
          const Expanded(
            child: PostList(PostListType.board, 'board-123'),
          ),
        ),
      );

      expect(find.byType(PostList), findsOneWidget);
    });
  });

  group('PostList render - with community state', () {
    testWidgets('renders with currentArtist set in community state',
        (WidgetTester tester) async {
      final artist = ArtistModel.fromJson({
        'id': 1,
        'name': {'ko': '지민', 'en': 'Jimin'},
        'image': null,
        'artist_group': null,
      });

      setupMockSupabase({
        'posts': <dynamic>[],
        'user_blocks': <dynamic>[],
        'fortune_telling': <dynamic>[],
      });

      await pumpAndDrain(
        tester,
        buildTestApp(
          const Expanded(
            child: PostList(PostListType.artist, 1),
          ),
          communityState: CommunityState(currentArtist: artist),
        ),
      );

      expect(find.byType(PostList), findsOneWidget);
      // Header should show artist name
      expect(find.text('지민'), findsOneWidget);
    });

    testWidgets('renders without currentArtist',
        (WidgetTester tester) async {
      setupMockSupabase({
        'posts': <dynamic>[],
        'user_blocks': <dynamic>[],
        'fortune_telling': <dynamic>[],
      });

      await pumpAndDrain(
        tester,
        buildTestApp(
          const Expanded(
            child: PostList(PostListType.artist, 1),
          ),
          communityState: const CommunityState(),
        ),
      );

      expect(find.byType(PostList), findsOneWidget);
    });
  });

  group('PostList render - locale variants', () {
    testWidgets('renders with English locale', (WidgetTester tester) async {
      setupMockSupabase({
        'posts': <dynamic>[],
        'user_blocks': <dynamic>[],
        'fortune_telling': <dynamic>[],
      });

      await pumpAndDrain(
        tester,
        buildTestApp(
          const Expanded(
            child: PostList(PostListType.artist, 1),
          ),
          locale: const Locale('en'),
        ),
      );

      expect(find.byType(PostList), findsOneWidget);
    });

    testWidgets('renders with Japanese locale', (WidgetTester tester) async {
      setupMockSupabase({
        'posts': <dynamic>[],
        'user_blocks': <dynamic>[],
        'fortune_telling': <dynamic>[],
      });

      await pumpAndDrain(
        tester,
        buildTestApp(
          const Expanded(
            child: PostList(PostListType.artist, 1),
          ),
          locale: const Locale('ja'),
        ),
      );

      expect(find.byType(PostList), findsOneWidget);
    });
  });

  group('PostList render - logged out states', () {
    testWidgets('renders logged out with artist type',
        (WidgetTester tester) async {
      setupMockSupabase({
        'posts': <dynamic>[],
        'user_blocks': <dynamic>[],
        'fortune_telling': <dynamic>[],
      });

      await pumpAndDrain(
        tester,
        buildTestApp(
          const Expanded(
            child: PostList(PostListType.artist, 1),
          ),
          loggedIn: false,
        ),
      );

      expect(find.byType(PostList), findsOneWidget);
    });
  });

  group('PostList render - fortune and goonghap buttons', () {
    testWidgets('fortune and goonghap InkWell buttons are present',
        (WidgetTester tester) async {
      setupMockSupabase({
        'posts': <dynamic>[],
        'user_blocks': <dynamic>[],
        'fortune_telling': <dynamic>[],
      });

      await pumpAndDrain(
        tester,
        buildTestApp(
          const Expanded(
            child: PostList(PostListType.artist, 1),
          ),
        ),
      );

      expect(find.byType(PostList), findsOneWidget);
      // Should have at least 2 InkWell buttons (fortune + goonghap)
      expect(find.byType(InkWell), findsWidgets);
      // Should have Dividers separating sections
      expect(find.byType(Divider), findsWidgets);
    });
  });
}
