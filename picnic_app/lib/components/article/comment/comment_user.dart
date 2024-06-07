import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:picnic_app/util.dart';

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
        child: profileImage != ''
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: profileImage,
                  width: 40,
                  height: 40,
                  placeholder: (context, url) => buildPlaceholderImage(),
                  fit: BoxFit.cover,
                ),
              )
            : CircleAvatar(
                radius: 25,
                child: Text(nickname.length > 2
                    ? nickname.toString().substring(0, 2)
                    : nickname.length == 1
                        ? nickname.substring(0, 1)
                        : '')));
  }
}
