import 'dart:async';

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

class _AttendanceCheckTabState extends ConsumerState<AttendanceCheckTab> {
  bool _isCheckingIn = false;
  AttendanceCheckResult? _checkInResult;
  Timer? _resultTimer;

  @override
  void dispose() {
    _resultTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    if (_isCheckingIn) return;

    setState(() => _isCheckingIn = true);

    try {
      final result = await ref.read(attendanceProvider.notifier).checkIn();
      if (result != null && mounted) {
        setState(() => _checkInResult = result);
        ref.read(userInfoProvider.notifier).getUserProfiles();
        _resultTimer?.cancel();
        _resultTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _checkInResult = null);
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

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200, width: 1),
      ),
      child: attendanceAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
                child:
                    Icon(Icons.refresh, size: 18, color: AppColors.primary500),
              ),
            ],
          ),
        ),
        data: (state) {
          final weeklyStatus = state.weeklyStatus;
          if (weeklyStatus == null || !isLogged) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
              // Header row: title + progress + timer
              Row(
                children: [
                  Text(
                    l10n.label_attendance_check_in,
                    style: getTextStyle(AppTypo.caption12B, AppColors.grey900),
                  ),
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 6.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${weeklyStatus.checkedCount}/${weeklyStatus.totalRequired}',
                      style: getTextStyle(
                          AppTypo.caption10SB, AppColors.primary500),
                    ),
                  ),
                  const Spacer(),
                  if (state.deadlineKST != null)
                    AttendanceDeadlineTimer(
                      deadlineUTC: state.deadlineKST!,
                      label: '',
                      onDeadlineReached: () =>
                          ref.invalidate(attendanceProvider),
                    ),
                ],
              ),
              SizedBox(height: 2.h),
              // Reward info
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${l10n.label_attendance_check_in} +60  ',
                      style: getTextStyle(
                          AppTypo.caption10R, AppColors.grey400),
                    ),
                    TextSpan(
                      text:
                          '${l10n.label_attendance_weekly_bonus} +120 🎁',
                      style: getTextStyle(
                          AppTypo.caption10SB, const Color(0xFFF57C00)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),

              // Weekly Calendar
              AttendanceWeeklyCalendar(
                days: weeklyStatus.days,
                todayChecked: state.todayChecked,
                weeklyBonusEligible: weeklyStatus.isWeeklyBonusEligible,
                checkedCount: weeklyStatus.checkedCount,
                totalRequired: weeklyStatus.totalRequired,
              ),
              SizedBox(height: 10.h),

              // Check-in Button (full width)
              SizedBox(
                width: double.infinity,
                height: 36.h,
                child: ElevatedButton(
                  onPressed: state.todayChecked || _isCheckingIn
                      ? null
                      : _handleCheckIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.todayChecked
                        ? AppColors.grey100
                        : AppColors.primary500,
                    disabledBackgroundColor: AppColors.grey100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: state.todayChecked
                            ? AppColors.grey200
                            : Colors.transparent,
                      ),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                  ),
                  child: _isCheckingIn
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary500,
                          ),
                        )
                      : _checkInResult != null
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  package: 'picnic_lib',
                                  'assets/icons/store/star_100.png',
                                  width: 16.w,
                                  height: 16.w,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '+${_checkInResult!.totalReward}',
                                  style: getTextStyle(
                                      AppTypo.body14B, Colors.white),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!state.todayChecked) ...[
                                  Image.asset(
                                    package: 'picnic_lib',
                                    'assets/icons/store/star_100.png',
                                    width: 16.w,
                                    height: 16.w,
                                  ),
                                  SizedBox(width: 4.w),
                                ],
                                Text(
                                  state.todayChecked
                                      ? l10n.label_attendance_checked
                                      : l10n.label_attendance_check_in,
                                  style: getTextStyle(
                                    AppTypo.caption12B,
                                    state.todayChecked
                                        ? AppColors.grey400
                                        : Colors.white,
                                  ),
                                ),
                                if (!state.todayChecked) ...[
                                  SizedBox(width: 4.w),
                                  Text(
                                    '+60',
                                    style: getTextStyle(
                                        AppTypo.caption12B, Colors.white70),
                                  ),
                                ],
                              ],
                            ),
                ),
              ),

              // New user notice (compact)
              if (weeklyStatus.isNewUser) ...[
                SizedBox(height: 6.h),
                Text(
                  l10n.label_attendance_new_user_notice,
                  style: getTextStyle(AppTypo.caption10R, AppColors.primary500),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
