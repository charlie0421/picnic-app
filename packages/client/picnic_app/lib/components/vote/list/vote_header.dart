import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/vote/list/countdown_timer.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';
import 'package:picnic_app/ui/style.dart';

class VoteCardInfoHeader extends StatelessWidget {
  const VoteCardInfoHeader({
    super.key,
    required this.title,
    required this.stopAt,
    this.onRefresh,
    required this.status,
  });

  final String title;
  final DateTime stopAt;
  final VoidCallback? onRefresh;
  final VoteStatus status;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == VoteStatus.active)
          Container(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRefresh,
              child: Container(
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(10),
                child: SvgPicture.asset(
                  'assets/icons/reset_style=line.svg',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          alignment: Alignment.center,
          child: Text(
            title,
            style: getTextStyle(
              AppTypo.body16B,
              AppColors.grey900,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        CountdownTimer(
          endTime: stopAt,
          status: status,
          onRefresh: onRefresh,
        )
      ],
    );
  }
}
