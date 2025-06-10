import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/ui/style.dart';
import 'vote_item_request_models.dart';

/// 상태 배지 위젯
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = VoteRequestStatusUtils.getStatusText(status);
    final statusColor = VoteRequestStatusUtils.getStatusColor(status);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        statusText,
        style: getTextStyle(AppTypo.caption12B, statusColor),
      ),
    );
  }
} 