import 'package:freezed_annotation/freezed_annotation.dart';

part '../../../generated/models/vote/video_info.freezed.dart';
part '../../../generated/models/vote/video_info.g.dart';

@freezed
class VideoInfo with _$VideoInfo {
  const factory VideoInfo({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'video_id') required String videoId,
    @JsonKey(name: 'video_url') required String videoUrl,
    @JsonKey(name: 'title') required Map<String, String> title,
    @JsonKey(name: 'thumbnail_url') required String thumbnailUrl,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'channel_title') required String channelTitle,
    @JsonKey(name: 'channel_id') required String channelId,
    @JsonKey(name: 'channel_thumbnail') required String channelThumbnail,
  }) = _VideoInfo;

  factory VideoInfo.fromJson(Map<String, dynamic> json) =>
      _$VideoInfoFromJson(json);
}
