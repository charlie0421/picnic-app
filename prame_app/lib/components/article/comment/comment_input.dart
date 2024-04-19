import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/comment.dart';
import 'package:prame_app/providers/article_list_provider.dart';
import 'package:prame_app/providers/comment_list_provider.dart';
import 'package:prame_app/ui/style.dart';

class CommentInput extends ConsumerStatefulWidget {
  const CommentInput(
      {required this.articleId, required this.pagingController, super.key});

  final int articleId;
  final PagingController<int, CommentModel> pagingController;

  @override
  ConsumerState<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends ConsumerState<CommentInput> {
  final _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      width: kIsWeb ? Constants.webMaxWidth : MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SizedBox(
              height: 60,
              child: TextFormField(
                  controller: _textEditingController,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: Intl.message('label_hint_comment'),
                    hintStyle: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.Gray400,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: const BorderSide(
                        color: AppColors.Gray300,
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.only(left: 10),
                    suffixIcon: Container(
                      // alignment: Alignment.bottomRight,
                      padding: EdgeInsets.only(top: 30.h),
                      child: Text(
                        '${_textEditingController.text.length}/100',
                        style: getTextStyle(AppTypo.UI11, AppColors.Gray400),
                      ),
                    ),
                  ),
                  maxLength: 100,
                  textInputAction: TextInputAction.done,
                  style: getTextStyle(AppTypo.UI16, AppColors.Gray900),
                  onFieldSubmitted: (value) => _commitComment()),
            ),
          ),
          IconButton(
            onPressed: () => _commitComment(),
            icon: Icon(Icons.send, color: Constants.mainColor),
          ),
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
      ref.read(commentCountProvider(widget.articleId).notifier).increment();

      widget.pagingController.refresh();
    });
    _textEditingController.clear();
  }
}
