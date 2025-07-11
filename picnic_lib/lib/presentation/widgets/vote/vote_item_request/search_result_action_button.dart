import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
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
                  child: SmallPulseLoadingIndicator(),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 12.r),
                    SizedBox(width: 3.w),
                    Text(
                      AppLocalizations.of(context).vote_item_request_submit,
                      style: getTextStyle(AppTypo.caption12B, Colors.white),
                    ),
                  ],
                ),
        ),
      );
    } else if (isAlreadyInVote) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.check_circle_rounded,
          size: 16.r,
          color: Colors.green,
        ),
      );
    } else if (status !=
        AppLocalizations.of(context).vote_item_request_can_apply) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: status ==
                  AppLocalizations.of(context).vote_item_request_status_pending
              ? Colors.orange.withValues(alpha: 0.1)
              : status ==
                      AppLocalizations.of(context)
                          .vote_item_request_status_approved
                  ? Colors.green.withValues(alpha: 0.1)
                  : AppColors.grey300.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: status ==
                    AppLocalizations.of(context)
                        .vote_item_request_status_pending
                ? Colors.orange.withValues(alpha: 0.3)
                : status ==
                        AppLocalizations.of(context)
                            .vote_item_request_status_approved
                    ? Colors.green.withValues(alpha: 0.3)
                    : AppColors.grey400.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status ==
                AppLocalizations.of(context).vote_item_request_waiting) ...[
              Icon(
                Icons.schedule_rounded,
                size: 10.r,
                color: Colors.orange,
              ),
              SizedBox(width: 3.w),
            ] else if (status ==
                AppLocalizations.of(context)
                    .vote_item_request_status_approved) ...[
              Icon(
                Icons.check_circle_rounded,
                size: 10.r,
                color: Colors.green,
              ),
              SizedBox(width: 3.w),
            ],
            Text(
              status,
              style: getTextStyle(
                AppTypo.caption12B,
                status == AppLocalizations.of(context).vote_item_request_waiting
                    ? Colors.orange
                    : status ==
                            AppLocalizations.of(context)
                                .vote_item_request_status_approved
                        ? Colors.green
                        : AppColors.grey600,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
