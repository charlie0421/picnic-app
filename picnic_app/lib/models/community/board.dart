import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/vote/artist.dart';

part 'board.freezed.dart';
part 'board.g.dart';

@freezed
class BoardModel with _$BoardModel {
  const BoardModel._();

  const factory BoardModel({
    required String board_id,
    required int artist_id,
    required Map<String, dynamic> name,
    @DescriptionConverter() required dynamic description,
    required bool is_official,
    required DateTime created_at,
    required DateTime updated_at,
    required ArtistModel? artist,
    @JsonKey(name: 'request_message') required String? requestMessage,
  }) = _BoardModel;

  factory BoardModel.fromJson(Map<String, dynamic> json) =>
      _$BoardModelFromJson(json);
}

class DescriptionConverter implements JsonConverter<dynamic, dynamic> {
  const DescriptionConverter();

  @override
  dynamic fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return json;
    } else if (json is String) {
      return json;
    }
    throw ArgumentError('Unexpected type for description: ${json.runtimeType}');
  }

  @override
  dynamic toJson(dynamic object) {
    if (object is Map<String, dynamic> || object is String) {
      return object;
    }
    throw ArgumentError(
        'Unexpected type for description: ${object.runtimeType}');
  }
}
