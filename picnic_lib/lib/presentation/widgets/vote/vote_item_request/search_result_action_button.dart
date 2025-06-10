import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/ui/style.dart';

/// 검색 결과 액션 버튼 위젯
class SearchResultActionButton extends StatelessWidget {
  final bool shouldShowApplicationButton;
  final bool isSubmitting;
  final bool isAlreadyInVote;
  final String status;
  final VoidCallback onPressed;

  const SearchResultActionButton({
    super.key,
    required this.shouldShowApplicationButton,
    required this.isSubmitting,
    required this.isAlreadyInVote,
    required this.status,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (shouldShowApplicationButton) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary500,
              AppColors.primary500.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary500.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isSubmitting ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            minimumSize: Size(50.w, 24.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          child: isSubmitting
              ? SizedBox(
                  width: 12.w,
                  height: 12.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 12.r),
                    SizedBox(width: 3.w),
                    Text(
                      t('vote_item_request_submit'),
                      style: getTextStyle(AppTypo.caption12B, Colors.white),
                    ),
                  ],
                ),
        ),
      );
    } else if (isAlreadyInVote) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.grey300.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.grey400.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 10.r,
              color: AppColors.grey600,
            ),
            SizedBox(width: 3.w),
            Text(
              t('vote_item_request_already_registered'),
              style: getTextStyle(AppTypo.caption12B, AppColors.grey600),
            ),
          ],
        ),
      );
    } else if (status != t('vote_item_request_can_apply')) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: status == t('vote_item_request_status_pending')
              ? Colors.orange.withValues(alpha: 0.1)
              : status == t('vote_item_request_status_approved')
                  ? Colors.green.withValues(alpha: 0.1)
                  : AppColors.grey300.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: status == t('vote_item_request_status_pending')
                ? Colors.orange.withValues(alpha: 0.3)
                : status == t('vote_item_request_status_approved')
                    ? Colors.green.withValues(alpha: 0.3)
                    : AppColors.grey400.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          status,
          style: getTextStyle(
            AppTypo.caption12B,
            status == t('vote_item_request_status_pending')
                ? Colors.orange
                : status == t('vote_item_request_status_approved')
                    ? Colors.green
                    : AppColors.grey600,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
} 