import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/comment/like_button.dart';
import 'package:picnic_lib/presentation/common/comment/reply_button.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';

class CommentActions extends StatelessWidget {
  final CommentModel item;
  final String postId;
  final bool showReplyButton;
  final Function? openCommentsModal;
  final Function()? onLike;
  final Function()? onReply;
  final bool isTranslating;
  final bool isTranslated;
  final bool showOriginal;
  final Function(String)? onTranslate;
  final Function()? onToggleOriginal;

  const CommentActions({
    super.key,
    required this.item,
    required this.postId,
    this.showReplyButton = true,
    this.openCommentsModal,
    this.onLike,
    this.onReply,
    required this.isTranslating,
    required this.isTranslated,
    required this.showOriginal,
    this.onTranslate,
    this.onToggleOriginal,
  });

  Widget _buildLikeButton() {
    return LikeButton(
      postId: postId,
      commentId: item.commentId,
      initialLikes: item.likes,
      isLiked: item.isLikedByMe ?? false,
      onLike: onLike,
    );
  }

  Widget _buildReplyCounter(BuildContext context) {
    if (item.parentCommentId != null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(right: 16.w),
      child: ReplyButton(
        comment: item,
        initialReplies: item.replies,
        isReplied: item.isRepliedByMe ?? false,
        openCommentsModal: openCommentsModal,
      ),
    );
  }

  Widget _buildReplyButton(BuildContext context) {
    if (!showReplyButton) return const SizedBox.shrink();

    return InkWell(
      onTap: onReply,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        alignment: Alignment.center,
        child: Text(
          AppLocalizations.of(context).label_reply,
          style: getTextStyle(AppTypo.caption12B, AppColors.grey500),
        ),
      ),
    );
  }

  Widget _buildTranslateButton(BuildContext context) {
    if (isTranslating) {
      return SizedBox(
        width: 12,
        height: 12,
        child: SmallPulseLoadingIndicator(),
      );
    }

    final currentLocale = Localizations.localeOf(context).languageCode;
    final commentLocale = item.locale ?? 'ko';

    // 현재 언어와 댓글 원문 언어가 같으면 번역 버튼을 보여주지 않음
    if (currentLocale == commentLocale) {
      return const SizedBox.shrink();
    }

    final hasTranslation = item.content!.containsKey(currentLocale);

    if (hasTranslation) {
      // 이미 번역이 있거나 번역이 완료된 경우
      return InkWell(
        onTap: onToggleOriginal,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          alignment: Alignment.center,
          child: Text(
            showOriginal
                ? AppLocalizations.of(context)
                    .post_comment_action_show_translation
                : AppLocalizations.of(context)
                    .post_comment_action_show_original,
            style: getTextStyle(AppTypo.caption12B, AppColors.grey500),
          ),
        ),
      );
    }

    // 번역이 아직 없는 경우
    return InkWell(
      onTap: () => onTranslate?.call(currentLocale),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        alignment: Alignment.center,
        child: Text(
          AppLocalizations.of(context).post_comment_action_translate,
          style: getTextStyle(AppTypo.caption12B, AppColors.grey500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final commentLocale = item.locale ?? 'ko';
    final isDifferentLanguage = currentLocale != commentLocale;

    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildLikeButton(),
          SizedBox(width: 16.w),
          _buildReplyCounter(context),
          _buildReplyButton(context),
          if (isDifferentLanguage) ...[
            SizedBox(width: 16.w),
            _buildTranslateButton(context),
          ],
        ],
      ),
    );
  }
}
