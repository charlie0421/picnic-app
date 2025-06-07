import 'package:freezed_annotation/freezed_annotation.dart';

part '../../../generated/models/vote/vote_request_user.freezed.dart';
part '../../../generated/models/vote/vote_request_user.g.dart';

@freezed
class VoteRequestUser with _$VoteRequestUser {
  const VoteRequestUser._();

  const factory VoteRequestUser({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'vote_request_id') required String voteRequestId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'status') required String status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _VoteRequestUser;

  factory VoteRequestUser.fromJson(Map<String, dynamic> json) =>
      _$VoteRequestUserFromJson(json);
} 