import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/attendance/confetti_helper.dart';

void main() {
  group('ConfettiHelper.calculateOpacity', () {
    test('returns 1.0 at start of animation', () {
      expect(ConfettiHelper.calculateOpacity(0.0), 1.0);
    });

    test('returns 0.0 at end of animation', () {
      expect(ConfettiHelper.calculateOpacity(1.0), 0.0);
    });

    test('returns 0.5 at midpoint', () {
      expect(ConfettiHelper.calculateOpacity(0.5), 0.5);
    });

    test('clamps negative progress to 1.0', () {
      expect(ConfettiHelper.calculateOpacity(-0.5), 1.0);
    });

    test('clamps progress > 1 to 0.0', () {
      expect(ConfettiHelper.calculateOpacity(1.5), 0.0);
    });
  });

  group('ConfettiHelper.calculateY', () {
    test('starts at startOffset when progress is 0', () {
      final y = ConfettiHelper.calculateY(
        progress: 0.0,
        speed: 1.0,
        height: 100,
      );
      expect(y, -20);
    });

    test('ends past height when progress is 1', () {
      final y = ConfettiHelper.calculateY(
        progress: 1.0,
        speed: 1.0,
        height: 100,
      );
      // -20 + (100+40)*1*1 = -20 + 140 = 120
      expect(y, 120);
    });

    test('slower speed means less distance', () {
      final y = ConfettiHelper.calculateY(
        progress: 1.0,
        speed: 0.5,
        height: 100,
      );
      // -20 + 140*0.5 = -20 + 70 = 50
      expect(y, 50);
    });

    test('custom startOffset', () {
      final y = ConfettiHelper.calculateY(
        progress: 0.0,
        speed: 1.0,
        height: 100,
        startOffset: -50,
      );
      expect(y, -50);
    });
  });

  group('ConfettiHelper.calculateX', () {
    test('returns 0 when startX is 0', () {
      expect(
        ConfettiHelper.calculateX(startX: 0.0, width: 100),
        0.0,
      );
    });

    test('returns width when startX is 1', () {
      expect(
        ConfettiHelper.calculateX(startX: 1.0, width: 100),
        100.0,
      );
    });

    test('returns half when startX is 0.5', () {
      expect(
        ConfettiHelper.calculateX(startX: 0.5, width: 200),
        100.0,
      );
    });
  });

  group('ConfettiHelper.calculateRotation', () {
    test('returns 0 when progress is 0', () {
      expect(
        ConfettiHelper.calculateRotation(progress: 0.0, rotationSpeed: 1.0),
        0.0,
      );
    });

    test('returns full rotation when progress is 1 and speed is 1', () {
      final result = ConfettiHelper.calculateRotation(
        progress: 1.0,
        rotationSpeed: 1.0,
      );
      expect(result, closeTo(6.28, 0.01));
    });

    test('double speed means double rotation', () {
      final result = ConfettiHelper.calculateRotation(
        progress: 1.0,
        rotationSpeed: 2.0,
      );
      expect(result, closeTo(12.56, 0.01));
    });
  });

  group('ConfettiHelper.generateParticles', () {
    test('generates correct number of particles', () {
      final particles = ConfettiHelper.generateParticles(20);
      expect(particles.length, 20);
    });

    test('generates zero particles', () {
      final particles = ConfettiHelper.generateParticles(0);
      expect(particles, isEmpty);
    });

    test('particles are deterministic with same seed', () {
      final p1 = ConfettiHelper.generateParticles(5);
      final p2 = ConfettiHelper.generateParticles(5);
      for (int i = 0; i < 5; i++) {
        expect(p1[i].startX, p2[i].startX);
        expect(p1[i].speed, p2[i].speed);
        expect(p1[i].color, p2[i].color);
      }
    });

    test('particle properties are within expected ranges', () {
      final particles = ConfettiHelper.generateParticles(100);
      for (final p in particles) {
        expect(p.startX, inInclusiveRange(0.0, 1.0));
        expect(p.speed, inInclusiveRange(0.5, 1.3));
        expect(p.rotationSpeed, inInclusiveRange(0.5, 2.5));
        expect(p.size, inInclusiveRange(3.0, 7.0));
      }
    });
  });

  group('ConfettiParticle', () {
    test('withValues constructor creates particle with explicit values', () {
      final p = ConfettiParticle.withValues(
        startX: 0.5,
        speed: 1.0,
        rotationSpeed: 1.5,
        size: 4.0,
        color: const Color(0xFFFF0000),
        isCircle: true,
      );
      expect(p.startX, 0.5);
      expect(p.speed, 1.0);
      expect(p.rotationSpeed, 1.5);
      expect(p.size, 4.0);
      expect(p.color, const Color(0xFFFF0000));
      expect(p.isCircle, true);
    });

    test('confettiColors has 6 colors', () {
      expect(ConfettiParticle.confettiColors.length, 6);
    });

    test('confettiColors contains expected colors', () {
      expect(
        ConfettiParticle.confettiColors,
        contains(const Color(0xFFA855F7)), // purple
      );
      expect(
        ConfettiParticle.confettiColors,
        contains(const Color(0xFFEF4444)), // red
      );
    });
  });

  group('ConfettiHelper.calculateTotalReward', () {
    test('base reward only', () {
      expect(
        ConfettiHelper.calculateTotalReward(
          baseReward: 60,
          weeklyBonusAmount: 0,
        ),
        60,
      );
    });

    test('base + weekly bonus', () {
      expect(
        ConfettiHelper.calculateTotalReward(
          baseReward: 60,
          weeklyBonusAmount: 120,
        ),
        180,
      );
    });

    test('zero rewards', () {
      expect(
        ConfettiHelper.calculateTotalReward(
          baseReward: 0,
          weeklyBonusAmount: 0,
        ),
        0,
      );
    });
  });

  group('ConfettiHelper.shouldShowWeeklyBonus', () {
    test('returns true when bonus > 0', () {
      expect(ConfettiHelper.shouldShowWeeklyBonus(120), true);
    });

    test('returns false when bonus is 0', () {
      expect(ConfettiHelper.shouldShowWeeklyBonus(0), false);
    });

    test('returns false when bonus is negative', () {
      expect(ConfettiHelper.shouldShowWeeklyBonus(-1), false);
    });
  });

  group('ConfettiHelper.calculateProgress', () {
    test('returns 0 when no checks', () {
      expect(
        ConfettiHelper.calculateProgress(checkedCount: 0, totalRequired: 7),
        0.0,
      );
    });

    test('returns 1 when all checked', () {
      expect(
        ConfettiHelper.calculateProgress(checkedCount: 7, totalRequired: 7),
        1.0,
      );
    });

    test('returns fraction for partial checks', () {
      expect(
        ConfettiHelper.calculateProgress(checkedCount: 3, totalRequired: 7),
        closeTo(0.4286, 0.001),
      );
    });

    test('returns 0 when totalRequired is 0', () {
      expect(
        ConfettiHelper.calculateProgress(checkedCount: 0, totalRequired: 0),
        0.0,
      );
    });

    test('handles overflow when checkedCount > totalRequired', () {
      final result = ConfettiHelper.calculateProgress(
        checkedCount: 10,
        totalRequired: 7,
      );
      expect(result, greaterThan(1.0));
    });
  });
}
