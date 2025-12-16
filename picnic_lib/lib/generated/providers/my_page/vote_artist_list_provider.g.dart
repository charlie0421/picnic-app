// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../presentation/providers/my_page/vote_artist_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AsyncVoteArtistList)
const asyncVoteArtistListProvider = AsyncVoteArtistListProvider._();

final class AsyncVoteArtistListProvider
    extends $AsyncNotifierProvider<AsyncVoteArtistList, List<ArtistModel>> {
  const AsyncVoteArtistListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'asyncVoteArtistListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$asyncVoteArtistListHash();

  @$internal
  @override
  AsyncVoteArtistList create() => AsyncVoteArtistList();
}

String _$asyncVoteArtistListHash() =>
    r'2ea7debfbdcf6aa3c5a068166b9f5d2970e5c431';

abstract class _$AsyncVoteArtistList extends $AsyncNotifier<List<ArtistModel>> {
  FutureOr<List<ArtistModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<ArtistModel>>, List<ArtistModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ArtistModel>>, List<ArtistModel>>,
              AsyncValue<List<ArtistModel>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
