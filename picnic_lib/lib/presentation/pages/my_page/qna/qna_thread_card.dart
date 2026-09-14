import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_status_chip.dart';
import 'package:picnic_lib/presentation/widgets/media/image_thumbnail.dart';
import 'package:picnic_lib/presentation/widgets/media/video_thumbnail.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_surface.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/ui/style.dart';

class QnaThreadCard extends StatelessWidget {
  final QnaThread thread;
  final QnaRepository repository;
  final VoidCallback onTap;

  const QnaThreadCard({
    super.key,
    required this.thread,
    required this.repository,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: PicnicSurface(
        padding: EdgeInsets.symmetric(
          horizontal: PicnicUi.horizontal(16),
          vertical: PicnicUi.vertical(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              thread.title,
              style: PicnicUi.text(size: 16, weight: FontWeight.w600),
            ),
            SizedBox(height: PicnicUi.vertical(8)),
            QnaStatusChip(status: thread.status),
            SizedBox(height: PicnicUi.vertical(8)),
            _AttachmentPreview(threadId: thread.id, repository: repository),
            SizedBox(height: PicnicUi.vertical(8)),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: PicnicUi.quietText),
                SizedBox(width: PicnicUi.horizontal(4)),
                Expanded(
                  child: Text(
                    DateFormat(
                      'yyyy-MM-dd HH:mm',
                    ).format(thread.updatedAt.toLocal()),
                    style: PicnicUi.text(size: 12, color: PicnicUi.quietText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  final int threadId;
  final QnaRepository repository;

  const _AttachmentPreview({required this.threadId, required this.repository});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: repository.getFirstAttachmentForThread(threadId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }
        final att = snapshot.data!;
        final isImage =
            (att.fileType?.startsWith('image/') ?? false) ||
            [
              'jpg',
              'jpeg',
              'png',
              'gif',
            ].any((ext) => att.fileName.toLowerCase().endsWith('.$ext'));
        final isVideo = att.fileType?.startsWith('video/') ?? false;
        final url = repository.getPublicUrl(att.filePath);

        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: isImage
                  ? ImageThumbnailFromUrl(imageUrl: url, fit: BoxFit.cover)
                  : isVideo
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        VideoThumbnailFromUrl(videoUrl: url, fit: BoxFit.cover),
                        const Align(
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: AppColors.grey200,
                      child: const Center(
                        child: Icon(
                          Icons.insert_drive_file,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
