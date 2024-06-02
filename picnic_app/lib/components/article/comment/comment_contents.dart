import 'package:flutter/material.dart';
import 'package:picnic_app/models/pic/comment.dart';
import 'package:picnic_app/ui/style.dart';

class CommentContents extends StatelessWidget {
  final CommentModel item;

  const CommentContents({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: double.infinity,
        child: Text(
          item.content,
          style: getTextStyle(AppTypo.BODY14R, AppColors.Gray900),
        ));
  }
}
