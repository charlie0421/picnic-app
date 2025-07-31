import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/widgets/star_candy_info_text.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_detail_title.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart';
import 'package:picnic_lib/ui/style.dart';

class StorePointInfo extends ConsumerStatefulWidget {
  const StorePointInfo({
    super.key,
    required this.title,
    this.width = 48,
    this.height = 36,
    this.titlePadding,
  });

  final double? width;
  final double? height;
  final String title;
  final double? titlePadding;

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
          margin: EdgeInsets.only(top: 20, left: 16.w, right: 16.w),
          padding: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.primary500,
              width: 1.5.r,
            ),
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
              const StarCandyInfoText(),
              _starCandyBonusGuide(),
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

  Widget _starCandyBonusGuide() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          logger.d('보너스 캔디 소멸 로직 안내');
          showUsagePolicyDialog(context);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '보너스 캔디 소멸 로직 안내',
              style: getTextStyle(AppTypo.body14B, AppColors.primary500),
            ),
            const SizedBox(height: 2),
            Container(
              height: 0.5,
              width: double.infinity,
              color: AppColors.primary500,
            ),
          ],
        ),
      ),
    );
  }
}
