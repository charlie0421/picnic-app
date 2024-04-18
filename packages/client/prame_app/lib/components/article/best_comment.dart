import 'package:flutter/material.dart';
import 'package:prame_app/models/article.dart';
import 'package:prame_app/ui/style.dart';

class BestComment extends StatelessWidget {
  const BestComment({super.key, required this.article});
  final ArticleModel article;
  @override
  Widget build(BuildContext context) {
    return article.mostLikedComment != null
        ? Container(
            padding: const EdgeInsets.all(8.0),
            child: Text.rich(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              TextSpan(
                children: [
                  TextSpan(
                    text: article.mostLikedComment != null
                        ? article.mostLikedComment!.user?.nickname
                        : '',
                    style: getTextStyle(
                      AppTypo.UI14B,
                      AppColors.Gray900,
                    ),
                  ),
                  TextSpan(
                    text: ' ',
                    style: getTextStyle(
                      AppTypo.UI14M,
                      AppColors.Gray900,
                    ),
                  ),
                  TextSpan(
                    text: article.mostLikedComment != null
                        ? article.mostLikedComment!.content.toString()
                        : '',
                    style: getTextStyle(
                      AppTypo.UI12M,
                      AppColors.Gray900,
                    ),
                  ),
                ],
              ),
            ),
          )
        : Container();
  }
}
