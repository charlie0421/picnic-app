// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncGalleryListHash() => r'70281c0a4831bf003e7498747876aa534fe7d77b';

/// See also [AsyncGalleryList].
@ProviderFor(AsyncGalleryList)
final asyncGalleryListProvider = AutoDisposeAsyncNotifierProvider<
    AsyncGalleryList, GalleryListModel>.internal(
  AsyncGalleryList.new,
  name: r'asyncGalleryListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$asyncGalleryListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AsyncGalleryList = AutoDisposeAsyncNotifier<GalleryListModel>;
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
