import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';

part '../../../generated/models/vote/vote_item_request_user.freezed.dart';
part '../../../generated/models/vote/vote_item_request_user.g.dart';

/// 투표 아이템 요청 사용자 모델
///
/// 데이터베이스 구조:
/// - id: UUID (Primary Key)
/// - vote_id: INTEGER (투표 ID)
/// - user_id: UUID (사용자 ID)
/// - artist_id: INTEGER (아티스트 ID, Foreign Key)
/// - status: TEXT (신청 상태)
/// - created_at, updated_at: TIMESTAMP
@freezed
class VoteItemRequestUser with _$VoteItemRequestUser {
  const factory VoteItemRequestUser({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'vote_id') required int voteId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'artist_id') required int artistId,
    @JsonKey(name: 'status') required String status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    // 조인된 아티스트 정보 (선택적)
    @JsonKey(name: 'artist') ArtistModel? artist,
  }) = _VoteItemRequestUser;

  factory VoteItemRequestUser.fromJson(Map<String, dynamic> json) =>
      _$VoteItemRequestUserFromJson(json);
}
