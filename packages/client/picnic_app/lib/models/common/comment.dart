import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/models/pic/comment_like.dart';
import 'package:picnic_app/models/user_profiles.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

@freezed
class CommentListModel with _$CommentListModel {
  const CommentListModel._();

  const factory CommentListModel({
    required List<CommentModel> items,
    required MetaModel meta,
  }) = _CommentListModel;

  factory CommentListModel.fromJson(Map<String, dynamic> json) =>
      _$CommentListModelFromJson(json);
}

@freezed
class CommentModel with _$CommentModel {
  const CommentModel._();

  const factory CommentModel({
    @JsonKey(name: 'comment_id') required String commentId,
    @JsonKey(name: 'user_id') String? userId,
    required List<CommentModel>? children,
    required UserCommentLikeModel? myLike,
    required UserProfilesModel user,
    required int likes,
    required int replies,
    required Map<String, dynamic>? content,
    required bool? isLiked,
    required bool? isReplied,
    required bool? isReportedByUser,
    required bool? isBlindedByAdmin,
    required PostModel? post,
    @JsonKey(name: 'parent_comment_id') required String? parentCommentId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
  }) = _CommentModel;

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);
}
