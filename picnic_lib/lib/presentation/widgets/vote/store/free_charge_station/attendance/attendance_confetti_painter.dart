import 'package:flutter/material.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/attendance/confetti_helper.dart';

/// Confetti particle painter for check-in celebration
class AttendanceConfettiPainter extends CustomPainter {
  final double progress;
  static final List<ConfettiParticle> _particles =
      ConfettiHelper.generateParticles(20);

  AttendanceConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in _particles) {
      final opacity = ConfettiHelper.calculateOpacity(progress);
      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final x = ConfettiHelper.calculateX(
        startX: particle.startX,
        width: size.width,
      );
      final y = ConfettiHelper.calculateY(
        progress: progress,
        speed: particle.speed,
        height: size.height,
      );
      final rotation = ConfettiHelper.calculateRotation(
        progress: progress,
        rotationSpeed: particle.rotationSpeed,
      );

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      if (particle.isCircle) {
        canvas.drawCircle(Offset.zero, particle.size, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size * 1.5,
            height: particle.size,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(AttendanceConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
