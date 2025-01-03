import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/presentation/providers/comment_list_provider.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/core/utils/ui.dart';

class CommentReplyLayer extends ConsumerWidget {
  const CommentReplyLayer({
    super.key,
    required PagingController<int, CommentModel> pagingController,
    required this.parentComment,
  });

  final CommentModel parentComment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.primary500,
      width: double.infinity,
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: 10.cw),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
              Intl.message('post_replying_comment',
                  args: [parentComment.user?.nickname ?? '']),
              style: getTextStyle(AppTypo.caption12B, AppColors.grey00)),
          IconButton(
            onPressed: () {
              ref.read(parentItemProvider.notifier).setParentItem(null);
            },
            iconSize: 20,
            icon: const Icon(Icons.close, color: AppColors.grey00),
          ),
        ],
      ),
    );
  }
}
