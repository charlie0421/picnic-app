import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/ui/style.dart';

class VoteDetailTitle extends StatelessWidget {
  final VoteModel voteModel;

  const VoteDetailTitle({
    super.key,
    required this.voteModel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 48.h,
        padding: const EdgeInsets.symmetric(horizontal: 16).r,
        decoration: BoxDecoration(
            color: AppColors.Mint500,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.Primary500,
              width: 1.5,
            )),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SvgPicture.asset(
              'assets/icons/vote/vote-title-left.svg',
              width: 16.w,
              height: 16.h,
            ),
            Center(
              child: SizedBox(
                height: 24.h,
                child: Stack(
                  children: [
                    Text(voteModel.vote_title ?? '',
                        style: getTextStyle(
                                context, AppTypo.BODY16M, AppColors.Primary500)
                            .copyWith(
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 1
                                  ..color = AppColors.Primary500
                                  ..strokeJoin = StrokeJoin.miter
                                  ..strokeMiterLimit = 28.96)),
                    Text(voteModel?.vote_title ?? '',
                        style: getTextStyle(
                            context, AppTypo.BODY16M, AppColors.Gray00)),
                  ],
                ),
              ),
            ),
            SvgPicture.asset(
              'assets/icons/vote/vote-title-right.svg',
              width: 16.w,
              height: 16.w,
            ),
          ],
        ));
  }
}
