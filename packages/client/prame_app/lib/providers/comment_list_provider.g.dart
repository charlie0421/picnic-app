// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncCommentListHash() => r'8faec7abbd85dc3548d643f0add69a41087205b8';

/// See also [AsyncCommentList].
@ProviderFor(AsyncCommentList)
final asyncCommentListProvider = AutoDisposeAsyncNotifierProvider<
    AsyncCommentList, CommentListModel>.internal(
  AsyncCommentList.new,
  name: r'asyncCommentListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$asyncCommentListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AsyncCommentList = AutoDisposeAsyncNotifier<CommentListModel>;
String _$parentItemHash() => r'30d7e81bfa5563d77693ce2e504753acaddecca4';

/// See also [ParentItem].
@ProviderFor(ParentItem)
final parentItemProvider =
    AutoDisposeNotifierProvider<ParentItem, CommentModel?>.internal(
  ParentItem.new,
  name: r'parentItemProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$parentItemHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ParentItem = AutoDisposeNotifier<CommentModel?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
