import 'package:flutter/material.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_status_badge.dart';
import 'package:picnic_lib/ui/style.dart';

class QnaStatusChip extends StatelessWidget {
  final String status; // expects 'RECEIVED' | 'IN_PROGRESS' | 'RESOLVED'
  final EdgeInsetsGeometry? padding;

  const QnaStatusChip({super.key, required this.status, this.padding});

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();
    late Color chipColor;
    late String statusText;

    if (s == 'RESOLVED') {
      chipColor = AppColors.secondary500;
      statusText = AppLocalizations.of(context).qna_status_resolved;
    } else if (s == 'IN_PROGRESS') {
      chipColor = AppColors.primary500;
      statusText = AppLocalizations.of(context).qna_status_in_progress;
    } else {
      // RECEIVED (접수): sub 계열 배경 + 진한 텍스트로 가독성 강화
      chipColor = AppColors.sub500;
      statusText = AppLocalizations.of(context).qna_status_received;
    }

    return PicnicStatusBadge(
      label: statusText,
      backgroundColor: chipColor,
      padding: padding,
    );
  }
}
