import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/data/models/vote/artist_group.dart';

part '../../../generated/models/vote/artist.freezed.dart';
part '../../../generated/models/vote/artist.g.dart';

@freezed
class ArtistModel with _$ArtistModel {
  const ArtistModel._();

  const factory ArtistModel({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'name') required Map<String, dynamic> name,
    @JsonKey(name: 'yy') int? yy,
    @JsonKey(name: 'mm') int? mm,
    @JsonKey(name: 'dd') int? dd,
    @JsonKey(name: 'birth_date') DateTime? birthDate,
    @JsonKey(name: 'gender') String? gender,
    @JsonKey(name: 'artist_group') ArtistGroupModel? artistGroup,
    @JsonKey(name: 'image') String? image,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'isBookmarked') bool? isBookmarked,
  }) = _ArtistModel;

  factory ArtistModel.fromJson(Map<String, dynamic> json) =>
      _$ArtistModelFromJson(json);

  @override
  DateTime? get birthDate {
    if (super.birthDate != null) return super.birthDate;
    if (yy != null && mm != null && dd != null) {
      try {
        return DateTime(yy!, mm!, dd!);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  String? get formattedBirthDate {
    final date = birthDate;
    if (date == null) return null;
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  String? get formattedName {
    if (name.containsKey('ko')) {
      return name['ko'];
    } else if (name.containsKey('en')) {
      return name['en'];
    } else if (name.isNotEmpty) {
      return name.values.first;
    }
    return null;
  }

  bool get isDeleted => deletedAt != null;
}
