import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/reflector.dart';

part 'board.freezed.dart';
part 'board.g.dart';

@reflector
@freezed
class BoardModel with _$BoardModel {
  const BoardModel._();

  const factory BoardModel({
    required String board_id,
    required Map<String, dynamic> name,
    required Map<String, dynamic> description,
    required bool is_official,
    required DateTime created_at,
    required DateTime updated_at,
  }) = _BoardModel;

  factory BoardModel.fromJson(Map<String, dynamic> json) =>
      _$BoardModelFromJson(json);
}
