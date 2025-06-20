import 'package:flutter/material.dart';
import 'package:picnic_lib/core/utils/date.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/ui/style.dart';

class CommentHeader extends StatelessWidget {
  final CommentModel item;

  const CommentHeader({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text.rich(
            TextSpan(children: <TextSpan>[
              TextSpan(
                  text: '${item.user?.nickname} ',
                  style:
                      getTextStyle(AppTypo.caption12B, AppColors.primary500)),
              TextSpan(
                  text: formatTimeAgo(context, item.createdAt),
                  style: getTextStyle(AppTypo.caption10SB, AppColors.grey400)),
            ]),
          ),
        ],
      ),
    );
  }
}
