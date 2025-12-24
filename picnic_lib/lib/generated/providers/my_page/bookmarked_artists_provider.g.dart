// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../presentation/providers/my_page/bookmarked_artists_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AsyncBookmarkedArtists)
const asyncBookmarkedArtistsProvider = AsyncBookmarkedArtistsProvider._();

final class AsyncBookmarkedArtistsProvider
    extends $AsyncNotifierProvider<AsyncBookmarkedArtists, List<ArtistModel>> {
  const AsyncBookmarkedArtistsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'asyncBookmarkedArtistsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$asyncBookmarkedArtistsHash();

  @$internal
  @override
  AsyncBookmarkedArtists create() => AsyncBookmarkedArtists();
}

String _$asyncBookmarkedArtistsHash() =>
    r'af371bd90d6b228ab13daecf7769c7f03205df89';

abstract class _$AsyncBookmarkedArtists
    extends $AsyncNotifier<List<ArtistModel>> {
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
