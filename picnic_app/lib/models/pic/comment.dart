import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/models/pic/comment_like.dart';
import 'package:picnic_app/models/user_profiles.dart';
import 'package:picnic_app/reflector.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

@reflector
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

@reflector
@freezed
class CommentModel with _$CommentModel {
  const CommentModel._();

  const factory CommentModel({
    required int id,
    required List<CommentModel>? children,
    required UserCommentLikeModel? myLike,
    required UserProfilesModel? user,
    required int likes,
    required String content,
    required int? parentId,
    required DateTime created_at,
  }) = _CommentModel;

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);
}
