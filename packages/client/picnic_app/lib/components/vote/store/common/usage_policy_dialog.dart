import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/common/bullet_point.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/number.dart';

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
                  style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                ),
                const SizedBox(height: 12),
                FutureBuilder(
                    future: ref.read(expireBonusProvider.future),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: snapshot.data!
                                .map((e) => Container(
                                      alignment: Alignment.center,
                                      width: 200.w,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 100.w,
                                            child: Text(
                                                '${e!['prediction_month']}-15',
                                                style: getTextStyle(
                                                    AppTypo.body16B,
                                                    AppColors.grey900)),
                                          ),
                                          SizedBox(width: 12.w),
                                          SizedBox(
                                            width: 36.w,
                                            child: Image.asset(
                                                'assets/icons/store/star_100.png',
                                                width: 36,
                                                height: 36),
                                          ),
                                          Text(
                                              formatNumberWithComma(
                                                      e['expiring_amount'] ?? 0)
                                                  .toString(),
                                              style: getTextStyle(
                                                  AppTypo.body16B,
                                                  AppColors.primary500)),
                                        ],
                                      ),
                                    ))
                                .toList());

                        // return Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     Image.asset('assets/icons/store/star_100.png',
                        //         width: 48.w, height: 48),
                        //     snapshot.data == null
                        //         ? Text(
                        //             '0',
                        //             style: getTextStyle(
                        //                 AppTypo.BODY16B, AppColors.Grey900),
                        //           )
                        //         : Text(
                        //             '${snapshot.data}',
                        //             style: getTextStyle(
                        //                 AppTypo.BODY16B, AppColors.Grey900),
                        //           ),
                        //   ],
                        // );
                      } else {
                        return const CircularProgressIndicator(
                            color: AppColors.primary500);
                      }
                    }),
                const SizedBox(height: 24),
                BulletPoint(
                  S.of(context).candy_usage_policy_contents,
                ),
                const SizedBox(height: 36),
                BulletPoint(
                  S.of(context).candy_usage_policy_contents2,
                ),
              ]),
            ),
          ));
}
