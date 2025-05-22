import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';

part '../../../generated/models/community/post_scrap.freezed.dart';
part '../../../generated/models/community/post_scrap.g.dart';

@freezed
class PostScrapModel with _$PostScrapModel {
  const PostScrapModel._();

  const factory PostScrapModel({
    @JsonKey(name: 'post_id') required String postId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'user_profiles') required UserProfilesModel? userProfiles,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'board') required BoardModel? board,
    @JsonKey(name: 'post') required PostModel? post,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
  }) = _PostScrapModel;

  factory PostScrapModel.fromJson(Map<String, dynamic> json) =>
      _$PostScrapModelFromJson(json);
}
