// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/artist_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getArtist)
const getArtistProvider = GetArtistFamily._();

final class GetArtistProvider
    extends
        $FunctionalProvider<
          AsyncValue<ArtistModel>,
          ArtistModel,
          FutureOr<ArtistModel>
        >
    with $FutureModifier<ArtistModel>, $FutureProvider<ArtistModel> {
  const GetArtistProvider._({
    required GetArtistFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'getArtistProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getArtistHash();

  @override
  String toString() {
    return r'getArtistProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ArtistModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ArtistModel> create(Ref ref) {
    final argument = this.argument as int;
    return getArtist(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GetArtistProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getArtistHash() => r'e2f44b9268c2239e49ba6be52ed4aca2f1d6b132';

final class GetArtistFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ArtistModel>, int> {
  const GetArtistFamily._()
    : super(
        retry: null,
        name: r'getArtistProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GetArtistProvider call(int artistId) =>
      GetArtistProvider._(argument: artistId, from: this);

  @override
  String toString() => r'getArtistProvider';
}
