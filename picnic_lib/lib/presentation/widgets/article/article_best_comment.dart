import 'package:flutter/material.dart';
import 'package:picnic_lib/data/models/pic/article.dart';
import 'package:picnic_lib/ui/style.dart';

class ArticleBestComment extends StatefulWidget {
  final ArticleModel article;
  final Function showComments;

  const ArticleBestComment(
      {super.key, required this.article, required this.showComments});

  @override
  State<ArticleBestComment> createState() => _ArticleBestCommentState();
}

class _ArticleBestCommentState extends State<ArticleBestComment> {
  @override
  Widget build(BuildContext context) {
    return widget.article.mostLikedComment != null
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.showComments(context, widget.article,
                commentId: widget.article.mostLikedComment?.commentId),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Text.rich(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                TextSpan(
                  children: [
                    TextSpan(
                      text: widget.article.mostLikedComment != null
                          ? widget.article.mostLikedComment!.user?.nickname
                          : '',
                      style: getTextStyle(
                        AppTypo.body14B,
                        AppColors.grey900,
                      ),
                    ),
                    TextSpan(
                      text: ' ',
                      style: getTextStyle(
                        AppTypo.body14M,
                        AppColors.grey900,
                      ),
                    ),
                    TextSpan(
                      text: widget.article.mostLikedComment != null
                          ? widget.article.mostLikedComment!.content.toString()
                          : '',
                      style: getTextStyle(
                        AppTypo.body14R,
                        AppColors.grey900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : Container();
  }
}
