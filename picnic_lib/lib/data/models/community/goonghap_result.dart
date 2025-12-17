import 'package:freezed_annotation/freezed_annotation.dart';

part '../../../generated/providers/models/community/goonghap_result.freezed.dart';
part '../../../generated/providers/models/community/goonghap_result.g.dart';

@freezed
abstract class GoonghapResult with _$GoonghapResult {
  const factory GoonghapResult({
    required String id,
    required String userId,
    required String idolName,
    required DateTime userBirthDate,
    required DateTime idolBirthDate,
    required String userGender,
    String? birthTime, // Optional
    required int goonghapScore,
    required String? goonghapSummary,
    required Map<String, dynamic>? details,
    required List<String>? tips,
    required DateTime createdAt,
  }) = _GoonghapResult;

  factory GoonghapResult.fromJson(Map<String, dynamic> json) =>
      _$GoonghapResultFromJson(json);
}

@freezed
abstract class StyleDetails with _$StyleDetails {
  const factory StyleDetails({
    required String? idolStyle,
    required String? userStyle,
    required String? coupleStyle,
  }) = _StyleDetails;

  factory StyleDetails.fromJson(Map<String, dynamic> json) =>
      _$StyleDetailsFromJson(json);
}

@freezed
abstract class ActivitiesDetails with _$ActivitiesDetails {
  const factory ActivitiesDetails({
    required List<String>? recommended,
    required String? description,
  }) = _ActivitiesDetails;

  factory ActivitiesDetails.fromJson(Map<String, dynamic> json) =>
      _$ActivitiesDetailsFromJson(json);
}
