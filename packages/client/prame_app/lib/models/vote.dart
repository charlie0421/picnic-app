import 'package:json_annotation/json_annotation.dart';
import 'package:prame_app/models/article_image.dart';
import 'package:prame_app/models/comment.dart';
import 'package:prame_app/models/gallery.dart';
import 'package:prame_app/models/meta.dart';
import 'package:prame_app/reflector.dart';

part 'vote.g.dart';

@reflector
@JsonSerializable()
class VoteListModel {
  final List<VoteModel> items;
  final MetaModel meta;

  VoteListModel({
    required this.items,
    required this.meta,
  });

  factory VoteListModel.fromJson(Map<String, dynamic> json) =>
      _$VoteListModelFromJson(json);

  Map<String, dynamic> toJson() => _$VoteListModelToJson(this);
}

@reflector
@JsonSerializable()
class VoteModel {
  final int id;
  final String voteTitle;
  final String voteCategory;
  final String mainImage;
  final String waitImage;
  final String resultImage;
  final String voteContent;
  final List<VoteItem> voteItems;
  final DateTime createdAt;
  final DateTime visibleAt;
  final DateTime stopAt;
  final DateTime startAt;

  VoteModel({
    required this.id,
    required this.voteTitle,
    required this.voteCategory,
    required this.mainImage,
    required this.waitImage,
    required this.resultImage,
    required this.voteContent,
    required this.voteItems,
    required this.visibleAt,
    required this.stopAt,
    required this.startAt,
    required this.createdAt,
  });

  factory VoteModel.fromJson(Map<String, dynamic> json) =>
      _$VoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$VoteModelToJson(this);
}

@reflector
@JsonSerializable()
class VoteItem {
  final int id;
  final int voteTotal;
  final int voteId;
  final MyStarMemberModel myStarMember;

  VoteItem({
    required this.id,
    required this.voteTotal,
    required this.voteId,
    required this.myStarMember,
  });

  factory VoteItem.fromJson(Map<String, dynamic> json) =>
      _$VoteItemFromJson(json);

  Map<String, dynamic> toJson() => _$VoteItemToJson(this);
}

@reflector
@JsonSerializable()
class MyStarMemberModel {
  final int id;
  final String nameKo;
  final String nameEn;
  final String gender;
  final String image;

  MyStarMemberModel({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.gender,
    required this.image,
  });

  factory MyStarMemberModel.fromJson(Map<String, dynamic> json) =>
      _$MyStarMemberModelFromJson(json);

  Map<String, dynamic> toJson() => _$MyStarMemberModelToJson(this);
}
