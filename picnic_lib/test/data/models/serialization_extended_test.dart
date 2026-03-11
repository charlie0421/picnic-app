import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/app_version.dart';
import 'package:picnic_lib/data/models/common/social_login_result.dart';
import 'package:picnic_lib/data/models/community/fortune.dart';
import 'package:picnic_lib/data/models/pic/celeb.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/data/models/vote/video_info.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/vote/vote_item_request_user.dart';
import 'package:picnic_lib/data/models/vote/vote_pick.dart';

void main() {
  group('AppVersionModel fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'ios': {'min': '1.0.0', 'latest': '2.0.0'},
        'android': {'min': '1.0.0', 'latest': '2.0.0'},
        'macos': {'min': '1.0.0', 'latest': '2.0.0'},
        'windows': {'min': '1.0.0', 'latest': '1.5.0'},
        'linux': {'min': '1.0.0', 'latest': '1.5.0'},
      };
      final model = AppVersionModel.fromJson(json);
      expect(model.id, equals(1));
      expect(model.ios['latest'], equals('2.0.0'));
      expect(model.android['min'], equals('1.0.0'));

      final output = model.toJson();
      expect(output['id'], equals(1));
    });
  });

  group('SocialLoginResult fromJson', () {
    test('roundtrip', () {
      final json = {
        'id_token': 'id-token-123',
        'access_token': 'access-token-456',
        'user_data': {'name': 'User', 'email': 'u@e.com'},
      };
      final result = SocialLoginResult.fromJson(json);
      expect(result.idToken, equals('id-token-123'));
      expect(result.accessToken, equals('access-token-456'));
      expect(result.userData!['name'], equals('User'));

      final output = result.toJson();
      expect(output['id_token'], equals('id-token-123'));
    });

    test('모든 필드 null', () {
      final result = SocialLoginResult.fromJson({});
      expect(result.idToken, isNull);
      expect(result.accessToken, isNull);
      expect(result.userData, isNull);
    });
  });

  group('VideoInfo fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'video_id': 'abc123',
        'video_url': 'https://youtube.com/watch?v=abc123',
        'title': {'ko': '영상 제목', 'en': 'Video Title'},
        'thumbnail_url': 'https://img.youtube.com/vi/abc123/0.jpg',
        'created_at': '2025-01-01T00:00:00.000Z',
        'channel_title': '채널명',
        'channel_id': 'ch-1',
        'channel_thumbnail': 'https://yt.com/ch.jpg',
      };
      final video = VideoInfo.fromJson(json);
      expect(video.id, equals(1));
      expect(video.videoId, equals('abc123'));
      expect(video.title['ko'], equals('영상 제목'));
      expect(video.channelTitle, equals('채널명'));

      final output = video.toJson();
      expect(output['video_id'], equals('abc123'));
    });
  });

  group('VoteItemRequestUser fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 'req-1',
        'vote_id': 100,
        'user_id': 'user-abc',
        'artist_id': 42,
        'status': 'approved',
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-02T00:00:00.000Z',
        'artist': null,
      };
      final model = VoteItemRequestUser.fromJson(json);
      expect(model.id, equals('req-1'));
      expect(model.voteId, equals(100));
      expect(model.userId, equals('user-abc'));
      expect(model.artistId, equals(42));
      expect(model.status, equals('approved'));
      expect(model.artist, isNull);

      final output = model.toJson();
      expect(output['id'], equals('req-1'));
      expect(output['vote_id'], equals(100));
    });
  });

  group('VotePickModel fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'vote': {
          'id': 10,
          'title': {'ko': '투표'},
          'vote_category': null,
          'main_image': null,
          'wait_image': null,
          'result_image': null,
          'vote_content': null,
          'vote_item': null,
          'created_at': null,
          'visible_at': null,
          'start_at': null,
          'stop_at': null,
          'is_ended': false,
          'is_upcoming': false,
          'is_partnership': false,
          'partner': null,
          'reward': null,
        },
        'vote_item': {
          'id': 20,
          'vote_total': 100,
          'vote_id': 10,
          'artist': null,
          'artist_group': null,
        },
        'amount': 5,
        'star_candy_usage': 10,
        'star_candy_bonus_usage': 3,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-02T00:00:00.000Z',
      };
      final pick = VotePickModel.fromJson(json);
      expect(pick.id, equals(1));
      expect(pick.vote.id, equals(10));
      expect(pick.voteItem.id, equals(20));
      expect(pick.amount, equals(5));
      expect(pick.starCandyUsage, equals(10));

      final output = pick.toJson();
      expect(output['id'], equals(1));
      expect(output['amount'], equals(5));
    });
  });

  group('CelebModel fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 1,
        'name_ko': '셀럽',
        'name_en': 'Celeb',
        'thumbnail': 'thumb.jpg',
        'users': null,
      };
      final celeb = CelebModel.fromJson(json);
      expect(celeb.id, equals(1));
      expect(celeb.nameKo, equals('셀럽'));
      expect(celeb.nameEn, equals('Celeb'));
      expect(celeb.thumbnail, equals('thumb.jpg'));

      final output = celeb.toJson();
      expect(output['name_ko'], equals('셀럽'));
    });
  });

  group('UserProfilesModel fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 'user-1',
        'nickname': '닉네임',
        'avatar_url': 'https://example.com/avatar.jpg',
        'country_code': 'KR',
        'deleted_at': null,
        'user_agreement': null,
        'is_admin': false,
        'star_candy': 100,
        'star_candy_bonus': 50,
        'jma_candy': 30,
        'birth_date': null,
        'gender': 'M',
        'birth_time': null,
      };
      final profile = UserProfilesModel.fromJson(json);
      expect(profile.id, equals('user-1'));
      expect(profile.nickname, equals('닉네임'));
      expect(profile.isAdmin, isFalse);
      expect(profile.starCandy, equals(100));
      expect(profile.starCandyBonus, equals(50));
      expect(profile.jmaCandy, equals(30));

      final output = profile.toJson();
      expect(output['id'], equals('user-1'));
      expect(output['star_candy'], equals(100));
    });
  });

  group('UserAgreement fromJson', () {
    test('roundtrip', () {
      final json = {
        'terms': '2025-01-01T00:00:00.000Z',
        'privacy': '2025-01-01T00:00:00.000Z',
      };
      final agreement = UserAgreement.fromJson(json);
      expect(agreement.terms.year, equals(2025));
      expect(agreement.privacy.year, equals(2025));

      final output = agreement.toJson();
      expect(output['terms'], isNotNull);
    });
  });

  group('FortuneModel fromJson', () {
    test('roundtrip', () {
      final json = {
        'id': 'fortune-1',
        'year': 2025,
        'artist_id': 1,
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
        'overall_luck': '매우 좋음',
        'monthly_fortunes': [
          {
            'month': 1,
            'honor': '좋음',
            'career': '보통',
            'health': '좋음',
            'summary': '1월 운세',
          },
        ],
        'aspects': {
          'honor': '좋음',
          'career': '매우 좋음',
          'health': '보통',
          'finances': '좋음',
          'relationships': '매우 좋음',
        },
        'lucky': {
          'days': ['월', '수'],
          'colors': ['빨강', '파랑'],
          'numbers': [3, 7],
          'directions': ['동', '남'],
        },
        'advice': ['조언1', '조언2'],
      };
      final fortune = FortuneModel.fromJson(json);
      expect(fortune.id, equals('fortune-1'));
      expect(fortune.year, equals(2025));
      expect(fortune.overallLuck, equals('매우 좋음'));
      expect(fortune.monthlyFortunes.length, equals(1));
      expect(fortune.monthlyFortunes[0].month, equals(1));
      expect(fortune.aspects.career, equals('매우 좋음'));
      expect(fortune.lucky.numbers, equals([3, 7]));
      expect(fortune.advice.length, equals(2));

      final output = fortune.toJson();
      expect(output['id'], equals('fortune-1'));
      expect(output['year'], equals(2025));
    });
  });

  group('MonthlyFortuneModel fromJson', () {
    test('기본 생성', () {
      final json = {
        'month': 6,
        'honor': '매우 좋음',
        'career': '좋음',
        'health': '보통',
        'summary': '6월 운세 요약',
      };
      final monthly = MonthlyFortuneModel.fromJson(json);
      expect(monthly.month, equals(6));
      expect(monthly.honor, equals('매우 좋음'));
      expect(monthly.summary, equals('6월 운세 요약'));
    });
  });

  group('LuckyModel fromJson', () {
    test('기본 생성', () {
      final json = {
        'days': ['화', '목'],
        'colors': ['녹색'],
        'numbers': [5, 9, 12],
        'directions': ['서'],
      };
      final lucky = LuckyModel.fromJson(json);
      expect(lucky.days, equals(['화', '목']));
      expect(lucky.colors, equals(['녹색']));
      expect(lucky.numbers, equals([5, 9, 12]));
      expect(lucky.directions, equals(['서']));
    });
  });
}
