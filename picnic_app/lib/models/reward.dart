import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';

part 'reward.freezed.dart';
part 'reward.g.dart';

@freezed
class RewardModel with _$RewardModel {
  const RewardModel._();

  const factory RewardModel(
      {@JsonKey(name: 'id') required int id,
      @JsonKey(name: 'title') Map<String, dynamic>? title,
      @JsonKey(name: 'thumbnail') String? thumbnail,
      @JsonKey(name: 'overview_images') List<String>? overviewImages,
      @JsonKey(name: 'location') Map<String, dynamic>? location,
      @JsonKey(name: 'size_guide') Map<String, dynamic>? sizeGuide,
      @JsonKey(name: 'size_guide_images')
      List<String>? size_guide_images}) = _RewardModel;
  String getTitle() {
    if (Intl.getCurrentLocale() == 'ko') {
      return title!['ko'];
    } else if (Intl.getCurrentLocale() == 'en') {
      return title!['en'];
    } else if (Intl.getCurrentLocale() == 'ja') {
      return title!['ja'];
    } else {
      return title!['zh'];
    }
  }

  factory RewardModel.fromJson(Map<String, dynamic> json) =>
      _$RewardModelFromJson(json);
}
