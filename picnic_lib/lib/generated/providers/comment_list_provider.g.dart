// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/comment_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AsyncCommentList)
const asyncCommentListProvider = AsyncCommentListFamily._();

final class AsyncCommentListProvider
    extends $AsyncNotifierProvider<AsyncCommentList, CommentState> {
  const AsyncCommentListProvider._({
    required AsyncCommentListFamily super.from,
    required ({
      int articleId,
      PagingController<int, CommentModel> pagingController,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'asyncCommentListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$asyncCommentListHash();

  @override
  String toString() {
    return r'asyncCommentListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  AsyncCommentList create() => AsyncCommentList();

  @override
  bool operator ==(Object other) {
    return other is AsyncCommentListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$asyncCommentListHash() => r'97384b41ea783f77726e958745c0ae7eb124c901';

final class AsyncCommentListFamily extends $Family
    with
        $ClassFamilyOverride<
          AsyncCommentList,
          AsyncValue<CommentState>,
          CommentState,
          FutureOr<CommentState>,
          ({
            int articleId,
            PagingController<int, CommentModel> pagingController,
          })
        > {
  const AsyncCommentListFamily._()
    : super(
        retry: null,
        name: r'asyncCommentListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AsyncCommentListProvider call({
    required int articleId,
    required PagingController<int, CommentModel> pagingController,
  }) => AsyncCommentListProvider._(
    argument: (articleId: articleId, pagingController: pagingController),
    from: this,
  );

  @override
  String toString() => r'asyncCommentListProvider';
}

abstract class _$AsyncCommentList extends $AsyncNotifier<CommentState> {
  late final _$args =
      ref.$arg
          as ({
            int articleId,
            PagingController<int, CommentModel> pagingController,
          });
  int get articleId => _$args.articleId;
  PagingController<int, CommentModel> get pagingController =>
      _$args.pagingController;

  FutureOr<CommentState> build({
    required int articleId,
    required PagingController<int, CommentModel> pagingController,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(
      articleId: _$args.articleId,
      pagingController: _$args.pagingController,
    );
    final ref = this.ref as $Ref<AsyncValue<CommentState>, CommentState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CommentState>, CommentState>,
              AsyncValue<CommentState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(ParentItem)
const parentItemProvider = ParentItemProvider._();

final class ParentItemProvider
    extends $NotifierProvider<ParentItem, CommentModel?> {
  const ParentItemProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'parentItemProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$parentItemHash();

  @$internal
  @override
  ParentItem create() => ParentItem();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommentModel? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommentModel?>(value),
    );
  }
}

String _$parentItemHash() => r'30d7e81bfa5563d77693ce2e504753acaddecca4';

abstract class _$ParentItem extends $Notifier<CommentModel?> {
  CommentModel? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<CommentModel?, CommentModel?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CommentModel?, CommentModel?>,
              CommentModel?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
