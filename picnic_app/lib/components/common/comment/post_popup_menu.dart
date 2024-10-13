import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/app.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/providers/community/post_provider.dart';
import 'package:picnic_app/supabase_options.dart';

class PostPopupMenu extends ConsumerStatefulWidget {
  final BuildContext context;
  final PostModel post;
  final Function refreshFunction;
  final Function? openReportModal;

  const PostPopupMenu({
    super.key,
    required this.post,
    required this.context,
    required this.refreshFunction,
    this.openReportModal,
  });
  // required

  @override
  ConsumerState<PostPopupMenu> createState() => _PostPopupMenuState();
}

class _PostPopupMenuState extends ConsumerState<PostPopupMenu> {
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
          logger.i('widget.openReportModal: ${widget.openReportModal}');

          if (widget.openReportModal != null) {
            widget.openReportModal!(
                S.of(context).label_title_report, widget.post);
          }
        } else if (result == 'Delete') {
          showSimpleDialog(
            title: S.of(context).popup_label_delete,
            content: '정말로 삭제하시겠습니까?',
            onOk: () async {
              await deletePost(ref, widget.post.postId);
              widget.refreshFunction();
              if (navigatorKey.currentContext != null) {
                Navigator.of(navigatorKey.currentContext!).pop();
              }
            },
            onCancel: () => Navigator.of(context).pop(),
          );
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
            value: 'Delete',
            enabled: _canDeletePost(),
            child: Row(
              children: [Text(S.of(context).popup_label_delete)],
            )),
        PopupMenuItem<String>(
            value: 'Report',
            enabled: _canReportPost(),
            child: Row(
              children: [Text(S.of(context).label_title_report)],
            )),
      ],
    );
  }

  bool _canDeletePost() {
    return widget.post.userId == supabase.auth.currentUser?.id &&
        widget.post.deletedAt == null;
  }

  bool _canReportPost() {
    return widget.post.userId != supabase.auth.currentUser?.id &&
        widget.post.deletedAt == null;
  }
}
