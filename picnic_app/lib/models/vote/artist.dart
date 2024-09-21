import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/vote/artist_group.dart';
import 'package:picnic_app/reflector.dart';

part 'artist.freezed.dart';
part 'artist.g.dart';

@reflector
@freezed
class ArtistModel with _$ArtistModel {
  const ArtistModel._();

  const factory ArtistModel({
    required int id,
    required Map<String, dynamic> name,
    required int? yy,
    required int? mm,
    required int? dd,
    required String gender,
    required String image,
    required ArtistGroupModel artist_group,
    required bool? isBookmarked,
    int? originalIndex,
  }) = _ArtistModel;

  factory ArtistModel.fromJson(Map<String, dynamic> json) =>
      _$ArtistModelFromJson(json);
}
