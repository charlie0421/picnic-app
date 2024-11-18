import 'package:freezed_annotation/freezed_annotation.dart';

part '../../generated/models/community/compatibility_result.freezed.dart';

part '../../generated/models/community/compatibility_result.g.dart';

@freezed
class CompatibilityResult with _$CompatibilityResult {
  const factory CompatibilityResult({
    required String id,
    required String userId,
    required String idolName,
    required DateTime userBirthDate,
    required DateTime idolBirthDate,
    required String userGender,
    String? birthTime, // Optional
    required int compatibilityScore,
    required String compatibilitySummary,
    required Map<String, dynamic> details,
    required List<String> tips,
    required DateTime createdAt,
  }) = _CompatibilityResult;

  factory CompatibilityResult.fromJson(Map<String, dynamic> json) =>
      _$CompatibilityResultFromJson(json);
}

@freezed
class StyleDetails with _$StyleDetails {
  const factory StyleDetails({
    required String idolStyle,
    required String userStyle,
    required String coupleStyle,
  }) = _StyleDetails;

  factory StyleDetails.fromJson(Map<String, dynamic> json) =>
      _$StyleDetailsFromJson(json);
}

@freezed
class ActivitiesDetails with _$ActivitiesDetails {
  const factory ActivitiesDetails({
    required List<String> recommended,
    required String description,
  }) = _ActivitiesDetails;

  factory ActivitiesDetails.fromJson(Map<String, dynamic> json) =>
      _$ActivitiesDetailsFromJson(json);
}
