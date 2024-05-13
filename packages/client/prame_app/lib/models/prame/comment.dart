import 'package:json_annotation/json_annotation.dart';
import 'package:prame_app/models/prame/article.dart';
import 'package:prame_app/models/prame/comment_like.dart';
import 'package:prame_app/models/meta.dart';
import 'package:prame_app/models/user.dart';
import 'package:prame_app/reflector.dart';

part 'comment.g.dart';

@reflector
@JsonSerializable()
class CommentListModel {
  final List<CommentModel> items;
  final MetaModel meta;

  CommentListModel({
    required this.items,
    required this.meta,
  });

  factory CommentListModel.fromJson(Map<String, dynamic> json) =>
      _$CommentListModelFromJson(json);

  Map<String, dynamic> toJson() => _$CommentListModelToJson(this);
}

@reflector
@JsonSerializable()
class CommentModel {
  final int id;
  final List<CommentModel>? children; // 자식 댓글 목록
  final UserCommentLikeModel? myLike;
  final UserModel? user;
  final int likes;
  final String content; // 댓글 내용
  final int? parentId;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.children,
    required this.user,
    required this.myLike,
    required this.likes,
    required this.content,
    required this.parentId,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);

  Map<String, dynamic> toJson() => _$CommentModelToJson(this);
}
