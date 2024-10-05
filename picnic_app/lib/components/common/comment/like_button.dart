import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/providers/community/comments_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

class LikeButton extends ConsumerStatefulWidget {
  final String commentId;
  final int initialLikes;
  final bool isLiked;

  const LikeButton({
    super.key,
    required this.commentId,
    required this.initialLikes,
    required this.isLiked,
  });

  @override
  LikeButtonState createState() => LikeButtonState();
}

class LikeButtonState extends ConsumerState<LikeButton> {
  late int likes;
  late bool isLiked;

  @override
  void initState() {
    super.initState();
    likes = widget.initialLikes;
    isLiked = widget.isLiked;
  }

  void _toggleLike() {
    if (isLiked) {
      unlikeComment(ref, widget.commentId);
      setState(() {
        likes--;
        isLiked = false;
      });
    } else {
      likeComment(ref, widget.commentId);
      setState(() {
        likes++;
        isLiked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleLike,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(8), // 터치 영역 제한
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/heart_style=line.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                  isLiked ? AppColors.primary500 : AppColors.mint500,
                  BlendMode.srcIn),
            ),
            SizedBox(width: 4.cw),
            Text('$likes',
                style: getTextStyle(AppTypo.body14M, AppColors.grey900))
          ],
        ),
      ),
    );
  }
}
