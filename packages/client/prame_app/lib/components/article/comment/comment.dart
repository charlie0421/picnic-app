import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/components/article/comment/comment_header.dart';
import 'package:prame_app/components/article/comment/comment_contents.dart';
import 'package:prame_app/components/article/comment/comment_actions.dart';
import 'package:prame_app/components/article/comment/comment_user.dart';
import 'package:prame_app/components/ui/bottom-sheet-header.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/article.dart';
import 'package:prame_app/models/comment.dart';
import 'package:prame_app/providers/comment_list_provider.dart';

class Comment extends ConsumerStatefulWidget {
  final ArticleModel articleModel;

  const Comment({super.key, required this.articleModel});

  @override
  ConsumerState<Comment> createState() => _CommentState();
}

class _CommentState extends ConsumerState<Comment> {
  int commentCount = 0;
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
    logger.w('fetchPage');
    final asyncCommentList = ref.read(asyncCommentListProvider.notifier).fetch(
        pageKey, 10, 'article.created_at', 'DESC',
        articleId: widget.articleModel.id);

    final page = await asyncCommentList;
    logger.w(page.items);
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
    logger.w('Comment build');
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: KeyboardDismissOnTap(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          BottomSheetHeader(
            title: '${widget.articleModel.titleKo} ($commentCount)',
          ),
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
                            Intl.message('label_episode_comment_empty'),
                            style: const TextStyle(
                                fontSize: 30, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  itemBuilder: (context, item, index) {
                    logger.w(item);
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          width: kIsWeb
                              ? Constants.webMaxWidth
                              : MediaQuery.of(context).size.width,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CommentUser(
                                nickname: item.user?.nickname ?? '',
                                profileImage: item.user?.profileImage ?? '',
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  child: Column(
                                    children: [
                                      CommentHeader(
                                        item: item,
                                        pagingController: _pagingController,
                                      ),
                                      CommentContents(item: item),
                                      CommentActions(
                                        item: item,
                                        textEditingController:
                                            _textEditingController,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        item.children != null
                            ? ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: item.children!.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    padding: const EdgeInsets.only(left: 58),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            CommentUser(
                                              nickname: item.children?[index]
                                                      .user?.nickname ??
                                                  '',
                                              profileImage: item
                                                      .children?[index]
                                                      .user
                                                      ?.profileImage ??
                                                  '',
                                            ),
                                            Expanded(
                                              child: CommentHeader(
                                                item: item.children![index],
                                                pagingController:
                                                    _pagingController,
                                              ),
                                            ),
                                          ],
                                        ),
                                        CommentActions(
                                          item: item.children![index],
                                          textEditingController:
                                              _textEditingController,
                                        ),
                                      ],
                                    ),
                                  );
                                })
                            : const SizedBox(),
                      ],
                    );
                  }),
            ),
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
                    height: 70,
                    child: TextFormField(
                        controller: _textEditingController,
                        decoration: InputDecoration(
                          hintText: Intl.message('label_hint_comment'),
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          contentPadding: const EdgeInsets.only(left: 10),
                        ),
                        maxLength: 100,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (value) => _commitComment()),
                  ),
                ),
                IconButton(
                  onPressed: () => _commitComment(),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  _commitComment() {
    final int parentId = ref.watch<int>(parentIdProvider);

    ref.read(asyncCommentListProvider.notifier).submitComment(
        articleId: widget.articleModel.id,
        content: _textEditingController.text,
        parentId: parentId);
    _textEditingController.clear();
  }
}
