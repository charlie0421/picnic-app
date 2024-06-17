import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/models/pic/comment.dart';
import 'package:picnic_app/providers/comment_list_provider.dart';
import 'package:picnic_app/ui/style.dart';

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
      color: AppColors.Grey300,
      width: double.infinity,
      height: 40.w,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                    text: '${parentComment.user?.nickname ?? ''} ',
                    style: getTextStyle(AppTypo.BODY14B, AppColors.Grey900)),
                TextSpan(
                    text: '님에게 답글을 남깁니다.',
                    style: getTextStyle(AppTypo.BODY14R, AppColors.Grey900)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(parentItemProvider.notifier).setParentItem(null);
            },
            iconSize: 20,
            icon: const Icon(Icons.close, color: AppColors.Grey900),
          ),
        ],
      ),
    );
  }
}
