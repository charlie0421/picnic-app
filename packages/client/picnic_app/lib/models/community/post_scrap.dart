import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/community/board.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/models/user_profiles.dart';

part 'post_scrap.freezed.dart';
part 'post_scrap.g.dart';

@freezed
class PostScrapModel with _$PostScrapModel {
  const PostScrapModel._();

  const factory PostScrapModel({
    required String post_id,
    required String user_id,
    required UserProfilesModel? user_profiles,
    required DateTime created_at,
    required DateTime updated_at,
    required BoardModel? board,
    required PostModel? post,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
  }) = _PostScrapModel;

  factory PostScrapModel.fromJson(Map<String, dynamic> json) =>
      _$PostScrapModelFromJson(json);
}
