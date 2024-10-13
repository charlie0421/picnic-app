import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_version.freezed.dart';
part 'app_version.g.dart';

@freezed
class AppVersionModel with _$AppVersionModel {
  const factory AppVersionModel({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'ios') required Map<String, dynamic> ios,
    @JsonKey(name: 'android') required Map<String, dynamic> android,
    @JsonKey(name: 'macos') required Map<String, dynamic> macos,
    @JsonKey(name: 'windows') required Map<String, dynamic> windows,
    @JsonKey(name: 'linux') required Map<String, dynamic> linux,
  }) = _AppVersionModel;

  factory AppVersionModel.fromJson(Map<String, dynamic> json) =>
      _$AppVersionModelFromJson(json);
}
