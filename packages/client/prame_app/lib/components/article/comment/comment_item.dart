import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:prame_app/components/article/comment/comment_actions.dart';
import 'package:prame_app/components/article/comment/comment_contents.dart';
import 'package:prame_app/components/article/comment/comment_header.dart';
import 'package:prame_app/components/article/comment/comment_user.dart';
import 'package:prame_app/components/article/comment/report_popup_menu.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/comment.dart';

class CommentItem extends StatelessWidget {
  const CommentItem({
    super.key,
    required PagingController<int, CommentModel> pagingController,
    required TextEditingController textEditingController,
    required this.commentModel,
  })  : _pagingController = pagingController,
        _textEditingController = textEditingController;

  final PagingController<int, CommentModel> _pagingController;
  final TextEditingController _textEditingController;
  final CommentModel commentModel;

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
            nickname: commentModel.user?.nickname ?? '',
            profileImage: commentModel.user?.profileImage ?? '',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CommentHeader(
                  item: commentModel,
                  pagingController: _pagingController,
                ),
                CommentContents(item: commentModel),
                CommentActions(
                  item: commentModel,
                  textEditingController: _textEditingController,
                ),
              ],
            ),
          ),
          ReportPopupMenu(
              context: context,
              commentId: commentModel.id,
              pagingController: _pagingController),
        ],
      ),
    );
  }
}
