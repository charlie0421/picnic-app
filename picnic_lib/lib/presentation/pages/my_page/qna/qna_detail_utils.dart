import 'package:picnic_lib/data/models/qna/qna_attachment.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';

/// Determines whether the auto-close notice should be shown.
bool shouldShowAutoCloseNotice({
  required String threadStatus,
  required List<QnaMessage> messages,
}) {
  if (threadStatus.toUpperCase() == 'RESOLVED') return false;
  if (messages.isEmpty) return false;
  final latest = messages.reduce(
    (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
  );
  return latest.isAdminMessage;
}

/// Determines if a date divider should be shown between messages
/// in a reversed list at the given index.
bool shouldShowDateDivider({
  required List<QnaMessage> reversedMessages,
  required int index,
}) {
  if (index == reversedMessages.length - 1) {
    return true;
  }
  final prevMessage = reversedMessages[index + 1];
  final currentMessageDate = reversedMessages[index].createdAt.toLocal();
  final prevMessageDate = prevMessage.createdAt.toLocal();
  return currentMessageDate.day != prevMessageDate.day ||
      currentMessageDate.month != prevMessageDate.month ||
      currentMessageDate.year != prevMessageDate.year;
}

/// Determines if an attachment is an image based on MIME type or extension.
bool isImageAttachment(QnaAttachment att) {
  final isImageByMime = att.fileType?.startsWith('image/') ?? false;
  final isImageByExtension = ['jpg', 'jpeg', 'png', 'gif']
      .any((ext) => att.fileName.toLowerCase().endsWith('.$ext'));
  return isImageByMime || isImageByExtension;
}

/// Determines if an attachment is a video based on MIME type.
bool isVideoAttachment(QnaAttachment att) {
  return att.fileType?.startsWith('video/') ?? false;
}
