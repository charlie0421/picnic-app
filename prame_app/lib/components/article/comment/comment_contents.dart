import 'package:flutter/material.dart';
import 'package:prame_app/models/comment.dart';
import 'package:prame_app/ui/style.dart';
import 'package:prame_app/util.dart';

class CommentContents extends StatelessWidget {
  final CommentModel item;

  const CommentContents({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        child: Text(
          item.content,
          style: getTextStyle(context, AppTypo.UI14, AppColors.Gray900),
        ));
  }
}
