import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

part '../generated/models/ad_info.freezed.dart';

@freezed
class AdInfo with _$AdInfo {
  const factory AdInfo({
    RewardedAd? ad,
    @Default(false) bool isShowing,
    @Default(false) bool isLoading,
  }) = _AdInfo;
}

@freezed
class AdState with _$AdState {
  const factory AdState({
    required List<AdInfo> ads,
  }) = _AdState;

  factory AdState.initial() =>
      AdState(ads: List.generate(2, (_) => const AdInfo()));
}
