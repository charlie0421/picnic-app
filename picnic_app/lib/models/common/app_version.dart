import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_version.freezed.dart';
part 'app_version.g.dart';

@freezed
class AppVersionModel with _$AppVersionModel {
  const AppVersionModel._();

  const factory AppVersionModel(
      {required int id,
      required Map<String, dynamic> ios,
      required Map<String, dynamic> android,
      required Map<String, dynamic> macos,
      required Map<String, dynamic> windows,
      required Map<String, dynamic> linux}) = _AppVersionModel;

  factory AppVersionModel.fromJson(Map<String, dynamic> json) =>
      _$AppVersionModelFromJson(json);
}
