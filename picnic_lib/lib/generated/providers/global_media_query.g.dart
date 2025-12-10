// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/global_media_query.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GlobalMediaQuery)
const globalMediaQueryProvider = GlobalMediaQueryProvider._();

final class GlobalMediaQueryProvider
    extends $NotifierProvider<GlobalMediaQuery, MediaQueryData> {
  const GlobalMediaQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalMediaQueryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalMediaQueryHash();

  @$internal
  @override
  GlobalMediaQuery create() => GlobalMediaQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaQueryData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaQueryData>(value),
    );
  }
}

String _$globalMediaQueryHash() => r'f9d0273a4086ac54689d50abffc7f179727b6b53';

abstract class _$GlobalMediaQuery extends $Notifier<MediaQueryData> {
  MediaQueryData build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<MediaQueryData, MediaQueryData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MediaQueryData, MediaQueryData>,
              MediaQueryData,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
