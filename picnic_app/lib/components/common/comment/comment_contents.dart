import 'package:flutter/material.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/ui/style.dart';

class CommentContents extends StatelessWidget {
  final CommentModel item;

  const CommentContents({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topLeft,
      child: Text(
        item.content,
        style: getTextStyle(AppTypo.body14M, AppColors.grey900),
      ),
    );
  }
}
