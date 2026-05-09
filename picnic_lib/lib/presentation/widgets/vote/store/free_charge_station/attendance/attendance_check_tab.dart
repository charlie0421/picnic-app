import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/errors/anti_abuse_exception.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/attendance_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/anti_abuse/rate_limited_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/attendance/attendance_check_result_overlay.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/attendance/attendance_reward_banner.dart';
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
  String? _checkInError;
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

    setState(() {
      _isCheckingIn = true;
      _checkInError = null;
    });

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
        _scheduleResultClear();
      }
    } on AntiAbuseException catch (e) {
      if (mounted) {
        await showRateLimitedDialog(context, channel: e.channel);
      }
    } on AttendanceException catch (e) {
      if (mounted) {
        setState(() => _checkInError = _getErrorMessage(e.type));
        _scheduleErrorClear();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _checkInError = AppLocalizations.of(context).common_retry_label);
        _scheduleErrorClear();
      }
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  void _scheduleResultClear() {
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

  void _scheduleErrorClear() {
    _resultTimer?.cancel();
    _resultTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _checkInError = null);
    });
  }

  String _getErrorMessage(AttendanceErrorType type) {
    final l10n = AppLocalizations.of(context);
    switch (type) {
      case AttendanceErrorType.auth:
        return l10n.dialog_content_login_required;
      case AttendanceErrorType.network:
      case AttendanceErrorType.server:
      case AttendanceErrorType.unknown:
        return l10n.common_retry_label;
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
      error: (error, _) => _buildErrorView(error, l10n),
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
            _buildProgressHeader(weeklyStatus, state),
            SizedBox(height: 12.h),
            AttendanceWeeklyCalendar(
              days: weeklyStatus.days,
              todayChecked: state.todayChecked,
              weeklyBonusEligible: weeklyStatus.isWeeklyBonusEligible,
              checkedCount: weeklyStatus.checkedCount,
              totalRequired: weeklyStatus.totalRequired,
            ),
            SizedBox(height: 12.h),
            const AttendanceRewardBanner(),
            SizedBox(height: 14.h),
            if (_checkInResult != null)
              AttendanceCheckResultOverlay(
                result: _checkInResult!,
                fadeAnimation: _fadeAnimation,
                bounceAnimation: _bounceAnimation,
                confettiController: _confettiController,
                showConfetti: _showConfetti,
              ),
            _buildCheckInButton(state, l10n),
            if (_checkInError != null) ...[
              SizedBox(height: 6.h),
              Text(
                _checkInError!,
                style: getTextStyle(AppTypo.caption12R, Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
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

  Widget _buildErrorView(Object error, AppLocalizations l10n) {
    final isAuthError = error is AttendanceException &&
        error.type == AttendanceErrorType.auth;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isAuthError
                ? l10n.dialog_content_login_required
                : l10n.common_retry_label,
            style: getTextStyle(AppTypo.caption12R, AppColors.grey400),
          ),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: () => ref.invalidate(attendanceProvider),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh, size: 18, color: AppColors.primary500),
                SizedBox(width: 4.w),
                Text(
                  l10n.common_retry_label,
                  style: getTextStyle(AppTypo.caption12R, AppColors.primary500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(
    AttendanceWeeklyStatus weeklyStatus,
    AttendanceState state,
  ) {
    return Row(
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
    );
  }

  Widget _buildCheckInButton(AttendanceState state, AppLocalizations l10n) {
    return SizedBox(
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
    );
  }
}
