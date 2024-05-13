import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/models/vote/vote.dart';
import 'package:prame_app/ui/style.dart';

class VoteTitle extends StatelessWidget {
  final VoteModel vote;

  const VoteTitle({super.key, required this.vote});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.h,
      child: Row(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              vote.voteTitle,
              style: getTextStyle(
                context,
                AppTypo.UI24B,
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
                DateFormat('yyyy-MM-dd hh:mm:ss').format(vote.startAt),
                style: getTextStyle(
                  context,
                  AppTypo.UI12B,
                  AppColors.Gray900,
                ).copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                DateFormat('yyyy-MM-dd hh:mm:ss').format(vote.stopAt),
                style: getTextStyle(
                  context,
                  AppTypo.UI12B,
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
