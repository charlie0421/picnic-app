import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/banner.dart';
import 'package:picnic_lib/data/models/pic/article_image.dart';
import 'package:picnic_lib/data/models/pic/celeb.dart';
import 'package:picnic_lib/data/models/pic/comment_like.dart';
import 'package:picnic_lib/data/models/pic/library.dart';
import 'package:picnic_lib/data/models/pic/artist_vote.dart';
import 'package:picnic_lib/data/models/reward.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/data/models/pic/article.dart';
import 'package:picnic_lib/data/models/pic/gallery.dart';

void main() {
  group('BannerModel', () {
    test('fromJson', () {
      final banner = BannerModel.fromJson(const {
        'id': 1,
        'title': {'ko': '이벤트 배너', 'en': 'Event Banner'},
        'thumbnail': 'https://example.com/thumb.jpg',
        'image': {'ko': 'https://example.com/ko.jpg', 'en': 'https://example.com/en.jpg'},
        'duration': 5000,
        'link': 'https://example.com',
      });
      expect(banner.id, 1);
      expect(banner.title['ko'], '이벤트 배너');
      expect(banner.thumbnail, 'https://example.com/thumb.jpg');
      expect(banner.duration, 5000);
      expect(banner.link, 'https://example.com');
    });

    test('fromJson with null link', () {
      final banner = BannerModel.fromJson(const {
        'id': 2,
        'title': {'ko': 'Test'},
        'thumbnail': 'thumb.jpg',
        'image': {'ko': 'img.jpg'},
        'duration': 3000,
        'link': null,
      });
      expect(banner.link, isNull);
    });

    test('fromJson with default duration', () {
      final banner = BannerModel.fromJson(const {
        'id': 3,
        'title': {'ko': 'Test'},
        'thumbnail': 'thumb.jpg',
        'image': {'ko': 'img.jpg'},
        'link': null,
      });
      expect(banner.duration, 3000);
    });
  });

  group('ArticleImageModel', () {
    test('fromJson', () {
      final img = ArticleImageModel.fromJson(const {
        'id': 1,
        'title_ko': '이미지 제목',
        'title_en': 'Image Title',
        'image': 'https://example.com/img.jpg',
        'article_image_user': null,
      });
      expect(img.id, 1);
      expect(img.titleKo, '이미지 제목');
      expect(img.titleEn, 'Image Title');
      expect(img.image, 'https://example.com/img.jpg');
    });
  });

  group('CelebModel', () {
    test('fromJson', () {
      final celeb = CelebModel.fromJson(const {
        'id': 1,
        'name_ko': '지민',
        'name_en': 'Jimin',
        'thumbnail': 'https://example.com/jimin.jpg',
      });
      expect(celeb.id, 1);
      expect(celeb.nameKo, '지민');
      expect(celeb.nameEn, 'Jimin');
      expect(celeb.thumbnail, 'https://example.com/jimin.jpg');
    });

    test('fromJson with null fields', () {
      final celeb = CelebModel.fromJson(const {
        'id': 2,
        'name_ko': 'Test',
        'name_en': 'Test',
      });
      expect(celeb.thumbnail, isNull);
      expect(celeb.users, isNull);
    });
  });

  group('UserCommentLikeModel', () {
    test('fromJson', () {
      final like = UserCommentLikeModel.fromJson(const {
        'id': 1,
        'user_id': 42,
        'created_at': '2024-01-15T10:30:00Z',
      });
      expect(like.id, 1);
      expect(like.userId, 42);
      expect(like.createdAt.year, 2024);
    });
  });

  group('LibraryModel', () {
    test('fromJson', () {
      final lib = LibraryModel.fromJson(const {
        'id': 1,
        'title': 'My Library',
        'images': null,
      });
      expect(lib.id, 1);
      expect(lib.title, 'My Library');
      expect(lib.images, isNull);
    });

    test('fromJson with images', () {
      final lib = LibraryModel.fromJson(const {
        'id': 2,
        'title': 'Gallery',
        'images': [
          {
            'id': 1,
            'title_ko': '이미지',
            'title_en': 'Image',
            'article_image_user': null,
          },
        ],
      });
      expect(lib.images!.length, 1);
    });
  });

  group('RewardModel', () {
    test('fromJson', () {
      final reward = RewardModel.fromJson(const {
        'id': 1,
        'title': {'ko': '포토카드', 'en': 'Photocard'},
        'thumbnail': 'https://example.com/reward.jpg',
        'overview_images': ['img1.jpg', 'img2.jpg'],
        'location': {'ko': '서울', 'en': 'Seoul'},
        'size_guide': null,
        'size_guide_images': null,
      });
      expect(reward.id, 1);
      expect(reward.title!['ko'], '포토카드');
      expect(reward.thumbnail, 'https://example.com/reward.jpg');
      expect(reward.overviewImages!.length, 2);
    });

    test('fromJson with minimal fields', () {
      final reward = RewardModel.fromJson(const {
        'id': 2,
      });
      expect(reward.id, 2);
      expect(reward.title, isNull);
      expect(reward.thumbnail, isNull);
    });
  });

  group('ArtistVoteModel', () {
    test('fromJson', () {
      final vote = ArtistVoteModel.fromJson({
        'id': 1,
        'title': {'ko': 'Best Male', 'en': 'Best Male'},
        'category': 'birthday',
        'artist_vote_item': null,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': null,
        'visible_at': null,
        'stop_at': '2024-02-01T00:00:00Z',
        'start_at': '2024-01-01T00:00:00Z',
      });
      expect(vote.id, 1);
      expect(vote.category, 'birthday');
      expect(vote.artistVoteItem, isNull);
    });
  });

  group('ArtistVoteItemModel', () {
    test('fromJson', () {
      final item = ArtistVoteItemModel.fromJson(const {
        'id': 1,
        'vote_total': 5000,
        'artist_vote_id': 10,
        'title': {'ko': '지민', 'en': 'Jimin'},
        'description': {'ko': '설명', 'en': 'desc'},
      });
      expect(item.id, 1);
      expect(item.voteTotal, 5000);
      expect(item.artistVoteId, 10);
    });
  });

  group('ArtistMemberModel (from artist_vote)', () {
    test('fromJson', () {
      final member = ArtistMemberModel.fromJson(const {
        'id': 1,
        'name': {'ko': '지민', 'en': 'Jimin'},
        'gender': 'male',
        'image': 'https://example.com/jimin.jpg',
      });
      expect(member.id, 1);
      expect(member.name['ko'], '지민');
      expect(member.gender, 'male');
    });
  });

  group('GalleryModel', () {
    test('fromJson', () {
      final gallery = GalleryModel.fromJson(const {
        'id': 1,
        'title_ko': '갤러리',
        'title_en': 'Gallery',
        'cover': 'cover.jpg',
        'celeb': {
          'id': 1,
          'name_ko': '지민',
          'name_en': 'Jimin',
        },
      });
      expect(gallery.id, 1);
      expect(gallery.titleKo, '갤러리');
      expect(gallery.getCdnUrl('photo.jpg'),
          'https://cdn-dev.picnic.fan/gallery/1/photo.jpg');
    });

    test('getCdnUrl', () {
      final gallery = GalleryModel.fromJson(const {
        'id': 42,
        'title_ko': 'Test',
        'title_en': 'Test',
        'celeb': null,
      });
      expect(gallery.getCdnUrl('image.webp'),
          'https://cdn-dev.picnic.fan/gallery/42/image.webp');
    });
  });

  group('PostModel', () {
    test('fromJson minimal', () {
      final post = PostModel.fromJson(const {
        'post_id': 'post-1',
        'user_id': 'user-1',
        'user_profiles': null,
        'board_id': 'board-1',
        'title': 'Test Post',
        'content': null,
        'view_count': 100,
        'reply_count': 5,
        'is_hidden': false,
        'boards': null,
        'is_anonymous': false,
        'is_scraped': false,
        'created_at': '2024-01-15T10:00:00Z',
        'updated_at': '2024-01-15T12:00:00Z',
      });
      expect(post.postId, 'post-1');
      expect(post.title, 'Test Post');
      expect(post.viewCount, 100);
      expect(post.replyCount, 5);
      expect(post.isHidden, isFalse);
    });
  });

  group('CommentModel', () {
    test('fromJson minimal', () {
      final comment = CommentModel.fromJson(const {
        'comment_id': 'comment-1',
        'children': null,
        'myLike': null,
        'user_profiles': null,
        'likes': 10,
        'replies': 3,
        'content': {'ko': '댓글 내용'},
        'isLikedByMe': false,
        'isReportedByMe': false,
        'isBlindedByAdmin': false,
        'isRepliedByMe': false,
        'post': null,
        'locale': 'ko',
        'parent_comment_id': null,
        'created_at': '2024-01-15T10:00:00Z',
        'updated_at': '2024-01-15T12:00:00Z',
      });
      expect(comment.commentId, 'comment-1');
      expect(comment.likes, 10);
      expect(comment.replies, 3);
      expect(comment.locale, 'ko');
    });
  });

  group('ArticleModel', () {
    test('fromJson', () {
      final article = ArticleModel.fromJson({
        'id': 1,
        'title_ko': '기사 제목',
        'title_en': 'Article Title',
        'content': 'Content text',
        'gallery': null,
        'article_image': null,
        'created_at': '2024-01-15T10:00:00Z',
        'comment_count': 5,
        'comment': null,
        'most_liked_comment': null,
      });
      expect(article.id, 1);
      expect(article.titleKo, '기사 제목');
      expect(article.content, 'Content text');
      expect(article.commentCount, 5);
    });
  });
}
