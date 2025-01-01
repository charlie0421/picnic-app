import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/data/models/community/post.dart';
import 'package:picnic_app/data/models/pic/comment_like.dart';
import 'package:picnic_app/data/models/user_profiles.dart';

part '../../../generated/models/common/comment.freezed.dart';
part '../../../generated/models/common/comment.g.dart';

@freezed
class CommentModel with _$CommentModel {
  const CommentModel._();

  const factory CommentModel({
    @JsonKey(name: 'comment_id') required String commentId,
    @JsonKey(name: 'user_id') String? userId,
    required List<CommentModel>? children,
    required UserCommentLikeModel? myLike,
    @JsonKey(name: 'user_profiles') required UserProfilesModel? user,
    required int likes,
    required int replies,
    required Map<String, dynamic>? content,
    required bool? isLikedByMe,
    required bool? isReportedByMe,
    required bool? isBlindedByAdmin,
    required bool? isRepliedByMe,
    required PostModel? post,
    required String? locale,
    @JsonKey(name: 'parent_comment_id') required String? parentCommentId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
  }) = _CommentModel;

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);
}
