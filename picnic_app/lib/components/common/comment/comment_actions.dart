import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/common/comment/like_button.dart';
import 'package:picnic_app/components/common/comment/reply_button.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/providers/comment_list_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

class CommentActions extends ConsumerWidget {
  final CommentModel item;
  final bool showReplyButton;
  final Function? openCommentsModal;

  const CommentActions({
    super.key,
    required this.item,
    this.showReplyButton = true,
    required this.openCommentsModal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      child: SizedBox(
          height: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              LikeButton(
                commentId: item.commentId,
                initialLikes: item.likes,
                isLiked: item.isLiked ?? false,
              ),
              SizedBox(width: 16.cw),
              if (item.parentCommentId == null)
                Container(
                  margin: EdgeInsets.only(right: 16.cw),
                  child: ReplyButton(
                    comment: item,
                    initialReplies: item.replies,
                    isReplied: item.isReplied ?? false,
                    openCommentsModal: openCommentsModal,
                  ),
                ),
              if (showReplyButton)
                InkWell(
                  onTap: () {
                    ref.read(parentItemProvider.notifier).setParentItem(item);
                    logger.i('parentItemProvider: ${item.commentId}');
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(S.of(context).label_reply,
                        style: getTextStyle(
                            AppTypo.caption12B, AppColors.grey500)),
                  ),
                ),
            ],
          )),
    );
  }
}
