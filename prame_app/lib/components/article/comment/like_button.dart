import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:prame_app/auth_dio.dart';
import 'package:prame_app/constants.dart';

class LikeButton extends StatefulWidget {
  final int commentId;
  final int initialLikes;
  final bool initiallyLiked;

  const LikeButton({
    Key? key,
    required this.commentId,
    required this.initialLikes,
    required this.initiallyLiked,
  }) : super(key: key);

  @override
  LikeButtonState createState() => LikeButtonState();
}

class LikeButtonState extends State<LikeButton> {
  late int likes;
  late bool isLiked;

  @override
  void initState() {
    super.initState();
    likes = widget.initialLikes;
    isLiked = widget.initiallyLiked;
  }

  void _toggleLike() {
    if (isLiked) {
      // API 호출로 좋아요 취소
      _removeCommentLike(widget.commentId);
    } else {
      // API 호출로 좋아요 추가
      _addCommentLike(widget.commentId);
    }
  }

  Future<void> _addCommentLike(int commentId) async {
    var dio = await authDio(baseUrl: Constants.userApiUrl);
    try {
      final response = await dio.post('/comment/$commentId/like');

      if (response.statusCode == 201) {
        setState(() {
          isLiked = true;
          likes += 1;
        });
      } else {
        throw Exception('Failed to load post');
      }
    } catch (e, stacTrace) {
      logger.i(stacTrace);
    }
  }

  Future<void> _removeCommentLike(int commentId) async {
    var dio = await authDio(baseUrl: Constants.userApiUrl);
    try {
      final response = await dio.delete('/comment/$commentId/like');

      if (response.statusCode == 200) {
        setState(() {
          isLiked = false;
          likes -= 1;
        });
      } else {
        throw Exception('Failed to load post');
      }
    } catch (e, stacTrace) {
      logger.i(stacTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _toggleLike,
          icon: Icon(
            isLiked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
            size: 16,
          ),
        ),
        Text('$likes', style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
