import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/data/models/qna/qna_attachment.dart';

part '../../../generated/models/qna/qna_message.freezed.dart';
part '../../../generated/models/qna/qna_message.g.dart';

@freezed
class QnaMessage with _$QnaMessage {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory QnaMessage({
    required int id,
    required int threadId,
    required String userId,
    String? content,
    required DateTime createdAt,
    required bool isAdminMessage,
    @Default([])
    @JsonKey(name: 'qna_attachments')
    List<QnaAttachment> attachments,
  }) = _QnaMessage;

  factory QnaMessage.fromJson(Map<String, dynamic> json) =>
      _$QnaMessageFromJson(json);
}
