import 'package:flutter/material.dart';
import 'package:prame_app/models/prame/article.dart';
import 'package:prame_app/ui/style.dart';

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
            context,
            AppTypo.UI14M,
            AppColors.Gray900,
          ),
        ));
  }
}
