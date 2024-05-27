import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/models/fan/comment.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';

class CommentHeader extends StatelessWidget {
  final CommentModel item;
  final PagingController<int, CommentModel> pagingController;

  const CommentHeader({
    super.key,
    required this.item,
    required this.pagingController,
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
                  style: getTextStyle(
                      context, AppTypo.BODY16B, AppColors.Gray900)),
              TextSpan(
                  text: formatTimeAgo(item.created_at),
                  style: getTextStyle(
                      context, AppTypo.BODY14M, AppColors.Gray900)),
            ]),
          ),
        ],
      ),
    );
  }
}
