import 'package:flutter/material.dart';
import 'package:picnic_app/models/pic/article.dart';
import 'package:picnic_app/ui/style.dart';

class ArticleContent extends StatelessWidget {
  ArticleModel article;

  ArticleContent({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          article.content,
          style: getTextStyle(
            AppTypo.BODY14M,
            AppColors.Gray900,
          ),
        ));
  }
}
