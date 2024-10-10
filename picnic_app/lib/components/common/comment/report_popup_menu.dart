import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/providers/community/comments_provider.dart';
import 'package:picnic_app/supabase_options.dart';

class CommentPopupMenu extends ConsumerStatefulWidget {
  final BuildContext context;
  final CommentModel comment;
  final PagingController<int, CommentModel>? pagingController;
  final Function? openReportModal;

  const CommentPopupMenu({
    super.key,
    required this.comment,
    required this.context,
    required this.pagingController,
    this.openReportModal,
  });
  // required

  @override
  ConsumerState<CommentPopupMenu> createState() => _CommentPopupMenuState();
}

class _CommentPopupMenuState extends ConsumerState<CommentPopupMenu> {
  @override
  Widget build(BuildContext context) {
    return (_canDeleteComment() || _canReportComment())
        ? PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_vert),
            onSelected: (String result) async {
              if (result == 'Report') {
                logger.i('widget.openReportModal: ${widget.openReportModal}');
                if (widget.openReportModal != null) {
                  widget.openReportModal!(
                      S.of(context).label_title_report, widget.comment);
                }
              } else if (result == 'Delete') {
                await deleteComment(ref, widget.comment.commentId);
                widget.pagingController?.refresh();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (_canDeleteComment())
                PopupMenuItem<String>(
                    value: 'Delete',
                    child: Row(
                      children: [Text(S.of(context).popup_label_delete)],
                    )),
              if (_canReportComment())
                PopupMenuItem<String>(
                    value: 'Report',
                    child: Row(
                      children: [Text(S.of(context).label_title_report)],
                    )),
            ],
          )
        : Container(
            width: 24,
          );
  }

  Future<void> _reportComment({required String commentId}) async {
    await supabase.from('comment').update({
      'report': true,
    }).eq('id', commentId);
  }

  bool _canDeleteComment() {
    return widget.comment.userId == supabase.auth.currentUser?.id &&
        widget.comment.deletedAt == null;
  }

  bool _canReportComment() {
    return widget.comment.userId != supabase.auth.currentUser?.id &&
        widget.comment.deletedAt == null;
  }
}
