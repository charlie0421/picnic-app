// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/vote_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AsyncVoteDetail)
const asyncVoteDetailProvider = AsyncVoteDetailFamily._();

final class AsyncVoteDetailProvider
    extends $AsyncNotifierProvider<AsyncVoteDetail, VoteModel?> {
  const AsyncVoteDetailProvider._({
    required AsyncVoteDetailFamily super.from,
    required ({int voteId, VotePortal votePortal}) super.argument,
  }) : super(
         retry: null,
         name: r'asyncVoteDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$asyncVoteDetailHash();

  @override
  String toString() {
    return r'asyncVoteDetailProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  AsyncVoteDetail create() => AsyncVoteDetail();

  @override
  bool operator ==(Object other) {
    return other is AsyncVoteDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$asyncVoteDetailHash() => r'7c1f85d5ef38e11c53a21b26182a526cff9f0511';

final class AsyncVoteDetailFamily extends $Family
    with
        $ClassFamilyOverride<
          AsyncVoteDetail,
          AsyncValue<VoteModel?>,
          VoteModel?,
          FutureOr<VoteModel?>,
          ({int voteId, VotePortal votePortal})
        > {
  const AsyncVoteDetailFamily._()
    : super(
        retry: null,
        name: r'asyncVoteDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AsyncVoteDetailProvider call({
    required int voteId,
    VotePortal votePortal = VotePortal.vote,
  }) => AsyncVoteDetailProvider._(
    argument: (voteId: voteId, votePortal: votePortal),
    from: this,
  );

  @override
  String toString() => r'asyncVoteDetailProvider';
}

abstract class _$AsyncVoteDetail extends $AsyncNotifier<VoteModel?> {
  late final _$args = ref.$arg as ({int voteId, VotePortal votePortal});
  int get voteId => _$args.voteId;
  VotePortal get votePortal => _$args.votePortal;

  FutureOr<VoteModel?> build({
    required int voteId,
    VotePortal votePortal = VotePortal.vote,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(voteId: _$args.voteId, votePortal: _$args.votePortal);
    final ref = this.ref as $Ref<AsyncValue<VoteModel?>, VoteModel?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<VoteModel?>, VoteModel?>,
              AsyncValue<VoteModel?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(AsyncVoteItemList)
const asyncVoteItemListProvider = AsyncVoteItemListFamily._();

final class AsyncVoteItemListProvider
    extends $AsyncNotifierProvider<AsyncVoteItemList, List<VoteItemModel?>> {
  const AsyncVoteItemListProvider._({
    required AsyncVoteItemListFamily super.from,
    required ({int voteId, VotePortal votePortal}) super.argument,
  }) : super(
         retry: null,
         name: r'asyncVoteItemListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$asyncVoteItemListHash();

  @override
  String toString() {
    return r'asyncVoteItemListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  AsyncVoteItemList create() => AsyncVoteItemList();

  @override
  bool operator ==(Object other) {
    return other is AsyncVoteItemListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$asyncVoteItemListHash() => r'1040418db6e9cd16840ba02d7012c659ad7dbe37';

final class AsyncVoteItemListFamily extends $Family
    with
        $ClassFamilyOverride<
          AsyncVoteItemList,
          AsyncValue<List<VoteItemModel?>>,
          List<VoteItemModel?>,
          FutureOr<List<VoteItemModel?>>,
          ({int voteId, VotePortal votePortal})
        > {
  const AsyncVoteItemListFamily._()
    : super(
        retry: null,
        name: r'asyncVoteItemListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AsyncVoteItemListProvider call({
    required int voteId,
    VotePortal votePortal = VotePortal.vote,
  }) => AsyncVoteItemListProvider._(
    argument: (voteId: voteId, votePortal: votePortal),
    from: this,
  );

  @override
  String toString() => r'asyncVoteItemListProvider';
}

abstract class _$AsyncVoteItemList
    extends $AsyncNotifier<List<VoteItemModel?>> {
  late final _$args = ref.$arg as ({int voteId, VotePortal votePortal});
  int get voteId => _$args.voteId;
  VotePortal get votePortal => _$args.votePortal;

  FutureOr<List<VoteItemModel?>> build({
    required int voteId,
    VotePortal votePortal = VotePortal.vote,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(voteId: _$args.voteId, votePortal: _$args.votePortal);
    final ref =
        this.ref
            as $Ref<AsyncValue<List<VoteItemModel?>>, List<VoteItemModel?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<VoteItemModel?>>,
                List<VoteItemModel?>
              >,
              AsyncValue<List<VoteItemModel?>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(fetchVoteAchieve)
const fetchVoteAchieveProvider = FetchVoteAchieveFamily._();

final class FetchVoteAchieveProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<VoteAchieve>?>,
          List<VoteAchieve>?,
          FutureOr<List<VoteAchieve>?>
        >
    with
        $FutureModifier<List<VoteAchieve>?>,
        $FutureProvider<List<VoteAchieve>?> {
  const FetchVoteAchieveProvider._({
    required FetchVoteAchieveFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'fetchVoteAchieveProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchVoteAchieveHash();

  @override
  String toString() {
    return r'fetchVoteAchieveProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<VoteAchieve>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<VoteAchieve>?> create(Ref ref) {
    final argument = this.argument as int;
    return fetchVoteAchieve(ref, voteId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FetchVoteAchieveProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchVoteAchieveHash() => r'd0378f9f5df39f5b8471c41903aa83b9a114cff7';

final class FetchVoteAchieveFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<VoteAchieve>?>, int> {
  const FetchVoteAchieveFamily._()
    : super(
        retry: null,
        name: r'fetchVoteAchieveProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FetchVoteAchieveProvider call({required int voteId}) =>
      FetchVoteAchieveProvider._(argument: voteId, from: this);

  @override
  String toString() => r'fetchVoteAchieveProvider';
}
