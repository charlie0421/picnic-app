import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/ui/style.dart';
import 'vote_item_request_models.dart';

/// 신청수 태그 위젯
class ApplicationCountTag extends StatelessWidget {
  final int applicationCount;

  const ApplicationCountTag({
    super.key,
    required this.applicationCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary500.withValues(alpha: 0.1),
                AppColors.primary500.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: AppColors.primary500.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.how_to_vote_rounded,
                size: 8.r,
                color: AppColors.primary500,
              ),
              SizedBox(width: 2.w),
              Text(
                ArtistNameUtils.formatNumber(applicationCount),
                style: getTextStyle(AppTypo.caption12B, AppColors.primary500),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 