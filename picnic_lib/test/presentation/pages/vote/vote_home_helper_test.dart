import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_home_helper.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';

// ---------------------------------------------------------------------------
// Factory helpers
// ---------------------------------------------------------------------------

VoteModel _makeVote({
  required int id,
  String? voteCategory,
  DateTime? startAt,
  DateTime? stopAt,
}) {
  return VoteModel(
    id: id,
    title: const {'en': 'Test Vote'},
    voteCategory: voteCategory,
    mainImage: null,
    waitImage: null,
    resultImage: null,
    voteContent: null,
    voteItem: null,
    createdAt: null,
    visibleAt: null,
    stopAt: stopAt,
    startAt: startAt,
    isEnded: false,
    isUpcoming: false,
    isPartnership: false,
    partner: null,
    reward: null,
  );
}

void main() {
  // =========================================================================
  // determineVoteStatus
  // =========================================================================
  group('determineVoteStatus', () {
    test('returns upcoming when startAt is in the future', () {
      final now = DateTime.utc(2026, 1, 1, 12, 0);
      final startAt = DateTime.utc(2026, 1, 2, 12, 0);
      expect(
        VoteHomeHelper.determineVoteStatus(startAt, now: now),
        VoteStatus.upcoming,
      );
    });

    test('returns active when startAt is in the past', () {
      final now = DateTime.utc(2026, 1, 2, 12, 0);
      final startAt = DateTime.utc(2026, 1, 1, 12, 0);
      expect(
        VoteHomeHelper.determineVoteStatus(startAt, now: now),
        VoteStatus.active,
      );
    });

    test('returns active when startAt equals now (not strictly after)', () {
      final now = DateTime.utc(2026, 1, 1, 12, 0);
      expect(
        VoteHomeHelper.determineVoteStatus(now, now: now),
        VoteStatus.active,
      );
    });
  });

  // =========================================================================
  // deduplicateVotes
  // =========================================================================
  group('deduplicateVotes', () {
    test('removes duplicate ids keeping first occurrence', () {
      final a = _makeVote(id: 1, voteCategory: 'birthday');
      final b = _makeVote(id: 2, voteCategory: 'comeback');
      final aDuplicate = _makeVote(id: 1, voteCategory: 'image');

      final result = VoteHomeHelper.deduplicateVotes([a, b], [aDuplicate]);
      expect(result.length, 2);
      expect(result.map((v) => v.id).toSet(), {1, 2});
      // The first occurrence (from listA) should win.
      expect(result.firstWhere((v) => v.id == 1).voteCategory, 'birthday');
    });

    test('handles empty lists', () {
      expect(VoteHomeHelper.deduplicateVotes([], []).length, 0);
    });

    test('handles one empty list', () {
      final a = _makeVote(id: 1);
      expect(VoteHomeHelper.deduplicateVotes([a], []).length, 1);
      expect(VoteHomeHelper.deduplicateVotes([], [a]).length, 1);
    });

    test('preserves all items when no duplicates exist', () {
      final a = _makeVote(id: 1);
      final b = _makeVote(id: 2);
      final c = _makeVote(id: 3);
      final result = VoteHomeHelper.deduplicateVotes([a], [b, c]);
      expect(result.length, 3);
    });
  });

  // =========================================================================
  // isImageOrWeeklyCategory
  // =========================================================================
  group('isImageOrWeeklyCategory', () {
    test('returns true for image categories', () {
      expect(VoteHomeHelper.isImageOrWeeklyCategory('image'), isTrue);
      expect(VoteHomeHelper.isImageOrWeeklyCategory('Image_Award'), isTrue);
      expect(VoteHomeHelper.isImageOrWeeklyCategory('best_image'), isTrue);
    });

    test('returns true for weekly categories', () {
      expect(VoteHomeHelper.isImageOrWeeklyCategory('weekly'), isTrue);
      expect(VoteHomeHelper.isImageOrWeeklyCategory('Weekly_Vote'), isTrue);
    });

    test('returns false for other categories', () {
      expect(VoteHomeHelper.isImageOrWeeklyCategory('birthday'), isFalse);
      expect(VoteHomeHelper.isImageOrWeeklyCategory('comeback'), isFalse);
      expect(VoteHomeHelper.isImageOrWeeklyCategory(null), isFalse);
      expect(VoteHomeHelper.isImageOrWeeklyCategory(''), isFalse);
    });
  });

  // =========================================================================
  // sortByStopAtAsc
  // =========================================================================
  group('sortByStopAtAsc', () {
    test('sorts by stopAt ascending', () {
      final v1 = _makeVote(id: 1, stopAt: DateTime.utc(2026, 3, 1));
      final v2 = _makeVote(id: 2, stopAt: DateTime.utc(2026, 1, 1));
      final v3 = _makeVote(id: 3, stopAt: DateTime.utc(2026, 2, 1));

      final result = VoteHomeHelper.sortByStopAtAsc([v1, v2, v3]);
      expect(result.map((v) => v.id).toList(), [2, 3, 1]);
    });

    test('null stopAt is treated as epoch zero (sorted first)', () {
      final v1 = _makeVote(id: 1, stopAt: DateTime.utc(2026, 1, 1));
      final v2 = _makeVote(id: 2, stopAt: null);

      final result = VoteHomeHelper.sortByStopAtAsc([v1, v2]);
      expect(result.first.id, 2);
    });

    test('does not mutate the original list', () {
      final original = [
        _makeVote(id: 1, stopAt: DateTime.utc(2026, 3, 1)),
        _makeVote(id: 2, stopAt: DateTime.utc(2026, 1, 1)),
      ];
      VoteHomeHelper.sortByStopAtAsc(original);
      expect(original.first.id, 1); // unchanged
    });

    test('handles empty list', () {
      expect(VoteHomeHelper.sortByStopAtAsc([]), isEmpty);
    });

    test('single item returns as-is', () {
      final v = _makeVote(id: 1, stopAt: DateTime.utc(2026, 1, 1));
      final result = VoteHomeHelper.sortByStopAtAsc([v]);
      expect(result.length, 1);
      expect(result.first.id, 1);
    });
  });

  // =========================================================================
  // takePageSlice
  // =========================================================================
  group('takePageSlice', () {
    test('returns at most pageSize items', () {
      final votes = List.generate(30, (i) => _makeVote(id: i));
      final result = VoteHomeHelper.takePageSlice(votes);
      expect(result.length, VoteHomeHelper.pageSize);
    });

    test('returns all items when fewer than pageSize', () {
      final votes = List.generate(5, (i) => _makeVote(id: i));
      final result = VoteHomeHelper.takePageSlice(votes);
      expect(result.length, 5);
    });

    test('respects custom size', () {
      final votes = List.generate(10, (i) => _makeVote(id: i));
      expect(VoteHomeHelper.takePageSlice(votes, 3).length, 3);
    });

    test('handles empty list', () {
      expect(VoteHomeHelper.takePageSlice([]), isEmpty);
    });
  });

  // =========================================================================
  // isLastPage
  // =========================================================================
  group('isLastPage', () {
    test('returns true when item count < page size', () {
      expect(VoteHomeHelper.isLastPage(10), isTrue);
    });

    test('returns false when item count == page size', () {
      expect(VoteHomeHelper.isLastPage(20), isFalse);
    });

    test('returns false when item count > page size (edge case)', () {
      expect(VoteHomeHelper.isLastPage(25), isFalse);
    });

    test('returns true for zero items', () {
      expect(VoteHomeHelper.isLastPage(0), isTrue);
    });

    test('works with custom size', () {
      expect(VoteHomeHelper.isLastPage(4, 5), isTrue);
      expect(VoteHomeHelper.isLastPage(5, 5), isFalse);
    });
  });

  // =========================================================================
  // nextPageKey
  // =========================================================================
  group('nextPageKey', () {
    test('returns 1 when items is null', () {
      expect(
        VoteHomeHelper.nextPageKey(items: null, lastKey: null),
        1,
      );
    });

    test('returns null on last page', () {
      final items = List.generate(10, (i) => _makeVote(id: i));
      expect(
        VoteHomeHelper.nextPageKey(items: items, lastKey: 2),
        isNull,
      );
    });

    test('returns lastKey + 1 when more pages available', () {
      final items = List.generate(20, (i) => _makeVote(id: i));
      expect(
        VoteHomeHelper.nextPageKey(items: items, lastKey: 3),
        4,
      );
    });

    test('returns 1 when lastKey is null and more pages available', () {
      final items = List.generate(20, (i) => _makeVote(id: i));
      expect(
        VoteHomeHelper.nextPageKey(items: items, lastKey: null),
        1,
      );
    });
  });

  // =========================================================================
  // shouldClearTitle
  // =========================================================================
  group('shouldClearTitle', () {
    test('returns true when vote active, at root, title non-empty', () {
      expect(
        VoteHomeHelper.shouldClearTitle(
          isVoteActive: true,
          isAtRoot: true,
          pageTitle: 'Some Title',
        ),
        isTrue,
      );
    });

    test('returns false when not vote active', () {
      expect(
        VoteHomeHelper.shouldClearTitle(
          isVoteActive: false,
          isAtRoot: true,
          pageTitle: 'Title',
        ),
        isFalse,
      );
    });

    test('returns false when not at root', () {
      expect(
        VoteHomeHelper.shouldClearTitle(
          isVoteActive: true,
          isAtRoot: false,
          pageTitle: 'Title',
        ),
        isFalse,
      );
    });

    test('returns false when title is already empty', () {
      expect(
        VoteHomeHelper.shouldClearTitle(
          isVoteActive: true,
          isAtRoot: true,
          pageTitle: '',
        ),
        isFalse,
      );
    });
  });

  // =========================================================================
  // isNavigationRoot
  // =========================================================================
  group('isNavigationRoot', () {
    test('returns true for null stack', () {
      expect(VoteHomeHelper.isNavigationRoot(null), isTrue);
    });

    test('returns true for empty stack', () {
      expect(VoteHomeHelper.isNavigationRoot([]), isTrue);
    });

    test('returns true for single-entry stack', () {
      expect(VoteHomeHelper.isNavigationRoot(['root']), isTrue);
    });

    test('returns false for multi-entry stack', () {
      expect(VoteHomeHelper.isNavigationRoot(['root', 'detail']), isFalse);
    });
  });

  // =========================================================================
  // isHighPriorityReward
  // =========================================================================
  group('isHighPriorityReward', () {
    test('returns true for indices 0, 1, 2', () {
      expect(VoteHomeHelper.isHighPriorityReward(0), isTrue);
      expect(VoteHomeHelper.isHighPriorityReward(1), isTrue);
      expect(VoteHomeHelper.isHighPriorityReward(2), isTrue);
    });

    test('returns false for index 3 and above', () {
      expect(VoteHomeHelper.isHighPriorityReward(3), isFalse);
      expect(VoteHomeHelper.isHighPriorityReward(10), isFalse);
    });
  });

  // =========================================================================
  // shouldOptimizeCache / targetCacheSize
  // =========================================================================
  group('shouldOptimizeCache', () {
    test('returns true when usage exceeds 70%', () {
      expect(VoteHomeHelper.shouldOptimizeCache(75, 100), isTrue);
    });

    test('returns false when usage is at or below 70%', () {
      expect(VoteHomeHelper.shouldOptimizeCache(70, 100), isFalse);
      expect(VoteHomeHelper.shouldOptimizeCache(50, 100), isFalse);
    });

    test('returns false when maximum is zero', () {
      expect(VoteHomeHelper.shouldOptimizeCache(50, 0), isFalse);
    });

    test('returns false when maximum is negative', () {
      expect(VoteHomeHelper.shouldOptimizeCache(50, -1), isFalse);
    });
  });

  group('targetCacheSize', () {
    test('returns 50% of maximum', () {
      expect(VoteHomeHelper.targetCacheSize(100), 50);
      expect(VoteHomeHelper.targetCacheSize(1000), 500);
    });

    test('rounds correctly', () {
      expect(VoteHomeHelper.targetCacheSize(101), 51); // 50.5 rounds to 51
    });
  });

  // =========================================================================
  // Constants
  // =========================================================================
  group('constants', () {
    test('pageSize is 20', () {
      expect(VoteHomeHelper.pageSize, 20);
    });

    test('cacheUsageThreshold is 0.7', () {
      expect(VoteHomeHelper.cacheUsageThreshold, 0.7);
    });

    test('cacheTargetRatio is 0.5', () {
      expect(VoteHomeHelper.cacheTargetRatio, 0.5);
    });
  });
}
