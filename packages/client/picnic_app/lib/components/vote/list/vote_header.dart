import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/vote/list/countdown_timer.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';
import 'package:picnic_app/ui/style.dart';

class VoteHeader extends StatelessWidget {
  const VoteHeader({
    Key? key,
    required this.title,
    required this.stopAt,
    this.onRefresh,
    required this.status, // 새로운 파라미터 추가
  }) : super(key: key);

  final String title;
  final DateTime stopAt;
  final VoidCallback? onRefresh;
  final VoteStatus status;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
          height: 32.h,
          child: Stack(children: [
            Container(
              alignment: Alignment.center,
              child: Text(
                title,
                style: getTextStyle(
                  AppTypo.BODY16B,
                  AppColors.Grey900,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (status == VoteStatus.active)
              Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onRefresh,
                      child: SvgPicture.asset(
                        'assets/icons/reset_style=line.svg',
                        width: 20,
                        height: 20,
                      )))
          ])),
      CountdownTimer(
        endTime: stopAt,
        status: status,
      )
    ]);
  }
}
