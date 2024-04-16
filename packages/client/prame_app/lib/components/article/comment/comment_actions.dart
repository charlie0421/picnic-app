import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/components/article/comment/like_button.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/comment.dart';
import 'package:prame_app/providers/comment_list_provider.dart';
import 'package:prame_app/ui/style.dart';

class CommentActions extends ConsumerWidget {
  final CommentModel item;
  final TextEditingController textEditingController;

  const CommentActions({
    super.key,
    required this.item,
    required this.textEditingController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                          style:
                              getTextStyle(AppTypo.UI16B, AppColors.Gray900)),
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
