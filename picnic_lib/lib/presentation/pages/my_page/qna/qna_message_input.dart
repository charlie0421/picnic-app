import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/media/video_thumbnail.dart';
import 'package:picnic_lib/presentation/widgets/media/image_thumbnail.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';

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
        border: Border(top: BorderSide(color: PicnicUi.border)),
      ),
      child: SafeArea(
        top: false,
        child: Text(
          AppLocalizations.of(context).qna_cannot_send_message_closed,
          textAlign: TextAlign.center,
          style: PicnicUi.text(color: PicnicUi.secondaryText),
        ),
      ),
    );
  }

  Widget _buildOpenInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: PicnicUi.surface,
        border: Border(top: BorderSide(color: PicnicUi.border)),
      ),
      child: SafeArea(
        top: false,
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
      ),
      child: Text(
        AppLocalizations.of(context).qna_auto_close_after_14_days_notice,
        textAlign: TextAlign.center,
        style: PicnicUi.text(size: 12, color: PicnicUi.secondaryText),
      ),
    );
  }

  Widget _buildAttachmentPreview() {
    return SizedBox(
      height: 64,
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
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => onRemoveAttachment(index),
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).deleteButtonTooltip,
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                  padding: const EdgeInsets.all(12),
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: PicnicUi.secondaryText,
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
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        ),
        Expanded(
          child: TextField(
            controller: messageController,
            style: PicnicUi.text(),
            decoration: InputDecoration(
              constraints: const BoxConstraints(minHeight: 48),
              hintText: AppLocalizations.of(context).qna_message_hint,
              hintStyle: PicnicUi.text(color: PicnicUi.secondaryText),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: PicnicUi.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: PicnicUi.actionColor),
              ),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        if (isSending)
          Semantics(
            label: AppLocalizations.of(context).loading,
            liveRegion: true,
            child: const SizedBox.square(
              dimension: 48,
              child: Center(child: SmallPulseLoadingIndicator()),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.send, size: 20),
            onPressed: onSend,
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          ),
      ],
    );
  }
}
