import 'package:freezed_annotation/freezed_annotation.dart';

part '../../../generated/providers/models/qna/qa_thread.freezed.dart';
part '../../../generated/providers/models/qna/qa_thread.g.dart';

@freezed
abstract class QnaThread with _$QnaThread {
  const factory QnaThread({
    required int id,
    required String userId,
    required String title,
    required DateTime createdAt,
    required String status,
    required DateTime updatedAt,
  }) = _QnaThread;

  factory QnaThread.fromJson(Map<String, dynamic> json) =>
      _$QnaThreadFromJson(json);
}
