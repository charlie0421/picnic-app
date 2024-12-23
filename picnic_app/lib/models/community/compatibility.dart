import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/util/logger.dart';

part '../../generated/models/community/compatibility.freezed.dart';
part '../../generated/models/community/compatibility.g.dart';

enum CompatibilityStatus { pending, completed, error, input }

Map<String, LocalizedCompatibility>? _parseI18nResults(dynamic i18nData) {
  if (i18nData == null) return null;

  try {
    final Map<String, LocalizedCompatibility> results = {};

    // 맵으로 직접 처리하는 경우
    if (i18nData is Map) {
      i18nData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          try {
            final localizedResult = LocalizedCompatibility.fromJson(value);
            results[key] = localizedResult;
          } catch (e, s) {
            logger.d('Error parsing localized result for $key: $e',
                stackTrace: s);
          }
        }
      });
    }
    // 리스트로 처리하는 경우
    else if (i18nData is List) {
      for (final item in i18nData) {
        if (item is! Map<String, dynamic>) continue;

        final language = item['language'] as String?;
        if (language == null) continue;

        try {
          final localizedResult = LocalizedCompatibility.fromJson(item);
          results[language] = localizedResult;
        } catch (e, s) {
          logger.d(
              'Error parsing localized result for $language: $e\nData: $item',
              stackTrace: s);
          continue;
        }
      }
    }

    return results.isEmpty ? null : results;
  } catch (e, s) {
    logger.d('Error parsing i18n results: $e', stackTrace: s);
    return null;
  }
}

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
  const CompatibilityModel._();

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
    @JsonKey(name: 'score') int? score,
    @JsonKey(name: 'compatibility_summary') String? compatibilitySummary,
    Details? details,
    List<String>? tips,
    DateTime? createdAt,
    DateTime? completedAt,
    @JsonKey(name: 'i18n', fromJson: _parseI18nResults)
    Map<String, LocalizedCompatibility>? localizedResults,
    @JsonKey(name: 'is_ads') bool? isAds,
    @JsonKey(name: 'is_paid') bool? isPaid,
  }) = _CompatibilityModel;

  factory CompatibilityModel.fromJson(Map<String, dynamic> json) =>
      _$CompatibilityModelFromJson(json);

  bool get isPending => status == CompatibilityStatus.pending;

  bool get isCompleted => status == CompatibilityStatus.completed;

  bool get hasError => status == CompatibilityStatus.error;

  LocalizedCompatibility? getLocalizedResult(String language) =>
      localizedResults?[language];
}

@freezed
class LocalizedCompatibility with _$LocalizedCompatibility {
  const factory LocalizedCompatibility({
    required String language,
    @JsonKey(name: 'score') required int score,
    @JsonKey(name: 'score_title') required String scoreTitle,
    @JsonKey(name: 'compatibility_summary')
    required String compatibilitySummary,
    @JsonKey(name: 'details') Details? details,
    @Default([]) List<String> tips,
  }) = _LocalizedCompatibility;

  factory LocalizedCompatibility.fromJson(Map<String, dynamic> json) =>
      _$LocalizedCompatibilityFromJson(json);
}

extension LocalizedCompatibilityX on LocalizedCompatibility {
  Details? get parsedDetails {
    try {
      return Details.fromJson(details?.toJson() ?? {});
    } catch (e, s) {
      logger.d('Error parsing details: $e', stackTrace: s);
      return null;
    }
  }
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
    @JsonKey(name: 'idol_style') required String idolStyle,
    @JsonKey(name: 'user_style') required String userStyle,
    @JsonKey(name: 'couple_style') required String coupleStyle,
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
