import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/reflector.dart';

part 'reward.g.dart';

@reflector
@JsonSerializable()
class RewardModel {
  final int id;
  final String title_ko;
  final String title_en;
  final String title_ja;
  final String title_zh;
  String? thumbnail;

  RewardModel({
    required this.id,
    required this.title_ko,
    required this.title_en,
    required this.title_ja,
    required this.title_zh,
    this.thumbnail,
  });

  String getTitle() {
    if (Intl.getCurrentLocale() == 'ko') {
      return title_ko;
    } else if (Intl.getCurrentLocale() == 'en') {
      return title_en;
    } else if (Intl.getCurrentLocale() == 'ja') {
      return title_ja;
    } else {
      return title_zh;
    }
  }

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return _$RewardModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$RewardModelToJson(this);
}
