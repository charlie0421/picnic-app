import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/vote/list/vote_header_countdown.dart';
import 'package:picnic_app/ui/style.dart';

class VoteHeader extends StatelessWidget {
  final String title;
  final DateTime stopAt;

  final VoidCallback? onRefresh;

  const VoteHeader(
      {super.key, required this.title, this.onRefresh, required this.stopAt});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 32.w,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Text(
                  title,
                  style: getTextStyle(
                    AppTypo.BODY16B,
                    AppColors.Grey900,
                  ),
                ),
              ),
              Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onRefresh,
                    child: SvgPicture.asset(
                      'assets/icons/reset_style=line.svg',
                      width: 20.w,
                      height: 20.w,
                    ),
                  )),
            ],
          ),
        ),
        SizedBox(
          width: 4.w,
        ),
        CountdownTimer(stopAt: stopAt),
      ],
    );
  }
}
