import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/data/models/promotion/promotion_campaign.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';

part '../../../generated/providers/models/promotion/promotion_campaign_v2.freezed.dart';
part '../../../generated/providers/models/promotion/promotion_campaign_v2.g.dart';

enum PromotionSurfaceV2 { home, paymentBadge }

extension PromotionSurfaceV2Wire on PromotionSurfaceV2 {
  String get wireValue =>
      this == PromotionSurfaceV2.home ? 'HOME' : 'PAYMENT_BADGE';
}

const _campaignV2Keys = {
  'campaign_id',
  'campaign_version_id',
  'code',
  'display_name',
  'multiplier_tenths',
  'event_starts_at',
  'event_ends_at',
  'repeat_iso_dows',
  'home_creative',
};
const _campaignV2EnvelopeKeys = {
  'items',
  'total_count',
  'next_cursor',
  'snapshot_at',
  'campaign_owned_home_banner_ids',
};

@freezed
abstract class ActivePromotionCampaignV2Model
    with _$ActivePromotionCampaignV2Model {
  const ActivePromotionCampaignV2Model._();
  const factory ActivePromotionCampaignV2Model({
    @JsonKey(name: 'campaign_id') required String campaignId,
    @JsonKey(name: 'campaign_version_id') required String campaignVersionId,
    required String code,
    @JsonKey(name: 'display_name') required Map<String, dynamic> displayName,
    @JsonKey(name: 'multiplier_tenths')
    @_StrictIntConverter()
    required int multiplierTenths,
    @JsonKey(name: 'event_starts_at')
    @_StrictTimestampConverter()
    required DateTime eventStartsAt,
    @JsonKey(name: 'event_ends_at')
    @_StrictTimestampConverter()
    required DateTime eventEndsAt,
    @JsonKey(name: 'repeat_iso_dows')
    @_StrictIntListConverter()
    required List<int> repeatIsoDows,
    @JsonKey(name: 'home_creative') PromotionCreativeModel? homeCreative,
  }) = _ActivePromotionCampaignV2Model;

  String localizedDisplayName(String locale) {
    for (final key in [locale, 'ko']) {
      final value = displayName[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return code;
  }

  bool hasReadableHomeCreative(String locale) =>
      homeCreative?.localizedTitle(locale) != null &&
      homeCreative?.localizedImage(locale) != null;

  factory ActivePromotionCampaignV2Model.fromJson(Map<String, dynamic> json) =>
      _requireValidCampaignV2Shape(
        _$ActivePromotionCampaignV2ModelFromJson(
          _normalizeCampaignV2Json(json),
        ),
      );
}

Map<String, dynamic> _normalizeCampaignV2Json(Map<String, dynamic> json) {
  final exact = requireExactContractKeys(json, _campaignV2Keys);
  final creative = exact['home_creative'];
  if (creative is Map && creative.isEmpty) {
    exact['home_creative'] = null;
  } else if (creative is Map) {
    _requireStrictInt(creative['banner_id'], 'home_creative.banner_id');
    final duration = creative['duration'];
    if (duration != null) {
      _requireStrictInt(duration, 'home_creative.duration');
    }
  }
  return exact;
}

ActivePromotionCampaignV2Model _requireValidCampaignV2Shape(
  ActivePromotionCampaignV2Model model,
) {
  if (model.multiplierTenths < 11 || model.multiplierTenths > 30) {
    throw FormatException(
      'multiplier_tenths must be within 11..30, got ${model.multiplierTenths}',
    );
  }
  final dows = model.repeatIsoDows;
  if (dows.isEmpty) {
    throw const FormatException('repeat_iso_dows must not be empty');
  }
  for (var i = 0; i < dows.length; i++) {
    if (dows[i] < 1 || dows[i] > 7) {
      throw FormatException(
        'repeat_iso_dows must be within 1..7, got $dows',
      );
    }
    if (i > 0 && dows[i] <= dows[i - 1]) {
      throw FormatException(
        'repeat_iso_dows must be unique and sorted ascending, got $dows',
      );
    }
  }
  if (!model.eventStartsAt.isBefore(model.eventEndsAt)) {
    throw FormatException(
      'event_starts_at must be before event_ends_at, got '
      '${model.eventStartsAt} >= ${model.eventEndsAt}',
    );
  }
  return model;
}

@freezed
abstract class ActivePromotionCampaignsV2Model
    with _$ActivePromotionCampaignsV2Model {
  const ActivePromotionCampaignsV2Model._();
  const factory ActivePromotionCampaignsV2Model({
    required List<ActivePromotionCampaignV2Model> items,
    @JsonKey(name: 'total_count')
    @WalletAmountConverter()
    required BigInt totalCount,
    @JsonKey(name: 'next_cursor') String? nextCursor,
    @JsonKey(name: 'snapshot_at')
    @_StrictTimestampConverter()
    required DateTime snapshotAt,
    @JsonKey(name: 'campaign_owned_home_banner_ids')
    @_StrictIntListConverter()
    required List<int> campaignOwnedHomeBannerIds,
  }) = _ActivePromotionCampaignsV2Model;

  List<ActivePromotionCampaignV2Model> visibleHomeItems(String locale) =>
      items.where((item) => item.hasReadableHomeCreative(locale)).toList();

  factory ActivePromotionCampaignsV2Model.fromJson(
    Map<String, dynamic> json,
  ) => _requireValidCampaignsV2Shape(
    _$ActivePromotionCampaignsV2ModelFromJson(
      requireExactContractKeys(json, _campaignV2EnvelopeKeys),
    ),
  );
}

ActivePromotionCampaignsV2Model _requireValidCampaignsV2Shape(
  ActivePromotionCampaignsV2Model model,
) {
  if (model.totalCount.isNegative) {
    throw FormatException(
      'total_count must be non-negative, got ${model.totalCount}',
    );
  }
  return model;
}

int _requireStrictInt(Object? value, String field) {
  if (value is! int) {
    throw FormatException(
      '$field must be an integer without a fractional part, got $value',
    );
  }
  return value;
}

class _StrictIntConverter implements JsonConverter<int, Object?> {
  const _StrictIntConverter();

  @override
  int fromJson(Object? json) => _requireStrictInt(json, 'value');

  @override
  Object toJson(int object) => object;
}

class _StrictIntListConverter implements JsonConverter<List<int>, Object?> {
  const _StrictIntListConverter();

  @override
  List<int> fromJson(Object? json) {
    if (json is! List) {
      throw FormatException('Expected a JSON array, got $json');
    }
    return [for (final e in json) _requireStrictInt(e, 'list item')];
  }

  @override
  Object toJson(List<int> object) => object;
}

final _rfc3339Pattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?'
  r'(?:Z|([+-])(\d{2}):(\d{2}))$',
);

DateTime _requireStrictTimestamp(Object? value, String field) {
  if (value is! String) {
    throw FormatException(
      '$field must be an RFC3339 timestamp string, got $value',
    );
  }
  final match = _rfc3339Pattern.firstMatch(value);
  if (match == null) {
    throw FormatException(
      '$field must be an RFC3339 timestamp with an explicit UTC offset, '
      'got $value',
    );
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  final second = int.parse(match.group(6)!);
  final normalized = DateTime.utc(year, month, day, hour, minute, second);
  if (normalized.year != year ||
      normalized.month != month ||
      normalized.day != day ||
      normalized.hour != hour ||
      normalized.minute != minute ||
      normalized.second != second) {
    throw FormatException(
      '$field is not a valid calendar timestamp, got $value',
    );
  }
  // The regex only constrains the offset to two digits each; DateTime.parse
  // converts an out-of-range offset (e.g. +24:00, +09:60) straight into
  // minutes without validating it, silently shifting the decoded instant.
  final offsetSign = match.group(7);
  if (offsetSign != null) {
    final offsetHour = int.parse(match.group(8)!);
    final offsetMinute = int.parse(match.group(9)!);
    if (offsetHour > 23 || offsetMinute > 59) {
      throw FormatException(
        '$field has an out-of-range UTC offset, got $value',
      );
    }
  }
  return DateTime.parse(value);
}

class _StrictTimestampConverter implements JsonConverter<DateTime, Object?> {
  const _StrictTimestampConverter();

  @override
  DateTime fromJson(Object? json) => _requireStrictTimestamp(json, 'value');

  @override
  Object toJson(DateTime object) => object.toIso8601String();
}
