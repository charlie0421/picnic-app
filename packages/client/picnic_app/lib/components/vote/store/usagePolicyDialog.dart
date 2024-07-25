import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/common/bullet_point.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';

void showUsagePolicyDialog(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(48).r,
          topRight: const Radius.circular(48).r,
        ),
      ),
      builder: (context) => StatefulBuilder(
            builder: (context, setState) => Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 40.h),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  S.of(context).candy_disappear_next_month,
                  style: getTextStyle(AppTypo.BODY16B, AppColors.Grey900),
                ),
                SizedBox(height: 12.h),
                FutureBuilder(
                    future: ref.read(expireBonusProvider.future),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/icons/store/star_100.png',
                                width: 48.w, height: 48.w),
                            snapshot.data == null
                                ? Text(
                                    '0',
                                    style: getTextStyle(
                                        AppTypo.BODY16B, AppColors.Grey900),
                                  )
                                : Text(
                                    '${snapshot.data}',
                                    style: getTextStyle(
                                        AppTypo.BODY16B, AppColors.Grey900),
                                  ),
                          ],
                        );
                      } else {
                        return const CircularProgressIndicator(
                            color: AppColors.Primary500);
                      }
                    }),
                SizedBox(height: 24.h),
                BulletPoint(
                  S.of(context).candy_usage_policy_contents,
                ),
                SizedBox(height: 36.h),
                BulletPoint(
                  S.of(context).candy_usage_policy_contents2,
                ),
              ]),
            ),
          ));
}
