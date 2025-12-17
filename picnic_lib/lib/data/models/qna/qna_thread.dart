import 'package:freezed_annotation/freezed_annotation.dart';

part '../../../generated/providers/models/qna/qna_thread.freezed.dart';
part '../../../generated/providers/models/qna/qna_thread.g.dart';

@freezed
abstract class QnaThread with _$QnaThread {
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

extension QnaThreadStatusX on QnaThread {
  bool get isReceived => status.toUpperCase() == 'RECEIVED';
  bool get isInProgress => status.toUpperCase() == 'IN_PROGRESS';
  bool get isResolved => status.toUpperCase() == 'RESOLVED';

  // Backward-friendly helpers
  bool get isOpen => !isResolved; // treat RECEIVED/IN_PROGRESS as open
  bool get isClosed => isResolved;
}
