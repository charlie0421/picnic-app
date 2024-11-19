// lib/models/compatibility_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/vote/artist.dart';

part '../../generated/models/community/compatibility.freezed.dart';

part '../../generated/models/community/compatibility.g.dart';

enum CompatibilityStatus { pending, completed, error }

@freezed
class CompatibilityHistoryModel with _$CompatibilityHistoryModel {
  const factory CompatibilityHistoryModel({
    required List<CompatibilityModel> items,
    required bool hasMore,
    @Default(false) bool isLoading,
  }) = _CompatibilityHistoryModel;

  factory CompatibilityHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$CompatibilityHistoryModelFromJson(json);
}

@freezed
class CompatibilityModel with _$CompatibilityModel {
  const CompatibilityModel._(); // 이 줄이 중요합니다

  const factory CompatibilityModel({
    @Default('') String id,
    required String userId,
    required ArtistModel artist,
    @JsonKey(name: 'user_birth_date') required DateTime birthDate,
    @JsonKey(name: 'user_birth_time') String? birthTime,
    @Default(CompatibilityStatus.pending) CompatibilityStatus status,
    String? gender,
    String? errorMessage,
    bool? isLoading,
    int? compatibilityScore,
    String? compatibilitySummary,
    Details? details,
    List<String>? tips,
    DateTime? createdAt,
    DateTime? completedAt,
  }) = _CompatibilityModel;

  // getter 메소드들 추가
  bool get isPending => status == CompatibilityStatus.pending;

  bool get isCompleted => status == CompatibilityStatus.completed;

  bool get hasError => status == CompatibilityStatus.error;

  factory CompatibilityModel.fromJson(Map<String, dynamic> json) =>
      _$CompatibilityModelFromJson(json);
}

@freezed
class Details with _$Details {
  const factory Details({
    required StyleDetails style,
    required ActivitiesDetails activities,
  }) = _Details;

  factory Details.fromJson(Map<String, dynamic> json) =>
      _$DetailsFromJson(json);
}

@freezed
class StyleDetails with _$StyleDetails {
  const factory StyleDetails({
    required String idol_style,
    required String user_style,
    required String couple_style,
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

// JSON 필드명 매핑을 위한 extension
extension CompatibilityStatusX on CompatibilityStatus {
  String toJson() => name;

  static CompatibilityStatus fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'pending':
        return CompatibilityStatus.pending;
      case 'completed':
        return CompatibilityStatus.completed;
      case 'error':
        return CompatibilityStatus.error;
      default:
        throw ArgumentError('Unknown CompatibilityStatus: $json');
    }
  }
}
