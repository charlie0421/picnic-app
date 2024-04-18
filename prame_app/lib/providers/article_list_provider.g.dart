// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncArticleListHash() => r'd367fdd604571a2f5013a07fb3bdac98501d294e';

/// See also [AsyncArticleList].
@ProviderFor(AsyncArticleList)
final asyncArticleListProvider = AutoDisposeAsyncNotifierProvider<
    AsyncArticleList, ArticleListModel?>.internal(
  AsyncArticleList.new,
  name: r'asyncArticleListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$asyncArticleListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AsyncArticleList = AutoDisposeAsyncNotifier<ArticleListModel?>;
String _$sortOptionHash() => r'4b6e9a1d384bf93a8668c1bde73329f3e74a7764';

/// See also [SortOption].
@ProviderFor(SortOption)
final sortOptionProvider =
    AutoDisposeNotifierProvider<SortOption, String>.internal(
  SortOption.new,
  name: r'sortOptionProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$sortOptionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SortOption = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
