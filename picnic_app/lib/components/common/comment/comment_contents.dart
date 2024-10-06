import 'package:flutter/material.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/ui/style.dart';

class CommentContents extends StatefulWidget {
  final CommentModel item;

  const CommentContents({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  _CommentContentsState createState() => _CommentContentsState();
}

class _CommentContentsState extends State<CommentContents> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topLeft,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textSpan = TextSpan(
            text: widget.item.content,
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
                    widget.item.deletedAt != null
                        ? '(삭제된 댓글입니다.)'
                        : widget.item.content,
                    style: getTextStyle(
                        AppTypo.body14M,
                        widget.item.deletedAt != null
                            ? AppColors.grey500
                            : AppColors.grey900),
                    maxLines: _expanded ? null : 1,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
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
