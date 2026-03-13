import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_achieve_helper.dart';

void main() {
  group('VoteDetailAchieveHelper - extended methods', () {
    // ── isMainMilestone ─────────────────────────────────────────────
    group('isMainMilestone', () {
      test('returns true for a main milestone', () {
        expect(
          VoteDetailAchieveHelper.isMainMilestone(100, [0, 100, 500]),
          true,
        );
      });

      test('returns false for an intermediate level', () {
        expect(
          VoteDetailAchieveHelper.isMainMilestone(50, [0, 100, 500]),
          false,
        );
      });

      test('0 is a main milestone when included', () {
        expect(
          VoteDetailAchieveHelper.isMainMilestone(0, [0, 100]),
          true,
        );
      });

      test('returns false for empty milestones list', () {
        expect(
          VoteDetailAchieveHelper.isMainMilestone(100, []),
          false,
        );
      });

      test('handles large milestone values', () {
        expect(
          VoteDetailAchieveHelper.isMainMilestone(1000000, [0, 1000000]),
          true,
        );
      });
    });

    // ── isLevelAchieved ─────────────────────────────────────────────
    group('isLevelAchieved', () {
      test('returns true when voteTotal equals level', () {
        expect(VoteDetailAchieveHelper.isLevelAchieved(100, 100), true);
      });

      test('returns true when voteTotal exceeds level', () {
        expect(VoteDetailAchieveHelper.isLevelAchieved(200, 100), true);
      });

      test('returns false when voteTotal is below level', () {
        expect(VoteDetailAchieveHelper.isLevelAchieved(50, 100), false);
      });

      test('returns true for zero level', () {
        expect(VoteDetailAchieveHelper.isLevelAchieved(0, 0), true);
      });

      test('returns false for negative voteTotal', () {
        expect(VoteDetailAchieveHelper.isLevelAchieved(-1, 0), false);
      });
    });

    // ── calculateProgressBarHeight ──────────────────────────────────
    group('calculateProgressBarHeight', () {
      test('single milestone [0] returns 0', () {
        // totalSteps = 1, height = 50*1 - 50 = 0
        expect(
          VoteDetailAchieveHelper.calculateProgressBarHeight([0]),
          0.0,
        );
      });

      test('two milestones [0, 100] returns 250', () {
        // totalSteps = 6, height = 50*6 - 50 = 250
        expect(
          VoteDetailAchieveHelper.calculateProgressBarHeight([0, 100]),
          250.0,
        );
      });

      test('three milestones [0, 100, 600] returns 500', () {
        // totalSteps = 11, height = 50*11 - 50 = 500
        expect(
          VoteDetailAchieveHelper.calculateProgressBarHeight([0, 100, 600]),
          500.0,
        );
      });

      test('four milestones returns 750', () {
        // totalSteps = 16, height = 50*16 - 50 = 750
        expect(
          VoteDetailAchieveHelper.calculateProgressBarHeight([0, 100, 500, 1000]),
          750.0,
        );
      });

      test('empty milestones returns 0', () {
        // totalSteps = 1, height = 50*1 - 50 = 0
        expect(
          VoteDetailAchieveHelper.calculateProgressBarHeight([]),
          0.0,
        );
      });
    });

    // ── Integration tests combining multiple methods ─────────────────
    group('integration', () {
      test('full milestone workflow', () {
        final amounts = [1000, 5000, 10000];
        final mainMilestones =
            VoteDetailAchieveHelper.generateMilestonesFromAchievements(amounts);
        expect(mainMilestones, [0, 1000, 5000, 10000]);

        final levels = VoteDetailAchieveHelper.generateLevels(mainMilestones);
        expect(levels.first, 0);
        expect(levels.last, 10000);

        // Check that all main milestones are in the levels
        for (final milestone in mainMilestones) {
          expect(levels.contains(milestone), true,
              reason: '$milestone should be in levels');
          expect(
              VoteDetailAchieveHelper.isMainMilestone(milestone, mainMilestones),
              true);
        }

        // Check progress at various points
        expect(
          VoteDetailAchieveHelper.calculateExactProgress(0, levels),
          0.0,
        );
        expect(
          VoteDetailAchieveHelper.calculateExactProgress(10000, levels),
          100.0,
        );

        // Milestone achievement check
        final result = VoteDetailAchieveHelper.checkMilestoneAchievement(
          currentVotes: 3000,
          milestoneAmounts: amounts,
          alreadyAchieved: {},
        );
        expect(result.allAchieved, [1000]);
        expect(result.newlyAchieved, [1000]);

        // Height calculation
        final height =
            VoteDetailAchieveHelper.calculateProgressBarHeight(mainMilestones);
        expect(height, greaterThan(0));
      });

      test('level achieved matches progress', () {
        final levels = VoteDetailAchieveHelper.generateLevels([0, 100]);

        for (final level in levels) {
          final achieved = VoteDetailAchieveHelper.isLevelAchieved(100, level);
          expect(achieved, true,
              reason: 'voteTotal 100 should achieve level $level');
        }

        // Level above voteTotal should not be achieved
        expect(VoteDetailAchieveHelper.isLevelAchieved(50, 60), false);
      });
    });
  });
}
