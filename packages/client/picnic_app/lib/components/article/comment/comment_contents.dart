import 'package:flutter/material.dart';
import 'package:picnic_app/models/fan/comment.dart';
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
          style: getTextStyle(context, AppTypo.UI14, AppColors.Gray900),
        ));
  }
}
