import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/community/board.dart';
import 'package:picnic_app/models/user_profiles.dart';

part 'post.freezed.dart';
part 'post.g.dart';

@freezed
class PostModel with _$PostModel {
  const PostModel._();

  const factory PostModel({
    @JsonKey(name: 'post_id') required String postId,
    @JsonKey(name: 'user_id') required String? userId,
    @JsonKey(name: 'user_profiles') required UserProfilesModel? userProfiles,
    @JsonKey(name: 'board_id') required String? boardId,
    @JsonKey(name: 'title') required String? title,
    @JsonKey(name: 'content') required List<dynamic>? content,
    @JsonKey(name: 'view_count') required int? viewCount,
    @JsonKey(name: 'reply_count') required int? replyCount,
    @JsonKey(name: 'is_hidden') required bool? isHidden,
    @JsonKey(name: 'board') required BoardModel? board,
    @JsonKey(name: 'is_anonymous') required bool? isAnonymous,
    @JsonKey(name: 'is_scraped') required bool? isScraped,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
  }) = _PostModel;

  factory PostModel.fromJson(Map<String, dynamic> json) =>
      _$PostModelFromJson(json);
}
