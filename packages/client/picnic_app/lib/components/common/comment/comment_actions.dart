import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/common/comment/like_button.dart';
import 'package:picnic_app/components/common/comment/reply_button.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/providers/comment_list_provider.dart';
import 'package:picnic_app/providers/community/comments_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/deepl_translate_service.dart';
import 'package:picnic_app/util/logger.dart';
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
    final currentLocale = Localizations.localeOf(context).languageCode;
    final isDifferentLanguage =
        item.content != null && item.content![currentLocale] == null;

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
              if (isDifferentLanguage)
                InkWell(
                  onTap: () async {
                    final translationService = DeepLTranslationService(
                        apiKey: 'ef2715c3-89d7-4b1b-a95b-e1fd3b7d734e:fx');
                    logger.i(
                        'item.content!.keys.first: ${item.content!.keys.first}');
                    logger.i(
                        'item.content!.values.first: ${item.content!.values.first}');
                    logger.i('currentLocale: $currentLocale');
                    final translatedText =
                        await translationService.translateText(
                      item.content![item.locale]!,
                      item.content![item.locale],
                      // Assuming the first value is the original text
                      Localizations.localeOf(context).languageCode,
                    );
                    await updateCommentTranslation(
                      ref,
                      item.commentId,
                      currentLocale,
                      translatedText,
                    );
                    // ref.refresh(commentListProvider);
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Container(
                    alignment: Alignment.center,
                    child: Text('번역',
                        style: getTextStyle(
                            AppTypo.caption12B, AppColors.grey500)),
                  ),
                ),
            ],
          )),
    );
  }
}
