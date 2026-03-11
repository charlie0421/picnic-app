import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/banner.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/data/models/community/goonghap_result.dart' as gr;
import 'package:picnic_lib/data/models/pic/article.dart';
import 'package:picnic_lib/data/models/pic/artist_vote.dart';

void main() {
  group('BannerModel fromJson/toJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'title': {'ko': '배너 제목', 'en': 'Banner Title'},
        'thumbnail': 'thumb.jpg',
        'image': {'ko': 'ko.jpg', 'en': 'en.jpg'},
        'duration': 5000,
        'link': 'https://example.com',
      };
      final banner = BannerModel.fromJson(json);
      expect(banner.id, equals(1));
      expect(banner.title['ko'], equals('배너 제목'));
      expect(banner.thumbnail, equals('thumb.jpg'));
      expect(banner.image['en'], equals('en.jpg'));
      expect(banner.duration, equals(5000));
      expect(banner.link, equals('https://example.com'));

      final output = banner.toJson();
      expect(output['id'], equals(1));
      expect(output['thumbnail'], equals('thumb.jpg'));
      expect(output['duration'], equals(5000));
    });

    test('link null', () {
      final json = {
        'id': 2,
        'title': {'ko': '제목'},
        'thumbnail': 'thumb2.jpg',
        'image': {'ko': 'img.jpg'},
        'duration': 3000,
        'link': null,
      };
      final banner = BannerModel.fromJson(json);
      expect(banner.link, isNull);
      expect(banner.duration, equals(3000));
    });

    test('duration 기본값', () {
      final json = {
        'id': 3,
        'title': {'ko': '제목'},
        'thumbnail': 'thumb3.jpg',
        'image': {'ko': 'img.jpg'},
        'link': null,
      };
      final banner = BannerModel.fromJson(json);
      expect(banner.duration, equals(3000)); // defaultValue: 3000
    });
  });

  group('CommentModel fromJson/toJson', () {
    test('기본 fromJson', () {
      final json = {
        'comment_id': 'comment-1',
        'user_id': 'user-1',
        'children': null,
        'myLike': null,
        'user_profiles': null,
        'likes': 5,
        'replies': 2,
        'content': {'text': '댓글 내용'},
        'is_liked_by_me': false,
        'is_reported_by_me': false,
        'is_blinded_by_admin': false,
        'is_replied_by_me': true,
        'post': null,
        'locale': 'ko',
        'parent_comment_id': null,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
        'deleted_at': null,
      };
      final comment = CommentModel.fromJson(json);
      expect(comment.commentId, equals('comment-1'));
      expect(comment.likes, equals(5));
      expect(comment.replies, equals(2));
      expect(comment.isLikedByMe, isFalse);
      expect(comment.isRepliedByMe, isTrue);
      expect(comment.locale, equals('ko'));
      expect(comment.deletedAt, isNull);

      final output = comment.toJson();
      expect(output['comment_id'], equals('comment-1'));
      expect(output['likes'], equals(5));
    });

    test('children 있는 댓글', () {
      final json = {
        'comment_id': 'parent-1',
        'user_id': 'user-1',
        'children': [
          {
            'comment_id': 'child-1',
            'user_id': 'user-2',
            'children': null,
            'myLike': null,
            'user_profiles': null,
            'likes': 1,
            'replies': 0,
            'content': {'text': '답글'},
            'is_liked_by_me': null,
            'is_reported_by_me': null,
            'is_blinded_by_admin': null,
            'is_replied_by_me': null,
            'post': null,
            'locale': 'ko',
            'parent_comment_id': 'parent-1',
            'created_at': '2025-01-02T00:00:00.000Z',
            'updated_at': '2025-01-02T00:00:00.000Z',
          },
        ],
        'myLike': null,
        'user_profiles': null,
        'likes': 10,
        'replies': 1,
        'content': {'text': '부모 댓글'},
        'is_liked_by_me': null,
        'is_reported_by_me': null,
        'is_blinded_by_admin': null,
        'is_replied_by_me': null,
        'post': null,
        'locale': null,
        'parent_comment_id': null,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
      };
      final comment = CommentModel.fromJson(json);
      expect(comment.children, isNotNull);
      expect(comment.children!.length, equals(1));
      expect(comment.children![0].commentId, equals('child-1'));
      expect(comment.children![0].parentCommentId, equals('parent-1'));
    });
  });

  group('ArticleModel fromJson/toJson', () {
    test('기본 fromJson', () {
      final json = {
        'id': 1,
        'title_ko': '기사 제목',
        'title_en': 'Article Title',
        'content': '기사 내용',
        'gallery': null,
        'article_image': null,
        'created_at': '2025-01-01T00:00:00.000Z',
        'comment_count': 5,
        'comment': null,
        'most_liked_comment': null,
      };
      final article = ArticleModel.fromJson(json);
      expect(article.id, equals(1));
      expect(article.titleKo, equals('기사 제목'));
      expect(article.titleEn, equals('Article Title'));
      expect(article.content, equals('기사 내용'));
      expect(article.commentCount, equals(5));

      final output = article.toJson();
      expect(output['id'], equals(1));
      expect(output['title_ko'], equals('기사 제목'));
    });

    test('article_image 있는 기사', () {
      final json = {
        'id': 2,
        'title_ko': '제목',
        'title_en': 'Title',
        'content': '내용',
        'gallery': null,
        'article_image': [
          {
            'id': 10,
            'title_ko': '이미지1',
            'title_en': 'Image1',
            'image': 'img1.jpg',
            'article_image_user': null,
          },
        ],
        'created_at': '2025-01-01T00:00:00.000Z',
        'comment_count': 0,
        'comment': null,
        'most_liked_comment': null,
      };
      final article = ArticleModel.fromJson(json);
      expect(article.articleImage, isNotNull);
      expect(article.articleImage!.length, equals(1));
      expect(article.articleImage![0].image, equals('img1.jpg'));
    });
  });

  group('ArtistVoteModel fromJson/toJson', () {
    test('기본 fromJson', () {
      final json = {
        'id': 1,
        'title': {'ko': '아티스트 투표'},
        'category': 'music',
        'artist_vote_item': null,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': null,
        'visible_at': null,
        'stop_at': '2025-03-01T00:00:00.000Z',
        'start_at': '2025-02-01T00:00:00.000Z',
      };
      final vote = ArtistVoteModel.fromJson(json);
      expect(vote.id, equals(1));
      expect(vote.title['ko'], equals('아티스트 투표'));
      expect(vote.category, equals('music'));

      final output = vote.toJson();
      expect(output['id'], equals(1));
      expect(output['category'], equals('music'));
    });
  });

  group('ArtistVoteItemModel fromJson/toJson', () {
    test('roundtrip', () {
      final json = {
        'id': 10,
        'vote_total': 500,
        'artist_vote_id': 1,
        'title': {'ko': '아이템 제목'},
        'description': {'ko': '아이템 설명'},
      };
      final item = ArtistVoteItemModel.fromJson(json);
      expect(item.id, equals(10));
      expect(item.voteTotal, equals(500));
      expect(item.artistVoteId, equals(1));

      final output = item.toJson();
      expect(output['vote_total'], equals(500));
    });
  });

  group('ArtistMemberModel fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'name': {'ko': '지민', 'en': 'Jimin'},
        'gender': 'M',
        'image': 'jimin.jpg',
        'artist_group': null,
      };
      final member = ArtistMemberModel.fromJson(json);
      expect(member.id, equals(1));
      expect(member.name['ko'], equals('지민'));
      expect(member.gender, equals('M'));

      final output = member.toJson();
      expect(output['id'], equals(1));
    });
  });

  group('ArtistGroupModel (pic) fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 5,
        'name': {'ko': 'BTS', 'en': 'BTS'},
        'image': 'bts.jpg',
      };
      final group = ArtistGroupModel.fromJson(json);
      expect(group.id, equals(5));
      expect(group.name['ko'], equals('BTS'));

      final output = group.toJson();
      expect(output['id'], equals(5));
    });
  });

  group('MyStarMemberModel fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'name_ko': '지민',
        'name_en': 'Jimin',
        'gender': 'M',
        'image': 'jimin.jpg',
        'mystar_group': null,
      };
      final member = MyStarMemberModel.fromJson(json);
      expect(member.id, equals(1));
      expect(member.nameKo, equals('지민'));
      expect(member.nameEn, equals('Jimin'));

      final output = member.toJson();
      expect(output['name_ko'], equals('지민'));
    });
  });

  group('MyStarGroupModel fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 10,
        'name_ko': 'BTS',
        'name_en': 'BTS',
        'image': 'group.jpg',
      };
      final group = MyStarGroupModel.fromJson(json);
      expect(group.id, equals(10));
      expect(group.nameKo, equals('BTS'));

      final output = group.toJson();
      expect(output['name_ko'], equals('BTS'));
    });
  });

  group('GoonghapModel fromJson', () {
    test('기본 fromJson', () {
      final json = {
        'id': 'g-1',
        'user_id': 'user-1',
        'artist': {
          'id': 1,
          'name': {'ko': '지민'},
          'birth_date': null,
          'gender': 'M',
          'image': null,
          'created_at': null,
          'updated_at': null,
          'deleted_at': null,
          'isBookmarked': null,
        },
        'user_birth_date': '2000-01-01T00:00:00.000Z',
        'user_birth_time': '3',
        'status': 'completed',
        'gender': 'F',
        'error_message': null,
        'is_loading': false,
        'score': 85,
        'goonghap_summary': '궁합 요약',
        'details': null,
        'tips': ['팁1', '팁2'],
        'created_at': '2025-01-01T00:00:00.000Z',
        'completed_at': '2025-01-01T00:01:00.000Z',
        'i18n': null,
        'is_ads': false,
        'is_paid': true,
      };
      final model = GoonghapModel.fromJson(json);
      expect(model.id, equals('g-1'));
      expect(model.isCompleted, isTrue);
      expect(model.isPending, isFalse);
      expect(model.hasError, isFalse);
      expect(model.score, equals(85));
      expect(model.tips!.length, equals(2));
      expect(model.isPaid, isTrue);
    });
  });

  group('GoonghapHistoryModel fromJson', () {
    test('roundtrip', () {
      final json = {
        'items': <Map<String, dynamic>>[],
        'has_more': false,
        'is_loading': false,
      };
      final history = GoonghapHistoryModel.fromJson(json);
      expect(history.items, isEmpty);
      expect(history.hasMore, isFalse);
      expect(history.isLoading, isFalse);
    });
  });

  group('GoonghapResult fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 'gr-1',
        'user_id': 'user-1',
        'idol_name': '지민',
        'user_birth_date': '2000-01-01T00:00:00.000Z',
        'idol_birth_date': '1995-10-13T00:00:00.000Z',
        'user_gender': 'F',
        'birth_time': '3',
        'goonghap_score': 90,
        'goonghap_summary': '궁합 요약',
        'tips': ['팁1'],
        'details': {
          'style': {'idol_style': 'IS', 'user_style': 'US'},
        },
        'created_at': '2025-01-01T00:00:00.000Z',
      };
      final result = gr.GoonghapResult.fromJson(json);
      expect(result.id, equals('gr-1'));
      expect(result.goonghapScore, equals(90));
      expect(result.goonghapSummary, equals('궁합 요약'));
      expect(result.tips!.length, equals(1));
      expect(result.details, isNotNull);

      final output = result.toJson();
      expect(output['goonghap_score'], equals(90));
    });
  });

  group('StyleDetails (goonghap_result) fromJson', () {
    test('roundtrip', () {
      final json = {
        'idol_style': 'IS',
        'user_style': 'US',
        'couple_style': 'CS',
      };
      final style = gr.StyleDetails.fromJson(json);
      expect(style.idolStyle, equals('IS'));
      expect(style.userStyle, equals('US'));
      expect(style.coupleStyle, equals('CS'));

      final output = style.toJson();
      expect(output['idol_style'], equals('IS'));
    });
  });

  group('ActivitiesDetails (goonghap_result) fromJson', () {
    test('roundtrip', () {
      final json = {
        'recommended': ['데이트', '산책'],
        'description': '활동 설명',
      };
      final activities = gr.ActivitiesDetails.fromJson(json);
      expect(activities.recommended!.length, equals(2));
      expect(activities.description, equals('활동 설명'));

      final output = activities.toJson();
      expect(output['description'], equals('활동 설명'));
    });
  });
}
