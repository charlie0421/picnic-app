import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prame_app/models/prame/article.dart';
import 'package:prame_app/providers/article_list_provider.dart';

import '../../ui/style.dart';

class ArticleCommentInfo extends ConsumerStatefulWidget {
  ArticleModel article;
  Function showComments;

  ArticleCommentInfo(
      {super.key, required this.article, required this.showComments});

  @override
  ConsumerState<ArticleCommentInfo> createState() => _ArticleCommentInfoState();
}

class _ArticleCommentInfoState extends ConsumerState<ArticleCommentInfo> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () => widget.showComments(context, widget.article),
        child: Text(
            '${Intl.message('label_read_more_comment')} ${ref.watch(commentCountProvider(widget.article.id)).value != 0 ? ref.watch(commentCountProvider(widget.article.id)).value : widget.article.commentCount}',
            style: getTextStyle(
              context,
              AppTypo.UI14B,
              AppColors.Gray900,
            )),
      ),
    );
  }
}
