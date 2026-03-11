import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/presentation/providers/community_navigation_provider.dart';

import '../../helpers/mock_data.dart';

void main() {
  group('CommunityStateInfo', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has null fields', () {
      final state = container.read(communityStateInfoProvider);
      expect(state.currentArtist, isNull);
      expect(state.currentPost, isNull);
      expect(state.currentBoard, isNull);
    });

    test('setCurrentArtist updates artist', () {
      final artist = MockData.artist();
      container
          .read(communityStateInfoProvider.notifier)
          .setCurrentArtist(artist);
      final state = container.read(communityStateInfoProvider);
      expect(state.currentArtist, isNotNull);
      expect(state.currentArtist!.id, artist.id);
    });

    test('setCurrentArtist replaces previous artist', () {
      final artist1 = MockData.artist(id: 1, nameKo: '지민');
      final artist2 = MockData.artist(id: 2, nameKo: '정국');
      final notifier = container.read(communityStateInfoProvider.notifier);
      notifier.setCurrentArtist(artist1);
      notifier.setCurrentArtist(artist2);
      final state = container.read(communityStateInfoProvider);
      expect(state.currentArtist!.id, 2);
    });

    test('setCurrentPost updates post', () {
      final post = PostModel.fromJson({
        'post_id': 'post-1',
        'user_id': 'user-1',
        'user_profiles': null,
        'board_id': 'board-1',
        'title': 'Test Post',
        'content': null,
        'view_count': 10,
        'reply_count': 2,
        'is_hidden': false,
        'boards': null,
        'is_anonymous': false,
        'is_scraped': false,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
      });
      container
          .read(communityStateInfoProvider.notifier)
          .setCurrentPost(post);
      final state = container.read(communityStateInfoProvider);
      expect(state.currentPost, isNotNull);
      expect(state.currentPost!.postId, 'post-1');
    });

    test('setCurrentBoard updates board', () {
      final board = BoardModel.fromJson({
        'board_id': 'board-1',
        'artist_id': 1,
        'name': {'ko': '자유게시판'},
        'description': '자유롭게 글을 쓸 수 있는 게시판',
        'is_official': true,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': null,
        'artist': null,
        'request_message': null,
        'status': 'active',
        'creator_id': null,
        'features': null,
      });
      container
          .read(communityStateInfoProvider.notifier)
          .setCurrentBoard(board);
      final state = container.read(communityStateInfoProvider);
      expect(state.currentBoard, isNotNull);
      expect(state.currentBoard!.boardId, 'board-1');
    });

    test('setCurrentBoard replaces previous board', () {
      final board1 = BoardModel.fromJson({
        'board_id': 'board-1',
        'artist_id': 1,
        'name': {'ko': '자유게시판'},
        'description': 'desc',
        'is_official': true,
        'created_at': null,
        'updated_at': null,
        'artist': null,
        'request_message': null,
        'status': 'active',
        'creator_id': null,
        'features': null,
      });
      final board2 = BoardModel.fromJson({
        'board_id': 'board-2',
        'artist_id': 2,
        'name': {'ko': '팬아트'},
        'description': 'fan art',
        'is_official': false,
        'created_at': null,
        'updated_at': null,
        'artist': null,
        'request_message': null,
        'status': 'active',
        'creator_id': null,
        'features': null,
      });
      final notifier = container.read(communityStateInfoProvider.notifier);
      notifier.setCurrentBoard(board1);
      notifier.setCurrentBoard(board2);
      final state = container.read(communityStateInfoProvider);
      expect(state.currentBoard!.boardId, 'board-2');
    });

    test('setCurrentPostScraped updates scraped status', () {
      final post = PostModel.fromJson({
        'post_id': 'post-1',
        'user_id': 'user-1',
        'user_profiles': null,
        'board_id': 'board-1',
        'title': 'Test',
        'content': null,
        'view_count': 0,
        'reply_count': 0,
        'is_hidden': false,
        'boards': null,
        'is_anonymous': false,
        'is_scraped': false,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
      });
      final notifier = container.read(communityStateInfoProvider.notifier);
      notifier.setCurrentPost(post);
      notifier.setCurrentPostScraped(true);
      final state = container.read(communityStateInfoProvider);
      expect(state.currentPost!.isScraped, isTrue);
    });
  });
}
