// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/active_featured_votes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 진행중(active)인 투표들을 stop_at 임박 순으로 최대 [_limit]개 반환.
/// 각 vote 는 표시용으로 1위 항목만 join 하고, 퍼센트 표시를 위해
/// vote_item.vote_total 만 가볍게 집계해 총합을 구한다.

@ProviderFor(AsyncActiveFeaturedVotes)
const asyncActiveFeaturedVotesProvider = AsyncActiveFeaturedVotesProvider._();

/// 진행중(active)인 투표들을 stop_at 임박 순으로 최대 [_limit]개 반환.
/// 각 vote 는 표시용으로 1위 항목만 join 하고, 퍼센트 표시를 위해
/// vote_item.vote_total 만 가볍게 집계해 총합을 구한다.
final class AsyncActiveFeaturedVotesProvider
    extends
        $AsyncNotifierProvider<
          AsyncActiveFeaturedVotes,
          List<FeaturedVoteEntry>
        > {
  /// 진행중(active)인 투표들을 stop_at 임박 순으로 최대 [_limit]개 반환.
  /// 각 vote 는 표시용으로 1위 항목만 join 하고, 퍼센트 표시를 위해
  /// vote_item.vote_total 만 가볍게 집계해 총합을 구한다.
  const AsyncActiveFeaturedVotesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'asyncActiveFeaturedVotesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$asyncActiveFeaturedVotesHash();

  @$internal
  @override
  AsyncActiveFeaturedVotes create() => AsyncActiveFeaturedVotes();
}

String _$asyncActiveFeaturedVotesHash() =>
    r'282f15e59a5be5fa808ee2e25213938570e1fe2c';

/// 진행중(active)인 투표들을 stop_at 임박 순으로 최대 [_limit]개 반환.
/// 각 vote 는 표시용으로 1위 항목만 join 하고, 퍼센트 표시를 위해
/// vote_item.vote_total 만 가볍게 집계해 총합을 구한다.

abstract class _$AsyncActiveFeaturedVotes
    extends $AsyncNotifier<List<FeaturedVoteEntry>> {
  FutureOr<List<FeaturedVoteEntry>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<FeaturedVoteEntry>>,
              List<FeaturedVoteEntry>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<FeaturedVoteEntry>>,
                List<FeaturedVoteEntry>
              >,
              AsyncValue<List<FeaturedVoteEntry>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
