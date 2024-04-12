import 'package:flutter/material.dart';
import 'package:prame_app/models/comment.dart';

class CommentHeader extends StatelessWidget {
  final CommentModel item;

  const CommentHeader({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey,
      ),
      child: Text.rich(
        TextSpan(children: <TextSpan>[
          TextSpan(
              text: '${item.user?.nickname} ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              )),
          TextSpan(
              text: item.content,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              )),
        ]),
      ),
    );
  }
}
