import 'package:freezed_annotation/freezed_annotation.dart';

part '../../../generated/models/vote/vote_request.freezed.dart';
part '../../../generated/models/vote/vote_request.g.dart';

@freezed
class VoteRequest with _$VoteRequest {
  const VoteRequest._();

  const factory VoteRequest({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'vote_id') required String voteId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _VoteRequest;

  factory VoteRequest.fromJson(Map<String, dynamic> json) =>
      _$VoteRequestFromJson(json);
}
