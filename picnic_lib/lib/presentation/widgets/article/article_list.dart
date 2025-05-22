import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/data/models/pic/article.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/presentation/providers/article_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/article/article_content.dart';
import 'package:picnic_lib/presentation/widgets/article/article_images.dart';
import 'package:picnic_lib/presentation/widgets/article/article_title.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';

class ArticleList extends ConsumerStatefulWidget {
  final int galleryId;

  const ArticleList(this.galleryId, {super.key});

  @override
  ConsumerState<ArticleList> createState() => _ArticleListState();
}

class _ArticleListState extends ConsumerState<ArticleList> {
  late final PagingController<int, ArticleModel> _pagingController;

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController<int, ArticleModel>(
      getNextPageKey: (state) {
        if (state.items == null) return 1;
        final isLastPage = state.items!.length < _pageSize;
        if (isLastPage) return null;
        return (state.keys?.last ?? 0) + 1;
      },
      fetchPage: _fetch,
    );
  }

  static const _pageSize = 10;

  Future<List<ArticleModel>> _fetch(int pageKey) async {
    final newItems = await ref.watch(FetchArticleListProvider(
            page: pageKey,
            limit: 10,
            sort: 'id',
            order: 'ASC',
            galleryId: widget.galleryId)
        .future);
    return newItems ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: PagingListener(
        controller: _pagingController,
        builder: (context, state, fetchNextPage) =>
            PagedListView<int, ArticleModel>(
          state: _pagingController.value,
          fetchNextPage: _pagingController.fetchNextPage,
          scrollDirection: Axis.vertical,
          builderDelegate: PagedChildBuilderDelegate<ArticleModel>(
              firstPageErrorIndicatorBuilder: (context) {
                return buildErrorView(context,
                    error: _pagingController.error.toString(),
                    retryFunction: () => _pagingController.refresh(),
                    stackTrace: null);
              },
              firstPageProgressIndicatorBuilder: (context) {
                return buildLoadingOverlay();
              },
              noItemsFoundIndicatorBuilder: (context) =>
                  const NoItemContainer(),
              itemBuilder: (context, item, index) =>
                  _buildArticle(context, ref, item)),
        ),
      ),
    );
  }

  Widget _buildArticle(
      BuildContext context, WidgetRef ref, ArticleModel article) {
    logger.i('ArticleList: $article');
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          ArticleTitle(article: article),
          const SizedBox(
            height: 10,
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 1),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .5),
                  spreadRadius: 1,
                  blurRadius: 7,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            height: 800,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArticleImages(article: article),
                ArticleContent(article: article),
                // ArticleBestComment(
                //     article: article, showComments: _showComments),
                // ArticleCommentInfo(
                //     article: article, showComments: _showComments)
              ],
            ),
          ),
        ],
      ),
    );
  }

// void _showComments(BuildContext context, ArticleModel articleModel,
//     {String? commentId}) {
//   logger.w('showComments');
//   showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       useSafeArea: true,
//       barrierColor: Colors.transparent,
//       builder: (BuildContext context) {
//         return SafeArea(
//             child: Comment(postModel: articleModel, commentId: commentId));
//       });
// }
}
