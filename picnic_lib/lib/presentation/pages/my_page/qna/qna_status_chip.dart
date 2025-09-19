import 'package:flutter/material.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/ui/style.dart';

class QnaStatusChip extends StatelessWidget {
  final String status; // expects 'RECEIVED' | 'IN_PROGRESS' | 'RESOLVED'
  final EdgeInsetsGeometry? padding;

  const QnaStatusChip({super.key, required this.status, this.padding});

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();
    late Color chipColor;
    late Color textColor;
    late String statusText;

    if (s == 'RESOLVED') {
      chipColor = AppColors.secondary500;
      textColor = AppColors.grey900;
      statusText = AppLocalizations.of(context).qna_status_resolved;
    } else if (s == 'IN_PROGRESS') {
      chipColor = AppColors.primary500;
      textColor = Colors.white;
      statusText = AppLocalizations.of(context).qna_status_in_progress;
    } else {
      // RECEIVED (접수): sub 계열 배경 + 진한 텍스트로 가독성 강화
      chipColor = AppColors.sub500;
      textColor = AppColors.grey900;
      statusText = AppLocalizations.of(context).qna_status_received;
    }

    return Chip(
      label: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: chipColor,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(width: 0.5, color: chipColor.withAlpha(102)),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
