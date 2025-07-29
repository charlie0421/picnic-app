import 'package:freezed_annotation/freezed_annotation.dart';

part '../../../generated/models/qna/qna_thread.freezed.dart';
part '../../../generated/models/qna/qna_thread.g.dart';

@freezed
class QnaThread with _$QnaThread {
  const factory QnaThread({
    required int id,
    required String userId,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String status,
  }) = _QnaThread;

  factory QnaThread.fromJson(Map<String, dynamic> json) =>
      _$QnaThreadFromJson(json);
}
