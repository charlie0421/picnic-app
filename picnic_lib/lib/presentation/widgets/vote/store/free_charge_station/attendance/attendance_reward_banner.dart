import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/ui/style.dart';

/// 출석체크 보상 안내 배너
class AttendanceRewardBanner extends StatelessWidget {
  const AttendanceRewardBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
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
              const Text('\u{1F381}', style: TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
