import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/constants.dart';
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
      icon: const Icon(Icons.more_vert),
      onSelected: (String result) async {
        if (result == 'Report') {
          logger.i('widget.openReportModal: ${widget.openReportModal}');
          if (widget.openReportModal != null) {
            widget.openReportModal!(
                S.of(context).label_title_report, widget.post);
          }
        } else if (result == 'Delete') {
          await deletePost(ref, widget.post.post_id);
          widget.refreshFunction();
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
    return widget.post.user_id == supabase.auth.currentUser?.id &&
        widget.post.deletedAt == null;
  }

  bool _canReportPost() {
    return true;
    // return widget.post.user_id != supabase.auth.currentUser?.id &&
    //     widget.post.deletedAt == null;
  }
}
