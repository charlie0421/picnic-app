// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/policy_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AsyncPolicy)
const asyncPolicyProvider = AsyncPolicyProvider._();

final class AsyncPolicyProvider
    extends $AsyncNotifierProvider<AsyncPolicy, PolicyModel> {
  const AsyncPolicyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'asyncPolicyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$asyncPolicyHash();

  @$internal
  @override
  AsyncPolicy create() => AsyncPolicy();
}

String _$asyncPolicyHash() => r'bdca60db7ed3e08bbd6e6fe508dd45f2cce34d3b';

abstract class _$AsyncPolicy extends $AsyncNotifier<PolicyModel> {
  FutureOr<PolicyModel> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<PolicyModel>, PolicyModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PolicyModel>, PolicyModel>,
              AsyncValue<PolicyModel>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
