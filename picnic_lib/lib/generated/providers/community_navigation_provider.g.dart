// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/community_navigation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CommunityStateInfo)
const communityStateInfoProvider = CommunityStateInfoProvider._();

final class CommunityStateInfoProvider
    extends $NotifierProvider<CommunityStateInfo, CommunityState> {
  const CommunityStateInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'communityStateInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$communityStateInfoHash();

  @$internal
  @override
  CommunityStateInfo create() => CommunityStateInfo();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommunityState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommunityState>(value),
    );
  }
}

String _$communityStateInfoHash() =>
    r'768a26b0a53d87aaa49dd3643bf6d180dea56bb5';

abstract class _$CommunityStateInfo extends $Notifier<CommunityState> {
  CommunityState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<CommunityState, CommunityState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CommunityState, CommunityState>,
              CommunityState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
