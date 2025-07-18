import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/number.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/providers/community/comments_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';

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
    if (!isSupabaseLoggedSafely) {
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
    } catch (e, s) {
      logger.e('exception:', error: e, stackTrace: s);

      if (!mounted) return;

      // Revert changes on error
      setState(() {
        likes = widget.initialLikes;
        isLiked = widget.isLiked;
      });

      SnackbarUtil().showSnackbar(
          AppLocalizations.of(context).post_comment_like_processing_fail);
      rethrow;
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
        package: 'picnic_lib',
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
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLikeIcon(),
            SizedBox(width: 4.w),
            _buildLikeCount(),
          ],
        ),
      ),
    );
  }
}
