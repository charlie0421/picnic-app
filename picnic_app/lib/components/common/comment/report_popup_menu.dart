import 'package:flutter/material.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/supabase_options.dart';

class ReportPopupMenu extends StatelessWidget {
  final BuildContext context;
  final String commentId;

  const ReportPopupMenu(
      {super.key, required this.commentId, required this.context});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert),
      onSelected: (String result) {
        if (result == 'Report') {
          showSimpleDialog(
              title: S.of(context).label_title_report,
              content: S.of(context).message_report_confirm,
              onOk: () async {
                _reportComment(commentId: commentId);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(S.of(context).message_report_ok),
                    duration: const Duration(microseconds: 500)));
                Navigator.pop(context);
              },
              onCancel: () => Navigator.pop(context));
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
            value: 'Report',
            child: Row(
              children: [
                const Icon(
                  Icons.flag,
                  color: picMainColor,
                ),
                const SizedBox(width: 5),
                Text(S.of(context).label_title_report)
              ],
            )),
      ],
    );
  }

  Future<void> _reportComment({required String commentId}) async {
    await supabase.from('comment').update({
      'report': true,
    }).eq('id', commentId);
  }
}
