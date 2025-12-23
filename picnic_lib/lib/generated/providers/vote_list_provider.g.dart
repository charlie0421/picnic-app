// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/vote_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AsyncVoteList)
const asyncVoteListProvider = AsyncVoteListFamily._();

final class AsyncVoteListProvider
    extends $AsyncNotifierProvider<AsyncVoteList, List<VoteModel>> {
  const AsyncVoteListProvider._({
    required AsyncVoteListFamily super.from,
    required (
      int,
      int,
      String,
      String,
      String, {
      VotePortal votePortal,
      VoteStatus status,
      VoteCategory category,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'asyncVoteListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$asyncVoteListHash();

  @override
  String toString() {
    return r'asyncVoteListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  AsyncVoteList create() => AsyncVoteList();

  @override
  bool operator ==(Object other) {
    return other is AsyncVoteListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$asyncVoteListHash() => r'c6b87882fb8848817332b23fa4439cde7fc4ee31';

final class AsyncVoteListFamily extends $Family
    with
        $ClassFamilyOverride<
          AsyncVoteList,
          AsyncValue<List<VoteModel>>,
          List<VoteModel>,
          FutureOr<List<VoteModel>>,
          (
            int,
            int,
            String,
            String,
            String, {
            VotePortal votePortal,
            VoteStatus status,
            VoteCategory category,
          })
        > {
  const AsyncVoteListFamily._()
    : super(
        retry: null,
        name: r'asyncVoteListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AsyncVoteListProvider call(
    int page,
    int limit,
    String sort,
    String order,
    String area, {
    VotePortal votePortal = VotePortal.vote,
    required VoteStatus status,
    required VoteCategory category,
  }) => AsyncVoteListProvider._(
    argument: (
      page,
      limit,
      sort,
      order,
      area,
      votePortal: votePortal,
      status: status,
      category: category,
    ),
    from: this,
  );

  @override
  String toString() => r'asyncVoteListProvider';
}

abstract class _$AsyncVoteList extends $AsyncNotifier<List<VoteModel>> {
  late final _$args =
      ref.$arg
          as (
            int,
            int,
            String,
            String,
            String, {
            VotePortal votePortal,
            VoteStatus status,
            VoteCategory category,
          });
  int get page => _$args.$1;
  int get limit => _$args.$2;
  String get sort => _$args.$3;
  String get order => _$args.$4;
  String get area => _$args.$5;
  VotePortal get votePortal => _$args.votePortal;
  VoteStatus get status => _$args.status;
  VoteCategory get category => _$args.category;

  FutureOr<List<VoteModel>> build(
    int page,
    int limit,
    String sort,
    String order,
    String area, {
    VotePortal votePortal = VotePortal.vote,
    required VoteStatus status,
    required VoteCategory category,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(
      _$args.$1,
      _$args.$2,
      _$args.$3,
      _$args.$4,
      _$args.$5,
      votePortal: _$args.votePortal,
      status: _$args.status,
      category: _$args.category,
    );
    final ref = this.ref as $Ref<AsyncValue<List<VoteModel>>, List<VoteModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<VoteModel>>, List<VoteModel>>,
              AsyncValue<List<VoteModel>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
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
