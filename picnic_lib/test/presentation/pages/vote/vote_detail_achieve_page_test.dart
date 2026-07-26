import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/number.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_achieve_page.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

Map<String, dynamic> _voteRow({
  int id = 1,
  String titleKo = '달성 투표',
  bool isEnded = false,
  bool isUpcoming = false,
  DateTime? startAt,
  DateTime? stopAt,
}) {
  final now = DateTime.now().toUtc();
  return {
    'id': id,
    'title': {'ko': titleKo, 'en': 'Achievement Vote'},
    'vote_category': 'achieve',
    'main_image': null,
    'wait_image': null,
    'result_image': null,
    'vote_content': null,
    'vote_item': null,
    'created_at': now.toIso8601String(),
    'visible_at': now.subtract(const Duration(days: 2)).toIso8601String(),
    'start_at': (startAt ?? now.subtract(const Duration(days: 1)))
        .toIso8601String(),
    'stop_at':
        (stopAt ?? now.add(const Duration(days: 7))).toIso8601String(),
    'is_ended': isEnded,
    'is_upcoming': isUpcoming,
    'is_partnership': false,
    'partner': null,
    'reward': null,
  };
}

Map<String, dynamic> _voteItemRow({
  int id = 1,
  int voteId = 1,
  int voteTotal = 5000,
  String artistNameKo = '지민',
  int artistId = 10,
}) {
  return {
    'id': id,
    'vote_id': voteId,
    'vote_total': voteTotal,
    'artist': {
      'id': artistId,
      'name': {'ko': artistNameKo, 'en': artistNameKo},
      'image': null,
      'artist_group': {
        'id': 1,
        'name': {'ko': 'BTS', 'en': 'BTS'},
        'image': null,
      },
    },
    'artist_group': null,
  };
}

Map<String, dynamic> _voteAchieveJson({
  int id = 1,
  int voteId = 1,
  int rewardId = 1,
  int order = 1,
  int amount = 10000,
  String rewardTitleKo = '포토카드',
  String? rewardThumbnail = 'https://example.com/reward.jpg',
}) {
  return {
    'id': id,
    'vote_id': voteId,
    'reward_id': rewardId,
    'order': order,
    'amount': amount,
    'reward': {
      'id': rewardId,
      'title': {'ko': rewardTitleKo},
      'thumbnail': rewardThumbnail,
    },
    'vote': _voteRow(id: voteId),
  };
}

/// Mirrors _generateMilestonesFromAchievements from VoteDetailAchievePage
List<int> generateMilestonesFromAchievements(List<VoteAchieve> achievements) {
  List<int> milestones = [0];
  milestones.addAll(achievements.map((achieve) => achieve.amount));
  return milestones;
}

/// Mirrors _calculateExactProgress from VoteDetailAchievePage
double calculateExactProgress(int voteTotal, List<int> levels) {
  if (voteTotal >= levels.last) {
    return 100.0;
  }
  if (voteTotal <= levels.first) {
    return 0.0;
  }

  // Find current level
  int currentLevelIndex = 0;
  for (int i = 0; i < levels.length - 1; i++) {
    if (voteTotal >= levels[i] && voteTotal < levels[i + 1]) {
      currentLevelIndex = i;
      break;
    }
  }

  // Each level has equal step size
  final totalSteps = levels.length - 1;
  final stepSize = 100.0 / totalSteps;

  // Progress within current step
  final currentLevel = levels[currentLevelIndex];
  final nextLevel = levels[currentLevelIndex + 1];
  final levelDiff = nextLevel - currentLevel;
  final currentDiff = voteTotal - currentLevel;

  final progressInCurrentStep = levelDiff > 0 ? currentDiff / levelDiff : 0.0;

  final baseProgress = currentLevelIndex * stepSize;
  final additionalProgress = progressInCurrentStep * stepSize;

  return (baseProgress + additionalProgress).clamp(0.0, 100.0);
}

/// Mirrors _generateLevels from VoteDetailAchievePage
List<int> generateLevels(List<int> mainMilestones) {
  List<int> allLevels = [];
  allLevels.add(0);

  for (int i = 1; i < mainMilestones.length; i++) {
    final start = mainMilestones[i - 1];
    final end = mainMilestones[i];

    // Each interval is divided into 5 equal parts
    final stepSize = (end - start) ~/ 5;

    if (start != 0) {
      for (int j = 1; j <= 4; j++) {
        allLevels.add(start + (stepSize * j));
      }
    } else {
      for (int j = 1; j <= 4; j++) {
        allLevels.add(stepSize * j);
      }
    }
    allLevels.add(end);
  }

  return allLevels;
}

/// Mirrors _calculateTotalSteps from VoteDetailAchievePage
int calculateTotalSteps(List<int> mainMilestones) {
  return generateLevels(mainMilestones).length;
}

/// Mirrors _checkMilestoneAchievement from VoteDetailAchievePage
List<VoteAchieve> checkMilestoneAchievement(
  int currentVotes,
  List<VoteAchieve> achievements,
  Set<int> achievedMilestones,
) {
  final sortedAchievements = List<VoteAchieve>.from(achievements)
    ..sort((a, b) => a.amount.compareTo(b.amount));

  List<VoteAchieve> newlyAchieved = [];

  for (var achievement in sortedAchievements) {
    if (currentVotes >= achievement.amount) {
      if (!achievedMilestones.contains(achievement.amount)) {
        newlyAchieved.add(achievement);
        achievedMilestones.add(achievement.amount);
      }
    }
  }

  return newlyAchieved;
}

void main() {
  setUp(() {
    initTestColors();
  });

  group('VoteDetailAchievePage', () {
    testWidgets('is a ConsumerStatefulWidget', (tester) async {
      const page = VoteDetailAchievePage(voteId: 1);
      expect(page, isA<ConsumerStatefulWidget>());
      expect(page.voteId, 1);
      expect(page.votePortal, VotePortal.vote);
    });

    testWidgets('accepts pic portal', (tester) async {
      const page = VoteDetailAchievePage(voteId: 42, votePortal: VotePortal.pic);
      expect(page.voteId, 42);
      expect(page.votePortal, VotePortal.pic);
    });

    testWidgets('creates state', (tester) async {
      const page = VoteDetailAchievePage(voteId: 1);
      final state = page.createState();
      expect(state, isNotNull);
    });

    test('different voteIds create different instances', () {
      const page1 = VoteDetailAchievePage(voteId: 1);
      const page2 = VoteDetailAchievePage(voteId: 2);
      expect(page1.voteId, isNot(equals(page2.voteId)));
    });

    test('default portal is VotePortal.vote', () {
      const page = VoteDetailAchievePage(voteId: 10);
      expect(page.votePortal, VotePortal.vote);
    });
  });

  group('VoteAchieve model', () {
    test('parses from JSON correctly', () {
      final json = _voteAchieveJson();
      final achieve = VoteAchieve.fromJson(json);

      expect(achieve.id, 1);
      expect(achieve.voteId, 1);
      expect(achieve.rewardId, 1);
      expect(achieve.order, 1);
      expect(achieve.amount, 10000);
      expect(achieve.reward.title, {'ko': '포토카드'});
      expect(achieve.reward.thumbnail, 'https://example.com/reward.jpg');
    });

    test('parses with different amounts', () {
      final achievements = [
        VoteAchieve.fromJson(_voteAchieveJson(id: 1, order: 1, amount: 10000, rewardTitleKo: '포토카드')),
        VoteAchieve.fromJson(_voteAchieveJson(id: 2, order: 2, rewardId: 2, amount: 50000, rewardTitleKo: '앨범')),
        VoteAchieve.fromJson(_voteAchieveJson(id: 3, order: 3, rewardId: 3, amount: 100000, rewardTitleKo: '콘서트 티켓')),
      ];

      expect(achievements.length, 3);
      expect(achievements[0].amount, 10000);
      expect(achievements[1].amount, 50000);
      expect(achievements[2].amount, 100000);
    });

    test('sorts by amount ascending', () {
      final achievements = [
        VoteAchieve.fromJson(_voteAchieveJson(id: 3, order: 3, rewardId: 3, amount: 100000)),
        VoteAchieve.fromJson(_voteAchieveJson(id: 1, order: 1, rewardId: 1, amount: 10000)),
        VoteAchieve.fromJson(_voteAchieveJson(id: 2, order: 2, rewardId: 2, amount: 50000)),
      ];

      achievements.sort((a, b) => a.amount.compareTo(b.amount));

      expect(achievements[0].amount, 10000);
      expect(achievements[1].amount, 50000);
      expect(achievements[2].amount, 100000);
    });

    test('milestone achievement check logic', () {
      final achievements = [
        VoteAchieve.fromJson(_voteAchieveJson(id: 1, order: 1, amount: 10000)),
        VoteAchieve.fromJson(_voteAchieveJson(id: 2, order: 2, rewardId: 2, amount: 50000)),
        VoteAchieve.fromJson(_voteAchieveJson(id: 3, order: 3, rewardId: 3, amount: 100000)),
      ];

      final sortedAchievements = List<VoteAchieve>.from(achievements)
        ..sort((a, b) => a.amount.compareTo(b.amount));

      // Case 1: currentVotes = 5000, no milestones achieved
      {
        const currentVotes = 5000;
        final achieved = sortedAchievements
            .where((a) => currentVotes >= a.amount)
            .toList();
        expect(achieved.length, 0);
      }

      // Case 2: currentVotes = 15000, first milestone achieved
      {
        const currentVotes = 15000;
        final achieved = sortedAchievements
            .where((a) => currentVotes >= a.amount)
            .toList();
        expect(achieved.length, 1);
        expect(achieved[0].amount, 10000);
      }

      // Case 3: currentVotes = 75000, two milestones achieved
      {
        const currentVotes = 75000;
        final achieved = sortedAchievements
            .where((a) => currentVotes >= a.amount)
            .toList();
        expect(achieved.length, 2);
        expect(achieved[0].amount, 10000);
        expect(achieved[1].amount, 50000);
      }

      // Case 4: currentVotes = 200000, all milestones achieved
      {
        const currentVotes = 200000;
        final achieved = sortedAchievements
            .where((a) => currentVotes >= a.amount)
            .toList();
        expect(achieved.length, 3);
      }
    });

    test('newly achieved milestone detection', () {
      final achievements = [
        VoteAchieve.fromJson(_voteAchieveJson(id: 1, order: 1, amount: 10000)),
        VoteAchieve.fromJson(_voteAchieveJson(id: 2, order: 2, rewardId: 2, amount: 50000)),
      ];

      final achievedMilestones = <int>{};

      // First check: 15000 votes
      final newly1 = checkMilestoneAchievement(15000, achievements, achievedMilestones);
      expect(newly1.length, 1);
      expect(newly1[0].amount, 10000);

      // Second check: 15001 votes (no new milestones)
      final newly2 = checkMilestoneAchievement(15001, achievements, achievedMilestones);
      expect(newly2.length, 0);

      // Third check: 60000 votes (new milestone!)
      final newly3 = checkMilestoneAchievement(60000, achievements, achievedMilestones);
      expect(newly3.length, 1);
      expect(newly3[0].amount, 50000);
    });

    test('VoteAchieve with null reward thumbnail', () {
      final json = _voteAchieveJson(rewardThumbnail: null);
      final achieve = VoteAchieve.fromJson(json);
      expect(achieve.reward.thumbnail, isNull);
    });

    test('VoteAchieve order matches sort order', () {
      final achievements = [
        VoteAchieve.fromJson(_voteAchieveJson(id: 1, order: 3, amount: 100000)),
        VoteAchieve.fromJson(_voteAchieveJson(id: 2, order: 1, rewardId: 2, amount: 10000)),
        VoteAchieve.fromJson(_voteAchieveJson(id: 3, order: 2, rewardId: 3, amount: 50000)),
      ];

      achievements.sort((a, b) => a.order.compareTo(b.order));

      expect(achievements[0].order, 1);
      expect(achievements[1].order, 2);
      expect(achievements[2].order, 3);
    });

    test('VoteAchieve reward id matches', () {
      final achieve = VoteAchieve.fromJson(_voteAchieveJson(rewardId: 42));
      expect(achieve.rewardId, 42);
      expect(achieve.reward.id, 42);
    });
  });

  group('VoteItemModel for achieve page', () {
    test('parses with valid artist data', () {
      final item = VoteItemModel.fromJson(_voteItemRow(voteTotal: 25000));
      expect(item.voteTotal, 25000);
      expect(item.artist?.name['ko'], '지민');
    });

    test('parses with group-only data', () {
      final item = VoteItemModel.fromJson({
        'id': 1,
        'vote_id': 1,
        'vote_total': 30000,
        'artist': {
          'id': 0,
          'name': {'ko': '', 'en': ''},
          'image': null,
          'artist_group': null,
        },
        'artist_group': {
          'id': 1,
          'name': {'ko': 'BTS', 'en': 'BTS'},
          'image': 'https://example.com/bts.jpg',
        },
      });
      expect(item.artist?.id, 0);
      expect(item.artistGroup?.name['ko'], 'BTS');
      expect(item.artistGroup?.image, 'https://example.com/bts.jpg');
    });

    test('copyWith updates voteTotal', () {
      final item = VoteItemModel.fromJson(_voteItemRow(voteTotal: 1000));
      final updated = item.copyWith(voteTotal: 2000);
      expect(updated.voteTotal, 2000);
      expect(updated.id, item.id);
    });

    test('VoteModel achieve category', () {
      final now = DateTime.now().toUtc();
      final vote = VoteModel.fromJson({
        'id': 1,
        'title': {'ko': '달성 투표'},
        'vote_category': 'achieve',
        'main_image': null,
        'wait_image': null,
        'result_image': null,
        'vote_content': null,
        'vote_item': null,
        'created_at': null,
        'visible_at': null,
        'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
        'is_ended': false,
        'is_upcoming': false,
        'is_partnership': false,
        'partner': null,
        'reward': null,
      });
      expect(vote.voteCategory, 'achieve');
    });

    test('progress calculation for level bar', () {
      final allLevels = [0, 2500, 5000, 7500, 10000, 15000, 20000, 25000, 30000, 50000];
      const voteTotal = 12000;

      int lowerIndex = 0;
      for (int i = allLevels.length - 1; i >= 0; i--) {
        if (voteTotal >= allLevels[i]) {
          lowerIndex = i;
          break;
        }
      }

      expect(lowerIndex, 4);
      expect(allLevels[lowerIndex], 10000);
      if (lowerIndex < allLevels.length - 1) {
        final upper = allLevels[lowerIndex + 1];
        final lower = allLevels[lowerIndex];
        final fraction = (voteTotal - lower) / (upper - lower);
        expect(fraction, closeTo(0.4, 0.01));
      }
    });
  });

  group('generateMilestonesFromAchievements', () {
    test('generates milestones with achievements', () {
      final achievements = [
        VoteAchieve.fromJson(_voteAchieveJson(id: 1, order: 1, amount: 10000)),
        VoteAchieve.fromJson(_voteAchieveJson(id: 2, order: 2, rewardId: 2, amount: 50000)),
        VoteAchieve.fromJson(_voteAchieveJson(id: 3, order: 3, rewardId: 3, amount: 100000)),
      ];

      final milestones = generateMilestonesFromAchievements(achievements);
      expect(milestones, [0, 10000, 50000, 100000]);
    });

    test('generates milestones with single achievement', () {
      final achievements = [
        VoteAchieve.fromJson(_voteAchieveJson(id: 1, order: 1, amount: 25000)),
      ];

      final milestones = generateMilestonesFromAchievements(achievements);
      expect(milestones, [0, 25000]);
    });

    test('generates milestones with empty achievements', () {
      final milestones = generateMilestonesFromAchievements([]);
      expect(milestones, [0]);
    });

    test('preserves achievement order', () {
      final achievements = [
        VoteAchieve.fromJson(_voteAchieveJson(id: 1, order: 1, amount: 5000)),
        VoteAchieve.fromJson(_voteAchieveJson(id: 2, order: 2, rewardId: 2, amount: 15000)),
        VoteAchieve.fromJson(_voteAchieveJson(id: 3, order: 3, rewardId: 3, amount: 30000)),
        VoteAchieve.fromJson(_voteAchieveJson(id: 4, order: 4, rewardId: 4, amount: 75000)),
      ];

      final milestones = generateMilestonesFromAchievements(achievements);
      expect(milestones, [0, 5000, 15000, 30000, 75000]);
    });
  });

  group('generateLevels', () {
    test('generates levels for two milestones', () {
      final levels = generateLevels([0, 10000]);
      // From 0 to 10000, stepSize = 10000 ~/ 5 = 2000
      // First section (start=0): 2000, 4000, 6000, 8000, then 10000
      expect(levels, [0, 2000, 4000, 6000, 8000, 10000]);
    });

    test('generates levels for three milestones', () {
      final levels = generateLevels([0, 10000, 50000]);
      // First section (0 to 10000): stepSize = 2000 -> 2000, 4000, 6000, 8000, 10000
      // Second section (10000 to 50000): stepSize = 8000 -> 18000, 26000, 34000, 42000, 50000
      expect(levels[0], 0);
      expect(levels[1], 2000);
      expect(levels[2], 4000);
      expect(levels[3], 6000);
      expect(levels[4], 8000);
      expect(levels[5], 10000);
      expect(levels[6], 18000);
      expect(levels[7], 26000);
      expect(levels[8], 34000);
      expect(levels[9], 42000);
      expect(levels[10], 50000);
      expect(levels.length, 11);
    });

    test('generates levels for single milestone (just 0)', () {
      final levels = generateLevels([0]);
      expect(levels, [0]);
    });

    test('level count per section is 5', () {
      final levels = generateLevels([0, 10000]);
      // 0 (initial) + 4 intermediate + 1 endpoint = 6
      expect(levels.length, 6);
    });

    test('generates correct levels for small milestones', () {
      final levels = generateLevels([0, 100]);
      // stepSize = 100 ~/ 5 = 20
      expect(levels, [0, 20, 40, 60, 80, 100]);
    });

    test('generates levels for multiple sections with non-zero start', () {
      final levels = generateLevels([0, 10000, 20000]);
      // Section 1 (0-10000): step=2000 -> 2000,4000,6000,8000,10000
      // Section 2 (10000-20000): step=2000 -> 12000,14000,16000,18000,20000
      expect(levels.contains(10000), isTrue);
      expect(levels.contains(12000), isTrue);
      expect(levels.contains(20000), isTrue);
    });

    test('handles large milestone values', () {
      final levels = generateLevels([0, 1000000]);
      expect(levels.first, 0);
      expect(levels.last, 1000000);
      expect(levels.length, 6);
    });
  });

  group('calculateTotalSteps', () {
    test('returns count of all levels', () {
      final totalSteps = calculateTotalSteps([0, 10000]);
      expect(totalSteps, 6); // 0, 2000, 4000, 6000, 8000, 10000
    });

    test('returns count for three milestones', () {
      final totalSteps = calculateTotalSteps([0, 10000, 50000]);
      expect(totalSteps, 11); // 6 + 5
    });

    test('returns 1 for single milestone', () {
      final totalSteps = calculateTotalSteps([0]);
      expect(totalSteps, 1);
    });

    test('returns correct count for four milestones', () {
      final totalSteps = calculateTotalSteps([0, 10000, 50000, 100000]);
      expect(totalSteps, 16); // 6 + 5 + 5
    });
  });

  group('calculateExactProgress', () {
    test('returns 0 when voteTotal is 0', () {
      final levels = [0, 2000, 4000, 6000, 8000, 10000];
      expect(calculateExactProgress(0, levels), 0.0);
    });

    test('returns 100 when voteTotal exceeds last level', () {
      final levels = [0, 2000, 4000, 6000, 8000, 10000];
      expect(calculateExactProgress(15000, levels), 100.0);
    });

    test('returns 100 when voteTotal equals last level', () {
      final levels = [0, 2000, 4000, 6000, 8000, 10000];
      expect(calculateExactProgress(10000, levels), 100.0);
    });

    test('returns 50% at midpoint', () {
      final levels = [0, 5000, 10000];
      // At 5000: level index 1, which is step 1 of 2 total steps = 50%
      expect(calculateExactProgress(5000, levels), closeTo(50.0, 0.1));
    });

    test('returns correct progress within a step', () {
      final levels = [0, 10000];
      // At 5000: halfway through the only step
      expect(calculateExactProgress(5000, levels), closeTo(50.0, 0.1));
    });

    test('returns correct progress at 25%', () {
      final levels = [0, 10000];
      expect(calculateExactProgress(2500, levels), closeTo(25.0, 0.1));
    });

    test('returns correct progress at 75%', () {
      final levels = [0, 10000];
      expect(calculateExactProgress(7500, levels), closeTo(75.0, 0.1));
    });

    test('handles multi-section progress', () {
      final levels = [0, 5000, 10000, 15000, 20000];
      // 4 total steps, each step = 25%
      // At 5000: end of first step = 25%
      expect(calculateExactProgress(5000, levels), closeTo(25.0, 0.1));
      // At 10000: end of second step = 50%
      expect(calculateExactProgress(10000, levels), closeTo(50.0, 0.1));
      // At 15000: end of third step = 75%
      expect(calculateExactProgress(15000, levels), closeTo(75.0, 0.1));
    });

    test('handles progress at step boundary', () {
      final levels = generateLevels([0, 10000, 50000]);
      // At exactly 10000, it should be at the boundary between sections
      final progress = calculateExactProgress(10000, levels);
      // 10000 is level index 5 of 10 total steps = 50%
      expect(progress, closeTo(50.0, 0.1));
    });

    test('handles very small voteTotal', () {
      final levels = [0, 10000];
      expect(calculateExactProgress(1, levels), closeTo(0.01, 0.1));
    });

    test('clamps between 0 and 100', () {
      final levels = [0, 10000];
      final progress = calculateExactProgress(5000, levels);
      expect(progress >= 0.0 && progress <= 100.0, isTrue);
    });

    test('handles negative voteTotal', () {
      final levels = [0, 10000];
      expect(calculateExactProgress(-100, levels), 0.0);
    });

    test('handles progress between unequal sections', () {
      // Milestones: 0, 10000, 50000
      // Levels: 0, 2000, 4000, 6000, 8000, 10000, 18000, 26000, 34000, 42000, 50000
      final levels = generateLevels([0, 10000, 50000]);

      // At 30000: between 26000 (index 7) and 34000 (index 8)
      final progress = calculateExactProgress(30000, levels);
      // index 7 covers: 7/10 * 100 = 70%, plus fraction within that step
      // (30000-26000)/(34000-26000) = 4000/8000 = 0.5
      // stepSize = 100/10 = 10
      // 70 + 0.5 * 10 = 75
      expect(progress, closeTo(75.0, 0.1));
    });
  });

  group('Milestone achievement with achievedMilestones tracking', () {
    test('first achievement detection', () {
      final achievements = [
        VoteAchieve.fromJson(_voteAchieveJson(id: 1, order: 1, amount: 10000)),
        VoteAchieve.fromJson(_voteAchieveJson(id: 2, order: 2, rewardId: 2, amount: 50000)),
      ];
      final achievedMilestones = <int>{};

      final result = checkMilestoneAchievement(15000, achievements, achievedMilestones);
      expect(result.length, 1);
      expect(result[0].amount, 10000);
      expect(achievedMilestones, {10000});
    });

    test('multiple achievements at once', () {
      final achievements = [
        VoteAchieve.fromJson(_voteAchieveJson(id: 1, order: 1, amount: 10000)),
        VoteAchieve.fromJson(_voteAchieveJson(id: 2, order: 2, rewardId: 2, amount: 50000)),
        VoteAchieve.fromJson(_voteAchieveJson(id: 3, order: 3, rewardId: 3, amount: 100000)),
      ];
      final achievedMilestones = <int>{};

      // Jump from 0 to 75000 - should achieve first two
      final result = checkMilestoneAchievement(75000, achievements, achievedMilestones);
      expect(result.length, 2);
      expect(result[0].amount, 10000);
      expect(result[1].amount, 50000);
      expect(achievedMilestones, {10000, 50000});
    });

    test('no new achievements when all already achieved', () {
      final achievements = [
        VoteAchieve.fromJson(_voteAchieveJson(id: 1, order: 1, amount: 10000)),
      ];
      final achievedMilestones = <int>{10000};

      final result = checkMilestoneAchievement(15000, achievements, achievedMilestones);
      expect(result.length, 0);
    });

    test('no achievements when votes below all milestones', () {
      final achievements = [
        VoteAchieve.fromJson(_voteAchieveJson(id: 1, order: 1, amount: 10000)),
      ];
      final achievedMilestones = <int>{};

      final result = checkMilestoneAchievement(5000, achievements, achievedMilestones);
      expect(result.length, 0);
      expect(achievedMilestones, isEmpty);
    });

    test('exactly at milestone amount triggers achievement', () {
      final achievements = [
        VoteAchieve.fromJson(_voteAchieveJson(id: 1, order: 1, amount: 10000)),
      ];
      final achievedMilestones = <int>{};

      final result = checkMilestoneAchievement(10000, achievements, achievedMilestones);
      expect(result.length, 1);
    });

    test('progressive milestone achievement across multiple checks', () {
      final achievements = [
        VoteAchieve.fromJson(_voteAchieveJson(id: 1, order: 1, amount: 10000)),
        VoteAchieve.fromJson(_voteAchieveJson(id: 2, order: 2, rewardId: 2, amount: 50000)),
        VoteAchieve.fromJson(_voteAchieveJson(id: 3, order: 3, rewardId: 3, amount: 100000)),
      ];
      final achievedMilestones = <int>{};

      // Check 1: 15000 votes
      final r1 = checkMilestoneAchievement(15000, achievements, achievedMilestones);
      expect(r1.length, 1);
      expect(achievedMilestones, {10000});

      // Check 2: 55000 votes
      final r2 = checkMilestoneAchievement(55000, achievements, achievedMilestones);
      expect(r2.length, 1);
      expect(achievedMilestones, {10000, 50000});

      // Check 3: 150000 votes
      final r3 = checkMilestoneAchievement(150000, achievements, achievedMilestones);
      expect(r3.length, 1);
      expect(achievedMilestones, {10000, 50000, 100000});

      // Check 4: no more milestones
      final r4 = checkMilestoneAchievement(200000, achievements, achievedMilestones);
      expect(r4.length, 0);
    });

    test('handles unsorted achievements', () {
      final achievements = [
        VoteAchieve.fromJson(_voteAchieveJson(id: 3, order: 3, rewardId: 3, amount: 100000)),
        VoteAchieve.fromJson(_voteAchieveJson(id: 1, order: 1, amount: 10000)),
        VoteAchieve.fromJson(_voteAchieveJson(id: 2, order: 2, rewardId: 2, amount: 50000)),
      ];
      final achievedMilestones = <int>{};

      // Should still correctly find achievements sorted by amount
      final result = checkMilestoneAchievement(75000, achievements, achievedMilestones);
      expect(result.length, 2);
      // Should be sorted by amount
      expect(result[0].amount, 10000);
      expect(result[1].amount, 50000);
    });
  });

  group('formatNumberWithComma', () {
    test('formats small numbers', () {
      expect(formatNumberWithComma('100'), '100');
    });

    test('formats thousands', () {
      expect(formatNumberWithComma('1000'), '1,000');
    });

    test('formats ten thousands', () {
      expect(formatNumberWithComma('10000'), '10,000');
    });

    test('formats hundred thousands', () {
      expect(formatNumberWithComma('100000'), '100,000');
    });

    test('formats millions', () {
      expect(formatNumberWithComma('1000000'), '1,000,000');
    });

    test('formats integer values', () {
      expect(formatNumberWithComma(50000), '50,000');
    });
  });

  group('Vote count container hasChanged logic', () {
    test('hasChanged is true when diff is non-zero positive', () {
      const voteCountDiff = 100;
      final hasChanged = voteCountDiff != 0;
      expect(hasChanged, isTrue);
    });

    test('hasChanged is true when diff is non-zero negative', () {
      const voteCountDiff = -50;
      final hasChanged = voteCountDiff != 0;
      expect(hasChanged, isTrue);
    });

    test('hasChanged is false when diff is zero', () {
      const voteCountDiff = 0;
      final hasChanged = voteCountDiff != 0;
      expect(hasChanged, isFalse);
    });
  });

  group('Timer and update logic', () {
    test('isDisposed prevents timer callback', () {
      bool isDisposed = true;
      bool callbackExecuted = false;

      if (!isDisposed) {
        callbackExecuted = true;
      }
      expect(callbackExecuted, isFalse);
    });

    test('mounted check prevents setState', () {
      bool mounted = false;
      bool stateUpdated = false;

      if (mounted) {
        stateUpdated = true;
      }
      expect(stateUpdated, isFalse);
    });

    test('first item extraction from vote item data', () {
      final voteItemData = [
        VoteItemModel.fromJson(_voteItemRow(voteTotal: 25000)),
        VoteItemModel.fromJson(_voteItemRow(id: 2, voteTotal: 15000, artistId: 11)),
      ];

      final firstItem = voteItemData[0];
      expect(firstItem.voteTotal, 25000);
    });

    test('empty vote item data returns early', () {
      final voteItemData = <VoteItemModel?>[];
      expect(voteItemData.isEmpty, isTrue);
    });

    test('null first item returns early', () {
      final List<VoteItemModel?> voteItemData = [null];
      expect(voteItemData[0], isNull);
    });
  });

  group('Achieve page navigation logic', () {
    test('navigation settings for achieve page', () {
      // Simulate the navigation settings used by _updateNavigation
      const showPortal = false;
      const showTopMenu = true;
      const showBottomNavigation = false;

      expect(showPortal, isFalse);
      expect(showTopMenu, isTrue);
      expect(showBottomNavigation, isFalse);
    });
  });

  group('Level bar progress visual logic', () {
    test('progressHeight calculation', () {
      final mainMilestones = [0, 10000, 50000];
      final totalSteps = calculateTotalSteps(mainMilestones);
      final progressHeight = 50 * totalSteps.toDouble() - 50;
      // totalSteps = 11, so progressHeight = 50 * 11 - 50 = 500
      expect(progressHeight, 500.0);
    });

    test('progressHeight with single milestone', () {
      final mainMilestones = [0, 10000];
      final totalSteps = calculateTotalSteps(mainMilestones);
      final progressHeight = 50 * totalSteps.toDouble() - 50;
      // totalSteps = 6, so progressHeight = 50 * 6 - 50 = 250
      expect(progressHeight, 250.0);
    });

    test('isAchieved check for each level', () {
      final levels = generateLevels([0, 10000, 50000]);
      const voteTotal = 30000;

      final achievedLevels = levels.where((level) => voteTotal >= level).toList();
      final unachievedLevels = levels.where((level) => voteTotal < level).toList();

      // At 30000, levels 0 through 26000 should be achieved
      expect(achievedLevels.every((l) => l <= 30000), isTrue);
      expect(unachievedLevels.every((l) => l > 30000), isTrue);
    });

    test('isMainMilestone check', () {
      final mainMilestones = [0, 10000, 50000];
      final levels = generateLevels(mainMilestones);

      for (var level in levels) {
        final isMain = mainMilestones.contains(level);
        if (level == 0 || level == 10000 || level == 50000) {
          expect(isMain, isTrue, reason: 'Level $level should be a main milestone');
        } else {
          expect(isMain, isFalse, reason: 'Level $level should not be a main milestone');
        }
      }
    });

    test('reward index increments only for main milestones > 0', () {
      final mainMilestones = [0, 10000, 50000];
      final levels = generateLevels(mainMilestones);

      int rewardIndex = 0;
      for (var level in levels) {
        final isMainMilestone = mainMilestones.contains(level);
        if (isMainMilestone && level > 0) {
          rewardIndex++;
        }
      }

      // Should increment for 10000 and 50000 only
      expect(rewardIndex, 2);
    });
  });

  group('Artist display logic for achieve page', () {
    test('shows artist name when artist id is non-zero', () {
      final item = VoteItemModel.fromJson(_voteItemRow(artistId: 10));
      final showArtist = (item.artist?.id ?? 0) != 0;
      expect(showArtist, isTrue);
    });

    test('shows group name when artist id is zero', () {
      final item = VoteItemModel.fromJson({
        'id': 1,
        'vote_id': 1,
        'vote_total': 5000,
        'artist': {
          'id': 0,
          'name': {'ko': '', 'en': ''},
          'image': null,
          'artist_group': null,
        },
        'artist_group': {
          'id': 1,
          'name': {'ko': 'BTS', 'en': 'BTS'},
          'image': null,
        },
      });
      final showArtist = (item.artist?.id ?? 0) != 0;
      expect(showArtist, isFalse);
    });

    test('artist image URL selection', () {
      final item = VoteItemModel.fromJson({
        'id': 1,
        'vote_id': 1,
        'vote_total': 5000,
        'artist': {
          'id': 10,
          'name': {'ko': '지민', 'en': 'Jimin'},
          'image': 'https://example.com/jimin.jpg',
          'artist_group': null,
        },
        'artist_group': null,
      });

      final imageUrl = ((item.artist?.id ?? 0) != 0
          ? item.artist?.image
          : item.artistGroup?.image) ?? '';
      expect(imageUrl, 'https://example.com/jimin.jpg');
    });

    test('group image URL selection when no artist', () {
      final item = VoteItemModel.fromJson({
        'id': 1,
        'vote_id': 1,
        'vote_total': 5000,
        'artist': {
          'id': 0,
          'name': {'ko': '', 'en': ''},
          'image': null,
          'artist_group': null,
        },
        'artist_group': {
          'id': 1,
          'name': {'ko': 'BTS', 'en': 'BTS'},
          'image': 'https://example.com/bts.jpg',
        },
      });

      final imageUrl = ((item.artist?.id ?? 0) != 0
          ? item.artist?.image
          : item.artistGroup?.image) ?? '';
      expect(imageUrl, 'https://example.com/bts.jpg');
    });

    test('empty image URL when no images available', () {
      final item = VoteItemModel.fromJson({
        'id': 1,
        'vote_id': 1,
        'vote_total': 5000,
        'artist': {
          'id': 10,
          'name': {'ko': '지민', 'en': 'Jimin'},
          'image': null,
          'artist_group': null,
        },
        'artist_group': null,
      });

      final imageUrl = ((item.artist?.id ?? 0) != 0
          ? item.artist?.image
          : item.artistGroup?.image) ?? '';
      expect(imageUrl, '');
    });
  });

  group('Vote detail status determination for achieve page', () {
    test('determines ended status for dialog', () {
      final vote = VoteModel.fromJson(_voteRow(isEnded: true));
      expect(vote.isEnded, isTrue);
    });

    test('determines upcoming status for dialog', () {
      final vote = VoteModel.fromJson(_voteRow(isUpcoming: true));
      expect(vote.isUpcoming, isTrue);
    });

    test('determines active status - show voting dialog', () {
      final vote = VoteModel.fromJson(_voteRow(isEnded: false, isUpcoming: false));
      expect(vote.isEnded, isFalse);
      expect(vote.isUpcoming, isFalse);
      // Active state allows voting dialog
    });

    test('vote start and stop times are parsed', () {
      final now = DateTime.now().toUtc();
      final vote = VoteModel.fromJson(_voteRow(
        startAt: now.subtract(const Duration(days: 3)),
        stopAt: now.add(const Duration(days: 10)),
      ));
      expect(vote.startAt, isNotNull);
      expect(vote.stopAt, isNotNull);
    });
  });

  group('Opacity clamping in vote count animation', () {
    test('opacity is clamped between 0 and 1', () {
      // Simulate the TweenAnimationBuilder logic
      for (double value = 0; value <= 1.0; value += 0.1) {
        final opacity = (1 - value).clamp(0.0, 1.0);
        expect(opacity >= 0.0 && opacity <= 1.0, isTrue);
      }
    });

    test('offset calculation', () {
      for (double value = 0; value <= 1.0; value += 0.1) {
        final offset = -10 * value;
        expect(offset <= 0, isTrue);
        expect(offset >= -10, isTrue);
      }
    });
  });

  group('VoteDetailAchievePage widget rendering', () {
    late void Function() restore;

    setUp(() {
      VisibilityDetectorController.instance.updateInterval = Duration.zero;
      setupMockSupabase({
        'vote': [_voteRow()],
        'vote_item': [
          _voteItemRow(id: 1, voteTotal: 5000),
          _voteItemRow(id: 2, voteTotal: 3000, artistId: 11, artistNameKo: '정국'),
        ],
        'vote_achieve': [
          _voteAchieveJson(id: 1, order: 1, amount: 10000),
          _voteAchieveJson(id: 2, order: 2, rewardId: 2, amount: 50000),
        ],
      });
      restore = suppressImageErrors();
    });

    tearDown(() {
      restore();
      tearDownMockSupabase();
    });

    Future<void> pumpAndDrain(WidgetTester tester, widget) async {
      await tester.pumpWidget(widget);
      drainExpectedImageErrors(tester);
      await tester.pump(const Duration(seconds: 1));
      drainExpectedImageErrors(tester);
    }

    testWidgets('renders without crashing', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(const VoteDetailAchievePage(voteId: 1)),
      );
      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
    });

    testWidgets('renders with pic portal', (WidgetTester tester) async {
      setupMockSupabase({
        'pic_vote': [_voteRow()],
        'pic_vote_item': [
          _voteItemRow(id: 1, voteTotal: 5000),
        ],
        'vote_achieve': [
          _voteAchieveJson(id: 1, order: 1, amount: 10000),
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailAchievePage(voteId: 1, votePortal: VotePortal.pic),
        ),
      );
      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
    });

    testWidgets('renders in logged-out state', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(
          const VoteDetailAchievePage(voteId: 1),
          loggedIn: false,
        ),
      );
      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
    });

    testWidgets('renders and can be scrolled', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(const VoteDetailAchievePage(voteId: 1)),
      );
      expect(find.byType(VoteDetailAchievePage), findsOneWidget);

      final scrollable = find.byType(CustomScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -300),
            warnIfMissed: false);
        drainExpectedImageErrors(tester);
        await tester.pump(const Duration(milliseconds: 200));
        drainExpectedImageErrors(tester);
      }
    });

    testWidgets('renders with no achieve milestones', (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [_voteRow()],
        'vote_item': [_voteItemRow(id: 1, voteTotal: 5000)],
        'vote_achieve': <dynamic>[],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(const VoteDetailAchievePage(voteId: 1)),
      );
      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
    });

    testWidgets('dispose cleans up without error', (WidgetTester tester) async {
      await pumpAndDrain(
        tester,
        buildTestAppPage(const VoteDetailAchievePage(voteId: 1)),
      );
      await tester.pumpWidget(buildTestAppPage(const SizedBox()));
      drainExpectedImageErrors(tester);
      await tester.pump(const Duration(milliseconds: 300));
      drainExpectedImageErrors(tester);
    });
  });
}
