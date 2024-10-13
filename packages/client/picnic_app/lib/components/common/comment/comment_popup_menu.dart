import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/app.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/providers/community/comments_provider.dart';
import 'package:picnic_app/supabase_options.dart';

class CommentPopupMenu extends ConsumerStatefulWidget {
  final CommentModel comment;
  final Function? refreshFunction;
  final Function? openReportModal;

  const CommentPopupMenu({
    super.key,
    required this.comment,
    this.refreshFunction,
    this.openReportModal,
  });

  @override
  ConsumerState<CommentPopupMenu> createState() => _CommentPopupMenuState();
}

class _CommentPopupMenuState extends ConsumerState<CommentPopupMenu> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      child: SvgPicture.asset(
        'assets/icons/more_style=line.svg',
        width: 20,
        height: 20,
        colorFilter:
            ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
      ),
      onSelected: (String result) async {
        if (result == 'Report') {
          if (widget.openReportModal != null) {
            widget.openReportModal!(
                S.of(context).label_title_report, widget.comment);
          }
        } else if (result == 'Delete') {
          showSimpleDialog(
              title: S.of(context).popup_label_delete,
              content: '정말로 삭제하시겠습니까?',
              onOk: () async {
                await deleteComment(ref, widget.comment.commentId);
                if (widget.refreshFunction != null) {
                  widget.refreshFunction!();
                }
                if (navigatorKey.currentContext != null) {
                  Navigator.of(navigatorKey.currentContext!).pop();
                }
              },
              onCancel: () {
                Navigator.of(context).pop();
              });
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
            value: 'Delete',
            enabled: _canDeleteComment(),
            child: Text(S.of(context).popup_label_delete)),
        PopupMenuItem<String>(
            value: 'Report',
            enabled: _canReportComment(),
            child: Text(S.of(context).label_title_report)),
      ],
    );
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
