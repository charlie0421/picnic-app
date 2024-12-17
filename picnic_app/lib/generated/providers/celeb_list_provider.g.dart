// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../providers/celeb_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncCelebListHash() => r'333e25f7b5309d5b363d27379691467f7b598d23';

/// See also [AsyncCelebList].
@ProviderFor(AsyncCelebList)
final asyncCelebListProvider = AutoDisposeAsyncNotifierProvider<AsyncCelebList,
    List<CelebModel>?>.internal(
  AsyncCelebList.new,
  name: r'asyncCelebListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$asyncCelebListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AsyncCelebList = AutoDisposeAsyncNotifier<List<CelebModel>?>;
String _$asyncMyCelebListHash() => r'd3e28b9a1676105913900557550e8bd06c8f173c';

/// See also [AsyncMyCelebList].
@ProviderFor(AsyncMyCelebList)
final asyncMyCelebListProvider =
    AsyncNotifierProvider<AsyncMyCelebList, List<CelebModel>?>.internal(
  AsyncMyCelebList.new,
  name: r'asyncMyCelebListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$asyncMyCelebListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AsyncMyCelebList = AsyncNotifier<List<CelebModel>?>;
String _$selectedCelebHash() => r'de544f79c7d80643ac5feb419ca90c23afd6bf78';

/// See also [SelectedCeleb].
@ProviderFor(SelectedCeleb)
final selectedCelebProvider =
    AutoDisposeNotifierProvider<SelectedCeleb, CelebModel?>.internal(
  SelectedCeleb.new,
  name: r'selectedCelebProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedCelebHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedCeleb = AutoDisposeNotifier<CelebModel?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
