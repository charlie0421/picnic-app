import 'package:json_annotation/json_annotation.dart';
import 'package:picnic_app/reflector.dart';

part 'reward.g.dart';

// @reflector
// @JsonSerializable()
// class CelebRewardListModel {
//   final List<CelebRewardModel> items;
//   final MetaModel meta;
//
//   CelebRewardListModel({
//     required this.items,
//     required this.meta,
//   });
//
//   factory CelebRewardListModel.fromJson(Map<String, dynamic> json) =>
//       _$CelebRewardListModelFromJson(json);
//
//   Map<String, dynamic> toJson() => _$CelebRewardListModelToJson(this);
// }

@reflector
@JsonSerializable()
class RewardModel {
  final int id;
  final String title_ko;
  final String title_en;
  String? thumbnail;

  RewardModel({
    required this.id,
    required this.title_ko,
    required this.title_en,
    this.thumbnail,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) =>
      _$RewardModelFromJson(json);

  Map<String, dynamic> toJson() => _$RewardModelToJson(this);
}
