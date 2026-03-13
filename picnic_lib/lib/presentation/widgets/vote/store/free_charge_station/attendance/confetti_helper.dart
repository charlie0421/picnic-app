import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Data class for a single confetti particle.
class ConfettiParticle {
  final double startX;
  final double speed;
  final double rotationSpeed;
  final double size;
  final Color color;
  final bool isCircle;

  ConfettiParticle(Random rng)
      : startX = rng.nextDouble(),
        speed = 0.5 + rng.nextDouble() * 0.8,
        rotationSpeed = 0.5 + rng.nextDouble() * 2,
        size = 3 + rng.nextDouble() * 4,
        color = confettiColors[rng.nextInt(confettiColors.length)],
        isCircle = rng.nextBool();

  /// For testing: create with explicit values.
  @visibleForTesting
  ConfettiParticle.withValues({
    required this.startX,
    required this.speed,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.isCircle,
  });

  static const List<Color> confettiColors = [
    Color(0xFFA855F7), // purple
    Color(0xFFEC4899), // pink
    Color(0xFFF59E0B), // amber
    Color(0xFF22C55E), // green
    Color(0xFF3B82F6), // blue
    Color(0xFFEF4444), // red
  ];
}

/// Helper class for confetti particle calculations.
class ConfettiHelper {
  /// Calculate the opacity of a particle based on animation progress.
  @visibleForTesting
  static double calculateOpacity(double progress) {
    return (1.0 - progress).clamp(0.0, 1.0);
  }

  /// Calculate the Y position of a particle.
  @visibleForTesting
  static double calculateY({
    required double progress,
    required double speed,
    required double height,
    double startOffset = -20,
  }) {
    return startOffset + (height + 40) * progress * speed;
  }

  /// Calculate the X position of a particle.
  @visibleForTesting
  static double calculateX({
    required double startX,
    required double width,
  }) {
    return startX * width;
  }

  /// Calculate the rotation angle of a particle.
  @visibleForTesting
  static double calculateRotation({
    required double progress,
    required double rotationSpeed,
  }) {
    return progress * rotationSpeed * 6.28;
  }

  /// Generate a list of confetti particles with a given seed.
  @visibleForTesting
  static List<ConfettiParticle> generateParticles(int count) {
    return List.generate(count, (i) => ConfettiParticle(Random(i)));
  }

  /// Calculate the total reward from check-in.
  @visibleForTesting
  static int calculateTotalReward({
    required int baseReward,
    required int weeklyBonusAmount,
  }) {
    return baseReward + weeklyBonusAmount;
  }

  /// Whether the weekly bonus indicator should be shown.
  @visibleForTesting
  static bool shouldShowWeeklyBonus(int weeklyBonusAmount) {
    return weeklyBonusAmount > 0;
  }

  /// Calculate attendance progress as a fraction.
  @visibleForTesting
  static double calculateProgress({
    required int checkedCount,
    required int totalRequired,
  }) {
    if (totalRequired <= 0) return 0.0;
    return checkedCount / totalRequired;
  }
}
