import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/article/article_best_comment.dart';
import 'package:picnic_app/components/article/article_comment_info.dart';
import 'package:picnic_app/components/article/article_content.dart';
import 'package:picnic_app/components/article/article_images.dart';
import 'package:picnic_app/components/article/article_title.dart';
import 'package:picnic_app/components/article/comment/comment.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/prame/article.dart';
import 'package:picnic_app/providers/article_list_provider.dart';
import 'package:picnic_app/util.dart';

class ArticleList extends ConsumerWidget {
  final int galleryId;

  const ArticleList(this.galleryId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(asyncArticleListProvider(galleryId)).when(
          data: (pagingController) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: PagedListView<int, ArticleModel>(
                pagingController: pagingController,
                scrollDirection: Axis.vertical,
                builderDelegate: PagedChildBuilderDelegate<ArticleModel>(
                    firstPageErrorIndicatorBuilder: (context) {
                      return ErrorView(context,
                          error: pagingController.error.toString(),
                          retryFunction: () => pagingController.refresh(),
                          stackTrace: null);
                    },
                    firstPageProgressIndicatorBuilder: (context) {
                      return buildLoadingOverlay();
                    },
                    noItemsFoundIndicatorBuilder: (context) {
                      return ErrorView(context,
                          error: 'No Items Found', stackTrace: null);
                    },
                    itemBuilder: (context, item, index) =>
                        _buildArticle(context, ref, item)),
              )),
          loading: () => buildLoadingOverlay(),
          error: (error, stackTrace) => ErrorView(context,
              error: error.toString(), stackTrace: stackTrace),
        );
  }

  Widget _buildArticle(
      BuildContext context, WidgetRef ref, ArticleModel article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          ArticleTitle(article: article),
          SizedBox(
            height: 10.h,
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
            height: 700.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArticleImages(article: article),
                ArticleContent(article: article),
                ArticleBestComment(
                    article: article, showComments: _showComments),
                ArticleCommentInfo(
                    article: article, showComments: _showComments)
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComments(BuildContext context, ArticleModel articleModel,
      {int? commentId}) {
    logger.w('showComments');
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        barrierColor: Colors.transparent,
        builder: (BuildContext context) {
          return SafeArea(
              child: Comment(articleModel: articleModel, commentId: commentId));
        });
  }
}
