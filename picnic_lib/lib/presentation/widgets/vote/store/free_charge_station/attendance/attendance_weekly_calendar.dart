import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/presentation/providers/attendance_provider.dart';
import 'package:picnic_lib/ui/style.dart';

class AttendanceWeeklyCalendar extends StatelessWidget {
  final List<AttendanceDayStatus> days;
  final bool todayChecked;
  final bool weeklyBonusEligible;
  final int checkedCount;
  final int totalRequired;

  static const _dayLabelsKo = ['월', '화', '수', '목', '금', '토', '일'];

  const AttendanceWeeklyCalendar({
    super.key,
    required this.days,
    required this.todayChecked,
    required this.weeklyBonusEligible,
    required this.checkedCount,
    required this.totalRequired,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (i) {
        if (i >= days.length) return const SizedBox.shrink();
        final day = days[i];
        final isSunday = day.dayOfWeek == 6;
        final isToday = day.isToday;
        final checked = day.checked || (isToday && todayChecked);
        final isPast = !day.isFuture && !isToday && !checked;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 1.5.w),
            child: _DayCell(
              label: _dayLabelsKo[i],
              checked: checked,
              isToday: isToday,
              isPast: isPast,
              isSunday: isSunday,
              weeklyBonusEligible: weeklyBonusEligible,
            ),
          ),
        );
      }),
    );
  }
}

class _DayCell extends StatelessWidget {
  final String label;
  final bool checked;
  final bool isToday;
  final bool isPast;
  final bool isSunday;
  final bool weeklyBonusEligible;

  const _DayCell({
    required this.label,
    required this.checked,
    required this.isToday,
    required this.isPast,
    required this.isSunday,
    required this.weeklyBonusEligible,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    double borderWidth = 1;

    if (checked) {
      bgColor = AppColors.primary500.withValues(alpha: 0.1);
      borderColor = AppColors.primary500.withValues(alpha: 0.4);
      borderWidth = 1.5;
    } else if (isToday) {
      bgColor = Colors.white;
      borderColor = AppColors.primary500;
      borderWidth = 1.5;
    } else if (isSunday) {
      bgColor = const Color(0xFFFFF8E1);
      borderColor = const Color(0xFFFFE082).withValues(alpha: 0.6);
    } else if (isPast) {
      bgColor = AppColors.grey100;
      borderColor = AppColors.grey200;
    } else {
      bgColor = AppColors.grey100;
      borderColor = AppColors.grey100;
    }

    final cell = Container(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Day label
          Text(
            label,
            style: getTextStyle(
              checked || isToday ? AppTypo.caption10SB : AppTypo.caption10R,
              isSunday
                  ? const Color(0xFFE65100)
                  : isToday
                      ? AppColors.primary500
                      : checked
                          ? AppColors.primary500
                          : AppColors.grey400,
            ),
          ),
          SizedBox(height: 2.h),

          // Status icon
          SizedBox(
            height: 18.h,
            child: Center(
              child: checked
                  ? Image.asset(
                      package: 'picnic_lib',
                      'assets/icons/store/star_100.png',
                      width: 16.w,
                      height: 16.w,
                    )
                  : isToday
                      ? Container(
                          width: 16.w,
                          height: 16.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary500,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 5.w,
                              height: 5.w,
                              decoration: BoxDecoration(
                                color: AppColors.primary500,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        )
                      : isPast
                          ? Icon(Icons.remove,
                              color: AppColors.grey300, size: 14.w)
                          : isSunday
                              ? Text('🎁', style: TextStyle(fontSize: 12.sp))
                              : Icon(Icons.remove,
                                  color: AppColors.grey200, size: 12.w),
            ),
          ),
          SizedBox(height: 1.h),

          // Point label
          Text(
            '+60',
            style: getTextStyle(
              AppTypo.caption10R,
              checked
                  ? AppColors.primary500
                  : isToday
                      ? AppColors.primary500.withValues(alpha: 0.7)
                      : isSunday
                          ? const Color(0xFFF57C00)
                          : isPast
                              ? AppColors.grey300
                              : AppColors.grey300,
            ),
          ),
        ],
      ),
    );

    if (!isSunday) return cell;

    // Sunday: wrap with x2 badge
    return Stack(
      clipBehavior: Clip.none,
      children: [
        cell,
        Positioned(
          top: -4.h,
          right: -2.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6D00),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'x2',
              style: getTextStyle(AppTypo.caption10SB, Colors.white)
                  .copyWith(fontSize: 9.sp, height: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
