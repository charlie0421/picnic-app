import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/community/post_provider.dart';
import 'package:picnic_lib/supabase_options.dart';

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
      child: SvgPicture.asset(
        package: 'picnic_lib',
        'assets/icons/more_style=line.svg',
        width: 20,
        height: 20,
        colorFilter:
            ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
      ),
      onSelected: (String result) async {
        if (result == 'Delete') {
          showSimpleDialog(
            title: S.of(context).post_delete_scrap_title,
            content: S.of(context).post_delete_scrap_confirm,
            onOk: () async {
              await unscrapPost(
                  ref, widget.post.postId, supabase.auth.currentUser!.id);
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
