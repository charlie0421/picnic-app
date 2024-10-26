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

class CommentActions extends ConsumerStatefulWidget {
  final CommentModel item;
  final String postId;
  final bool showReplyButton;
  final Function? openCommentsModal;
  final Function()? onLike;
  final Function()? onReply;

  const CommentActions({
    super.key,
    required this.item,
    required this.postId,
    this.showReplyButton = true,
    this.openCommentsModal,
    this.onLike,
    this.onReply,
  });

  @override
  ConsumerState<CommentActions> createState() => _CommentActionsState();
}

class _CommentActionsState extends ConsumerState<CommentActions> {
  bool _isTranslating = false;

  Widget _buildLikeButton() {
    return LikeButton(
      postId: widget.postId,
      commentId: widget.item.commentId,
      initialLikes: widget.item.likes,
      isLiked: widget.item.isLikedByMe ?? false,
      onLike: widget.onLike,
    );
  }

  Widget _buildReplyCounter() {
    if (widget.item.parentCommentId != null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(right: 16.cw),
      child: ReplyButton(
        comment: widget.item,
        initialReplies: widget.item.replies,
        isReplied: widget.item.isRepliedByMe ?? false,
        openCommentsModal: widget.openCommentsModal,
      ),
    );
  }

  Widget _buildReplyButton() {
    if (!widget.showReplyButton) return const SizedBox.shrink();

    return InkWell(
      onTap: () {
        ref.read(parentItemProvider.notifier).setParentItem(widget.item);
        widget.onReply?.call();
        logger.i('parentItemProvider: ${widget.item.commentId}');
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        alignment: Alignment.center,
        child: Text(
          S.of(context).label_reply,
          style: getTextStyle(AppTypo.caption12B, AppColors.grey500),
        ),
      ),
    );
  }

  Widget _buildTranslateButton(String currentLocale) {
    if (_isTranslating) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.grey500),
        ),
      );
    }

    return InkWell(
      onTap: () => _handleTranslation(currentLocale),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        alignment: Alignment.center,
        child: Text(
          S.of(context).post_comment_action_translate,
          style: getTextStyle(AppTypo.caption12B, AppColors.grey500),
        ),
      ),
    );
  }

  Future<void> _handleTranslation(String currentLocale) async {
    if (_isTranslating) return;

    setState(() {
      _isTranslating = true;
    });

    try {
      final translationService = DeepLTranslationService(
        apiKey: 'ef2715c3-89d7-4b1b-a95b-e1fd3b7d734e:fx',
      );

      logger.i(
          'item.content![item.locale]!: ${widget.item.content![widget.item.locale]!}');

      final translatedText = await translationService.translateText(
        widget.item.content![widget.item.locale]!,
        widget.item.locale!,
        currentLocale,
      );

      if (!mounted) return;

      final translationNotifier = ref.read(
        commentTranslationNotifierProvider.notifier,
      );

      await translationNotifier.updateTranslation(
        widget.item.commentId,
        currentLocale,
        translatedText,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).post_comment_translate_complete),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // ref.refresh(commentListProvider);
    } catch (e, s) {
      logger.e('Translation error:', error: e, stackTrace: s);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).post_comment_translate_fail),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTranslating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final isDifferentLanguage = currentLocale != widget.item.locale;
    final isNotExistTransText = widget.item.content![currentLocale] == null;

    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildLikeButton(),
          SizedBox(width: 16.cw),
          _buildReplyCounter(),
          _buildReplyButton(),
          if (isDifferentLanguage && isNotExistTransText) ...[
            SizedBox(width: 16.cw),
            _buildTranslateButton(currentLocale),
          ],
        ],
      ),
    );
  }
}
