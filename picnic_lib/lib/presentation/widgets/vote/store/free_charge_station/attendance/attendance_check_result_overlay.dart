import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/attendance_models.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/attendance/attendance_confetti_painter.dart';
import 'package:picnic_lib/ui/style.dart';

/// 출석체크 완료 시 보상 애니메이션 오버레이
class AttendanceCheckResultOverlay extends StatelessWidget {
  final AttendanceCheckResult result;
  final Animation<double> fadeAnimation;
  final Animation<double> bounceAnimation;
  final AnimationController confettiController;
  final bool showConfetti;

  const AttendanceCheckResultOverlay({
    super.key,
    required this.result,
    required this.fadeAnimation,
    required this.bounceAnimation,
    required this.confettiController,
    required this.showConfetti,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: bounceAnimation,
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary500, const Color(0xFFE91E63)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary500.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    package: 'picnic_lib',
                    'assets/icons/store/bonus.png',
                    width: 20,
                    height: 20,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    '+${result.totalReward}',
                    style: getTextStyle(AppTypo.title18B, Colors.white),
                  ),
                  if (result.weeklyBonusAmount > 0) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${l10n.label_attendance_weekly_bonus} +${result.weeklyBonusAmount}',
                        style: getTextStyle(AppTypo.caption10SB, Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (showConfetti)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: confettiController,
                builder: (context, _) => CustomPaint(
                  painter: AttendanceConfettiPainter(
                    progress: confettiController.value,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
