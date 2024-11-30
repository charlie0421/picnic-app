import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/number.dart';
import 'package:picnic_app/util/ui.dart';

class ReplyButton extends ConsumerStatefulWidget {
  final CommentModel comment;
  final int initialReplies;
  final bool isReplied;
  final Function? openCommentsModal;

  const ReplyButton({
    super.key,
    required this.comment,
    required this.initialReplies,
    required this.isReplied,
    required this.openCommentsModal,
  });

  @override
  ReplyButtonState createState() => ReplyButtonState();
}

class ReplyButtonState extends ConsumerState<ReplyButton> {
  late int replies;
  late bool isReplied;

  @override
  void initState() {
    super.initState();
    replies = widget.initialReplies;
    isReplied = widget.isReplied;
  }

  void _handleButton() {
    if (widget.openCommentsModal != null) {
      widget.openCommentsModal!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleButton,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/reply_style=fill.svg',
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
                isReplied ? AppColors.primary500 : AppColors.grey300,
                BlendMode.srcIn),
          ),
          SizedBox(width: 4.cw),
          Text(formatNumberWithComma(replies),
              style: getTextStyle(AppTypo.body14M, AppColors.grey900))
        ],
      ),
    );
  }
}
