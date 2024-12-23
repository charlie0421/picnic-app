import 'package:freezed_annotation/freezed_annotation.dart';

part '../generated/models/reward.freezed.dart';
part '../generated/models/reward.g.dart';

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
          @JsonKey(name: 'size_guide_images') List<String>? sizeGuideImages}) =
      _RewardModel;

  factory RewardModel.fromJson(Map<String, dynamic> json) =>
      _$RewardModelFromJson(json);
}
