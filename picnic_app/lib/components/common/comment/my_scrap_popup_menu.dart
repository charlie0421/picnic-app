import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/app.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/providers/community/post_provider.dart';
import 'package:picnic_app/supabase_options.dart';

class MyScrapPopupMenu extends ConsumerStatefulWidget {
  final BuildContext context;
  final PostModel post;
  final Function refreshFunction;

  const MyScrapPopupMenu({
    super.key,
    required this.post,
    required this.context,
    required this.refreshFunction,
  });
  // required

  @override
  ConsumerState<MyScrapPopupMenu> createState() => _MyScrapPopupMenuState();
}

class _MyScrapPopupMenuState extends ConsumerState<MyScrapPopupMenu> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert),
      onSelected: (String result) async {
        if (result == 'Delete') {
          showSimpleDialog(
            title: '스크랩 삭제',
            content: '정말로 삭제하시겠습니까?',
            onOk: () async {
              await unscrapPost(
                  ref, widget.post.post_id, supabase.auth.currentUser!.id);
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
            child: Row(
              children: [Text(S.of(context).popup_label_delete)],
            )),
      ],
    );
  }
}
