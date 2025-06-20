import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/supabase_options.dart';

class PostPopupMenu extends ConsumerStatefulWidget {
  final BuildContext context;
  final PostModel post;
  final Function? refreshFunction;
  final Function? openReportModal;
  final Function? deletePost;

  const PostPopupMenu({
    super.key,
    required this.post,
    required this.context,
    this.refreshFunction,
    this.openReportModal,
    this.deletePost,
  });

  // required

  @override
  ConsumerState<PostPopupMenu> createState() => _PostPopupMenuState();
}

class _PostPopupMenuState extends ConsumerState<PostPopupMenu> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!isSupabaseLoggedSafely) {
          showRequireLoginDialog();
        }
      },
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        enabled: isSupabaseLoggedSafely,
        child: SvgPicture.asset(
          package: 'picnic_lib',
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
              await widget.openReportModal!
                      (t('label_title_report'), widget.post)
                  .then((value) {
                if (widget.refreshFunction != null) widget.refreshFunction!();
              });
            }
          } else if (result == 'Delete') {
            showSimpleDialog(
              title: t('popup_label_delete'),
              content: t('post_comment_delete_confirm'),
              onOk: () async {
                if (widget.deletePost != null) widget.deletePost!(widget.post);
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
                children: [Text(t('popup_label_delete'))],
              )),
          PopupMenuItem<String>(
              value: 'Report',
              enabled: _canReportPost(),
              child: Row(
                children: [Text(t('label_title_report'))],
              )),
        ],
      ),
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
