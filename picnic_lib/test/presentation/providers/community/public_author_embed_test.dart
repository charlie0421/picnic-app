import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/providers/community/comments_provider.dart';
import 'package:picnic_lib/presentation/providers/community/post_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/mock_supabase.dart';

/// 커뮤니티 게시글·댓글의 작성자 정보는 user_profiles 원본 테이블이 아니라
/// 공개 뷰 user_profiles_public 에서 읽어야 한다. 뷰는 id·nickname·avatar_url·
/// created_at·updated_at·deleted_at 만 노출한다.
///
/// 목 서버는 select 를 해석하지 않고 픽스처를 그대로 돌려주므로, 어떤 관계를
/// 임베드하는지는 실제로 나간 요청의 select 파라미터로 고정한다.
const _postAuthorEmbed =
    'user_profiles:user_profiles_public!posts_user_id_fkey(id,nickname,avatar_url,created_at,updated_at,deleted_at)';
const _postDetailAuthorEmbed =
    'user_profiles:user_profiles_public!posts_user_id_fkey(nickname,avatar_url,created_at,updated_at,deleted_at)';
const _commentAuthorEmbed =
    'user_profiles:user_profiles_public!comments_user_id_fkey(nickname,avatar_url,created_at,updated_at,deleted_at)';
const _userCommentAuthorEmbed =
    'user:user_profiles_public!comments_user_id_fkey(id,nickname,avatar_url,created_at,updated_at,deleted_at)';

const _authorId = 'author-1';
const _viewerId = 'viewer-1';

List<Uri> _restRequests(List<Uri> requests, String table) =>
    requests.where((u) => u.path.endsWith('/rest/v1/$table')).toList();

/// select 에 기대한 공개 뷰 임베드가 정확히 한 번 있고, 그 밖에는
/// user_profiles 원본 테이블을 가리키는 임베드가 없는지 확인한다.
void _expectOnlyPublicAuthorEmbed(Uri request, String embed) {
  final select = request.queryParameters['select']!.replaceAll(
    RegExp(r'\s'),
    '',
  );
  expect(embed.allMatches(select).length, 1, reason: select);
  expect(
    select.replaceFirst(embed, ''),
    isNot(contains('user_profiles')),
    reason: select,
  );
}

Map<String, dynamic> _author({bool withId = true}) => {
  if (withId) 'id': _authorId,
  'nickname': 'PublicAuthor',
  'avatar_url': 'https://example.com/author.png',
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-02T00:00:00Z',
  'deleted_at': null,
};

const _board = {
  'board_id': 'board-1',
  'name': {'en': 'Board'},
  'artist_id': 1,
  'description': 'Board description',
};

Map<String, dynamic> _postRow(String postId, Map<String, dynamic>? author) => {
  'post_id': postId,
  'user_id': _authorId,
  'board_id': 'board-1',
  'title': 'Title',
  'content': null,
  'view_count': 0,
  'reply_count': 0,
  'is_hidden': false,
  'is_anonymous': false,
  'boards': _board,
  'user_profiles': author,
  'post_reports': null,
  'post_scraps': <Map<String, dynamic>>[],
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-01T00:00:00Z',
  'deleted_at': null,
};

/// _fetchComments 의 select 와 같은 모양의 행. user_id 는 select 하지 않는다.
Map<String, dynamic> _commentRow(
  String commentId,
  Map<String, dynamic>? author, {
  String? parentCommentId,
}) => {
  'comment_id': commentId,
  'parent_comment_id': parentCommentId,
  'likes': 0,
  'replies': 0,
  'content': {'ko': '댓글'},
  'locale': 'ko',
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-01T00:00:00Z',
  'deleted_at': null,
  'user_profiles': author,
  'comment_reports': <Map<String, dynamic>>[],
  'comment_likes': <Map<String, dynamic>>[],
  'post': null,
};

/// 루트·자식 댓글 요청을 parent_comment_id 필터로 구분해 응답하는 목 서버.
/// 공용 목은 필터를 무시해서 자식 댓글이 루트 목록에 섞인다.
List<Uri> _installCommentServer({
  required List<Map<String, dynamic>> roots,
  required List<Map<String, dynamic>> children,
}) {
  final requests = <Uri>[];
  testSupabaseClient = SupabaseClient(
    'http://localhost:54321',
    'test-anon-key-for-testing-purposes-only',
    httpClient: MockClient((request) async {
      final uri = request.url;
      requests.add(uri);
      var rows = <Map<String, dynamic>>[];
      if (uri.path.endsWith('/rest/v1/comments')) {
        rows = uri.queryParameters['parent_comment_id'] == 'is.null'
            ? roots
            : children;
      }
      return http.Response(
        jsonEncode(rows),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    }),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  return requests;
}

void main() {
  for (final signedIn in [false, true]) {
    group(
      'post authors via public view (${signedIn ? 'signed-in' : 'anon'})',
      () {
        late ProviderContainer container;

        setUp(() async {
          final tables = <String, dynamic>{
            'posts': [_postRow('post-1', _author()), _postRow('post-2', null)],
            'user_blocks': <Map<String, dynamic>>[],
          };
          if (signedIn) {
            await setupMockSupabaseWithAuth(tables, userId: _viewerId);
          } else {
            setupMockSupabase(tables);
          }
          container = ProviderContainer();
        });

        tearDown(() {
          container.dispose();
          tearDownMockSupabase();
        });

        void expectListRequestAndAuthors(List<PostModel>? posts) {
          final postRequests = _restRequests(capturedMockRequests, 'posts');
          expect(postRequests, hasLength(1));
          _expectOnlyPublicAuthorEmbed(postRequests.single, _postAuthorEmbed);
          expect(
            _restRequests(capturedMockRequests, 'user_blocks'),
            hasLength(signedIn ? 1 : 0),
          );

          expect(posts, hasLength(2));
          final author = posts![0].userProfiles!;
          expect(author.id, _authorId);
          expect(author.nickname, 'PublicAuthor');
          expect(author.avatarUrl, 'https://example.com/author.png');
          expect(author.deletedAt, isNull);
          expect(posts[1].userProfiles, isNull);
        }

        test('postsByArtist', () async {
          final posts = await container.read(
            postsByArtistProvider(1, 10, 1).future,
          );
          expectListRequestAndAuthors(posts);
        });

        test('postsByBoard', () async {
          final posts = await container.read(
            postsByBoardProvider('board-1', 10, 1).future,
          );
          expectListRequestAndAuthors(posts);
        });

        test('postsByUser preserves scope, filters and pagination', () async {
          tearDownMockSupabase();
          final tables = <String, dynamic>{
            'posts': [_postRow('post-1', _author())],
            'user_blocks': [
              {'blocked_user_id': 'blocked-author'},
            ],
          };
          if (signedIn) {
            await setupMockSupabaseWithAuth(tables, userId: _viewerId);
          } else {
            setupMockSupabase(tables);
          }

          final posts = await container.read(
            postsByUserProvider(_authorId, 10, 2).future,
          );

          final postRequests = _restRequests(capturedMockRequests, 'posts');
          expect(postRequests, hasLength(1));
          final request = postRequests.single;
          _expectOnlyPublicAuthorEmbed(request, _postAuthorEmbed);
          expect(request.queryParameters['select'], contains('boards!inner(*)'));
          expect(
            request.queryParameters['select'],
            contains('post_reports!left(post_id)'),
          );
          expect(
            request.queryParameters['select'],
            contains('post_scraps!left(post_id)'),
          );
          expect(request.queryParameters['user_id'], 'eq.author-1');
          expect(request.queryParameters['deleted_at'], 'is.null');
          expect(request.queryParameters['post_reports'], 'is.null');
          expect(request.queryParameters['order'], 'created_at.desc.nullslast');
          expect(request.queryParameters['offset'], '10');
          expect(request.queryParameters['limit'], '10');
          expect(
            request.queryParameters['or'],
            signedIn ? '(and(user_id.not.in.(blocked-author)))' : isNull,
          );
          final blockRequests = _restRequests(
            capturedMockRequests,
            'user_blocks',
          );
          expect(blockRequests, hasLength(signedIn ? 1 : 0));
          if (signedIn) {
            expect(blockRequests.single.queryParameters['user_id'], 'eq.viewer-1');
            expect(blockRequests.single.queryParameters['deleted_at'], 'is.null');
          }

          final post = posts.single;
          expect(post.postId, 'post-1');
          expect(post.userId, _authorId);
          expect(post.userProfiles!.id, _authorId);
          expect(post.userProfiles!.nickname, 'PublicAuthor');
          expect(post.userProfiles!.avatarUrl, 'https://example.com/author.png');
          expect(post.userProfiles!.deletedAt, isNull);
          expect(post.board!.boardId, 'board-1');
          expect(post.board!.name, {'en': 'Board'});
          expect(post.createdAt, DateTime.utc(2026, 1, 1));
        });

        test('postsByUser preserves posts with a null public author', () async {
          final posts = await container.read(
            postsByUserProvider(_authorId, 10, 1).future,
          );

          expectListRequestAndAuthors(posts);
          expect(posts.map((post) => post.postId), ['post-1', 'post-2']);
          expect(posts[0].board!.boardId, 'board-1');
          expect(posts[1].board!.boardId, 'board-1');
          expect(posts[1].userId, _authorId);
        });

        testWidgets('postsByQuery', (tester) async {
          // 정렬 키가 현재 로캘을 navigatorKey 의 context 에서 읽는다.
          await tester.pumpWidget(
            MaterialApp(
              navigatorKey: navigatorKey,
              locale: const Locale('en'),
              home: const SizedBox(),
            ),
          );

          final posts = await tester.runAsync(
            () =>
                container.read(postsByQueryProvider(1, 'Title', 1, 10).future),
          );
          expectListRequestAndAuthors(posts);
        });

        test('postById', () async {
          tearDownMockSupabase();
          // 상세 쿼리는 게시판을 `board` 별칭으로 받는다.
          final row = {
            ..._postRow('post-1', _author(withId: false)),
            'board': _board,
          }..remove('boards');
          final tables = <String, dynamic>{
            'posts': [row],
            'user_blocks': <Map<String, dynamic>>[],
          };
          if (signedIn) {
            await setupMockSupabaseWithAuth(tables, userId: _viewerId);
          } else {
            setupMockSupabase(tables);
          }

          final post = await container.read(postByIdProvider('post-1').future);

          final postRequests = _restRequests(capturedMockRequests, 'posts');
          expect(postRequests, hasLength(1));
          _expectOnlyPublicAuthorEmbed(
            postRequests.single,
            _postDetailAuthorEmbed,
          );
          expect(post!.userProfiles!.nickname, 'PublicAuthor');
          expect(
            post.userProfiles!.avatarUrl,
            'https://example.com/author.png',
          );
          expect(post.userProfiles!.id, isNull);
        });
      },
    );
  }

  group('comment authors via public view', () {
    tearDown(tearDownMockSupabase);

    test(
      'root and child queries (anon) embed the view and parse authors',
      () async {
        final requests = _installCommentServer(
          roots: [_commentRow('root-1', _author(withId: false))],
          children: [
            _commentRow(
              'child-1',
              _author(withId: false),
              parentCommentId: 'root-1',
            ),
            _commentRow('child-2', null, parentCommentId: 'root-1'),
          ],
        );
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final comments = await container.read(
          commentsProvider('post-1', 1, 10).future,
        );

        final commentRequests = _restRequests(requests, 'comments');
        expect(commentRequests, hasLength(2));
        expect(
          commentRequests[0].queryParameters['parent_comment_id'],
          'is.null',
        );
        expect(
          commentRequests[1].queryParameters['parent_comment_id'],
          allOf(startsWith('in.'), contains('root-1')),
        );
        for (final request in commentRequests) {
          _expectOnlyPublicAuthorEmbed(request, _commentAuthorEmbed);
        }

        final root = comments.single;
        expect(root.user!.nickname, 'PublicAuthor');
        final children = {for (final c in root.children!) c.commentId: c};
        expect(
          children['child-1']!.user!.avatarUrl,
          'https://example.com/author.png',
        );
        expect(children['child-2']!.user, isNull);
      },
    );

    test('root and child queries (signed-in) embed the view', () async {
      await setupMockSupabaseWithAuth({
        'comments': [_commentRow('root-1', _author(withId: false))],
        'user_blocks': <Map<String, dynamic>>[],
      }, userId: _viewerId);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final comments = await container.read(
        commentsProvider('post-1', 1, 10).future,
      );

      final commentRequests = _restRequests(capturedMockRequests, 'comments');
      expect(commentRequests, hasLength(2));
      for (final request in commentRequests) {
        _expectOnlyPublicAuthorEmbed(request, _commentAuthorEmbed);
      }
      expect(_restRequests(capturedMockRequests, 'user_blocks'), hasLength(1));
      expect(comments.single.user!.nickname, 'PublicAuthor');
    });

    test(
      'user comments keep the `user` alias, so CommentModel.user stays null',
      () async {
        // 이 쿼리는 작성자를 `user` 키로 받는다. 모델은 `user_profiles` 키만 읽는다.
        final row = {
          ..._commentRow('comment-1', null),
          'user_id': _authorId,
          'post': {'post_id': 'post-1', 'board_id': 'board-1'},
          'user': _author(),
        }..remove('user_profiles');
        setupMockSupabase({
          'comments': [row],
        });
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final comments = await container.read(
          userCommentsProvider(_authorId, 1, 10).future,
        );

        final commentRequests = _restRequests(capturedMockRequests, 'comments');
        expect(commentRequests, hasLength(1));
        _expectOnlyPublicAuthorEmbed(
          commentRequests.single,
          _userCommentAuthorEmbed,
        );
        expect(comments.single.commentId, 'comment-1');
        expect(comments.single.user, isNull);
      },
    );
  });
}
