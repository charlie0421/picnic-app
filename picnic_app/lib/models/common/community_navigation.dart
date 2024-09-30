import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/reflector.dart';

part 'community_navigation.freezed.dart';

@reflector
@freezed
class CommunityNavigation with _$CommunityNavigation {
  const CommunityNavigation._();

  const factory CommunityNavigation({
    @Default(0) int currentArtistId,
    @Default('') String currentArtistName,
    @Default('') String currentBoardId,
    @Default('') String currentBoardName,
  }) = _Navigation;
}
