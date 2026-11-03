// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/promotion_badge_resolver_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(paymentBadgePromotion)
const paymentBadgePromotionProvider = PaymentBadgePromotionProvider._();

final class PaymentBadgePromotionProvider
    extends
        $FunctionalProvider<
          AsyncValue<ResolvedPaymentBadgePromotion?>,
          ResolvedPaymentBadgePromotion?,
          FutureOr<ResolvedPaymentBadgePromotion?>
        >
    with
        $FutureModifier<ResolvedPaymentBadgePromotion?>,
        $FutureProvider<ResolvedPaymentBadgePromotion?> {
  const PaymentBadgePromotionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentBadgePromotionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentBadgePromotionHash();

  @$internal
  @override
  $FutureProviderElement<ResolvedPaymentBadgePromotion?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ResolvedPaymentBadgePromotion?> create(Ref ref) {
    return paymentBadgePromotion(ref);
  }
}

String _$paymentBadgePromotionHash() =>
    r'd69ce6d37b4c6756f18bb487045b52c728a07b6b';

@ProviderFor(homePromotionCampaign)
const homePromotionCampaignProvider = HomePromotionCampaignFamily._();

final class HomePromotionCampaignProvider
    extends
        $FunctionalProvider<
          AsyncValue<HomePromotionResolution>,
          HomePromotionResolution,
          FutureOr<HomePromotionResolution>
        >
    with
        $FutureModifier<HomePromotionResolution>,
        $FutureProvider<HomePromotionResolution> {
  const HomePromotionCampaignProvider._({
    required HomePromotionCampaignFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'homePromotionCampaignProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$homePromotionCampaignHash();

  @override
  String toString() {
    return r'homePromotionCampaignProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<HomePromotionResolution> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HomePromotionResolution> create(Ref ref) {
    final argument = this.argument as String;
    return homePromotionCampaign(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HomePromotionCampaignProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$homePromotionCampaignHash() =>
    r'9c124423ac34dc71dcde2646f8f2ea4a7bfce6c6';

final class HomePromotionCampaignFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<HomePromotionResolution>, String> {
  const HomePromotionCampaignFamily._()
    : super(
        retry: null,
        name: r'homePromotionCampaignProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  HomePromotionCampaignProvider call(String locale) =>
      HomePromotionCampaignProvider._(argument: locale, from: this);

  @override
  String toString() => r'homePromotionCampaignProvider';
}
