import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/vote/vote_pick.dart';

void main() {
  VoteModel makeVote() => VoteModel(
        id: 1,
        title: {'ko': '투표'},
        voteCategory: null,
        mainImage: null,
        waitImage: null,
        resultImage: null,
        voteContent: null,
        voteItem: null,
        createdAt: null,
        visibleAt: null,
        startAt: DateTime(2025, 1, 1),
        stopAt: DateTime(2025, 1, 31),
        isEnded: false,
        isUpcoming: false,
        isPartnership: false,
        partner: null,
        reward: null,
      );

  VoteItemModel makeVoteItem({int voteTotal = 500}) => VoteItemModel(
        id: 10,
        voteTotal: voteTotal,
        voteId: 1,
        artist: null,
        artistGroup: null,
      );

  group('VotePickModel', () {
    test('기본 생성', () {
      final pick = VotePickModel(
        id: 100,
        vote: makeVote(),
        voteItem: makeVoteItem(),
        amount: 50,
        createdAt: DateTime(2025, 1, 15),
        updatedAt: DateTime(2025, 1, 15),
      );

      expect(pick.id, equals(100));
      expect(pick.vote.id, equals(1));
      expect(pick.voteItem.id, equals(10));
      expect(pick.amount, equals(50));
      expect(pick.starCandyUsage, isNull);
      expect(pick.starCandyBonusUsage, isNull);
    });

    test('별사탕 사용량 포함', () {
      final pick = VotePickModel(
        id: 101,
        vote: makeVote(),
        voteItem: makeVoteItem(),
        amount: 100,
        starCandyUsage: 80,
        starCandyBonusUsage: 20,
        createdAt: DateTime(2025, 1, 15),
        updatedAt: DateTime(2025, 1, 15),
      );

      expect(pick.starCandyUsage, equals(80));
      expect(pick.starCandyBonusUsage, equals(20));
    });

    test('amount null 허용', () {
      final pick = VotePickModel(
        id: 102,
        vote: makeVote(),
        voteItem: makeVoteItem(voteTotal: 0),
        amount: null,
        createdAt: null,
        updatedAt: null,
      );

      expect(pick.amount, isNull);
      expect(pick.createdAt, isNull);
    });
  });
}
