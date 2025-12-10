// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../presentation/providers/community/fortune_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getFortune)
const getFortuneProvider = GetFortuneFamily._();

final class GetFortuneProvider
    extends
        $FunctionalProvider<
          AsyncValue<FortuneModel>,
          FortuneModel,
          FutureOr<FortuneModel>
        >
    with $FutureModifier<FortuneModel>, $FutureProvider<FortuneModel> {
  const GetFortuneProvider._({
    required GetFortuneFamily super.from,
    required ({int artistId, int year, String language}) super.argument,
  }) : super(
         retry: null,
         name: r'getFortuneProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getFortuneHash();

  @override
  String toString() {
    return r'getFortuneProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<FortuneModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FortuneModel> create(Ref ref) {
    final argument =
        this.argument as ({int artistId, int year, String language});
    return getFortune(
      ref,
      artistId: argument.artistId,
      year: argument.year,
      language: argument.language,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GetFortuneProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getFortuneHash() => r'd7e2a2688d0201d54a36ba0f06b9e8aef4fe5389';

final class GetFortuneFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<FortuneModel>,
          ({int artistId, int year, String language})
        > {
  const GetFortuneFamily._()
    : super(
        retry: null,
        name: r'getFortuneProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GetFortuneProvider call({
    required int artistId,
    required int year,
    String language = 'ko',
  }) => GetFortuneProvider._(
    argument: (artistId: artistId, year: year, language: language),
    from: this,
  );

  @override
  String toString() => r'getFortuneProvider';
}
