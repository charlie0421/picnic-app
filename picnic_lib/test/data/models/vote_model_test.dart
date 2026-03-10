import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';

void main() {
  group('VoteModel', () {
    late Map<String, dynamic> testJson;
    late VoteModel testVote;

    setUp(() {
      testJson = {
        'id': 1,
        'title': {'ko': '테스트 투표', 'en': 'Test Vote'},
        'vote_category': 'idol',
        'main_image': 'https://example.com/main.jpg',
        'wait_image': 'https://example.com/wait.jpg',
        'result_image': 'https://example.com/result.jpg',
        'vote_content': '투표 내용',
        'vote_item': null,
        'created_at': '2025-01-01T00:00:00.000Z',
        'visible_at': '2025-01-01T00:00:00.000Z',
        'stop_at': '2099-12-31T23:59:59.000Z',
        'start_at': '2025-01-01T00:00:00.000Z',
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      };

      testVote = VoteModel(
        id: 1,
        title: {'ko': '테스트 투표', 'en': 'Test Vote'},
        voteCategory: 'idol',
        mainImage: 'https://example.com/main.jpg',
        waitImage: 'https://example.com/wait.jpg',
        resultImage: 'https://example.com/result.jpg',
        voteContent: '투표 내용',
        voteItem: null,
        createdAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
        visibleAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
        stopAt: DateTime.parse('2099-12-31T23:59:59.000Z'),
        startAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
        isEnded: false,
        isUpcoming: false,
        isPartnership: false,
        partner: null,
        reward: null,
      );
    });

    group('fromJson', () {
      test('유효한 JSON에서 VoteModel을 생성할 수 있다', () {
        final vote = VoteModel.fromJson(testJson);

        expect(vote.id, equals(1));
        expect(vote.title, equals({'ko': '테스트 투표', 'en': 'Test Vote'}));
        expect(vote.voteCategory, equals('idol'));
        expect(vote.mainImage, equals('https://example.com/main.jpg'));
        expect(vote.isEnded, isFalse);
        expect(vote.isUpcoming, isFalse);
      });

      test('nullable 필드가 null인 JSON을 파싱할 수 있다', () {
        final minimalJson = {
          'id': 2,
          'title': {'ko': '최소 투표'},
          'vote_category': null,
          'main_image': null,
          'wait_image': null,
          'result_image': null,
          'vote_content': null,
          'vote_item': null,
          'created_at': null,
          'visible_at': null,
          'stop_at': null,
          'start_at': null,
          'is_ended': null,
          'is_upcoming': null,
          'is_partnership': null,
          'partner': null,
          'reward': null,
        };

        final vote = VoteModel.fromJson(minimalJson);
        expect(vote.id, equals(2));
        expect(vote.voteCategory, isNull);
        expect(vote.mainImage, isNull);
        expect(vote.startAt, isNull);
        expect(vote.stopAt, isNull);
      });
    });

    group('toJson', () {
      test('VoteModel을 JSON으로 변환할 수 있다', () {
        final json = testVote.toJson();

        expect(json['id'], equals(1));
        expect(json['title'], equals({'ko': '테스트 투표', 'en': 'Test Vote'}));
        expect(json['vote_category'], equals('idol'));
        expect(json['main_image'], equals('https://example.com/main.jpg'));
        expect(json['is_ended'], isFalse);
      });
    });

    group('copyWith', () {
      test('특정 필드만 변경하여 새 인스턴스를 생성할 수 있다', () {
        final modified = testVote.copyWith(
          id: 99,
          voteCategory: 'music',
          isEnded: true,
        );

        expect(modified.id, equals(99));
        expect(modified.voteCategory, equals('music'));
        expect(modified.isEnded, isTrue);
        // 변경하지 않은 필드는 유지
        expect(modified.title, equals(testVote.title));
        expect(modified.mainImage, equals(testVote.mainImage));
      });
    });

    group('동등성', () {
      test('동일한 값을 가진 두 VoteModel은 같다', () {
        final vote1 = VoteModel.fromJson(testJson);
        final vote2 = VoteModel.fromJson(testJson);
        expect(vote1, equals(vote2));
      });

      test('다른 id를 가진 두 VoteModel은 다르다', () {
        final json2 = Map<String, dynamic>.from(testJson);
        json2['id'] = 999;
        final vote1 = VoteModel.fromJson(testJson);
        final vote2 = VoteModel.fromJson(json2);
        expect(vote1, isNot(equals(vote2)));
      });
    });

    group('cardStatus (computed property)', () {
      test('startAt이 미래이면 upcoming을 반환한다', () {
        final futureVote = testVote.copyWith(
          startAt: DateTime.now().add(const Duration(days: 30)),
          stopAt: DateTime.now().add(const Duration(days: 60)),
        );
        expect(futureVote.cardStatus, equals(VoteCardStatus.upcoming));
      });

      test('stopAt이 과거이면 ended를 반환한다', () {
        final endedVote = testVote.copyWith(
          startAt: DateTime.now().subtract(const Duration(days: 60)),
          stopAt: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(endedVote.cardStatus, equals(VoteCardStatus.ended));
      });

      test('현재 시간이 startAt과 stopAt 사이이면 ongoing을 반환한다', () {
        final ongoingVote = testVote.copyWith(
          startAt: DateTime.now().subtract(const Duration(days: 1)),
          stopAt: DateTime.now().add(const Duration(days: 30)),
        );
        expect(ongoingVote.cardStatus, equals(VoteCardStatus.ongoing));
      });

      test('startAt이 null이고 stopAt이 미래이면 ongoing을 반환한다', () {
        final vote = testVote.copyWith(
          startAt: null,
          stopAt: DateTime.now().add(const Duration(days: 30)),
        );
        expect(vote.cardStatus, equals(VoteCardStatus.ongoing));
      });

      test('startAt과 stopAt 모두 null이면 ongoing을 반환한다', () {
        final vote = testVote.copyWith(startAt: null, stopAt: null);
        expect(vote.cardStatus, equals(VoteCardStatus.ongoing));
      });
    });
  });

  group('VoteItemModel', () {
    test('fromJson으로 VoteItemModel을 생성할 수 있다', () {
      final json = {
        'id': 10,
        'vote_total': 500,
        'star_candy_total': 100,
        'star_candy_bonus_total': 50,
        'vote_id': 1,
        'artist': null,
        'artist_group': null,
      };

      final item = VoteItemModel.fromJson(json);
      expect(item.id, equals(10));
      expect(item.voteTotal, equals(500));
      expect(item.starCandyTotal, equals(100));
      expect(item.starCandyBonusTotal, equals(50));
      expect(item.voteId, equals(1));
      expect(item.artist, isNull);
      expect(item.artistGroup, isNull);
    });

    test('toJson으로 JSON 변환이 가능하다', () {
      final item = VoteItemModel(
        id: 10,
        voteTotal: 500,
        voteId: 1,
        artist: null,
        artistGroup: null,
      );

      final json = item.toJson();
      expect(json['id'], equals(10));
      expect(json['vote_total'], equals(500));
      expect(json['vote_id'], equals(1));
    });

    test('copyWith으로 특정 필드를 변경할 수 있다', () {
      final item = VoteItemModel(
        id: 10,
        voteTotal: 500,
        voteId: 1,
        artist: null,
        artistGroup: null,
      );

      final modified = item.copyWith(voteTotal: 999);
      expect(modified.voteTotal, equals(999));
      expect(modified.id, equals(10));
    });

    test('동일한 값을 가진 VoteItemModel은 같다', () {
      final item1 = VoteItemModel(
        id: 10,
        voteTotal: 500,
        voteId: 1,
        artist: null,
        artistGroup: null,
      );
      final item2 = VoteItemModel(
        id: 10,
        voteTotal: 500,
        voteId: 1,
        artist: null,
        artistGroup: null,
      );
      expect(item1, equals(item2));
    });
  });

  group('VoteAchieve', () {
    test('fromJson으로 VoteAchieve를 생성할 수 있다', () {
      final json = {
        'id': 1,
        'vote_id': 10,
        'reward_id': 5,
        'order': 1,
        'amount': 100,
        'reward': {
          'id': 5,
          'title': null,
          'thumbnail': null,
          'overview_images': null,
          'location': null,
          'size_guide': null,
          'size_guide_images': null,
        },
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
          'stop_at': null,
          'start_at': null,
          'is_ended': null,
          'is_upcoming': null,
          'is_partnership': null,
          'partner': null,
          'reward': null,
        },
      };

      final achieve = VoteAchieve.fromJson(json);
      expect(achieve.id, equals(1));
      expect(achieve.voteId, equals(10));
      expect(achieve.rewardId, equals(5));
      expect(achieve.order, equals(1));
      expect(achieve.amount, equals(100));
      expect(achieve.reward, isNotNull);
      expect(achieve.vote, isNotNull);
    });
  });

  group('ArtistModelWithHighlight', () {
    test('필수 파라미터로 객체를 생성할 수 있다', () {
      final artist = ArtistModelWithHighlight(
        artist: ArtistModel(
          id: 1,
          name: {'ko': '테스트 아티스트'},
        ),
        highlightedName: '<b>테스트</b> 아티스트',
        highlightedGroupName: '<b>테스트</b> 그룹',
      );

      expect(artist.artist.id, equals(1));
      expect(artist.highlightedName, contains('<b>'));
      expect(artist.highlightedGroupName, contains('<b>'));
    });
  });
}
