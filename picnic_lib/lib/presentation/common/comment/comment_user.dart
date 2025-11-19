import 'package:flutter/material.dart';
import 'package:picnic_lib/presentation/common/avatar_container.dart';

class CommentUser extends StatelessWidget {
  final String nickname;
  final String profileImage;

  const CommentUser({
    super.key,
    required this.nickname,
    required this.profileImage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: profileImage.trim().isNotEmpty
          ? ProfileImageContainer(
              avatarUrl: profileImage,
              borderRadius: 20,
              width: 40,
              height: 40,
            )
          : CircleAvatar(
              radius: 25,
              child: Text(
                nickname.length > 2
                    ? nickname.toString().substring(0, 2)
                    : nickname.length == 1
                    ? nickname.substring(0, 1)
                    : '',
              ),
            ),
    );
  }
}
