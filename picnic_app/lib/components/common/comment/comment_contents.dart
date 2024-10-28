// comment_contents.dart
import 'package:flutter/material.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/logger.dart';

class CommentContents extends StatefulWidget {
  final CommentModel item;
  final bool isTranslated;
  final bool showOriginal;

  const CommentContents({
    super.key,
    required this.item,
    required this.isTranslated,
    required this.showOriginal,
  });

  @override
  State<CommentContents> createState() => _CommentContentsState();
}

class _CommentContentsState extends State<CommentContents> {
  bool _expanded = false;

  String _getDisplayContent(BuildContext context) {
    logger.i(
        'isTranslated: ${widget.isTranslated}, showOriginal: ${widget.showOriginal}');

    if (widget.item.isReportedByMe! ||
        (widget.item.isBlindedByAdmin ?? false)) {
      return '(${S.of(context).post_comment_reported_comment})';
    }

    if (widget.item.deletedAt != null) {
      return '(${S.of(context).post_comment_deleted_comment})';
    }

    String currentLocale = Localizations.localeOf(context).languageCode;
    String commentLocale = widget.item.locale ?? 'ko';

    // 원문 보기가 활성화되었거나, 번역이 없거나, 번역 모드가 아닌 경우 원본 텍스트 반환
    if (widget.showOriginal ||
        !widget.isTranslated ||
        !widget.item.content!.containsKey(currentLocale)) {
      return widget.item.content![commentLocale]!;
    }

    // 그 외의 경우 번역된 텍스트 반환
    return widget.item.content![currentLocale]!;
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final commentLocale = widget.item.locale ?? 'ko';
    final isTranslatedText = widget.isTranslated &&
        widget.item.content!.containsKey(currentLocale) &&
        currentLocale != commentLocale &&
        !widget.showOriginal;
    final content = _getDisplayContent(context);

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

          textPainter.layout(maxWidth: constraints.maxWidth - 40);

          final exceedsMaxLines = textPainter.didExceedMaxLines;

          return GestureDetector(
            onTap: () {
              if (exceedsMaxLines) {
                setState(() {
                  _expanded = !_expanded;
                });
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        content,
                        style: getTextStyle(
                          AppTypo.body14M,
                          widget.item.isReportedByMe! ||
                                  (widget.item.isBlindedByAdmin ?? false)
                              ? AppColors.point500
                              : widget.item.deletedAt != null
                                  ? AppColors.grey500
                                  : AppColors.grey900,
                        ),
                        maxLines: _expanded ? null : 1,
                        overflow: _expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),
                    ),
                    if (!_expanded && exceedsMaxLines)
                      Text(
                        S.of(context).post_comment_content_more,
                        style: getTextStyle(AppTypo.body14M, AppColors.grey500),
                      ),
                  ],
                ),
                if (isTranslatedText)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '(${S.of(context).post_comment_translated})',
                      style:
                          getTextStyle(AppTypo.caption12B, AppColors.grey500),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
