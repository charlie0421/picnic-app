import 'package:freezed_annotation/freezed_annotation.dart';

part '../../../generated/models/common/popup.freezed.dart';
part '../../../generated/models/common/popup.g.dart';

@freezed
class Popup with _$Popup {
  const factory Popup({
    required int id,
    required Map<String, String> title,
    required Map<String, String> content,
    Map<String, String>? image,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'start_at') DateTime? startAt,
    @JsonKey(name: 'stop_at') DateTime? stopAt,
  }) = _Popup;

  factory Popup.fromJson(Map<String, dynamic> json) => _$PopupFromJson(json);
}
