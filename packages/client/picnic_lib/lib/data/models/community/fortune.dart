import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';

part '../../../generated/models/community/fortune.freezed.dart';
part '../../../generated/models/community/fortune.g.dart';

@freezed
class FortuneModel with _$FortuneModel {
  const factory FortuneModel({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'year') required int year,
    @JsonKey(name: 'artist_id') required int artistId,
    @JsonKey(name: 'artist') required ArtistModel artist,
    @JsonKey(name: 'overall_luck') required String overallLuck,
    @JsonKey(name: 'monthly_fortunes')
    required List<MonthlyFortuneModel> monthlyFortunes,
    @JsonKey(name: 'aspects') required AspectModel aspects,
    @JsonKey(name: 'lucky') required LuckyModel lucky,
    @JsonKey(name: 'advice') required List<String> advice,
  }) = _FortuneModel;

  factory FortuneModel.fromJson(Map<String, dynamic> json) =>
      _$FortuneModelFromJson(json);
}

@freezed
class MonthlyFortuneModel with _$MonthlyFortuneModel {
  const factory MonthlyFortuneModel({
    @JsonKey(name: 'month') required int month,
    @JsonKey(name: 'honor') required String honor,
    @JsonKey(name: 'career') required String career,
    @JsonKey(name: 'health') required String health,
    @JsonKey(name: 'summary') required String summary,
  }) = _MonthlyFortuneModel;

  factory MonthlyFortuneModel.fromJson(Map<String, dynamic> json) =>
      _$MonthlyFortuneModelFromJson(json);
}

@freezed
class AspectModel with _$AspectModel {
  const factory AspectModel({
    @JsonKey(name: 'honor') required String honor,
    @JsonKey(name: 'career') required String career,
    @JsonKey(name: 'health') required String health,
    @JsonKey(name: 'finances') required String finances,
    @JsonKey(name: 'relationships') required String relationships,
  }) = _AspectModel;

  factory AspectModel.fromJson(Map<String, dynamic> json) =>
      _$AspectModelFromJson(json);
}

@freezed
class LuckyModel with _$LuckyModel {
  const factory LuckyModel({
    @JsonKey(name: 'days') required List<String> days,
    @JsonKey(name: 'colors') required List<String> colors,
    @JsonKey(name: 'numbers') required List<int> numbers,
    @JsonKey(name: 'directions') required List<String> directions,
  }) = _LuckyModel;

  factory LuckyModel.fromJson(Map<String, dynamic> json) =>
      _$LuckyModelFromJson(json);
}
