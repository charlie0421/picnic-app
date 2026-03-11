import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/data/models/community/post_scrap.dart';
import 'package:picnic_lib/data/models/common/popup.dart';
import 'package:picnic_lib/data/models/pic/article_image.dart';
import 'package:picnic_lib/data/models/pic/comment_like.dart';
import 'package:picnic_lib/data/models/pic/library.dart';
import 'package:picnic_lib/data/models/policy.dart';
import 'package:picnic_lib/data/models/reward.dart';
import 'package:picnic_lib/data/models/user_push_token.dart';
import 'package:picnic_lib/data/models/vote/artist_group.dart';
import 'package:picnic_lib/data/models/vote/vote_item_request.dart';

void main() {
  group('VoteItemRequest fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 'req-1',
        'vote_id': 100,
        'status': 'approved',
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-02T00:00:00.000Z',
      };
      final model = VoteItemRequest.fromJson(json);
      expect(model.id, equals('req-1'));
      expect(model.voteId, equals(100));
      expect(model.status, equals('approved'));
      expect(model.createdAt.year, equals(2025));

      final output = model.toJson();
      expect(output['id'], equals('req-1'));
      expect(output['vote_id'], equals(100));
    });
  });

  group('ArtistGroupModel (vote) fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'name': {'ko': 'BTS', 'en': 'BTS'},
        'image': 'group.jpg',
      };
      final model = ArtistGroupModel.fromJson(json);
      expect(model.id, equals(1));
      expect(model.name['ko'], equals('BTS'));
      expect(model.image, equals('group.jpg'));

      final output = model.toJson();
      expect(output['id'], equals(1));
    });

    test('image null', () {
      final json = {
        'id': 2,
        'name': {'ko': '블랙핑크'},
        'image': null,
      };
      final model = ArtistGroupModel.fromJson(json);
      expect(model.image, isNull);
    });
  });

  group('ArticleImageModel fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 10,
        'title_ko': '이미지 제목',
        'title_en': 'Image Title',
        'image': 'photo.jpg',
        'article_image_user': null,
      };
      final model = ArticleImageModel.fromJson(json);
      expect(model.id, equals(10));
      expect(model.titleKo, equals('이미지 제목'));
      expect(model.titleEn, equals('Image Title'));
      expect(model.image, equals('photo.jpg'));
      expect(model.articleImageUser, isNull);

      final output = model.toJson();
      expect(output['title_ko'], equals('이미지 제목'));
    });
  });

  group('UserCommentLikeModel fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'user_id': 42,
        'created_at': '2025-06-01T12:00:00.000Z',
      };
      final model = UserCommentLikeModel.fromJson(json);
      expect(model.id, equals(1));
      expect(model.userId, equals(42));
      expect(model.createdAt.month, equals(6));

      final output = model.toJson();
      expect(output['id'], equals(1));
      expect(output['user_id'], equals(42));
    });
  });

  group('LibraryModel fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 5,
        'title': '라이브러리 제목',
        'images': null,
      };
      final model = LibraryModel.fromJson(json);
      expect(model.id, equals(5));
      expect(model.title, equals('라이브러리 제목'));
      expect(model.images, isNull);

      final output = model.toJson();
      expect(output['id'], equals(5));
    });

    test('images 있는 경우', () {
      final json = {
        'id': 6,
        'title': '제목',
        'images': [
          {
            'id': 1,
            'title_ko': '사진1',
            'title_en': 'Photo1',
            'image': 'img.jpg',
            'article_image_user': null,
          },
        ],
      };
      final model = LibraryModel.fromJson(json);
      expect(model.images, isNotNull);
      expect(model.images!.length, equals(1));
      expect(model.images![0].titleKo, equals('사진1'));
    });
  });

  group('PostModel fromJson', () {
    test('기본 fromJson', () {
      final json = {
        'post_id': 'post-1',
        'user_id': 'user-1',
        'user_profiles': null,
        'board_id': 'board-1',
        'title': '게시글 제목',
        'content': [
          {'type': 'text', 'value': '내용'}
        ],
        'view_count': 100,
        'reply_count': 5,
        'is_hidden': false,
        'boards': null,
        'is_anonymous': false,
        'is_scraped': true,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-02T00:00:00.000Z',
        'deleted_at': null,
      };
      final post = PostModel.fromJson(json);
      expect(post.postId, equals('post-1'));
      expect(post.title, equals('게시글 제목'));
      expect(post.viewCount, equals(100));
      expect(post.replyCount, equals(5));
      expect(post.isHidden, isFalse);
      expect(post.isAnonymous, isFalse);
      expect(post.isScraped, isTrue);
      expect(post.deletedAt, isNull);

      final output = post.toJson();
      expect(output['post_id'], equals('post-1'));
      expect(output['view_count'], equals(100));
    });
  });

  group('BoardModel fromJson', () {
    test('description as Map', () {
      final json = {
        'board_id': 'board-1',
        'artist_id': 1,
        'name': {'ko': '자유게시판', 'en': 'Free Board'},
        'description': {'ko': '자유롭게 글을 쓰세요', 'en': 'Write freely'},
        'is_official': true,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': null,
        'artist': null,
        'request_message': null,
        'status': 'active',
        'creator_id': 'user-1',
        'features': ['post', 'comment'],
      };
      final board = BoardModel.fromJson(json);
      expect(board.boardId, equals('board-1'));
      expect(board.artistId, equals(1));
      expect(board.name['ko'], equals('자유게시판'));
      expect(board.description, isA<Map>());
      expect(board.isOfficial, isTrue);
      expect(board.status, equals('active'));
      expect(board.features!.length, equals(2));

      final output = board.toJson();
      expect(output['board_id'], equals('board-1'));
    });

    test('description as String', () {
      final json = {
        'board_id': 'board-2',
        'artist_id': 2,
        'name': {'ko': '게시판'},
        'description': '문자열 설명',
        'is_official': false,
        'created_at': null,
        'updated_at': null,
        'artist': null,
        'request_message': null,
        'status': null,
        'creator_id': null,
        'features': null,
      };
      final board = BoardModel.fromJson(json);
      expect(board.description, equals('문자열 설명'));
    });
  });

  group('DescriptionConverter', () {
    test('fromJson Map', () {
      const converter = DescriptionConverter();
      final result = converter.fromJson({'ko': '설명'});
      expect(result, isA<Map>());
    });

    test('fromJson String', () {
      const converter = DescriptionConverter();
      final result = converter.fromJson('문자열');
      expect(result, equals('문자열'));
    });

    test('fromJson 잘못된 타입 예외', () {
      const converter = DescriptionConverter();
      expect(() => converter.fromJson(123), throwsArgumentError);
    });

    test('toJson Map', () {
      const converter = DescriptionConverter();
      final result = converter.toJson({'ko': '값'});
      expect(result, isA<Map>());
    });

    test('toJson String', () {
      const converter = DescriptionConverter();
      final result = converter.toJson('값');
      expect(result, equals('값'));
    });

    test('toJson 잘못된 타입 예외', () {
      const converter = DescriptionConverter();
      expect(() => converter.toJson(123), throwsArgumentError);
    });
  });

  group('Popup fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'title': {'ko': '팝업 제목', 'en': 'Popup Title'},
        'content': {'ko': '팝업 내용', 'en': 'Popup Content'},
        'image': {'ko': 'ko.jpg'},
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': null,
        'deleted_at': null,
        'start_at': '2025-01-01T00:00:00.000Z',
        'stop_at': '2025-12-31T00:00:00.000Z',
      };
      final popup = Popup.fromJson(json);
      expect(popup.id, equals(1));
      expect(popup.title['ko'], equals('팝업 제목'));
      expect(popup.content['en'], equals('Popup Content'));
      expect(popup.image!['ko'], equals('ko.jpg'));
      expect(popup.startAt!.year, equals(2025));

      final output = popup.toJson();
      expect(output['id'], equals(1));
    });

    test('optional fields null', () {
      final json = {
        'id': 2,
        'title': {'ko': '제목'},
        'content': {'ko': '내용'},
      };
      final popup = Popup.fromJson(json);
      expect(popup.image, isNull);
      expect(popup.startAt, isNull);
      expect(popup.stopAt, isNull);
      expect(popup.deletedAt, isNull);
    });
  });

  group('RewardModel fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'title': {'ko': '리워드', 'en': 'Reward'},
        'thumbnail': 'reward.jpg',
        'overview_images': ['img1.jpg', 'img2.jpg'],
        'location': {'ko': '서울'},
        'size_guide': {'ko': 'S/M/L'},
        'size_guide_images': ['guide.jpg'],
      };
      final reward = RewardModel.fromJson(json);
      expect(reward.id, equals(1));
      expect(reward.title!['ko'], equals('리워드'));
      expect(reward.thumbnail, equals('reward.jpg'));
      expect(reward.overviewImages!.length, equals(2));
      expect(reward.sizeGuideImages!.length, equals(1));

      final output = reward.toJson();
      expect(output['id'], equals(1));
      expect(output['thumbnail'], equals('reward.jpg'));
    });

    test('모든 optional null', () {
      final json = {'id': 2};
      final reward = RewardModel.fromJson(json);
      expect(reward.title, isNull);
      expect(reward.thumbnail, isNull);
      expect(reward.overviewImages, isNull);
    });
  });

  group('PolicyModel fromJson', () {
    test('roundtrip', () {
      final json = {
        'privacy_en': {'content': 'Privacy policy EN', 'version': '1.0'},
        'terms_en': {'content': 'Terms EN', 'version': '1.0'},
        'privacy_ko': {'content': '개인정보처리방침', 'version': '1.0'},
        'terms_ko': {'content': '이용약관', 'version': '1.0'},
      };
      final policy = PolicyModel.fromJson(json);
      expect(policy.privacyEn.content, equals('Privacy policy EN'));
      expect(policy.termsKo.content, equals('이용약관'));
      expect(policy.privacyKo.version, equals('1.0'));

      final output = policy.toJson();
      expect(output['privacy_en'], isNotNull);
    });
  });

  group('PrivacyModel fromJson', () {
    test('roundtrip', () {
      final json = {
        'content': '개인정보처리방침 내용',
        'version': '2.0',
      };
      final privacy = PrivacyModel.fromJson(json);
      expect(privacy.content, equals('개인정보처리방침 내용'));
      expect(privacy.version, equals('2.0'));

      final output = privacy.toJson();
      expect(output['content'], equals('개인정보처리방침 내용'));
    });
  });

  group('TermsModel fromJson', () {
    test('roundtrip', () {
      final json = {
        'content': '이용약관 내용',
        'version': '3.0',
      };
      final terms = TermsModel.fromJson(json);
      expect(terms.content, equals('이용약관 내용'));
      expect(terms.version, equals('3.0'));
    });
  });

  group('UserPushToken fromJson/toJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'user_id': 'user-123',
        'token_ios': 'ios-token',
        'token_android': 'android-token',
        'token_web': null,
        'token_macos': null,
        'token_windows': null,
      };
      final token = UserPushToken.fromJson(json);
      expect(token.id, equals(1));
      expect(token.userId, equals('user-123'));
      expect(token.tokenIos, equals('ios-token'));
      expect(token.tokenAndroid, equals('android-token'));
      expect(token.tokenWeb, isNull);

      final output = token.toJson();
      expect(output['user_id'], equals('user-123'));
      expect(output['token_ios'], equals('ios-token'));
    });

    test('copyWith', () {
      final token = UserPushToken(
        id: 1,
        userId: 'user-1',
        tokenIos: 'old-token',
      );
      final updated = token.copyWith(tokenIos: 'new-token');
      expect(updated.tokenIos, equals('new-token'));
      expect(updated.userId, equals('user-1'));
      expect(updated.id, equals(1));
    });
  });

  group('PostScrapModel fromJson', () {
    test('기본 fromJson', () {
      final json = {
        'post_id': 'post-1',
        'user_id': 'user-1',
        'user_profiles': null,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-02T00:00:00.000Z',
        'board': null,
        'post': null,
        'deleted_at': null,
      };
      final scrap = PostScrapModel.fromJson(json);
      expect(scrap.postId, equals('post-1'));
      expect(scrap.userId, equals('user-1'));
      expect(scrap.board, isNull);
      expect(scrap.post, isNull);
      expect(scrap.deletedAt, isNull);

      final output = scrap.toJson();
      expect(output['post_id'], equals('post-1'));
    });
  });
}
