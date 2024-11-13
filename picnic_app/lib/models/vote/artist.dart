import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/vote/artist_group.dart';

part 'artist.freezed.dart';

part 'artist.g.dart';

@freezed
class ArtistModel with _$ArtistModel {
  const factory ArtistModel({
    required int id,
    required Map<String, dynamic> name,
    int? yy,
    int? mm,
    int? dd,
    DateTime? birth_date,
    String? gender,
    ArtistGroupModel? artist_group,
    String? image,
    DateTime? created_at,
    DateTime? updated_at,
    DateTime? deleted_at,
    bool? isBookmarked,
  }) = _ArtistModel;

  factory ArtistModel.fromJson(Map<String, dynamic> json) =>
      _$ArtistModelFromJson(json);

  const ArtistModel._(); // private constructor for custom methods

  DateTime? get birthDate {
    if (birth_date != null) return birth_date;
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

  bool get isDeleted => deleted_at != null;
}
