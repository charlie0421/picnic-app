import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/banner.dart';
import 'package:picnic_lib/data/models/common/popup.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/data/models/community/post_scrap.dart';
import 'package:picnic_lib/data/models/pic/article_image.dart';
import 'package:picnic_lib/data/models/pic/comment_like.dart';
import 'package:picnic_lib/data/models/pic/gallery.dart';
import 'package:picnic_lib/data/models/pic/library.dart';
import 'package:picnic_lib/data/models/policy.dart';
import 'package:picnic_lib/data/models/qna/qna_attachment.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart' as thread;
import 'package:picnic_lib/data/models/reward.dart';
import 'package:picnic_lib/data/models/user_push_token.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/artist_group.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/vote/vote_item_request.dart';

void main() {
  group('ArtistModel fromJson/toJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'name': {'ko': '지민', 'en': 'Jimin'},
        'yy': 1995,
        'mm': 10,
        'dd': 13,
        'birth_date': null,
        'gender': 'M',
        'artist_group': null,
        'image': 'https://example.com/jimin.jpg',
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
        'deleted_at': null,
        'isBookmarked': true,
      };
      final artist = ArtistModel.fromJson(json);
      expect(artist.id, equals(1));
      expect(artist.name['ko'], equals('지민'));
      expect(artist.yy, equals(1995));
      expect(artist.gender, equals('M'));
      expect(artist.isBookmarked, isTrue);

      final output = artist.toJson();
      expect(output['id'], equals(1));
      expect(output['name']['ko'], equals('지민'));
    });
  });

  group('ArtistGroupModel fromJson/toJson', () {
    test('roundtrip', () {
      final json = {
        'id': 10,
        'name': {'ko': 'BTS', 'en': 'BTS'},
        'image': 'group.jpg',
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': null,
      };
      final group = ArtistGroupModel.fromJson(json);
      expect(group.id, equals(10));
      expect(group.name['ko'], equals('BTS'));

      final output = group.toJson();
      expect(output['id'], equals(10));
    });
  });

  group('VoteModel fromJson/toJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'title': {'ko': '투표 제목'},
        'vote_category': null,
        'main_image': 'main.jpg',
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': '2025-01-01T00:00:00.000Z',
        'visible_at': null,
        'start_at': '2025-02-01T00:00:00.000Z',
        'stop_at': '2025-03-01T00:00:00.000Z',
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      };
      final vote = VoteModel.fromJson(json);
      expect(vote.id, equals(1));
      expect(vote.title!['ko'], equals('투표 제목'));
      expect(vote.mainImage, equals('main.jpg'));
      expect(vote.isEnded, isFalse);

      final output = vote.toJson();
      expect(output['id'], equals(1));
      expect(output['main_image'], equals('main.jpg'));
    });
  });

  group('VoteItemRequest fromJson/toJson', () {
    test('roundtrip', () {
      final json = {
        'id': 'req-1',
        'vote_id': 100,
        'status': 'pending',
        'created_at': '2025-03-01T00:00:00.000Z',
        'updated_at': '2025-03-01T00:00:00.000Z',
      };
      final request = VoteItemRequest.fromJson(json);
      expect(request.id, equals('req-1'));
      expect(request.voteId, equals(100));
      expect(request.status, equals('pending'));

      final output = request.toJson();
      expect(output['id'], equals('req-1'));
    });
  });

  group('QnaThread fromJson/toJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'user_id': 'user-1',
        'title': '문의사항',
        'status': 'received',
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-15T00:00:00.000Z',
      };
      final t = thread.QnaThread.fromJson(json);
      expect(t.id, equals(1));
      expect(t.title, equals('문의사항'));
      expect(t.status, equals('received'));

      final output = t.toJson();
      expect(output['title'], equals('문의사항'));
    });
  });

  group('QnaMessage fromJson/toJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'thread_id': 10,
        'user_id': 'user-abc',
        'content': '메시지 내용',
        'created_at': '2025-03-01T00:00:00.000Z',
        'is_admin_message': false,
        'qna_attachments': [],
      };
      final msg = QnaMessage.fromJson(json);
      expect(msg.id, equals(1));
      expect(msg.content, equals('메시지 내용'));
      expect(msg.userId, equals('user-abc'));
      expect(msg.isAdminMessage, isFalse);

      final output = msg.toJson();
      expect(output['content'], equals('메시지 내용'));
    });
  });

  group('QnaAttachment fromJson/toJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'message_id': 5,
        'file_name': 'doc.pdf',
        'file_path': 'https://example.com/file.pdf',
        'file_type': 'application/pdf',
        'file_size': 1024,
        'created_at': '2025-03-01T00:00:00.000Z',
      };
      final attachment = QnaAttachment.fromJson(json);
      expect(attachment.id, equals(1));
      expect(attachment.fileName, equals('doc.pdf'));
      expect(attachment.filePath, equals('https://example.com/file.pdf'));

      final output = attachment.toJson();
      expect(output['file_name'], equals('doc.pdf'));
    });
  });

  group('Popup fromJson/toJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'title': {'ko': '팝업 제목', 'en': 'Popup Title'},
        'content': {'ko': '내용', 'en': 'Content'},
        'image': {'ko': 'ko.jpg', 'en': 'en.jpg'},
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': null,
        'deleted_at': null,
        'start_at': '2025-02-01T00:00:00.000Z',
        'stop_at': '2025-03-01T00:00:00.000Z',
      };
      final popup = Popup.fromJson(json);
      expect(popup.id, equals(1));
      expect(popup.title['ko'], equals('팝업 제목'));

      final output = popup.toJson();
      expect(output['id'], equals(1));
    });
  });

  group('RewardModel fromJson/toJson', () {
    test('roundtrip', () {
      final json = {
        'id': 5,
        'title': {'ko': '보상', 'en': 'Reward'},
        'thumbnail': 'thumb.jpg',
        'overview_images': ['img1.jpg', 'img2.jpg'],
        'location': {'ko': '서울', 'en': 'Seoul'},
        'size_guide': {'width': '5cm'},
        'size_guide_images': ['size.jpg'],
      };
      final reward = RewardModel.fromJson(json);
      expect(reward.id, equals(5));
      expect(reward.title!['ko'], equals('보상'));
      expect(reward.overviewImages!.length, equals(2));

      final output = reward.toJson();
      expect(output['id'], equals(5));
    });
  });

  group('UserPushToken fromJson/toJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'user_id': 'user-abc',
        'token_ios': 'ios-token',
        'token_android': null,
        'token_web': null,
        'token_macos': null,
        'token_windows': null,
      };
      final token = UserPushToken.fromJson(json);
      expect(token.id, equals(1));
      expect(token.tokenIos, equals('ios-token'));
      expect(token.tokenAndroid, isNull);

      final output = token.toJson();
      expect(output['user_id'], equals('user-abc'));
      expect(output['token_ios'], equals('ios-token'));
    });
  });

  group('PolicyModel fromJson/toJson', () {
    test('roundtrip', () {
      final json = {
        'privacy_en': {'content': 'Privacy', 'version': '1.0'},
        'terms_en': {'content': 'Terms', 'version': '1.0'},
        'privacy_ko': {'content': '개인정보', 'version': '1.0'},
        'terms_ko': {'content': '이용약관', 'version': '1.0'},
      };
      final policy = PolicyModel.fromJson(json);
      expect(policy.privacyEn.content, equals('Privacy'));
      expect(policy.termsKo.content, equals('이용약관'));

      final output = policy.toJson();
      expect((output['privacy_en'] as Map)['content'], equals('Privacy'));
    });
  });

  group('GalleryModel fromJson', () {
    test('fromJson', () {
      final json = {
        'id': 1,
        'title_ko': '갤러리',
        'title_en': 'Gallery',
        'cover': 'cover.jpg',
        'celeb': null,
      };
      final gallery = GalleryModel.fromJson(json);
      expect(gallery.id, equals(1));
      expect(gallery.titleKo, equals('갤러리'));
      expect(gallery.cover, equals('cover.jpg'));
    });
  });

  group('UserCommentLikeModel fromJson', () {
    test('fromJson', () {
      final json = {
        'id': 1,
        'user_id': 42,
        'created_at': '2025-03-01T00:00:00.000Z',
      };
      final like = UserCommentLikeModel.fromJson(json);
      expect(like.id, equals(1));
      expect(like.userId, equals(42));
    });
  });

  group('BoardModel fromJson', () {
    test('fromJson 기본', () {
      final json = {
        'board_id': 'board-1',
        'name': {'ko': '자유게시판', 'en': 'Free Board'},
        'description': {'ko': '설명', 'en': 'Description'},
        'artist_id': 42,
        'is_official': true,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
        'artist': null,
        'request_message': null,
        'status': 'active',
        'creator_id': null,
        'features': ['post', 'comment'],
      };
      final board = BoardModel.fromJson(json);
      expect(board.boardId, equals('board-1'));
      expect(board.name['ko'], equals('자유게시판'));
      expect(board.isOfficial, isTrue);
      expect(board.features!.length, equals(2));
    });

    test('description이 문자열인 경우', () {
      final json = {
        'board_id': 'board-2',
        'name': {'ko': '게시판'},
        'description': '일반 문자열 설명',
        'artist_id': 1,
        'is_official': null,
        'created_at': null,
        'updated_at': null,
        'artist': null,
        'request_message': null,
        'status': null,
        'creator_id': null,
        'features': null,
      };
      final board = BoardModel.fromJson(json);
      expect(board.description, equals('일반 문자열 설명'));
    });
  });

  group('PostModel fromJson', () {
    test('fromJson 기본', () {
      final json = {
        'post_id': 'post-1',
        'user_id': 'user-1',
        'user_profiles': null,
        'board_id': 'board-1',
        'title': '테스트 글',
        'content': [{'type': 'text', 'value': '내용'}],
        'view_count': 10,
        'reply_count': 3,
        'is_hidden': false,
        'board': null,
        'is_anonymous': false,
        'is_scraped': false,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
      };
      final post = PostModel.fromJson(json);
      expect(post.postId, equals('post-1'));
      expect(post.title, equals('테스트 글'));
      expect(post.viewCount, equals(10));
    });
  });

  group('PostScrapModel fromJson', () {
    test('fromJson 기본', () {
      final json = {
        'post_id': 'post-1',
        'user_id': 'user-1',
        'user_profiles': null,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
        'board': null,
        'post': null,
      };
      final scrap = PostScrapModel.fromJson(json);
      expect(scrap.postId, equals('post-1'));
      expect(scrap.deletedAt, isNull);
    });
  });

  group('ArticleImageModel fromJson', () {
    test('fromJson 기본', () {
      final json = {
        'id': 1,
        'title_ko': '이미지',
        'title_en': 'Image',
        'image': 'img.jpg',
        'article_image_user': null,
      };
      final img = ArticleImageModel.fromJson(json);
      expect(img.id, equals(1));
      expect(img.image, equals('img.jpg'));
    });
  });

  group('LibraryModel fromJson', () {
    test('fromJson 기본', () {
      final json = {
        'id': 1,
        'title': '라이브러리',
        'images': null,
      };
      final lib = LibraryModel.fromJson(json);
      expect(lib.id, equals(1));
      expect(lib.title, equals('라이브러리'));
    });
  });
}
