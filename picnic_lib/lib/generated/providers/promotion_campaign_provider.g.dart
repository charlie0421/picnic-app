// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/promotion_campaign_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(promotionCampaignRepository)
const promotionCampaignRepositoryProvider =
    PromotionCampaignRepositoryProvider._();

final class PromotionCampaignRepositoryProvider
    extends
        $FunctionalProvider<
          PromotionCampaignRepository,
          PromotionCampaignRepository,
          PromotionCampaignRepository
        >
    with $Provider<PromotionCampaignRepository> {
  const PromotionCampaignRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'promotionCampaignRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$promotionCampaignRepositoryHash();

  @$internal
  @override
  $ProviderElement<PromotionCampaignRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PromotionCampaignRepository create(Ref ref) {
    return promotionCampaignRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PromotionCampaignRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PromotionCampaignRepository>(value),
    );
  }
}

String _$promotionCampaignRepositoryHash() =>
    r'55449fe1405c59024e37af5950352699886f13d7';

@ProviderFor(activePromotionCampaign)
const activePromotionCampaignProvider = ActivePromotionCampaignFamily._();

final class ActivePromotionCampaignProvider
    extends
        $FunctionalProvider<
          AsyncValue<ActivePromotionCampaignsModel>,
          ActivePromotionCampaignsModel,
          FutureOr<ActivePromotionCampaignsModel>
        >
    with
        $FutureModifier<ActivePromotionCampaignsModel>,
        $FutureProvider<ActivePromotionCampaignsModel> {
  const ActivePromotionCampaignProvider._({
    required ActivePromotionCampaignFamily super.from,
    required PromotionSurface super.argument,
  }) : super(
         retry: null,
         name: r'activePromotionCampaignProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activePromotionCampaignHash();

  @override
  String toString() {
    return r'activePromotionCampaignProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ActivePromotionCampaignsModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ActivePromotionCampaignsModel> create(Ref ref) {
    final argument = this.argument as PromotionSurface;
    return activePromotionCampaign(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ActivePromotionCampaignProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activePromotionCampaignHash() =>
    r'24fb8c3e86b0c29c89f47d4e5a65731a6e234d97';

final class ActivePromotionCampaignFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ActivePromotionCampaignsModel>,
          PromotionSurface
        > {
  const ActivePromotionCampaignFamily._()
    : super(
        retry: null,
        name: r'activePromotionCampaignProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ActivePromotionCampaignProvider call(PromotionSurface surface) =>
      ActivePromotionCampaignProvider._(argument: surface, from: this);

  @override
  String toString() => r'activePromotionCampaignProvider';
}
