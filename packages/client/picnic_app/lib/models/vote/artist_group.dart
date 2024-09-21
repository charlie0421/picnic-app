import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/reflector.dart';

part 'artist_group.freezed.dart';
part 'artist_group.g.dart';

@reflector
@freezed
class ArtistGroupModel with _$ArtistGroupModel {
  const ArtistGroupModel._();

  const factory ArtistGroupModel(
      {required int id,
      required Map<String, dynamic> name,
      required String image}) = _ArtistGroupModel;

  factory ArtistGroupModel.fromJson(Map<String, dynamic> json) =>
      _$ArtistGroupModelFromJson(json);
}
