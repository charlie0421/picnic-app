/// Pure logic helpers extracted from [VoteDetailAchievePage] for testability.
///
/// All methods are static and side-effect free.
class VoteDetailAchieveHelper {
  /// Creates a list of main milestone values from achievement amounts,
  /// always starting with 0.
  static List<int> generateMilestonesFromAchievements(List<int> amounts) {
    final milestones = <int>[0];
    milestones.addAll(amounts);
    return milestones;
  }

  /// Generates all intermediate level markers between each pair of main
  /// milestones. Each interval is subdivided into 5 equal steps.
  ///
  /// Returns a list that always starts with 0 and includes every main
  /// milestone plus 4 intermediate values between each pair.
  static List<int> generateLevels(List<int> mainMilestones) {
    final allLevels = <int>[0];

    for (int i = 1; i < mainMilestones.length; i++) {
      final start = mainMilestones[i - 1];
      final end = mainMilestones[i];

      // Each interval divided into 5 equal steps
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

  /// Returns the total number of level steps (including 0 and all milestones).
  static int calculateTotalSteps(List<int> mainMilestones) {
    return generateLevels(mainMilestones).length;
  }

  /// Calculates a 0-100 progress percentage based on [voteTotal] within the
  /// given [levels] list (as produced by [generateLevels]).
  ///
  /// Each segment between consecutive levels contributes an equal share of the
  /// total progress bar, regardless of the absolute numerical gap.
  static double calculateExactProgress(int voteTotal, List<int> levels) {
    if (levels.isEmpty) return 0.0;
    if (voteTotal >= levels.last) return 100.0;
    if (voteTotal <= levels.first) return 0.0;

    // Find current segment
    int currentLevelIndex = 0;
    for (int i = 0; i < levels.length - 1; i++) {
      if (voteTotal >= levels[i] && voteTotal < levels[i + 1]) {
        currentLevelIndex = i;
        break;
      }
    }

    final totalSteps = levels.length - 1;
    final stepSize = 100.0 / totalSteps;

    final currentLevel = levels[currentLevelIndex];
    final nextLevel = levels[currentLevelIndex + 1];
    final levelDiff = nextLevel - currentLevel;
    final currentDiff = voteTotal - currentLevel;

    final progressInCurrentStep =
        levelDiff > 0 ? currentDiff / levelDiff : 0.0;

    final baseProgress = currentLevelIndex * stepSize;
    final additionalProgress = progressInCurrentStep * stepSize;

    return (baseProgress + additionalProgress).clamp(0.0, 100.0);
  }

  /// Determine if a given level value is a main milestone (as opposed to
  /// an intermediate step).
  static bool isMainMilestone(int level, List<int> mainMilestones) {
    return mainMilestones.contains(level);
  }

  /// Determine if a given level is achieved based on vote total.
  static bool isLevelAchieved(int voteTotal, int level) {
    return voteTotal >= level;
  }

  /// Calculate the height needed for the progress bar based on total steps.
  ///
  /// Each step is 50 pixels tall, minus one row.
  static double calculateProgressBarHeight(List<int> mainMilestones) {
    final totalSteps = calculateTotalSteps(mainMilestones);
    return 50 * totalSteps.toDouble() - 50;
  }

  /// Determines which milestones have been newly achieved.
  ///
  /// [currentVotes] - the current vote total.
  /// [milestoneAmounts] - all milestone amounts (sorted ascending).
  /// [alreadyAchieved] - set of milestone amounts already acknowledged.
  ///
  /// Returns a [MilestoneCheckResult] containing:
  /// - all achieved milestone amounts
  /// - newly achieved milestone amounts (not in [alreadyAchieved])
  static MilestoneCheckResult checkMilestoneAchievement({
    required int currentVotes,
    required List<int> milestoneAmounts,
    required Set<int> alreadyAchieved,
  }) {
    final sorted = List<int>.from(milestoneAmounts)..sort();

    final allAchieved = <int>[];
    final newlyAchieved = <int>[];

    for (final amount in sorted) {
      if (currentVotes >= amount) {
        allAchieved.add(amount);
        if (!alreadyAchieved.contains(amount)) {
          newlyAchieved.add(amount);
        }
      }
    }

    return MilestoneCheckResult(
      allAchieved: allAchieved,
      newlyAchieved: newlyAchieved,
    );
  }
}

/// Result of [VoteDetailAchieveHelper.checkMilestoneAchievement].
class MilestoneCheckResult {
  final List<int> allAchieved;
  final List<int> newlyAchieved;

  const MilestoneCheckResult({
    required this.allAchieved,
    required this.newlyAchieved,
  });
}
