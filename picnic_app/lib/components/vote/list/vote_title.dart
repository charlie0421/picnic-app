import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/ui/style.dart';

class VoteTitle extends StatelessWidget {
  final VoteModel vote;

  const VoteTitle({super.key, required this.vote});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      child: Row(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              vote.vote_title,
              style: getTextStyle(
                context,
                AppTypo.TITLE18B,
                AppColors.Gray900,
              ),
            ),
          ),
          SizedBox(
            width: 10.w,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('yyyy-MM-dd hh:mm:ss').format(vote.start_at),
                style: getTextStyle(
                  context,
                  AppTypo.CAPTION12M,
                  AppColors.Gray900,
                ).copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                DateFormat('yyyy-MM-dd hh:mm:ss').format(vote.stop_at),
                style: getTextStyle(
                  context,
                  AppTypo.CAPTION12M,
                  AppColors.Gray900,
                ).copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
