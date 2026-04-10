import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/media/video_thumbnail.dart';
import 'package:picnic_lib/presentation/widgets/media/image_thumbnail.dart';
import 'package:picnic_lib/ui/style.dart';

class QnaMessageInput extends StatelessWidget {
  final bool isThreadOpen;
  final bool showAutoCloseNotice;
  final bool isSending;
  final List<File> attachments;
  final TextEditingController messageController;
  final VoidCallback onSend;
  final VoidCallback onPickMedia;
  final ValueChanged<int> onRemoveAttachment;

  const QnaMessageInput({
    super.key,
    required this.isThreadOpen,
    required this.showAutoCloseNotice,
    required this.isSending,
    required this.attachments,
    required this.messageController,
    required this.onSend,
    required this.onPickMedia,
    required this.onRemoveAttachment,
  });

  @override
  Widget build(BuildContext context) {
    if (!isThreadOpen) {
      return _buildClosedNotice(context);
    }
    return _buildOpenInput(context);
  }

  Widget _buildClosedNotice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        child: Text(
          AppLocalizations.of(context).qna_cannot_send_message_closed,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.grey500),
        ),
      ),
    );
  }

  Widget _buildOpenInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showAutoCloseNotice) _buildAutoCloseNotice(context),
            if (attachments.isNotEmpty) _buildAttachmentPreview(),
            _buildInputRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoCloseNotice(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Text(
        AppLocalizations.of(context).qna_auto_close_after_14_days_notice,
        textAlign: TextAlign.center,
        style: getTextStyle(AppTypo.caption12R, AppColors.grey600),
      ),
    );
  }

  Widget _buildAttachmentPreview() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        itemBuilder: (context, index) {
          final file = attachments[index];
          final isImage =
              lookupMimeType(file.path)?.startsWith('image/') ?? false;
          final isVideo =
              lookupMimeType(file.path)?.startsWith('video/') ?? false;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 8.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: isImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ImageThumbnailFromFile(
                            file: file,
                            width: 52,
                            height: 52,
                            borderRadius: 8,
                            fit: BoxFit.cover,
                          ),
                        )
                      : isVideo
                      ? VideoThumbnailFromFile(
                          file: file,
                          width: 52,
                          height: 52,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: AppColors.grey200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.insert_drive_file,
                            color: AppColors.grey500,
                          ),
                        ),
                ),
                Positioned(
                  top: -10,
                  right: -10,
                  child: GestureDetector(
                    onTap: () => onRemoveAttachment(index),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputRow(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.perm_media_outlined, size: 20),
          onPressed: onPickMedia,
          tooltip: AppLocalizations.of(context).qna_add_media_tooltip,
          padding: const EdgeInsets.all(4.0),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
        ),
        Expanded(
          child: TextField(
            controller: messageController,
            decoration: InputDecoration.collapsed(
              hintText: AppLocalizations.of(context).qna_message_hint,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        if (isSending)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          )
        else
          IconButton(
            icon: const Icon(Icons.send, size: 20),
            onPressed: onSend,
            padding: const EdgeInsets.all(4.0),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          ),
      ],
    );
  }
}
