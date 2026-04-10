import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_detail_utils.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_message_bubble.dart';
import 'package:picnic_lib/ui/style.dart';

class QnaMessageListView extends StatelessWidget {
  final List<QnaMessage> messages;
  final String currentUserId;
  final String Function(String path) getPublicUrl;

  const QnaMessageListView({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.getPublicUrl,
  });

  @override
  Widget build(BuildContext context) {
    final reversedMessages = messages.reversed.toList();

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(8.0),
      itemCount: reversedMessages.length,
      itemBuilder: (context, index) {
        final message = reversedMessages[index];
        final showDivider = shouldShowDateDivider(
          reversedMessages: reversedMessages,
          index: index,
        );

        return Column(
          children: [
            if (showDivider) _buildDateDivider(context, message.createdAt.toLocal()),
            QnaMessageBubble(
              message: message,
              isMyMessage: message.userId == currentUserId,
              getPublicUrl: getPublicUrl,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateDivider(BuildContext context, DateTime date) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: AppColors.grey300,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          DateFormat(
            'yyyy년 M월 d일',
            AppLocalizations.of(context).localeName,
          ).format(date),
          style: getTextStyle(AppTypo.caption12R, AppColors.grey900),
        ),
      ),
    );
  }
}
