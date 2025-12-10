// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/article_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fetchArticleList)
const fetchArticleListProvider = FetchArticleListFamily._();

final class FetchArticleListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ArticleModel>?>,
          List<ArticleModel>?,
          FutureOr<List<ArticleModel>?>
        >
    with
        $FutureModifier<List<ArticleModel>?>,
        $FutureProvider<List<ArticleModel>?> {
  const FetchArticleListProvider._({
    required FetchArticleListFamily super.from,
    required ({int page, int galleryId, int limit, String sort, String order})
    super.argument,
  }) : super(
         retry: null,
         name: r'fetchArticleListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchArticleListHash();

  @override
  String toString() {
    return r'fetchArticleListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<ArticleModel>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ArticleModel>?> create(Ref ref) {
    final argument =
        this.argument
            as ({
              int page,
              int galleryId,
              int limit,
              String sort,
              String order,
            });
    return fetchArticleList(
      ref,
      page: argument.page,
      galleryId: argument.galleryId,
      limit: argument.limit,
      sort: argument.sort,
      order: argument.order,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FetchArticleListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchArticleListHash() => r'466dce0d8bc62be54e79c39cca4e2df10929fe83';

final class FetchArticleListFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ArticleModel>?>,
          ({int page, int galleryId, int limit, String sort, String order})
        > {
  const FetchArticleListFamily._()
    : super(
        retry: null,
        name: r'fetchArticleListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FetchArticleListProvider call({
    required int page,
    required int galleryId,
    required int limit,
    required String sort,
    required String order,
  }) => FetchArticleListProvider._(
    argument: (
      page: page,
      galleryId: galleryId,
      limit: limit,
      sort: sort,
      order: order,
    ),
    from: this,
  );

  @override
  String toString() => r'fetchArticleListProvider';
}

@ProviderFor(SortOption)
const sortOptionProvider = SortOptionProvider._();

final class SortOptionProvider
    extends $NotifierProvider<SortOption, SortOptionType> {
  const SortOptionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sortOptionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sortOptionHash();

  @$internal
  @override
  SortOption create() => SortOption();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SortOptionType value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SortOptionType>(value),
    );
  }
}

String _$sortOptionHash() => r'8d0e51b1242be85e0437cebf8d5053fbce6dd7fe';

abstract class _$SortOption extends $Notifier<SortOptionType> {
  SortOptionType build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SortOptionType, SortOptionType>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SortOptionType, SortOptionType>,
              SortOptionType,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(CommentCount)
const commentCountProvider = CommentCountFamily._();

final class CommentCountProvider
    extends $AsyncNotifierProvider<CommentCount, int> {
  const CommentCountProvider._({
    required CommentCountFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'commentCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$commentCountHash();

  @override
  String toString() {
    return r'commentCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CommentCount create() => CommentCount();

  @override
  bool operator ==(Object other) {
    return other is CommentCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$commentCountHash() => r'5687d5fee456a37c642c76eefe393e1d11162b55';

final class CommentCountFamily extends $Family
    with
        $ClassFamilyOverride<
          CommentCount,
          AsyncValue<int>,
          int,
          FutureOr<int>,
          int
        > {
  const CommentCountFamily._()
    : super(
        retry: null,
        name: r'commentCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CommentCountProvider call(int articleId) =>
      CommentCountProvider._(argument: articleId, from: this);

  @override
  String toString() => r'commentCountProvider';
}

abstract class _$CommentCount extends $AsyncNotifier<int> {
  late final _$args = ref.$arg as int;
  int get articleId => _$args;

  FutureOr<int> build(int articleId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<int>, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<int>, int>,
              AsyncValue<int>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
