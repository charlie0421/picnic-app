import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/vote/list/vote_header_countdown.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/ui/style.dart';

class VoteHeader extends StatelessWidget {
  final VoteModel vote;
  final VoidCallback? onRefresh;

  const VoteHeader({super.key, required this.vote, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 32.h,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Text(
                  vote.getTitle(),
                  style: getTextStyle(
                    AppTypo.BODY16B,
                    AppColors.Gray900,
                  ),
                ),
              ),
              Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: onRefresh,
                    child: SvgPicture.asset(
                      'assets/icons/vote/refresh.svg',
                      width: 20.w,
                      height: 20.h,
                    ),
                  )),
            ],
          ),
        ),
        SizedBox(
          width: 4.h,
        ),
        CountdownTimer(stopAt: vote.stop_at),
      ],
    );
  }
}
