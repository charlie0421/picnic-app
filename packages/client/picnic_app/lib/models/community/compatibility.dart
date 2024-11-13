// lib/models/compatibility_model.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/vote/artist.dart';

part 'compatibility.freezed.dart';

part 'compatibility.g.dart';

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
    required DateTime birthDate,
    String? birthTime,
    @Default(CompatibilityStatus.pending) CompatibilityStatus status,
    String? gender,
    String? errorMessage,
    bool? isLoading,
    int? compatibilityScore,
    String? compatibilitySummary,
    StyleDetails? style,
    ActivitiesDetails? activities,
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
