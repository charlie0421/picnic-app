import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_helper.dart';

void main() {
  VoteItemModel item({required int id, int? voteTotal}) => VoteItemModel(
        id: id,
        voteTotal: voteTotal,
        voteId: 1,
        artist: null,
        artistGroup: null,
      );

  group('computeRanksFromSorted', () {
    test('returns empty map for empty list', () {
      expect(VoteDetailHelper.computeRanksFromSorted([]), isEmpty);
    });

    test('returns empty map for list of only nulls', () {
      expect(VoteDetailHelper.computeRanksFromSorted([null, null]), isEmpty);
    });

    test('ranks single item as 1', () {
      expect(
        VoteDetailHelper.computeRanksFromSorted([item(id: 10, voteTotal: 100)]),
        {10: 1},
      );
    });

    test('assigns sequential ranks for strictly descending input', () {
      final ranks = VoteDetailHelper.computeRanksFromSorted([
        item(id: 2, voteTotal: 30),
        item(id: 3, voteTotal: 20),
        item(id: 1, voteTotal: 10),
      ]);
      expect(ranks, {2: 1, 3: 2, 1: 3});
    });

    test('ties share a rank and the next distinct value skips ranks', () {
      // 50,50,10 -> ranks 1,1,3 (rank 2 skipped)
      final ranks = VoteDetailHelper.computeRanksFromSorted([
        item(id: 1, voteTotal: 50),
        item(id: 2, voteTotal: 50),
        item(id: 3, voteTotal: 10),
      ]);
      expect(ranks[1], 1);
      expect(ranks[2], 1);
      expect(ranks[3], 3);
    });

    test('all equal totals all share rank 1', () {
      final ranks = VoteDetailHelper.computeRanksFromSorted([
        item(id: 1, voteTotal: 10),
        item(id: 2, voteTotal: 10),
        item(id: 3, voteTotal: 10),
      ]);
      expect(ranks, {1: 1, 2: 1, 3: 1});
    });

    test('trailing tie block shares a rank', () {
      // 30,20,20 -> 1,2,2
      final ranks = VoteDetailHelper.computeRanksFromSorted([
        item(id: 1, voteTotal: 30),
        item(id: 2, voteTotal: 20),
        item(id: 3, voteTotal: 20),
      ]);
      expect(ranks, {1: 1, 2: 2, 3: 2});
    });

    test('null voteTotal is treated as 0 (sorted last in valid input)', () {
      final ranks = VoteDetailHelper.computeRanksFromSorted([
        item(id: 2, voteTotal: 5),
        item(id: 1, voteTotal: null),
      ]);
      expect(ranks, {2: 1, 1: 2});
    });

    test('skips null entries without consuming a rank slot', () {
      // null between two reals must not shift rank numbering
      final ranks = VoteDetailHelper.computeRanksFromSorted([
        item(id: 1, voteTotal: 20),
        null,
        item(id: 3, voteTotal: 10),
      ]);
      expect(ranks.length, 2);
      expect(ranks, {1: 1, 3: 2});
    });

    test('parity with computeRanks on already-sorted-desc input', () {
      final sorted = [
        item(id: 1, voteTotal: 100),
        item(id: 2, voteTotal: 100),
        item(id: 3, voteTotal: 80),
        item(id: 4, voteTotal: 80),
        item(id: 5, voteTotal: 80),
        item(id: 6, voteTotal: 5),
        item(id: 7, voteTotal: 0),
      ];
      expect(
        VoteDetailHelper.computeRanksFromSorted(sorted),
        VoteDetailHelper.computeRanks(sorted),
      );
    });
  });
}
