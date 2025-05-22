import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/pic/article.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/providers/article_list_provider.dart';

import '../../../ui/style.dart';

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
            '${t('label_read_more_comment')} ${ref.watch(commentCountProvider(widget.article.id)).value != 0 ? ref.watch(commentCountProvider(widget.article.id)).value : widget.article.commentCount}',
            style: getTextStyle(
              AppTypo.body14B,
              AppColors.grey900,
            )),
      ),
    );
  }
}
