import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/reflector.dart';

part 'reward.freezed.dart';
part 'reward.g.dart';

@reflector
@freezed
class RewardModel with _$RewardModel {
  const RewardModel._();

  const factory RewardModel(
      {required int id,
      Map<String, dynamic>? title,
      String? thumbnail,
      List<String>? overview_images,
      Map<String, dynamic>? location,
      Map<String, dynamic>? size_guide,
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

  String getThumbnailUrl() {
    return 'https://cdn-dev.picnic.fan/reward/$id/$thumbnail';
  }

  getImageUrl(String key, int index) {
    return 'https://cdn-dev.picnic.fan/reward/$id/${key}';
  }

  factory RewardModel.fromJson(Map<String, dynamic> json) =>
      _$RewardModelFromJson(json);
}
