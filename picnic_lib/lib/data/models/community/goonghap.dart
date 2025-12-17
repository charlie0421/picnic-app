import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';

part '../../../generated/providers/models/community/goonghap.freezed.dart';
part '../../../generated/providers/models/community/goonghap.g.dart';

enum GoonghapStatus { pending, completed, error, input }

Map<String, LocalizedGoonghap>? _parseI18nResults(dynamic i18nData) {
  if (i18nData == null) return null;

  try {
    final Map<String, LocalizedGoonghap> results = {};

    // 맵으로 직접 처리하는 경우
    if (i18nData is Map) {
      i18nData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          try {
            final localizedResult = LocalizedGoonghap.fromJson(value);
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
          final localizedResult = LocalizedGoonghap.fromJson(item);
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
abstract class GoonghapHistoryModel with _$GoonghapHistoryModel {
  const factory GoonghapHistoryModel({
    required List<GoonghapModel> items,
    required bool hasMore,
    @Default(false) bool isLoading,
  }) = _GoonghapHistoryModel;

  factory GoonghapHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$GoonghapHistoryModelFromJson(json);
}

@freezed
abstract class GoonghapModel with _$GoonghapModel {
  const GoonghapModel._();

  const factory GoonghapModel({
    @Default('') String id,
    required String userId,
    required ArtistModel artist,
    @JsonKey(name: 'user_birth_date') required DateTime birthDate,
    @JsonKey(name: 'user_birth_time') String? birthTime,
    @Default(GoonghapStatus.pending) GoonghapStatus status,
    String? gender,
    String? errorMessage,
    bool? isLoading,
    @JsonKey(name: 'score') int? score,
    @JsonKey(name: 'goonghap_summary') String? goonghapSummary,
    Details? details,
    List<String>? tips,
    DateTime? createdAt,
    DateTime? completedAt,
    @JsonKey(name: 'i18n', fromJson: _parseI18nResults)
    Map<String, LocalizedGoonghap>? localizedResults,
    @JsonKey(name: 'is_ads') bool? isAds,
    @JsonKey(name: 'is_paid') bool? isPaid,
  }) = _GoonghapModel;

  factory GoonghapModel.fromJson(Map<String, dynamic> json) =>
      _$GoonghapModelFromJson(json);

  bool get isPending => status == GoonghapStatus.pending;

  bool get isCompleted => status == GoonghapStatus.completed;

  bool get hasError => status == GoonghapStatus.error;

  LocalizedGoonghap? getLocalizedResult(String language) =>
      localizedResults?[language];
}

@freezed
abstract class LocalizedGoonghap with _$LocalizedGoonghap {
  const factory LocalizedGoonghap({
    required String language,
    @JsonKey(name: 'score') @Default(0) int score,
    @JsonKey(name: 'score_title') @Default('') String scoreTitle,
    @JsonKey(name: 'goonghap_summary')
    @Default('') String goonghapSummary,
    @JsonKey(name: 'details') Details? details,
    @Default([]) List<String> tips,
  }) = _LocalizedGoonghap;

  factory LocalizedGoonghap.fromJson(Map<String, dynamic> json) =>
      _$LocalizedGoonghapFromJson(json);
}

extension LocalizedGoonghapX on LocalizedGoonghap {
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
abstract class Details with _$Details {
  const factory Details({
    required StyleDetails style,
    required ActivitiesDetails activities,
  }) = _Details;

  factory Details.fromJson(Map<String, dynamic> json) =>
      _$DetailsFromJson(json);
}

@freezed
abstract class StyleDetails with _$StyleDetails {
  const factory StyleDetails({
    @JsonKey(name: 'idol_style') required String idolStyle,
    @JsonKey(name: 'user_style') required String userStyle,
    @JsonKey(name: 'couple_style') required String coupleStyle,
  }) = _StyleDetails;

  factory StyleDetails.fromJson(Map<String, dynamic> json) =>
      _$StyleDetailsFromJson(json);
}

@freezed
abstract class ActivitiesDetails with _$ActivitiesDetails {
  const factory ActivitiesDetails({
    required List<String> recommended,
    required String description,
  }) = _ActivitiesDetails;

  factory ActivitiesDetails.fromJson(Map<String, dynamic> json) =>
      _$ActivitiesDetailsFromJson(json);
}

extension GoonghapStatusX on GoonghapStatus {
  String toJson() => name;

  static GoonghapStatus fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'pending':
        return GoonghapStatus.pending;
      case 'completed':
        return GoonghapStatus.completed;
      case 'error':
        return GoonghapStatus.error;
      default:
        throw ArgumentError('Unknown GoonghapStatus: $json');
    }
  }
}
