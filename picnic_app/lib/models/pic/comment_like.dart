import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment_like.freezed.dart';

part 'comment_like.g.dart';

@freezed
class UserCommentLikeModel with _$UserCommentLikeModel {
  const UserCommentLikeModel._();

  const factory UserCommentLikeModel({
    required int id,
    required int user_id,
    required DateTime created_at,
  }) = _UserCommentLikeModel;

  factory UserCommentLikeModel.fromJson(Map<String, dynamic> json) =>
      _$UserCommentLikeModelFromJson(json);
}
