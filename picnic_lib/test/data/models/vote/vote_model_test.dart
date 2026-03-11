import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';

void main() {
  group('VoteModel.cardStatus', () {
    VoteModel createVote({
      DateTime? startAt,
      DateTime? stopAt,
    }) {
      return VoteModel(
        id: 1,
        title: const {'ko': '테스트 투표'},
        voteCategory: null,
        mainImage: null,
        waitImage: null,
        resultImage: null,
        voteContent: null,
        voteItem: null,
        createdAt: null,
        visibleAt: null,
        stopAt: stopAt,
        startAt: startAt,
        isEnded: null,
        isUpcoming: null,
        isPartnership: null,
        partner: null,
        reward: null,
      );
    }

    test('시작 전이면 upcoming', () {
      final vote = createVote(
        startAt: DateTime.now().add(const Duration(hours: 1)),
        stopAt: DateTime.now().add(const Duration(hours: 2)),
      );
      expect(vote.cardStatus, equals(VoteCardStatus.upcoming));
    });

    test('종료 후이면 ended', () {
      final vote = createVote(
        startAt: DateTime.now().subtract(const Duration(hours: 2)),
        stopAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(vote.cardStatus, equals(VoteCardStatus.ended));
    });

    test('진행 중이면 ongoing', () {
      final vote = createVote(
        startAt: DateTime.now().subtract(const Duration(hours: 1)),
        stopAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(vote.cardStatus, equals(VoteCardStatus.ongoing));
    });

    test('startAt/stopAt이 null이면 ongoing', () {
      final vote = createVote();
      expect(vote.cardStatus, equals(VoteCardStatus.ongoing));
    });

    test('startAt만 null이면 ongoing 또는 ended 판단', () {
      // startAt null → 시작 조건 스킵 → stopAt으로만 판단
      final endedVote = createVote(
        stopAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(endedVote.cardStatus, equals(VoteCardStatus.ended));

      final ongoingVote = createVote(
        stopAt: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(ongoingVote.cardStatus, equals(VoteCardStatus.ongoing));
    });
  });

  group('VoteCardStatus enum', () {
    test('3개의 상태값이 정의됨', () {
      expect(VoteCardStatus.values.length, equals(3));
    });

    test('모든 상태값 존재', () {
      expect(VoteCardStatus.upcoming, isNotNull);
      expect(VoteCardStatus.ongoing, isNotNull);
      expect(VoteCardStatus.ended, isNotNull);
    });
  });

  group('ArtistModelWithHighlight', () {
    test('생성 확인', () {
      final artist = ArtistModel(
        id: 1,
        name: const {'ko': 'BTS'},
      );
      final highlighted = ArtistModelWithHighlight(
        artist: artist,
        highlightedName: '<b>BTS</b>',
        highlightedGroupName: '<b>방탄소년단</b>',
      );
      expect(highlighted.artist.id, equals(1));
      expect(highlighted.highlightedName, equals('<b>BTS</b>'));
      expect(highlighted.highlightedGroupName, equals('<b>방탄소년단</b>'));
    });
  });

  group('VoteItemModel', () {
    test('필수 필드 생성', () {
      const item = VoteItemModel(
        id: 1,
        voteTotal: 100,
        voteId: 10,
        artist: null,
        artistGroup: null,
      );
      expect(item.id, equals(1));
      expect(item.voteTotal, equals(100));
      expect(item.voteId, equals(10));
      expect(item.starCandyTotal, isNull);
      expect(item.starCandyBonusTotal, isNull);
    });

    test('선택 필드 포함 생성', () {
      const item = VoteItemModel(
        id: 1,
        voteTotal: 100,
        voteId: 10,
        artist: null,
        artistGroup: null,
        starCandyTotal: 500,
        starCandyBonusTotal: 50,
      );
      expect(item.starCandyTotal, equals(500));
      expect(item.starCandyBonusTotal, equals(50));
    });
  });
}
