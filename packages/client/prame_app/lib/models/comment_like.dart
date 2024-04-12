import 'package:json_annotation/json_annotation.dart';
import 'package:prame_app/models/meta.dart';
import 'package:prame_app/reflector.dart';

part 'comment_like.g.dart';

@reflector
@JsonSerializable()
class UserCommentLikeListModel {
  final List<UserCommentLikeModel> items;
  final MetaModel meta;

  UserCommentLikeListModel({
    required this.items,
    required this.meta,
  });

  factory UserCommentLikeListModel.fromJson(Map<String, dynamic> json) =>
      _$UserCommentLikeListModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserCommentLikeListModelToJson(this);
}

@reflector
@JsonSerializable()
class UserCommentLikeModel {
  final int id;
  final int userId;
  final DateTime createdAt;

  UserCommentLikeModel({
    required this.id,
    required this.userId,
    required this.createdAt,
  });

  factory UserCommentLikeModel.fromJson(Map<String, dynamic> json) =>
      _$UserCommentLikeModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserCommentLikeModelToJson(this);
}
