import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/models/pic/article.dart';
import 'package:picnic_app/ui/style.dart';

class ArticleTitle extends StatelessWidget {
  final ArticleModel article;

  const ArticleTitle({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30.h,
      child: Row(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              article.title_ko,
              style: getTextStyle(
                context,
                AppTypo.TITLE18B,
                AppColors.Gray900,
              ),
            ),
          ),
          SizedBox(
            width: 10.w,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Text(
              DateFormat('yyyy-MM-dd').format(article.created_at),
              style: getTextStyle(
                context,
                AppTypo.BODY14B,
                AppColors.Gray900,
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
