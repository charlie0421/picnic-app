import 'package:flutter/material.dart';
import 'package:picnic_lib/data/models/pic/article.dart';
import 'package:picnic_lib/ui/style.dart';

class ArticleContent extends StatelessWidget {
  final ArticleModel article;

  const ArticleContent({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          article.content,
          style: getTextStyle(
            AppTypo.body14M,
            AppColors.grey900,
          ),
        ));
  }
}
