import 'package:flutter/material.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/ui/style.dart';

class CommentContents extends StatefulWidget {
  final CommentModel item;

  const CommentContents({
    super.key,
    required this.item,
  });

  @override
  _CommentContentsState createState() => _CommentContentsState();
}

class _CommentContentsState extends State<CommentContents> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    String currentLocale = Localizations.localeOf(context).languageCode;
    String content = widget.item.content!.keys.contains(currentLocale)
        ? widget.item.content![currentLocale]
        : widget.item.content![widget.item.locale];
    bool isTranslated = widget.item.content!.keys.contains(currentLocale) &&
        currentLocale != widget.item.locale;

    return Container(
      alignment: Alignment.topLeft,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textSpan = TextSpan(
            text: content,
            style: getTextStyle(AppTypo.body14M, AppColors.grey900),
          );

          final textPainter = TextPainter(
            text: textSpan,
            maxLines: 1,
            textDirection: TextDirection.ltr,
          );

          textPainter.layout(
              maxWidth: constraints.maxWidth - 40); // 40은 "더보기" 텍스트의 예상 너비입니다.

          final exceedsMaxLines = textPainter.didExceedMaxLines;

          return GestureDetector(
            onTap: () {
              if (exceedsMaxLines) {
                setState(() {
                  _expanded = !_expanded;
                });
              }
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.item.isReportedByUser! ||
                            (widget.item.isBlindedByAdmin ?? false)
                        ? '(신고된 댓글입니다.)'
                        : widget.item.deletedAt != null
                            ? '(삭제된 댓글입니다.)'
                            : content,
                    style: getTextStyle(
                        AppTypo.body14M,
                        widget.item.isReportedByUser! ||
                                (widget.item.isBlindedByAdmin ?? false)
                            ? AppColors.point500
                            : widget.item.deletedAt != null
                                ? AppColors.grey500
                                : AppColors.grey900),
                    maxLines: _expanded ? null : 1,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                ),
                if (isTranslated)
                  Text(
                    '(번역됨)',
                    style: getTextStyle(AppTypo.caption12B, AppColors.grey500),
                  ),
                if (exceedsMaxLines && !_expanded)
                  Text(
                    '더보기',
                    style: getTextStyle(AppTypo.body14M, AppColors.grey500),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
