import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/pic/article.dart';
import 'package:picnic_app/providers/article_list_provider.dart';

import '../../ui/style.dart';

class ArticleCommentInfo extends ConsumerStatefulWidget {
  final ArticleModel article;
  final Function showComments;

  const ArticleCommentInfo(
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
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.showComments(context, widget.article),
        child: Text(
            '${S.of(context).label_read_more_comment} ${ref.watch(commentCountProvider(widget.article.id)).value != 0 ? ref.watch(commentCountProvider(widget.article.id)).value : widget.article.comment_count}',
            style: getTextStyle(
              AppTypo.BODY14B,
              AppColors.Grey900,
            )),
      ),
    );
  }
}
