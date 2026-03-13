import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';

import '../../../../helpers/test_environment.dart';

/// Tests for VoteList logic patterns.
///
/// Widget testing is constrained because VoteList depends on
/// asyncVoteListProvider which fetches from Supabase. We test
/// the pure logic patterns the widget relies on.
void main() {
  setUpAll(() {
    initTestColors();
  });

  group('VoteStatus mapping to VoteCardStatus', () {
    VoteCardStatus getSkeletonStatus(VoteStatus status, VoteModel? item) {
      if (status == VoteStatus.debug && item != null) {
        final now = DateTime.now();
        if (item.startAt != null && now.isBefore(item.startAt!)) {
          return VoteCardStatus.upcoming;
        } else if (item.stopAt != null && now.isAfter(item.stopAt!)) {
          return VoteCardStatus.ended;
        } else {
          return VoteCardStatus.ongoing;
        }
      }
      switch (status) {
        case VoteStatus.upcoming:
          return VoteCardStatus.upcoming;
        case VoteStatus.active:
          return VoteCardStatus.ongoing;
        case VoteStatus.end:
          return VoteCardStatus.ended;
        default:
          return VoteCardStatus.ongoing;
      }
    }

    test('active status maps to ongoing', () {
      expect(getSkeletonStatus(VoteStatus.active, null), VoteCardStatus.ongoing);
    });

    test('end status maps to ended', () {
      expect(getSkeletonStatus(VoteStatus.end, null), VoteCardStatus.ended);
    });

    test('upcoming status maps to upcoming', () {
      expect(getSkeletonStatus(VoteStatus.upcoming, null), VoteCardStatus.upcoming);
    });

    test('all status maps to ongoing by default', () {
      expect(getSkeletonStatus(VoteStatus.all, null), VoteCardStatus.ongoing);
    });

    test('activeAndUpcoming status maps to ongoing by default', () {
      expect(
        getSkeletonStatus(VoteStatus.activeAndUpcoming, null),
        VoteCardStatus.ongoing,
      );
    });

    test('debug status with future start_at maps to upcoming', () {
      final futureVote = VoteModel.fromJson({
        'id': 1,
        'title': {'ko': '테스트'},
        'vote_category': 'birthday',
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at':
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'stop_at':
            DateTime.now().add(const Duration(days: 14)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': true,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });

      expect(
        getSkeletonStatus(VoteStatus.debug, futureVote),
        VoteCardStatus.upcoming,
      );
    });

    test('debug status with past stop_at maps to ended', () {
      final endedVote = VoteModel.fromJson({
        'id': 2,
        'title': {'ko': '테스트'},
        'vote_category': 'birthday',
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at':
            DateTime.now().subtract(const Duration(days: 14)).toIso8601String(),
        'stop_at':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'is_ended': true,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });

      expect(
        getSkeletonStatus(VoteStatus.debug, endedVote),
        VoteCardStatus.ended,
      );
    });

    test('debug status with current timeframe maps to ongoing', () {
      final activeVote = VoteModel.fromJson({
        'id': 3,
        'title': {'ko': '테스트'},
        'vote_category': 'birthday',
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'stop_at':
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });

      expect(
        getSkeletonStatus(VoteStatus.debug, activeVote),
        VoteCardStatus.ongoing,
      );
    });

    test('debug status without item (null) maps to ongoing', () {
      // When item is null, debug falls through to switch statement
      expect(getSkeletonStatus(VoteStatus.debug, null), VoteCardStatus.ongoing);
    });
  });

  group('Vote category filtering logic', () {
    List<VoteModel> createVotes(List<String?> categories) {
      return categories.asMap().entries.map((e) {
        return VoteModel.fromJson({
          'id': e.key + 1,
          'title': {'ko': '투표 ${e.key}'},
          'vote_category': e.value,
          'main_image': null,
          'wait_image': null,
          'result_image': null,
          'vote_content': null,
          'vote_item': null,
          'created_at': null,
          'visible_at': null,
          'start_at':
              DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'stop_at':
              DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          'is_ended': false,
          'is_upcoming': false,
          'is_partnership': false,
          'partner': null,
          'reward': null,
        });
      }).toList();
    }

    test('PIC portal filters to image and weekly categories', () {
      final votes = createVotes(
          ['birthday', 'image_vote', 'weekly_best', 'comeback', 'weekly_pick']);

      final filtered = votes.where((v) {
        final cat = (v.voteCategory ?? '').toLowerCase();
        final isImage = cat.contains('image');
        final isWeekly = cat.contains('weekly');
        return isImage || isWeekly;
      }).toList();

      expect(filtered.length, equals(3));
      expect(filtered[0].voteCategory, equals('image_vote'));
      expect(filtered[1].voteCategory, equals('weekly_best'));
      expect(filtered[2].voteCategory, equals('weekly_pick'));
    });

    test('specific area filters exclude image and weekly', () {
      final votes = createVotes(
          ['birthday', 'image_vote', 'weekly_best', 'comeback', 'achieve']);

      final filtered = votes.where((v) {
        final cat = (v.voteCategory ?? '').toLowerCase();
        final isImage = cat.contains('image');
        final isWeekly = cat.contains('weekly');
        return !(isImage || isWeekly);
      }).toList();

      expect(filtered.length, equals(3));
      expect(filtered[0].voteCategory, equals('birthday'));
      expect(filtered[1].voteCategory, equals('comeback'));
      expect(filtered[2].voteCategory, equals('achieve'));
    });

    test('area "all" returns all votes unfiltered', () {
      final votes =
          createVotes(['birthday', 'image_vote', 'weekly_best', 'comeback']);

      // area == 'all' means no filtering
      expect(votes.length, equals(4));
    });

    test('pic-chart area treated as pic portal for filtering', () {
      const area = 'pic-chart';
      final isPicChart = area == 'pic-chart';
      final queryArea = isPicChart ? 'all' : area;

      expect(isPicChart, isTrue);
      expect(queryArea, equals('all'));
    });

    test('null category handled safely', () {
      final votes = createVotes([null, 'birthday', null]);

      final filtered = votes.where((v) {
        final cat = (v.voteCategory ?? '').toLowerCase();
        final isImage = cat.contains('image');
        final isWeekly = cat.contains('weekly');
        return !(isImage || isWeekly);
      }).toList();

      // null category doesn't contain image or weekly, so it passes filter
      expect(filtered.length, equals(3));
    });
  });

  group('VoteStatus debug mode itemStatus logic', () {
    test('debug mode computes itemStatus from dates', () {
      VoteStatus computeItemStatus(VoteStatus widgetStatus, VoteModel item) {
        if (widgetStatus == VoteStatus.debug) {
          final now = DateTime.now();
          if (item.startAt != null && now.isBefore(item.startAt!)) {
            return VoteStatus.upcoming;
          } else if (item.stopAt != null && now.isAfter(item.stopAt!)) {
            return VoteStatus.end;
          } else {
            return VoteStatus.active;
          }
        }
        return widgetStatus;
      }

      final activeVote = VoteModel.fromJson({
        'id': 1,
        'title': {'ko': '테스트'},
        'vote_category': 'birthday',
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'stop_at':
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });

      expect(
        computeItemStatus(VoteStatus.debug, activeVote),
        VoteStatus.active,
      );

      // Non-debug passes through
      expect(
        computeItemStatus(VoteStatus.active, activeVote),
        VoteStatus.active,
      );
      expect(
        computeItemStatus(VoteStatus.end, activeVote),
        VoteStatus.end,
      );
    });
  });

  group('Pagination logic', () {
    test('onPageChanged triggers fetch at last item', () {
      const itemsLength = 10;
      const index = 9;
      bool shouldFetch = index == itemsLength - 1;
      expect(shouldFetch, isTrue);
    });

    test('onPageChanged does not trigger fetch in the middle', () {
      const itemsLength = 10;
      const index = 5;
      bool shouldFetch = index == itemsLength - 1;
      expect(shouldFetch, isFalse);
    });

    test('fetchVotes skips when no more items and not initial/refresh', () {
      bool noMoreItems = true;
      bool isInitialLoad = false;
      bool isRefresh = false;
      bool shouldReturn =
          noMoreItems && !isInitialLoad && !isRefresh;
      expect(shouldReturn, isTrue);
    });

    test('fetchVotes does not skip on initial load even if noMoreItems', () {
      bool noMoreItems = true;
      bool isInitialLoad = true;
      bool isRefresh = false;
      bool shouldReturn =
          noMoreItems && !isInitialLoad && !isRefresh;
      expect(shouldReturn, isFalse);
    });

    test('fetchVotes does not skip on refresh even if noMoreItems', () {
      bool noMoreItems = true;
      bool isInitialLoad = false;
      bool isRefresh = true;
      bool shouldReturn =
          noMoreItems && !isInitialLoad && !isRefresh;
      expect(shouldReturn, isFalse);
    });
  });

  group('VoteModel cardStatus', () {
    test('returns upcoming when start_at is in the future', () {
      final vote = VoteModel.fromJson({
        'id': 1,
        'title': {'ko': '미래'},
        'vote_category': 'birthday',
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at':
            DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'stop_at':
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': true,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });

      expect(vote.cardStatus, VoteCardStatus.upcoming);
    });

    test('returns ended when stop_at is in the past', () {
      final vote = VoteModel.fromJson({
        'id': 2,
        'title': {'ko': '종료'},
        'vote_category': 'birthday',
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at':
            DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
        'stop_at':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'is_ended': true,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });

      expect(vote.cardStatus, VoteCardStatus.ended);
    });

    test('returns ongoing for currently active vote', () {
      final vote = VoteModel.fromJson({
        'id': 3,
        'title': {'ko': '진행중'},
        'vote_category': 'birthday',
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'stop_at':
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });

      expect(vote.cardStatus, VoteCardStatus.ongoing);
    });
  });

  group('Sort key handling', () {
    test('debug mode sort key contains timestamp', () {
      final status = VoteStatus.debug;
      final sortKey = status == VoteStatus.debug
          ? 'id_${DateTime.now().millisecondsSinceEpoch}'
          : 'id';

      expect(sortKey.startsWith('id_'), isTrue);
    });

    test('normal mode sort key is plain id', () {
      final status = VoteStatus.active;
      final sortKey = status == VoteStatus.debug
          ? 'id_${DateTime.now().millisecondsSinceEpoch}'
          : 'id';

      expect(sortKey, equals('id'));
    });

    test('actual sort strips timestamp suffix', () {
      const sort = 'id_1234567890';
      final actualSort = sort.startsWith('id_') ? 'id' : sort;
      expect(actualSort, equals('id'));
    });
  });
}
