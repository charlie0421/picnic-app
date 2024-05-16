import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/article/comment/comment_actions.dart';
import 'package:picnic_app/components/article/comment/comment_contents.dart';
import 'package:picnic_app/components/article/comment/comment_header.dart';
import 'package:picnic_app/components/article/comment/comment_user.dart';
import 'package:picnic_app/components/article/comment/report_popup_menu.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/prame/comment.dart';
import 'package:picnic_app/ui/style.dart';

class CommentItem extends ConsumerStatefulWidget {
  const CommentItem({
    super.key,
    required PagingController<int, CommentModel> pagingController,
    required this.commentModel,
    required this.articleId,
    this.shouldHighlight = false,
  }) : _pagingController = pagingController;

  final PagingController<int, CommentModel> _pagingController;
  final CommentModel commentModel;
  final int articleId;
  final bool shouldHighlight;

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

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation =
        Tween<double>(begin: 1, end: .95).animate(_animationController!);

    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        setState(() {
          _backgroundColor = AppColors.Gray100;
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
          padding: const EdgeInsets.only(left: 20),
          margin: const EdgeInsets.only(bottom: 20),
          width: kIsWeb
              ? Constants.webMaxWidth
              : MediaQuery.of(context).size.width,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommentUser(
                nickname: widget.commentModel.user?.nickname ?? '',
                profileImage: widget.commentModel.user?.profileImage ?? '',
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CommentHeader(
                      item: widget.commentModel,
                      pagingController: widget._pagingController,
                    ),
                    CommentContents(item: widget.commentModel),
                    CommentActions(
                      item: widget.commentModel,
                    ),
                  ],
                ),
              ),
              ReportPopupMenu(
                  context: context,
                  commentId: widget.commentModel.id,
                  pagingController: widget._pagingController),
            ],
          ),
        ),
      ),
    );
  }
}
