import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:prame_app/components/article/comment/comment_actions.dart';
import 'package:prame_app/components/article/comment/comment_contents.dart';
import 'package:prame_app/components/article/comment/comment_header.dart';
import 'package:prame_app/components/article/comment/comment_user.dart';
import 'package:prame_app/components/article/comment/report_popup_menu.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/comment.dart';
import 'package:prame_app/providers/comment_list_provider.dart';

class CommentItem extends ConsumerStatefulWidget {
  const CommentItem({
    super.key,
    required PagingController<int, CommentModel> pagingController,
    required this.commentModel,
    required this.articleId,
  }) : _pagingController = pagingController;

  final PagingController<int, CommentModel> _pagingController;
  final CommentModel commentModel;
  final int articleId;

  @override
  ConsumerState<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends ConsumerState<CommentItem> {
  TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20),
      margin: const EdgeInsets.only(bottom: 20),
      width: kIsWeb ? Constants.webMaxWidth : MediaQuery.of(context).size.width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommentUser(
            nickname: widget.commentModel.user?.nickname ?? '',
            profileImage: widget.commentModel.user?.profileImage ?? '',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CommentHeader(
                  item: widget.commentModel,
                  pagingController: widget._pagingController,
                ),
                CommentContents(item: widget.commentModel),
                CommentActions(
                  item: widget.commentModel,
                ),
              ],
            ),
          ),
          ReportPopupMenu(
              context: context,
              commentId: widget.commentModel.id,
              pagingController: widget._pagingController),
        ],
      ),
    );
  }

  _commitComment() {
    final parentItemState = ref.watch(parentItemProvider);

    ref
        .read(asyncCommentListProvider.notifier)
        .submitComment(
            articleId: widget.articleId,
            content: _textEditingController.text,
            parentId: parentItemState?.id)
        .then((value) {
      ref.read(parentItemProvider.notifier).setParentItem(null);
      widget._pagingController.refresh();
    });
    _textEditingController.clear();
  }
}
