// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/article_image_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AsyncArticleImageList)
const asyncArticleImageListProvider = AsyncArticleImageListFamily._();

final class AsyncArticleImageListProvider
    extends
        $AsyncNotifierProvider<AsyncArticleImageList, List<ArticleImageModel>> {
  const AsyncArticleImageListProvider._({
    required AsyncArticleImageListFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'asyncArticleImageListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$asyncArticleImageListHash();

  @override
  String toString() {
    return r'asyncArticleImageListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AsyncArticleImageList create() => AsyncArticleImageList();

  @override
  bool operator ==(Object other) {
    return other is AsyncArticleImageListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$asyncArticleImageListHash() =>
    r'425a968fafc39248b4d589cea6c9ea97ad69b3c9';

final class AsyncArticleImageListFamily extends $Family
    with
        $ClassFamilyOverride<
          AsyncArticleImageList,
          AsyncValue<List<ArticleImageModel>>,
          List<ArticleImageModel>,
          FutureOr<List<ArticleImageModel>>,
          int
        > {
  const AsyncArticleImageListFamily._()
    : super(
        retry: null,
        name: r'asyncArticleImageListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AsyncArticleImageListProvider call({required int galleryId}) =>
      AsyncArticleImageListProvider._(argument: galleryId, from: this);

  @override
  String toString() => r'asyncArticleImageListProvider';
}

abstract class _$AsyncArticleImageList
    extends $AsyncNotifier<List<ArticleImageModel>> {
  late final _$args = ref.$arg as int;
  int get galleryId => _$args;

  FutureOr<List<ArticleImageModel>> build({required int galleryId});
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(galleryId: _$args);
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<ArticleImageModel>>,
              List<ArticleImageModel>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ArticleImageModel>>,
                List<ArticleImageModel>
              >,
              AsyncValue<List<ArticleImageModel>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
