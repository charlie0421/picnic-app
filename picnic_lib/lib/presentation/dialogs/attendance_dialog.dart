import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/util.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/attendance/attendance_check_tab.dart';
import 'package:picnic_lib/ui/style.dart';

void showAttendanceDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => const AttendanceDialog(),
  );
}

class AttendanceDialog extends ConsumerWidget {
  const AttendanceDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final userInfo = ref.watch(userInfoProvider);
    final starCandy = userInfo.value?.starCandy ?? 0;
    final starCandyBonus = userInfo.value?.starCandyBonus ?? 0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient background
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary500,
                    AppColors.primary500.withValues(alpha: 0.75),
                    const Color(0xFFE91E63).withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -10,
                    bottom: -15,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 20.h),
                    child: Column(
                      children: [
                        // Title + close button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.label_attendance_check,
                              style: getTextStyle(AppTypo.title18B, Colors.white),
                            ),
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                                onPressed: () => Navigator.of(context).pop(),
                                padding: EdgeInsets.zero,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),

                        // Star candy balances
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Star candy
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Image.asset(
                                      package: 'picnic_lib',
                                      'assets/icons/store/star_candy.png',
                                      width: 40,
                                      height: 40,
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      l10n.jma_voting_my_star_candy,
                                      style: getTextStyle(AppTypo.caption12R, Colors.white70),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      numberFormatter.format(starCandy),
                                      style: getTextStyle(AppTypo.title18B, Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              // Divider
                              Center(
                                child: Container(
                                  width: 1,
                                  height: 48,
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              // Bonus
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Image.asset(
                                      package: 'picnic_lib',
                                      'assets/icons/store/bonus.png',
                                      width: 40,
                                      height: 40,
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      l10n.label_bonus,
                                      style: getTextStyle(AppTypo.caption12R, Colors.white70),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      numberFormatter.format(starCandyBonus),
                                      style: getTextStyle(AppTypo.title18B, Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Attendance section
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: const AttendanceCheckTab(),
            ),

            // KST notice
            Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Text(
                l10n.label_attendance_kst_notice,
                style: getTextStyle(AppTypo.caption10R, AppColors.grey400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
