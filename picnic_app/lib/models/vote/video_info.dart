import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/reflector.dart';

part 'video_info.freezed.dart';
part 'video_info.g.dart';

@reflector
@freezed
class VideoInfo with _$VideoInfo {
  const factory VideoInfo({
    required int id,
    required String video_id,
    required Map<String, String> title,
    required String thumbnail_url,
  }) = _VideoInfo;

  factory VideoInfo.fromJson(Map<String, dynamic> json) =>
      _$VideoInfoFromJson(json);
}
