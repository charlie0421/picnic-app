import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/community/board.dart';
import 'package:picnic_app/models/user_profiles.dart';

part 'post.freezed.dart';
part 'post.g.dart';

@freezed
class PostModel with _$PostModel {
  const PostModel._();

  const factory PostModel({
    required String post_id,
    required String user_id,
    required UserProfilesModel? user_profiles,
    required String board_id,
    required String title,
    required List<dynamic> content,
    required int view_count,
    required int reply_count,
    required bool is_hidden,
    required DateTime created_at,
    required DateTime updated_at,
    required BoardModel boards,
    required bool is_anonymous,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
  }) = _PostModel;

  factory PostModel.fromJson(Map<String, dynamic> json) =>
      _$PostModelFromJson(json);
}
