import 'package:flutter/material.dart';

class CommentContent extends StatelessWidget {
  final String nickname;
  final String content;

  const CommentContent(
      {super.key, required this.nickname, required this.content});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      softWrap: true,
      overflow: TextOverflow.visible,
      TextSpan(children: <TextSpan>[
        TextSpan(
            text: '$nickname ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            )),
        TextSpan(
            text: content,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
            )),
      ]),
    );
  }
}
