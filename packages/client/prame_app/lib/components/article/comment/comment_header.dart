import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:prame_app/models/prame/comment.dart';
import 'package:prame_app/ui/style.dart';
import 'package:prame_app/util.dart';

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
                  style:
                      getTextStyle(context, AppTypo.UI16B, AppColors.Gray900)),
              TextSpan(
                  text: formatTimeAgo(item.createdAt),
                  style:
                      getTextStyle(context, AppTypo.UI14M, AppColors.Gray900)),
            ]),
          ),
        ],
      ),
    );
  }
}
