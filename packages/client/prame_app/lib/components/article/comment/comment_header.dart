import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/components/article/comment/like_button.dart';
import 'package:prame_app/components/article/comment/report_popup_menu.dart';
import 'package:prame_app/models/comment.dart';
import 'package:prame_app/providers/comment_list_provider.dart';
import 'package:prame_app/util.dart';

class CommentActions extends ConsumerWidget {
  final CommentModel item;
  final PagingController<int, CommentModel> pagingController;
  final TextEditingController textEditingController;

  const CommentActions({
    super.key,
    required this.item,
    required this.textEditingController,
    required this.pagingController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      height: 30,
      margin: const EdgeInsets.only(left: 20, right: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                  onTap: () {
                    textEditingController.text = '@${item.user?.nickname} ';
                    ref.read(parentIdProvider.notifier).setParentId(item.id);
                  },
                  child: Text(
                    Intl.message('label_reply'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  )),
              LikeButton(
                commentId: item.id,
                initialLikes: item.likes,
                initiallyLiked: item.myLike != null,
              ),
              const SizedBox(width: 20),
              Text(formatTimeAgo(item.createdAt)),
            ],
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
