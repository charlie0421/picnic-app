// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncGalleryListHash() => r'49a831e7c121b33d3cb030469ce4971053a55926';

/// See also [AsyncGalleryList].
@ProviderFor(AsyncGalleryList)
final asyncGalleryListProvider = AutoDisposeAsyncNotifierProvider<
    AsyncGalleryList, List<GalleryModel>>.internal(
  AsyncGalleryList.new,
  name: r'asyncGalleryListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$asyncGalleryListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AsyncGalleryList = AutoDisposeAsyncNotifier<List<GalleryModel>>;
String _$selectedGalleryIdHash() => r'f9c59fefd740c43c42e7777b3634ca015bfb2573';

/// See also [SelectedGalleryId].
@ProviderFor(SelectedGalleryId)
final selectedGalleryIdProvider =
    AutoDisposeNotifierProvider<SelectedGalleryId, int>.internal(
  SelectedGalleryId.new,
  name: r'selectedGalleryIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedGalleryIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedGalleryId = AutoDisposeNotifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
