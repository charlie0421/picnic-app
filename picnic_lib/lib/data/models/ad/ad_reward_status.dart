import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';

part '../../../generated/providers/models/ad/ad_reward_status.freezed.dart';
part '../../../generated/providers/models/ad/ad_reward_status.g.dart';

enum AdRewardReferenceType { pangleClaim, admobClaim, internalImpression }

enum AdRewardState { pending, granted, denied, expired, abandoned }

extension AdRewardReferenceTypeWire on AdRewardReferenceType {
  String get wireValue => switch (this) {
    AdRewardReferenceType.pangleClaim => 'PANGLE_CLAIM',
    AdRewardReferenceType.admobClaim => 'ADMOB_CLAIM',
    AdRewardReferenceType.internalImpression => 'INTERNAL_IMPRESSION',
  };
}

class AdRewardReferenceTypeConverter
    implements JsonConverter<AdRewardReferenceType, String> {
  const AdRewardReferenceTypeConverter();
  @override
  AdRewardReferenceType fromJson(String value) => switch (value) {
    'PANGLE_CLAIM' => AdRewardReferenceType.pangleClaim,
    'ADMOB_CLAIM' => AdRewardReferenceType.admobClaim,
    'INTERNAL_IMPRESSION' => AdRewardReferenceType.internalImpression,
    _ => throw FormatException('Unknown ad reference type: $value'),
  };
  @override
  String toJson(AdRewardReferenceType value) => value.wireValue;
}

class AdRewardStateConverter implements JsonConverter<AdRewardState, String> {
  const AdRewardStateConverter();
  @override
  AdRewardState fromJson(String value) => switch (value) {
    'PENDING' => AdRewardState.pending,
    'GRANTED' => AdRewardState.granted,
    'DENIED' => AdRewardState.denied,
    'EXPIRED' => AdRewardState.expired,
    'ABANDONED' => AdRewardState.abandoned,
    _ => throw FormatException('Unknown ad reward state: $value'),
  };
  @override
  String toJson(AdRewardState value) => value.name.toUpperCase();
}

const _referenceKeys = {'type', 'id'};
const _claimKeys = {'reference', 'platform', 'signed_token', 'expires_at'};
const _grantKeys = {'id', 'currency', 'amount', 'granted_at', 'expires_at'};
const _statusKeys = {'reference', 'state', 'grant', 'wallet', 'snapshot_at'};
const _pageKeys = {'items', 'total_count', 'next_cursor', 'snapshot_at'};

T _decodeContract<T>(T Function() decode) {
  try {
    return decode();
  } on FormatException {
    rethrow;
  } catch (error) {
    throw FormatException('Invalid ad reward contract', error);
  }
}

@freezed
abstract class AdRewardReference with _$AdRewardReference {
  const factory AdRewardReference({
    @AdRewardReferenceTypeConverter() required AdRewardReferenceType type,
    required String id,
  }) = _AdRewardReference;
  factory AdRewardReference.fromJson(Map<String, dynamic> json) =>
      _decodeContract(
        () => _$AdRewardReferenceFromJson(
          requireExactContractKeys(json, _referenceKeys),
        ),
      );
}

@freezed
abstract class PangleClaimModel with _$PangleClaimModel {
  const PangleClaimModel._();
  const factory PangleClaimModel({
    required AdRewardReference reference,
    required String platform,
    @JsonKey(name: 'signed_token') required String signedToken,
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
  }) = _PangleClaimModel;

  /// Pangle 네이티브 로더가 요구하는 `<userId>,<platform>,v2.<token>` 형식.
  ///
  /// [platform] 은 **반드시 소문자**여야 한다. 네이티브 검증기가 정확 일치를
  /// 요구하기 때문이다 — Android `require(parts[1] == "android")`,
  /// iOS `parts[1] == "ios"`. 어긋나면 로드가 `InvalidMediaExtra`
  /// ("Signed v2 mediaExtra is required") 로 거부되고, 앱은 그 실패를
  /// no-fill 로 분류해 사용자에게 "모든 광고 소진" 으로 안내한다.
  ///
  /// 서버(`ad-reward-claim`)는 요청의 platform 을 `toUpperCase()` 해서 저장하고
  /// 그 값을 응답에도 그대로 실어 준다(`ANDROID`/`IOS`). 그래서 서버가 준 값을
  /// 믿고 쓰면 형식이 깨진다 — 2026-07-29 부터 2026-08-13 까지 Pangle 클레임
  /// 1,452 건이 만들어졌으나 지급은 0 건이었다(PICNIC-2377).
  ///
  /// 형식을 약속하는 쪽이 형식을 보장한다. 서버 표기에 의존하지 않고 여기서
  /// 정규화한다.
  String mediaExtra(String userId) =>
      '$userId,${platform.toLowerCase()},v2.$signedToken';
  factory PangleClaimModel.fromJson(Map<String, dynamic> json) =>
      _decodeContract(() {
        final claim = _$PangleClaimModelFromJson(
          requireExactContractKeys(json, _claimKeys),
        );
        if (claim.reference.type != AdRewardReferenceType.pangleClaim) {
          throw const FormatException('Expected PANGLE_CLAIM reference');
        }
        return claim;
      });
}

/// AdMob SSV callback에 전달할 서명 토큰이 포함된 서버 발급 클레임.
@freezed
abstract class AdmobClaimModel with _$AdmobClaimModel {
  const factory AdmobClaimModel({
    required AdRewardReference reference,
    required String platform,
    @JsonKey(name: 'signed_token') required String signedToken,
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
  }) = _AdmobClaimModel;
  factory AdmobClaimModel.fromJson(Map<String, dynamic> json) =>
      _decodeContract(() {
        final claim = _$AdmobClaimModelFromJson(
          requireExactContractKeys(json, _claimKeys),
        );
        if (claim.reference.type != AdRewardReferenceType.admobClaim) {
          throw const FormatException('Expected ADMOB_CLAIM reference');
        }
        return claim;
      });
}

@freezed
abstract class AdRewardGrantModel with _$AdRewardGrantModel {
  const factory AdRewardGrantModel({
    required String id,
    @WalletCurrencyConverter() required WalletCurrency currency,
    @WalletAmountConverter() required BigInt amount,
    @JsonKey(name: 'granted_at') required DateTime grantedAt,
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
  }) = _AdRewardGrantModel;
  factory AdRewardGrantModel.fromJson(Map<String, dynamic> json) =>
      _decodeContract(
        () => _$AdRewardGrantModelFromJson(
          requireExactContractKeys(json, _grantKeys),
        ),
      );
}

@freezed
abstract class AdRewardStatusModel with _$AdRewardStatusModel {
  const factory AdRewardStatusModel({
    required AdRewardReference reference,
    @AdRewardStateConverter() required AdRewardState state,
    required AdRewardGrantModel? grant,
    required WalletSummaryModel wallet,
    @JsonKey(name: 'snapshot_at') required DateTime snapshotAt,
  }) = _AdRewardStatusModel;
  factory AdRewardStatusModel.fromJson(Map<String, dynamic> json) =>
      _decodeContract(
        () => _$AdRewardStatusModelFromJson(
          requireExactContractKeys(json, _statusKeys),
        ),
      );
}

@freezed
abstract class AdRewardPageModel with _$AdRewardPageModel {
  const factory AdRewardPageModel({
    required List<AdRewardStatusModel> items,
    @JsonKey(name: 'total_count')
    @WalletAmountConverter()
    required BigInt totalCount,
    @JsonKey(name: 'next_cursor') required String? nextCursor,
    @JsonKey(name: 'snapshot_at') required DateTime snapshotAt,
  }) = _AdRewardPageModel;
  factory AdRewardPageModel.fromJson(Map<String, dynamic> json) =>
      _decodeContract(
        () => _$AdRewardPageModelFromJson(
          requireExactContractKeys(json, _pageKeys),
        ),
      );
}

@freezed
abstract class InternalShortformViewResponse
    with _$InternalShortformViewResponse {
  const factory InternalShortformViewResponse({
    required bool ok,
    @JsonKey(name: 'reward_added') required int rewardAdded,
    @JsonKey(name: 'impression_id') required String impressionId,
    @JsonKey(name: 'new_bonus') required int? newBonus,
    AdRewardStatusModel? reward,
  }) = _InternalShortformViewResponse;
  factory InternalShortformViewResponse.fromJson(Map<String, dynamic> json) =>
      _decodeContract(() => _parseInternalShortformViewResponse(json));
}

InternalShortformViewResponse _parseInternalShortformViewResponse(
  Map<String, dynamic> json,
) {
  const legacy = {'ok', 'reward_added', 'impression_id', 'new_bonus'};
  const current = {...legacy, 'reward'};
  final keys = json.keys.toSet();
  if ((keys.length != legacy.length || !keys.containsAll(legacy)) &&
      (keys.length != current.length || !keys.containsAll(current))) {
    throw FormatException('Invalid internal shortform response keys: $keys');
  }
  return InternalShortformViewResponse(
    ok: json['ok'] as bool,
    rewardAdded: json['reward_added'] as int,
    impressionId: json['impression_id'] as String,
    newBonus: json['new_bonus'] as int?,
    reward: json['reward'] == null
        ? null
        : AdRewardStatusModel.fromJson(
            Map<String, dynamic>.from(json['reward'] as Map),
          ),
  );
}
