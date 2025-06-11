import 'package:freezed_annotation/freezed_annotation.dart';

part '../../../generated/models/vote/vote_item_request.freezed.dart';
part '../../../generated/models/vote/vote_item_request.g.dart';

/// 투표 아이템 요청 모델
///
/// 데이터베이스 구조:
/// - id: UUID (Primary Key)
/// - vote_id: INTEGER (투표 ID)
/// - status: VARCHAR(50) (요청 상태)
/// - created_at, updated_at: TIMESTAMP
@freezed
class VoteItemRequest with _$VoteItemRequest {
  const factory VoteItemRequest({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'vote_id') required int voteId,
    @JsonKey(name: 'status') required String status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _VoteItemRequest;

  factory VoteItemRequest.fromJson(Map<String, dynamic> json) =>
      _$VoteItemRequestFromJson(json);
}
