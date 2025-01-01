import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/data/models/vote/artist.dart';

part '../../../generated/models/community/board.freezed.dart';
part '../../../generated/models/community/board.g.dart';

@freezed
class BoardModel with _$BoardModel {
  const BoardModel._();

  const factory BoardModel({
    @JsonKey(name: 'board_id') required String boardId,
    @JsonKey(name: 'artist_id') required int artistId,
    @JsonKey(name: 'name') required Map<String, dynamic> name,
    @DescriptionConverter() required dynamic description,
    @JsonKey(name: 'is_official') required bool? isOfficial,
    @JsonKey(name: 'created_at') required DateTime? createdAt,
    @JsonKey(name: 'updated_at') required DateTime? updatedAt,
    required ArtistModel? artist,
    @JsonKey(name: 'request_message') required String? requestMessage,
    @JsonKey(name: 'status') required String? status,
    @JsonKey(name: 'creator_id') required String? creatorId,
    @JsonKey(name: 'features') required List<String>? features,
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
