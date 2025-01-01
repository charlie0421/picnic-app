import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/data/models/pic/article.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/core/utils/ui.dart';

class ArticleTitle extends StatelessWidget {
  final ArticleModel article;

  const ArticleTitle({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              article.titleKo,
              style: getTextStyle(
                AppTypo.title18B,
                AppColors.grey900,
              ),
            ),
          ),
          SizedBox(
            width: 10.cw,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Text(
              DateFormat('yyyy-MM-dd').format(article.createdAt),
              style: getTextStyle(
                AppTypo.body14B,
                AppColors.grey900,
              ).copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
