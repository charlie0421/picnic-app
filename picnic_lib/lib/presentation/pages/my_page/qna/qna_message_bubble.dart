import 'package:flutter/material.dart';
import 'package:picnic_lib/core/utils/date.dart';
import 'package:picnic_lib/data/models/qna/qna_attachment.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_detail_utils.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_full_screen_image_viewer.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_video_player_page.dart';
import 'package:picnic_lib/presentation/widgets/media/video_thumbnail.dart';
import 'package:picnic_lib/presentation/widgets/media/image_thumbnail.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:url_launcher/url_launcher.dart';

class QnaMessageBubble extends StatelessWidget {
  final QnaMessage message;
  final bool isMyMessage;
  final String Function(String path) getPublicUrl;

  const QnaMessageBubble({
    super.key,
    required this.message,
    required this.isMyMessage,
    required this.getPublicUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = message.content != null && message.content!.isNotEmpty;
    final attachments = _buildAttachments(context, message, hasText);

    if (!hasText && attachments.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: isMyMessage
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: attachments,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          color: isMyMessage ? AppColors.primary500 : AppColors.grey200,
          child: Column(
            crossAxisAlignment: isMyMessage
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasText)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    message.content!,
                    style: getTextStyle(
                      AppTypo.body14R,
                      isMyMessage ? AppColors.grey00 : AppColors.grey900,
                    ),
                  ),
                ),
              ...attachments,
              if (hasText)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 8.0),
                  child: Text(
                    formatTimeAgo(context, message.createdAt.toLocal()),
                    style: getTextStyle(
                      AppTypo.caption12R,
                      isMyMessage
                          ? AppColors.grey00.withAlpha(204)
                          : AppColors.grey400,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAttachments(
    BuildContext context,
    QnaMessage message,
    bool hasText,
  ) {
    return message.attachments.map((att) {
      final isImage = isImageAttachment(att);
      final isVideo = isVideoAttachment(att);

      if (isImage) {
        final imageWidget = _buildImageAttachment(context, att, message, hasText);
        return hasText
            ? Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                child: imageWidget,
              )
            : imageWidget;
      } else if (isVideo) {
        final videoWidget = _buildVideoAttachment(context, att);
        return hasText
            ? Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                child: videoWidget,
              )
            : videoWidget;
      } else {
        return _buildFileAttachment(context, att);
      }
    }).toList();
  }

  Widget _buildImageAttachment(
    BuildContext context,
    QnaAttachment att,
    QnaMessage message,
    bool hasText,
  ) {
    final imageUrl = getPublicUrl(att.filePath);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: GestureDetector(
        onTap: () {
          final imageAttachments =
              message.attachments.where(isImageAttachment).toList();
          final imageUrls =
              imageAttachments.map((a) => getPublicUrl(a.filePath)).toList();
          final currentIndex = imageAttachments.indexOf(att);

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => QnaFullScreenImageViewer(
                imageUrls: imageUrls,
                initialIndex: currentIndex,
              ),
            ),
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            ImageThumbnailFromUrl(imageUrl: imageUrl, fit: BoxFit.cover),
            if (!hasText)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(178),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formatTimeAgo(context, message.createdAt.toLocal()),
                    style: getTextStyle(
                      AppTypo.caption12R,
                      AppColors.grey00.withAlpha(204),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoAttachment(BuildContext context, QnaAttachment att) {
    final videoUrl = getPublicUrl(att.filePath);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QnaVideoPlayerPage(videoUrl: videoUrl),
          ),
        );
      },
      child: VideoThumbnailFromUrl(videoUrl: videoUrl),
    );
  }

  Widget _buildFileAttachment(BuildContext context, QnaAttachment att) {
    final fileUrl = getPublicUrl(att.filePath);
    return InkWell(
      onTap: () async {
        try {
          final uri = Uri.parse(fileUrl);
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (!launched && context.mounted) {
            SnackbarUtil().error('Cannot open the link.', context: context);
          }
        } catch (_) {
          if (context.mounted) {
            SnackbarUtil().error('Cannot open the link.', context: context);
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          att.fileName,
          style: const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

}
