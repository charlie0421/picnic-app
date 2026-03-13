import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_achieve_helper.dart';

void main() {
  group('VoteDetailAchieveHelper', () {
    // ---------------------------------------------------------------
    // generateMilestonesFromAchievements
    // ---------------------------------------------------------------
    group('generateMilestonesFromAchievements', () {
      test('returns [0] for empty amounts list', () {
        expect(
          VoteDetailAchieveHelper.generateMilestonesFromAchievements([]),
          equals([0]),
        );
      });

      test('prepends 0 to a single amount', () {
        expect(
          VoteDetailAchieveHelper.generateMilestonesFromAchievements([1000]),
          equals([0, 1000]),
        );
      });

      test('prepends 0 to multiple amounts', () {
        expect(
          VoteDetailAchieveHelper.generateMilestonesFromAchievements(
            [1000, 5000, 10000],
          ),
          equals([0, 1000, 5000, 10000]),
        );
      });

      test('preserves order of input amounts', () {
        expect(
          VoteDetailAchieveHelper.generateMilestonesFromAchievements(
            [5000, 1000],
          ),
          equals([0, 5000, 1000]),
        );
      });

      test('handles very large amounts', () {
        final result =
            VoteDetailAchieveHelper.generateMilestonesFromAchievements(
          [1000000, 5000000],
        );
        expect(result, equals([0, 1000000, 5000000]));
      });
    });

    // ---------------------------------------------------------------
    // generateLevels
    // ---------------------------------------------------------------
    group('generateLevels', () {
      test('returns [0] for single-element milestone [0]', () {
        expect(
          VoteDetailAchieveHelper.generateLevels([0]),
          equals([0]),
        );
      });

      test('subdivides one interval into 5 steps', () {
        // [0, 100] -> 0, then steps 20, 40, 60, 80, then 100
        final levels = VoteDetailAchieveHelper.generateLevels([0, 100]);
        expect(levels, equals([0, 20, 40, 60, 80, 100]));
      });

      test('subdivides two intervals correctly', () {
        // [0, 100, 600]
        // Interval 0->100: steps = 20 each -> 20, 40, 60, 80, 100
        // Interval 100->600: step = 100 each -> 200, 300, 400, 500, 600
        final levels = VoteDetailAchieveHelper.generateLevels([0, 100, 600]);
        expect(
          levels,
          equals([0, 20, 40, 60, 80, 100, 200, 300, 400, 500, 600]),
        );
      });

      test('handles non-zero start for second interval', () {
        // [0, 50, 150]
        // 0->50: step=10 -> 10, 20, 30, 40, 50
        // 50->150: step=20 -> 70, 90, 110, 130, 150
        final levels = VoteDetailAchieveHelper.generateLevels([0, 50, 150]);
        expect(
          levels,
          equals([0, 10, 20, 30, 40, 50, 70, 90, 110, 130, 150]),
        );
      });

      test('handles large milestones', () {
        final levels =
            VoteDetailAchieveHelper.generateLevels([0, 10000, 50000]);
        // 0->10000: step=2000 -> 2000, 4000, 6000, 8000, 10000
        // 10000->50000: step=8000 -> 18000, 26000, 34000, 42000, 50000
        expect(levels.first, 0);
        expect(levels.last, 50000);
        expect(levels.length, 11); // 1 + 5 + 5
      });

      test('integer division truncates step sizes', () {
        // [0, 7]: step = 7 ~/ 5 = 1 -> 1, 2, 3, 4, 7
        final levels = VoteDetailAchieveHelper.generateLevels([0, 7]);
        expect(levels, equals([0, 1, 2, 3, 4, 7]));
      });

      test('three intervals produce 16 entries', () {
        final levels =
            VoteDetailAchieveHelper.generateLevels([0, 100, 500, 1000]);
        // 1 (zero) + 5 + 5 + 5 = 16
        expect(levels.length, 16);
        expect(levels.first, 0);
        expect(levels.last, 1000);
      });
    });

    // ---------------------------------------------------------------
    // calculateTotalSteps
    // ---------------------------------------------------------------
    group('calculateTotalSteps', () {
      test('single milestone [0] returns 1', () {
        expect(VoteDetailAchieveHelper.calculateTotalSteps([0]), 1);
      });

      test('two milestones returns 6 (0 + 5 steps)', () {
        expect(VoteDetailAchieveHelper.calculateTotalSteps([0, 100]), 6);
      });

      test('three milestones returns 11', () {
        expect(
          VoteDetailAchieveHelper.calculateTotalSteps([0, 100, 600]),
          11,
        );
      });
    });

    // ---------------------------------------------------------------
    // calculateExactProgress
    // ---------------------------------------------------------------
    group('calculateExactProgress', () {
      test('returns 0 when voteTotal is 0', () {
        final levels = VoteDetailAchieveHelper.generateLevels([0, 100]);
        expect(
          VoteDetailAchieveHelper.calculateExactProgress(0, levels),
          0.0,
        );
      });

      test('returns 100 when voteTotal equals last level', () {
        final levels = VoteDetailAchieveHelper.generateLevels([0, 100]);
        expect(
          VoteDetailAchieveHelper.calculateExactProgress(100, levels),
          100.0,
        );
      });

      test('returns 100 when voteTotal exceeds last level', () {
        final levels = VoteDetailAchieveHelper.generateLevels([0, 100]);
        expect(
          VoteDetailAchieveHelper.calculateExactProgress(200, levels),
          100.0,
        );
      });

      test('returns 0 for empty levels list', () {
        expect(
          VoteDetailAchieveHelper.calculateExactProgress(50, []),
          0.0,
        );
      });

      test('midpoint of first segment returns ~10% for 5-step levels', () {
        // levels: [0, 20, 40, 60, 80, 100] -> 5 segments, each 20% of bar
        final levels = VoteDetailAchieveHelper.generateLevels([0, 100]);
        // vote=10 is midway through first segment (0..20), so 0.5 * 20% = 10%
        final progress =
            VoteDetailAchieveHelper.calculateExactProgress(10, levels);
        expect(progress, closeTo(10.0, 0.01));
      });

      test('exact segment boundary returns correct percentage', () {
        final levels = VoteDetailAchieveHelper.generateLevels([0, 100]);
        // vote=20 -> end of 1st segment -> 20%
        final progress =
            VoteDetailAchieveHelper.calculateExactProgress(20, levels);
        expect(progress, closeTo(20.0, 0.01));
      });

      test('exact segment boundary at 60 returns 60%', () {
        final levels = VoteDetailAchieveHelper.generateLevels([0, 100]);
        final progress =
            VoteDetailAchieveHelper.calculateExactProgress(60, levels);
        expect(progress, closeTo(60.0, 0.01));
      });

      test('handles multi-milestone progress correctly', () {
        final levels = VoteDetailAchieveHelper.generateLevels([0, 100, 600]);
        // 11 levels -> 10 segments, each 10% of bar
        // vote=100 is the 5th level (index 5), so exactly 50%
        final progress =
            VoteDetailAchieveHelper.calculateExactProgress(100, levels);
        expect(progress, closeTo(50.0, 0.01));
      });

      test('progress is strictly between 0 and 100 for intermediate values',
          () {
        final levels = VoteDetailAchieveHelper.generateLevels([0, 1000]);
        final progress =
            VoteDetailAchieveHelper.calculateExactProgress(500, levels);
        expect(progress, greaterThan(0.0));
        expect(progress, lessThan(100.0));
      });

      test('negative voteTotal returns 0', () {
        final levels = VoteDetailAchieveHelper.generateLevels([0, 100]);
        expect(
          VoteDetailAchieveHelper.calculateExactProgress(-10, levels),
          0.0,
        );
      });

      test('progress increases monotonically', () {
        final levels = VoteDetailAchieveHelper.generateLevels([0, 100, 500]);
        double prev = 0.0;
        for (int v = 0; v <= 500; v += 10) {
          final p = VoteDetailAchieveHelper.calculateExactProgress(v, levels);
          expect(p, greaterThanOrEqualTo(prev),
              reason: 'progress should not decrease at vote=$v');
          prev = p;
        }
      });
    });

    // ---------------------------------------------------------------
    // checkMilestoneAchievement
    // ---------------------------------------------------------------
    group('checkMilestoneAchievement', () {
      test('no milestones achieved when votes is 0', () {
        final result = VoteDetailAchieveHelper.checkMilestoneAchievement(
          currentVotes: 0,
          milestoneAmounts: [100, 500, 1000],
          alreadyAchieved: {},
        );
        expect(result.allAchieved, isEmpty);
        expect(result.newlyAchieved, isEmpty);
      });

      test('all milestones achieved when votes exceed all', () {
        final result = VoteDetailAchieveHelper.checkMilestoneAchievement(
          currentVotes: 2000,
          milestoneAmounts: [100, 500, 1000],
          alreadyAchieved: {},
        );
        expect(result.allAchieved, equals([100, 500, 1000]));
        expect(result.newlyAchieved, equals([100, 500, 1000]));
      });

      test('partial milestones achieved', () {
        final result = VoteDetailAchieveHelper.checkMilestoneAchievement(
          currentVotes: 600,
          milestoneAmounts: [100, 500, 1000],
          alreadyAchieved: {},
        );
        expect(result.allAchieved, equals([100, 500]));
        expect(result.newlyAchieved, equals([100, 500]));
      });

      test('already achieved milestones are not newly achieved', () {
        final result = VoteDetailAchieveHelper.checkMilestoneAchievement(
          currentVotes: 2000,
          milestoneAmounts: [100, 500, 1000],
          alreadyAchieved: {100, 500},
        );
        expect(result.allAchieved, equals([100, 500, 1000]));
        expect(result.newlyAchieved, equals([1000]));
      });

      test('exact milestone boundary is achieved', () {
        final result = VoteDetailAchieveHelper.checkMilestoneAchievement(
          currentVotes: 500,
          milestoneAmounts: [100, 500, 1000],
          alreadyAchieved: {},
        );
        expect(result.allAchieved, contains(500));
        expect(result.newlyAchieved, contains(500));
      });

      test('one vote below milestone is not achieved', () {
        final result = VoteDetailAchieveHelper.checkMilestoneAchievement(
          currentVotes: 99,
          milestoneAmounts: [100, 500, 1000],
          alreadyAchieved: {},
        );
        expect(result.allAchieved, isEmpty);
        expect(result.newlyAchieved, isEmpty);
      });

      test('empty milestone list returns empty result', () {
        final result = VoteDetailAchieveHelper.checkMilestoneAchievement(
          currentVotes: 500,
          milestoneAmounts: [],
          alreadyAchieved: {},
        );
        expect(result.allAchieved, isEmpty);
        expect(result.newlyAchieved, isEmpty);
      });

      test('unsorted milestones are handled correctly', () {
        final result = VoteDetailAchieveHelper.checkMilestoneAchievement(
          currentVotes: 600,
          milestoneAmounts: [1000, 100, 500],
          alreadyAchieved: {},
        );
        // After sorting: 100, 500, 1000
        expect(result.allAchieved, equals([100, 500]));
      });

      test('all already achieved returns empty newlyAchieved', () {
        final result = VoteDetailAchieveHelper.checkMilestoneAchievement(
          currentVotes: 2000,
          milestoneAmounts: [100, 500, 1000],
          alreadyAchieved: {100, 500, 1000},
        );
        expect(result.allAchieved, equals([100, 500, 1000]));
        expect(result.newlyAchieved, isEmpty);
      });

      test('single milestone achieved exactly', () {
        final result = VoteDetailAchieveHelper.checkMilestoneAchievement(
          currentVotes: 100,
          milestoneAmounts: [100],
          alreadyAchieved: {},
        );
        expect(result.allAchieved, equals([100]));
        expect(result.newlyAchieved, equals([100]));
      });

      test('negative currentVotes achieves nothing', () {
        final result = VoteDetailAchieveHelper.checkMilestoneAchievement(
          currentVotes: -10,
          milestoneAmounts: [0, 100],
          alreadyAchieved: {},
        );
        expect(result.allAchieved, isEmpty);
        expect(result.newlyAchieved, isEmpty);
      });

      test('duplicate milestones in input', () {
        final result = VoteDetailAchieveHelper.checkMilestoneAchievement(
          currentVotes: 200,
          milestoneAmounts: [100, 100, 200],
          alreadyAchieved: {},
        );
        expect(result.allAchieved, equals([100, 100, 200]));
      });
    });

    // ---------------------------------------------------------------
    // calculateExactProgress - additional edge cases
    // ---------------------------------------------------------------
    group('calculateExactProgress - additional', () {
      test('single element levels list with voteTotal above returns 100', () {
        // [0] -> levels.last is 0, voteTotal 50 >= 0 -> returns 100.0
        expect(
          VoteDetailAchieveHelper.calculateExactProgress(50, [0]),
          100.0,
        );
      });

      test('two identical levels (levelDiff == 0) returns base progress', () {
        // [0, 5, 5, 10] -> 3 segments, each ~33.33%
        // voteTotal=5 >= levels[1]=5 and < levels[2]=5 is FALSE (5 < 5 is false)
        // so it checks levels[2]=5 and < levels[3]=10 -> TRUE, currentLevelIndex=2
        // But wait - voteTotal=5 >= levels[0]=0 and < levels[1]=5 is FALSE (5 < 5)
        // voteTotal=5 >= levels[1]=5 and < levels[2]=5 is FALSE (5 < 5)
        // voteTotal=5 >= levels[2]=5 and < levels[3]=10 is TRUE -> index=2
        // baseProgress = 2 * (100/3) = 66.67
        expect(
          VoteDetailAchieveHelper.calculateExactProgress(5, [0, 5, 5, 10]),
          closeTo(66.67, 0.01),
        );
      });

      test('voteTotal exactly at first level returns 0', () {
        expect(
          VoteDetailAchieveHelper.calculateExactProgress(0, [0, 100]),
          0.0,
        );
      });

      test('voteTotal between last two levels', () {
        final levels = [0, 20, 40, 60, 80, 100];
        // vote=90 -> in segment 4 (80..100), 50% through -> 4*20% + 10% = 90%
        final progress =
            VoteDetailAchieveHelper.calculateExactProgress(90, levels);
        expect(progress, closeTo(90.0, 0.01));
      });

      test('very large voteTotal returns 100', () {
        final levels = [0, 100, 200];
        expect(
          VoteDetailAchieveHelper.calculateExactProgress(999999, levels),
          100.0,
        );
      });
    });

    // ---------------------------------------------------------------
    // generateLevels - additional edge cases
    // ---------------------------------------------------------------
    group('generateLevels - additional', () {
      test('empty milestones returns [0]', () {
        expect(
          VoteDetailAchieveHelper.generateLevels([]),
          equals([0]),
        );
      });

      test('milestones where step size is 0 (same start and end)', () {
        // [0, 0] -> step = 0 ~/ 5 = 0 -> 0, 0, 0, 0, 0
        final levels = VoteDetailAchieveHelper.generateLevels([0, 0]);
        expect(levels.first, 0);
        expect(levels.last, 0);
        expect(levels.length, 6);
      });

      test('very small interval (step size rounds to 0)', () {
        // [0, 3] -> step = 3 ~/ 5 = 0 -> 0, 0, 0, 0, 3
        final levels = VoteDetailAchieveHelper.generateLevels([0, 3]);
        expect(levels.first, 0);
        expect(levels.last, 3);
      });
    });

    // ---------------------------------------------------------------
    // calculateTotalSteps - additional
    // ---------------------------------------------------------------
    group('calculateTotalSteps - additional', () {
      test('four milestones', () {
        // 1 + 5 + 5 + 5 = 16
        expect(
          VoteDetailAchieveHelper.calculateTotalSteps([0, 100, 500, 1000]),
          16,
        );
      });

      test('empty milestones returns 1', () {
        expect(
          VoteDetailAchieveHelper.calculateTotalSteps([]),
          1,
        );
      });
    });

    // ---------------------------------------------------------------
    // MilestoneCheckResult
    // ---------------------------------------------------------------
    group('MilestoneCheckResult', () {
      test('stores values correctly', () {
        const result = MilestoneCheckResult(
          allAchieved: [100, 500],
          newlyAchieved: [500],
        );
        expect(result.allAchieved, equals([100, 500]));
        expect(result.newlyAchieved, equals([500]));
      });
    });
  });
}
