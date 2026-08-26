// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/promotion_campaign_v2_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(promotionCampaignV2Repository)
const promotionCampaignV2RepositoryProvider =
    PromotionCampaignV2RepositoryProvider._();

final class PromotionCampaignV2RepositoryProvider
    extends
        $FunctionalProvider<
          PromotionCampaignV2Repository,
          PromotionCampaignV2Repository,
          PromotionCampaignV2Repository
        >
    with $Provider<PromotionCampaignV2Repository> {
  const PromotionCampaignV2RepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'promotionCampaignV2RepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$promotionCampaignV2RepositoryHash();

  @$internal
  @override
  $ProviderElement<PromotionCampaignV2Repository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PromotionCampaignV2Repository create(Ref ref) {
    return promotionCampaignV2Repository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PromotionCampaignV2Repository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PromotionCampaignV2Repository>(
        value,
      ),
    );
  }
}

String _$promotionCampaignV2RepositoryHash() =>
    r'54473e4ea3bf28c3a5b3188edef53977d8d5b4af';

@ProviderFor(activePromotionCampaignV2)
const activePromotionCampaignV2Provider = ActivePromotionCampaignV2Family._();

final class ActivePromotionCampaignV2Provider
    extends
        $FunctionalProvider<
          AsyncValue<ActivePromotionCampaignsV2Model>,
          ActivePromotionCampaignsV2Model,
          FutureOr<ActivePromotionCampaignsV2Model>
        >
    with
        $FutureModifier<ActivePromotionCampaignsV2Model>,
        $FutureProvider<ActivePromotionCampaignsV2Model> {
  const ActivePromotionCampaignV2Provider._({
    required ActivePromotionCampaignV2Family super.from,
    required PromotionSurfaceV2 super.argument,
  }) : super(
         retry: null,
         name: r'activePromotionCampaignV2Provider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activePromotionCampaignV2Hash();

  @override
  String toString() {
    return r'activePromotionCampaignV2Provider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ActivePromotionCampaignsV2Model> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ActivePromotionCampaignsV2Model> create(Ref ref) {
    final argument = this.argument as PromotionSurfaceV2;
    return activePromotionCampaignV2(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ActivePromotionCampaignV2Provider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activePromotionCampaignV2Hash() =>
    r'6e5b834dd7762976a6f4299b1a0d6a27277ed1ba';

final class ActivePromotionCampaignV2Family extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ActivePromotionCampaignsV2Model>,
          PromotionSurfaceV2
        > {
  const ActivePromotionCampaignV2Family._()
    : super(
        retry: null,
        name: r'activePromotionCampaignV2Provider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ActivePromotionCampaignV2Provider call(PromotionSurfaceV2 surface) =>
      ActivePromotionCampaignV2Provider._(argument: surface, from: this);

  @override
  String toString() => r'activePromotionCampaignV2Provider';
}
