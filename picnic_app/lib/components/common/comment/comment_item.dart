import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/common/avartar_container.dart';
import 'package:picnic_app/components/common/comment/comment_actions.dart';
import 'package:picnic_app/components/common/comment/comment_contents.dart';
import 'package:picnic_app/components/common/comment/comment_header.dart';
import 'package:picnic_app/components/common/comment/comment_popup_menu.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

class CommentItem extends ConsumerStatefulWidget {
  const CommentItem({
    super.key,
    required this.pagingController,
    required this.commentModel,
    this.shouldHighlight = false,
    this.showReplyButton = true,
    this.openCommentsModal,
    this.openReportModal,
  });

  final PagingController<int, CommentModel>? pagingController;
  final CommentModel commentModel;
  final bool shouldHighlight;
  final bool showReplyButton;
  final Function? openCommentsModal;
  final Function? openReportModal;

  @override
  ConsumerState<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends ConsumerState<CommentItem>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _animation;
  Color _backgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();

    logger.i('widget.commentModel: ${widget.commentModel}');

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation =
        Tween<double>(begin: 1, end: .95).animate(_animationController!);

    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        setState(() {
          _backgroundColor = AppColors.grey100;
        });
      } else if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        setState(() {
          _backgroundColor = Colors.white;
        });
      }
    });

    if (widget.shouldHighlight) {
      _animationController!.forward().then((_) {
        _animationController!.reverse();
      });
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation!,
      child: AnimatedContainer(
        duration: const Duration(seconds: 1),
        decoration: BoxDecoration(
          border: Border.all(
            color: _backgroundColor,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _backgroundColor.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16.cw,
            vertical: 8,
          ),
          width: getPlatformScreenSize(context).width,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary500,
                    width: 1,
                  ),
                ),
                child: ProfileImageContainer(
                  avatarUrl: widget.commentModel.user.avatar_url,
                  borderRadius: 16,
                  width: 32,
                  height: 32,
                ),
              ),
              SizedBox(width: 10.cw),
              Expanded(
                child: Column(
                  children: [
                    CommentHeader(
                      item: widget.commentModel,
                    ),
                    const SizedBox(height: 4),
                    CommentContents(item: widget.commentModel),
                    const SizedBox(height: 4),
                    CommentActions(
                      item: widget.commentModel,
                      showReplyButton: widget.showReplyButton,
                      openCommentsModal: widget.openCommentsModal,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.cw),
              CommentPopupMenu(
                context: context,
                comment: widget.commentModel,
                refreshFunction: widget.pagingController?.refresh,
                openReportModal: widget.openReportModal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
