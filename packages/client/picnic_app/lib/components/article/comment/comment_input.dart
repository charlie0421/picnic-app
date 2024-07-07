import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/pic/comment.dart';
import 'package:picnic_app/providers/article_list_provider.dart';
import 'package:picnic_app/providers/comment_list_provider.dart';
import 'package:picnic_app/ui/style.dart';

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
      width: kIsWeb ? Constants.webWidth : MediaQuery.of(context).size.width,
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
                    hintText: S.of(context).label_hint_comment,
                    hintStyle: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.Grey400,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: const BorderSide(
                        color: AppColors.Grey300,
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.only(left: 10),
                    suffixIcon: Container(
                      // alignment: Alignment.bottomRight,
                      padding: EdgeInsets.only(top: 30.w),
                      child: Text(
                        '${_textEditingController.text.length}/100',
                        style:
                            getTextStyle(AppTypo.CAPTION12R, AppColors.Grey400),
                      ),
                    ),
                  ),
                  maxLength: 100,
                  textInputAction: TextInputAction.done,
                  style: getTextStyle(AppTypo.BODY16R, AppColors.Grey900),
                  onFieldSubmitted: (value) => _commitComment()),
            ),
          ),
          IconButton(
            onPressed: () => _commitComment(),
            icon: const Icon(Icons.send, color: picMainColor),
          ),
        ],
      ),
    );
  }

  _commitComment() {
    final parentItemState = ref.watch(parentItemProvider);
    ref
        .read(asyncCommentListProvider(
          articleId: widget.articleId,
          pagingController: widget.pagingController,
        ).notifier)
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
