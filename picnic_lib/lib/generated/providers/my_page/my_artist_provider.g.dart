// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../presentation/providers/my_page/my_artist_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AsyncMyArtist)
const asyncMyArtistProvider = AsyncMyArtistProvider._();

final class AsyncMyArtistProvider
    extends $AsyncNotifierProvider<AsyncMyArtist, List<ArtistModel>> {
  const AsyncMyArtistProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'asyncMyArtistProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$asyncMyArtistHash();

  @$internal
  @override
  AsyncMyArtist create() => AsyncMyArtist();
}

String _$asyncMyArtistHash() => r'e384848ddee1e2def699f040c200d219856f72fd';

abstract class _$AsyncMyArtist extends $AsyncNotifier<List<ArtistModel>> {
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
