import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/dialogs/require_login_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/community/comments_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/number.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

class LikeButton extends ConsumerStatefulWidget {
  final String postId;
  final String commentId;
  final int initialLikes;
  final bool isLiked;
  final Function()? onLike;

  const LikeButton({
    super.key,
    required this.postId,
    required this.commentId,
    required this.initialLikes,
    required this.isLiked,
    this.onLike,
  });

  @override
  LikeButtonState createState() => LikeButtonState();
}

class LikeButtonState extends ConsumerState<LikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late int likes;
  late bool isLiked;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    likes = widget.initialLikes;
    isLiked = widget.isLiked;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLikes != widget.initialLikes ||
        oldWidget.isLiked != widget.isLiked) {
      setState(() {
        likes = widget.initialLikes;
        isLiked = widget.isLiked;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (!supabase.isLogged) {
      showRequireLoginDialog();
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final commentsNotifier = ref.read(
        commentsNotifierProvider(widget.postId, 1, 10).notifier,
      );

      // Optimistic update
      setState(() {
        likes += isLiked ? -1 : 1;
        isLiked = !isLiked;
      });

      _animationController.forward();
      widget.onLike?.call();

      if (isLiked) {
        await commentsNotifier.likeComment(widget.commentId);
      } else {
        await commentsNotifier.unlikeComment(widget.commentId);
      }
    } catch (e) {
      if (!mounted) return;

      // Revert changes on error
      setState(() {
        likes = widget.initialLikes;
        isLiked = widget.isLiked;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).post_comment_like_processing_fail),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildLikeIcon() {
    if (_isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: SvgPicture.asset(
        'assets/icons/heart_style=fill.svg',
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(
          isLiked ? AppColors.primary500 : AppColors.grey300,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildLikeCount() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: Text(
        formatNumberWithComma(likes),
        key: ValueKey<int>(likes),
        style: getTextStyle(AppTypo.body14M, AppColors.grey900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleLike,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.cw),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLikeIcon(),
            SizedBox(width: 4.cw),
            _buildLikeCount(),
          ],
        ),
      ),
    );
  }
}
