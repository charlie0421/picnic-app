import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/article/comment/like_button.dart';
import 'package:picnic_app/models/fan/comment.dart';
import 'package:picnic_app/providers/comment_list_provider.dart';
import 'package:picnic_app/ui/style.dart';

class CommentActions extends ConsumerWidget {
  final CommentModel item;

  const CommentActions({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentComment = ref.watch(parentItemProvider);

    return InkWell(
      child: SizedBox(
        height: 40,
        child: item.parentId == null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      ref.read(parentItemProvider.notifier).setParentItem(item);
                    },
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Container(
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.only(
                        top: 5.h,
                        bottom: 10.h,
                      ),
                      child: Text(Intl.message('label_reply'),
                          style: getTextStyle(
                              context, AppTypo.UI16B, AppColors.Gray900)),
                    ),
                  ),
                  LikeButton(
                    commentId: item.id,
                    initialLikes: item.likes,
                    initiallyLiked: item.myLike != null,
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  LikeButton(
                    commentId: item.id,
                    initialLikes: item.likes,
                    initiallyLiked: item.myLike != null,
                  ),
                ],
              ),
      ),
    );
  }
}
