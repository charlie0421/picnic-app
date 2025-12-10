// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/reward_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AsyncRewardList)
const asyncRewardListProvider = AsyncRewardListProvider._();

final class AsyncRewardListProvider
    extends $AsyncNotifierProvider<AsyncRewardList, List<RewardModel>> {
  const AsyncRewardListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'asyncRewardListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$asyncRewardListHash();

  @$internal
  @override
  AsyncRewardList create() => AsyncRewardList();
}

String _$asyncRewardListHash() => r'656cd13609c2604f918fd0055fed2e3bf1f95c76';

abstract class _$AsyncRewardList extends $AsyncNotifier<List<RewardModel>> {
  FutureOr<List<RewardModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<RewardModel>>, List<RewardModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<RewardModel>>, List<RewardModel>>,
              AsyncValue<List<RewardModel>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
