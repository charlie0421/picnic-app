import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_status_badge.dart';

class QnaCategoryChip extends StatelessWidget {
  final String label;

  const QnaCategoryChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        PicnicUi.horizontal(16),
        PicnicUi.vertical(12),
        PicnicUi.horizontal(16),
        0,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: PicnicStatusBadge(
          label: label,
          backgroundColor: AppColors.point500,
        ),
      ),
    );
  }
}
