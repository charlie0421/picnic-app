import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/attendance_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/attendance/attendance_weekly_calendar.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/attendance/attendance_deadline_timer.dart';
import 'package:picnic_lib/ui/style.dart';

class AttendanceCheckTab extends ConsumerStatefulWidget {
  const AttendanceCheckTab({super.key});

  @override
  ConsumerState<AttendanceCheckTab> createState() => _AttendanceCheckTabState();
}

class _AttendanceCheckTabState extends ConsumerState<AttendanceCheckTab>
    with TickerProviderStateMixin {
  bool _isCheckingIn = false;
  AttendanceCheckResult? _checkInResult;
  Timer? _resultTimer;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _confettiController;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _resultTimer?.cancel();
    _bounceController.dispose();
    _fadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    if (_isCheckingIn) return;

    setState(() => _isCheckingIn = true);

    try {
      final result = await ref.read(attendanceProvider.notifier).checkIn();
      if (result != null && mounted) {
        setState(() {
          _checkInResult = result;
          _showConfetti = true;
        });
        _bounceController.forward(from: 0);
        _fadeController.forward(from: 0);
        _confettiController.forward(from: 0);
        ref.read(userInfoProvider.notifier).getUserProfiles();
        _resultTimer?.cancel();
        _resultTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _checkInResult = null;
              _showConfetti = false;
            });
          }
        });
      }
    } catch (_) {
      // Error is handled by provider
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final attendanceAsync = ref.watch(attendanceProvider);
    final userInfo = ref.watch(userInfoProvider);
    final isLogged = userInfo.value != null;

    return attendanceAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.common_retry_label,
              style: getTextStyle(AppTypo.caption12R, AppColors.grey400),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () => ref.invalidate(attendanceProvider),
              child: Icon(Icons.refresh, size: 18, color: AppColors.primary500),
            ),
          ],
        ),
      ),
      data: (state) {
        final weeklyStatus = state.weeklyStatus;
        if (weeklyStatus == null || !isLogged) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l10n.dialog_content_login_required,
              style: getTextStyle(AppTypo.caption12R, AppColors.grey500),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary500,
                        AppColors.primary500.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${weeklyStatus.checkedCount}/${weeklyStatus.totalRequired}',
                    style: getTextStyle(AppTypo.caption12B, Colors.white),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: weeklyStatus.checkedCount / weeklyStatus.totalRequired,
                      backgroundColor: AppColors.grey100,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
                      minHeight: 4,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                if (state.deadlineKST != null)
                  AttendanceDeadlineTimer(
                    deadlineUTC: state.deadlineKST!,
                    label: '',
                    onDeadlineReached: () => ref.invalidate(attendanceProvider),
                  ),
              ],
            ),
            SizedBox(height: 12.h),

            // Weekly Calendar
            AttendanceWeeklyCalendar(
              days: weeklyStatus.days,
              todayChecked: state.todayChecked,
              weeklyBonusEligible: weeklyStatus.isWeeklyBonusEligible,
              checkedCount: weeklyStatus.checkedCount,
              totalRequired: weeklyStatus.totalRequired,
            ),
            SizedBox(height: 12.h),

            // Reward info banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFF8E1),
                    const Color(0xFFFFF3E0),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE0B2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${l10n.label_attendance_check_in} ',
                        style: getTextStyle(AppTypo.caption12R, AppColors.grey600),
                      ),
                      Image.asset(
                        package: 'picnic_lib',
                        'assets/icons/store/bonus.png',
                        width: 16,
                        height: 16,
                      ),
                      Text(
                        ' +60',
                        style: getTextStyle(AppTypo.caption12B, AppColors.grey700),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${l10n.label_attendance_weekly_bonus} ',
                        style: getTextStyle(AppTypo.caption12R, AppColors.grey600),
                      ),
                      Image.asset(
                        package: 'picnic_lib',
                        'assets/icons/store/bonus.png',
                        width: 16,
                        height: 16,
                      ),
                      Text(
                        ' +120 ',
                        style: getTextStyle(AppTypo.caption12B, const Color(0xFFE65100)),
                      ),
                      const Text('🎁', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Check-in result animation with confetti
            if (_checkInResult != null)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _bounceAnimation,
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
                              '+${_checkInResult!.totalReward}',
                              style: getTextStyle(AppTypo.title18B, Colors.white),
                            ),
                            if (_checkInResult!.weeklyBonusAmount > 0) ...[
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${l10n.label_attendance_weekly_bonus} +${_checkInResult!.weeklyBonusAmount}',
                                  style: getTextStyle(AppTypo.caption10SB, Colors.white),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Confetti particles overlay
                  if (_showConfetti)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _confettiController,
                          builder: (context, _) => CustomPaint(
                            painter: _ConfettiPainter(
                              progress: _confettiController.value,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

            // Check-in Button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: state.todayChecked || _isCheckingIn
                      ? null
                      : LinearGradient(
                          colors: [AppColors.primary500, const Color(0xFFE91E63)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  color: state.todayChecked ? AppColors.grey100 : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: state.todayChecked
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.primary500.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: ElevatedButton(
                  onPressed: state.todayChecked || _isCheckingIn
                      ? null
                      : _handleCheckIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: state.todayChecked
                          ? BorderSide(color: AppColors.grey200)
                          : BorderSide.none,
                    ),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                  ),
                  child: _isCheckingIn
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary500,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!state.todayChecked) ...[
                              Image.asset(
                                package: 'picnic_lib',
                                'assets/icons/store/bonus.png',
                                width: 20.w,
                                height: 20.w,
                              ),
                              SizedBox(width: 6.w),
                            ],
                            Text(
                              state.todayChecked
                                  ? l10n.label_attendance_checked
                                  : l10n.label_attendance_check_in,
                              style: getTextStyle(
                                AppTypo.body16B,
                                state.todayChecked
                                    ? AppColors.grey400
                                    : Colors.white,
                              ),
                            ),
                            if (!state.todayChecked) ...[
                              SizedBox(width: 6.w),
                              Text(
                                '+60',
                                style: getTextStyle(
                                    AppTypo.body16B, Colors.white.withValues(alpha: 0.7)),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ),

            // New user notice
            if (weeklyStatus.isNewUser) ...[
              SizedBox(height: 8.h),
              Text(
                l10n.label_attendance_new_user_notice,
                style: getTextStyle(AppTypo.caption10R, AppColors.primary500),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Confetti particle painter for check-in celebration
class _ConfettiPainter extends CustomPainter {
  final double progress;
  static final List<_ConfettiParticle> _particles = List.generate(
    20,
    (i) => _ConfettiParticle(Random(i)),
  );

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in _particles) {
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final x = particle.startX * size.width;
      final y = -20 + (size.height + 40) * progress * particle.speed;
      final rotation = progress * particle.rotationSpeed * 6.28;

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
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ConfettiParticle {
  final double startX;
  final double speed;
  final double rotationSpeed;
  final double size;
  final Color color;
  final bool isCircle;

  _ConfettiParticle(Random rng)
      : startX = rng.nextDouble(),
        speed = 0.5 + rng.nextDouble() * 0.8,
        rotationSpeed = 0.5 + rng.nextDouble() * 2,
        size = 3 + rng.nextDouble() * 4,
        color = [
          const Color(0xFFA855F7), // purple
          const Color(0xFFEC4899), // pink
          const Color(0xFFF59E0B), // amber
          const Color(0xFF22C55E), // green
          const Color(0xFF3B82F6), // blue
          const Color(0xFFEF4444), // red
        ][rng.nextInt(6)],
        isCircle = rng.nextBool();
}
