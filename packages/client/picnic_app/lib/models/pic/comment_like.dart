import 'package:freezed_annotation/freezed_annotation.dart';

part '../../generated/models/pic/comment_like.freezed.dart';
part '../../generated/models/pic/comment_like.g.dart';

@freezed
class UserCommentLikeModel with _$UserCommentLikeModel {
  const UserCommentLikeModel._();

  const factory UserCommentLikeModel({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'user_id') required int userId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _UserCommentLikeModel;

  factory UserCommentLikeModel.fromJson(Map<String, dynamic> json) =>
      _$UserCommentLikeModelFromJson(json);
}
