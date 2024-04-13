import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:prame_app/components/article/comment/report_popup_menu.dart';
import 'package:prame_app/models/comment.dart';
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
    return Container(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text.rich(
            TextSpan(children: <TextSpan>[
              TextSpan(
                  text: '${item.user?.nickname} ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  )),
              TextSpan(text: formatTimeAgo(item.createdAt)),
            ]),
          ),
          ReportPopupMenu(
              context: context,
              commentId: item.id,
              pagingController: pagingController),
        ],
      ),
    );
  }
}
