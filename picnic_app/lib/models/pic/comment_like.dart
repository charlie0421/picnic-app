import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/meta.dart';
import 'package:picnic_app/reflector.dart';

part 'comment_like.freezed.dart';
part 'comment_like.g.dart';

@reflector
@freezed
class UserCommentLikeListModel with _$UserCommentLikeListModel {
  const UserCommentLikeListModel._();

  const factory UserCommentLikeListModel({
    required List<UserCommentLikeModel> items,
    required MetaModel meta,
  }) = _UserCommentLikeListModel;

  factory UserCommentLikeListModel.fromJson(Map<String, dynamic> json) =>
      _$UserCommentLikeListModelFromJson(json);
}

@reflector
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
