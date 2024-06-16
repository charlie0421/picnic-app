import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/reflector.dart';

part 'reward.freezed.dart';
part 'reward.g.dart';

@reflector
@freezed
class RewardModel with _$RewardModel {
  const RewardModel._();

  const factory RewardModel({
    required int id,
    required String title_ko,
    required String title_en,
    required String title_ja,
    required String title_zh,
    String? thumbnail,
  }) = _RewardModel;

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

  factory RewardModel.fromJson(Map<String, dynamic> json) =>
      _$RewardModelFromJson(json);
}
