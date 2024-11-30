import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/article/article_content.dart';
import 'package:picnic_app/components/article/article_images.dart';
import 'package:picnic_app/components/article/article_title.dart';
import 'package:picnic_app/components/common/no_item_container.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/models/pic/article.dart';
import 'package:picnic_app/providers/article_list_provider.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';

class ArticleList extends ConsumerStatefulWidget {
  final int galleryId;

  const ArticleList(this.galleryId, {super.key});

  @override
  ConsumerState<ArticleList> createState() => _ArticleListState();
}

class _ArticleListState extends ConsumerState<ArticleList> {
  final PagingController<int, ArticleModel> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      ref
          .watch(FetchArticleListProvider(
                  page: pageKey,
                  limit: 10,
                  sort: 'id',
                  order: 'ASC',
                  galleryId: widget.galleryId)
              .future)
          .then((newItems) {
        final isLastPage = newItems!.length < 10;
        if (isLastPage) {
          _pagingController.appendLastPage(newItems);
        } else {
          final nextPageKey = pageKey + 1;
          _pagingController.appendPage(newItems, nextPageKey);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: PagedListView<int, ArticleModel>(
        pagingController: _pagingController,
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
            noItemsFoundIndicatorBuilder: (context) => const NoItemContainer(),
            itemBuilder: (context, item, index) =>
                _buildArticle(context, ref, item)),
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
                color: Colors.grey.withOpacity(1),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
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
