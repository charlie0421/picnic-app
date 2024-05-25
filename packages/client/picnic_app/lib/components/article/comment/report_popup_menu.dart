import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/common_dialog.dart';
import 'package:picnic_app/models/fan/comment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportPopupMenu extends StatelessWidget {
  final BuildContext context;
  final PagingController<int, CommentModel> pagingController;
  final int commentId;

  const ReportPopupMenu(
      {super.key,
      required this.commentId,
      required this.pagingController,
      required this.context});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert),
      onSelected: (String result) {
        if (result == 'Report') {
          showCommonDialog(
              context: context,
              title: Intl.message('label_title_report'),
              contents: Intl.message('message_report_confirm'),
              okBtnFn: () async {
                _reportComment(commentId: commentId);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(Intl.message('message_report_ok')),
                    duration: const Duration(microseconds: 500)));
                Navigator.pop(context);
              },
              cancelBtnFn: () => Navigator.pop(context));
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
            value: 'Report',
            child: Row(
              children: [
                const Icon(
                  Icons.flag,
                  color: fanMainColor,
                ),
                const SizedBox(width: 5),
                Text(Intl.message('label_title_report'))
              ],
            )),
      ],
    );
  }

  Future<void> _reportComment({required int commentId}) async {
    final response = await Supabase.instance.client.from('comment').update({
      'report': true,
    }).eq('id', commentId);
  }
}
