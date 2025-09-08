import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';

import 'package:picnic_lib/presentation/widgets/star_candy_info_text.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_detail_title.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart';
import 'package:picnic_lib/presentation/common/underlined_text.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/supabase_options.dart';

class StorePointInfo extends ConsumerStatefulWidget {
  const StorePointInfo({
    super.key,
    required this.title,
    this.width = 48,
    this.height = 36,
    this.titlePadding,
    this.topMargin = 20,
  });

  final double? width;
  final double? height;
  final String title;
  final double? titlePadding;
  final double topMargin;

  @override
  ConsumerState<StorePointInfo> createState() => _StorePointInfoState();
}

class _StorePointInfoState extends ConsumerState<StorePointInfo> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: widget.height,
          width: widget.width,
          margin: EdgeInsets.only(
            top: widget.topMargin,
            left: 16.w,
            right: 16.w,
          ),
          padding: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary500, width: 1.5.r),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(40.r),
              topRight: Radius.circular(40.r),
              bottomLeft: Radius.circular(40.r),
              bottomRight: Radius.circular(40.r),
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSupabaseLoggedSafely) ...[
                const StarCandyInfoText(),
                GestureDetector(
                  onTap: () {
                    logger.d('보너스 캔디 소멸 로직 안내');
                    showUsagePolicyDialog(context);
                  },
                  child: UnderlinedText(
                    text: AppLocalizations.of(
                      context,
                    ).expiring_bonus_candy_guide,
                    textStyle: getTextStyle(
                      AppTypo.caption12B,
                      AppColors.primary500,
                    ),
                    underlineColor: AppColors.primary500,
                    underlineGap: 0,
                  ),
                ),
              ] else ...[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    logger.d('로그인 필요 다이얼로그 표시');
                    showRequireLoginDialog();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: UnderlinedText(
                      text: AppLocalizations.of(
                        context,
                      ).label_mypage_should_login,
                      textStyle: getTextStyle(
                        AppTypo.body14M,
                        AppColors.primary500,
                      ),
                      underlineColor: AppColors.primary500,
                      underlineGap: 0,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    logger.d('보너스 캔디 소멸 로직 안내');
                    showUsagePolicyDialog(context);
                  },
                  child: UnderlinedText(
                    text: AppLocalizations.of(
                      context,
                    ).expiring_bonus_candy_guide,
                    textStyle: getTextStyle(
                      AppTypo.caption12B,
                      AppColors.primary500,
                    ),
                    underlineColor: AppColors.primary500,
                    underlineGap: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              alignment: Alignment.topCenter,
              padding: EdgeInsets.symmetric(horizontal: 33.w),
              child: VoteCommonTitle(title: widget.title),
            ),
          ),
        ),
      ],
    );
  }
}
