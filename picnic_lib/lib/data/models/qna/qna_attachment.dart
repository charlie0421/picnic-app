import 'package:freezed_annotation/freezed_annotation.dart';

part '../../../generated/providers/models/qna/qna_attachment.freezed.dart';
part '../../../generated/providers/models/qna/qna_attachment.g.dart';

@freezed
abstract class QnaAttachment with _$QnaAttachment {
  const factory QnaAttachment({
    required int id,
    required int messageId,
    required String fileName,
    required String filePath,
    String? fileType,
    int? fileSize,
    required DateTime createdAt,
  }) = _QnaAttachment;

  factory QnaAttachment.fromJson(Map<String, dynamic> json) =>
      _$QnaAttachmentFromJson(json);
}
