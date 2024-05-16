import 'package:flutter/material.dart';
import 'package:picnic_app/models/prame/article.dart';
import 'package:picnic_app/ui/style.dart';

class ArticleBestComment extends StatefulWidget {
  final ArticleModel article;
  Function showComments;

  ArticleBestComment(
      {super.key, required this.article, required this.showComments});

  @override
  State<ArticleBestComment> createState() => _ArticleBestCommentState();
}

class _ArticleBestCommentState extends State<ArticleBestComment> {
  @override
  Widget build(BuildContext context) {
    return widget.article.mostLikedComment != null
        ? GestureDetector(
            onTap: () => widget.showComments(context, widget.article,
                commentId: widget.article.mostLikedComment?.id),
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
                        context,
                        AppTypo.UI14B,
                        AppColors.Gray900,
                      ),
                    ),
                    TextSpan(
                      text: ' ',
                      style: getTextStyle(
                        context,
                        AppTypo.UI14M,
                        AppColors.Gray900,
                      ),
                    ),
                    TextSpan(
                      text: widget.article.mostLikedComment != null
                          ? widget.article.mostLikedComment!.content.toString()
                          : '',
                      style: getTextStyle(
                        context,
                        AppTypo.UI12M,
                        AppColors.Gray900,
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
