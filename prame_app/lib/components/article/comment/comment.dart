import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/components/article/comment/comment_item.dart';
import 'package:prame_app/components/ui/bottom-sheet-header.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/article.dart';
import 'package:prame_app/models/comment.dart';
import 'package:prame_app/providers/comment_list_provider.dart';
import 'package:prame_app/ui/style.dart';

class Comment extends ConsumerStatefulWidget {
  final ArticleModel articleModel;

  const Comment({super.key, required this.articleModel});

  @override
  ConsumerState<Comment> createState() => _CommentState();
}

class _CommentState extends ConsumerState<Comment> {
  final _textEditingController = TextEditingController();
  late final PagingController<int, CommentModel> _pagingController;

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController<int, CommentModel>(firstPageKey: 1);
    _pagingController.addPageRequestListener((pageKey) {
      fetchPage(pageKey);
    });
  }

  void fetchPage(int pageKey) async {
    final asyncCommentList = ref.read(asyncCommentListProvider.notifier).fetch(
        pageKey, 10, 'comment.created_at', 'DESC',
        articleId: widget.articleModel.id);

    final page = await asyncCommentList;
    if (page.meta.currentPage < page.meta.totalPages) {
      _pagingController.appendPage(page.items, pageKey + 1);
    } else {
      _pagingController.appendLastPage(page.items);
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncCommentListState = ref.watch(asyncCommentListProvider);
    asyncCommentListState.value?.meta.totalItems;

    final commentCount = asyncCommentListState.value != null &&
            asyncCommentListState.value!.meta.totalItems != null
        ? asyncCommentListState.value!.meta.totalItems
        : 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: KeyboardDismissOnTap(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          BottomSheetHeader(
              title: '${widget.articleModel.titleKo} ($commentCount)'),
          Flexible(
            flex: 1,
            child: PagedListView<int, CommentModel>(
              physics: const ScrollPhysics(),
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<CommentModel>(
                  noItemsFoundIndicatorBuilder: (context) => Center(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            Intl.message('label_article_comment_empty'),
                            style: const TextStyle(
                                fontSize: 30, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  itemBuilder: (context, item, index) {
                    return Column(
                      children: [
                        CommentItem(
                            commentModel: item,
                            pagingController: _pagingController,
                            textEditingController: _textEditingController),
                        item.children != null
                            ? ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: item.children!.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    padding: const EdgeInsets.only(left: 50),
                                    child: CommentItem(
                                        commentModel: item.children![index],
                                        pagingController: _pagingController,
                                        textEditingController:
                                            _textEditingController),
                                  );
                                })
                            : const Text('aaaa'),
                      ],
                    );
                  }),
            ),
          ),
          Column(
            children: [
              Consumer(
                builder: (BuildContext context, WidgetRef ref, Widget? child) {
                  final parentComment = ref.watch(parentItemProvider);
                  return parentComment != null && parentComment.id != 0
                      ? Container(
                          color: AppColors.Gray300,
                          width: double.infinity,
                          height: 40.h,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                        text:
                                            '${parentComment.user?.nickname ?? ''} ',
                                        style: getTextStyle(
                                            AppTypo.UI14B, AppColors.Gray900)),
                                    TextSpan(
                                        text: '님에게 답글을 남깁니다.',
                                        style: getTextStyle(
                                            AppTypo.UI12, AppColors.Gray900)),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  ref
                                      .read(parentItemProvider.notifier)
                                      .setParentItem(null);
                                },
                                iconSize: 20,
                                icon: const Icon(Icons.close,
                                    color: AppColors.Gray900),
                              ),
                            ],
                          ),
                        )
                      : Container();
                },
              ),
              Container(
                height: 80,
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                width: kIsWeb
                    ? Constants.webMaxWidth
                    : MediaQuery.of(context).size.width,
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
                                  style: getTextStyle(
                                      AppTypo.UI11, AppColors.Gray400),
                                ),
                              ),
                            ),
                            maxLength: 100,
                            textInputAction: TextInputAction.done,
                            style:
                                getTextStyle(AppTypo.UI16, AppColors.Gray900),
                            onFieldSubmitted: (value) => _commitComment()),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _commitComment(),
                      icon: Icon(Icons.send, color: Constants.mainColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  _commitComment() {
    final parentItemState = ref.watch(parentItemProvider);

    ref
        .read(asyncCommentListProvider.notifier)
        .submitComment(
            articleId: widget.articleModel.id,
            content: _textEditingController.text,
            parentId: parentItemState?.id)
        .then((value) {
      ref.read(parentItemProvider.notifier).setParentItem(null);
      _pagingController.refresh();
    });
    _textEditingController.clear();
  }
}
