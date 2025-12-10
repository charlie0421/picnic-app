// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/banner_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AsyncBannerList)
const asyncBannerListProvider = AsyncBannerListFamily._();

final class AsyncBannerListProvider
    extends $AsyncNotifierProvider<AsyncBannerList, List<BannerModel>> {
  const AsyncBannerListProvider._({
    required AsyncBannerListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'asyncBannerListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$asyncBannerListHash();

  @override
  String toString() {
    return r'asyncBannerListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AsyncBannerList create() => AsyncBannerList();

  @override
  bool operator ==(Object other) {
    return other is AsyncBannerListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$asyncBannerListHash() => r'85b2efcc225349363e39c90e1c47d89c133ebe30';

final class AsyncBannerListFamily extends $Family
    with
        $ClassFamilyOverride<
          AsyncBannerList,
          AsyncValue<List<BannerModel>>,
          List<BannerModel>,
          FutureOr<List<BannerModel>>,
          String
        > {
  const AsyncBannerListFamily._()
    : super(
        retry: null,
        name: r'asyncBannerListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AsyncBannerListProvider call({required String location}) =>
      AsyncBannerListProvider._(argument: location, from: this);

  @override
  String toString() => r'asyncBannerListProvider';
}

abstract class _$AsyncBannerList extends $AsyncNotifier<List<BannerModel>> {
  late final _$args = ref.$arg as String;
  String get location => _$args;

  FutureOr<List<BannerModel>> build({required String location});
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(location: _$args);
    final ref =
        this.ref as $Ref<AsyncValue<List<BannerModel>>, List<BannerModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<BannerModel>>, List<BannerModel>>,
              AsyncValue<List<BannerModel>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
