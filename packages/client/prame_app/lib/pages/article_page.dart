import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:prame_app/components/article/article_list.dart';
import 'package:prame_app/components/article/article_sort_widget.dart';
import 'package:prame_app/components/article/comment/comment.dart';
import 'package:prame_app/constants.dart';
import 'package:prame_app/models/article.dart';

class ArticlePage extends ConsumerStatefulWidget {
  final int galleryId;

  const ArticlePage({super.key, required this.galleryId});

  @override
  ConsumerState<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends ConsumerState<ArticlePage> {
  @override
  initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    logger.d('ArticlePage build');
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ArticleSortWidget(
            galleryId: widget.galleryId,
          ),
        ),
        SizedBox(
          height: 20.h,
        ),
        Expanded(child: ArticleList(widget.galleryId)),
      ],
    );
  }
}
