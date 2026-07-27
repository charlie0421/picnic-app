// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/latest_media_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AsyncLatestMedia)
const asyncLatestMediaProvider = AsyncLatestMediaProvider._();

final class AsyncLatestMediaProvider
    extends $AsyncNotifierProvider<AsyncLatestMedia, List<VideoInfo>> {
  const AsyncLatestMediaProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'asyncLatestMediaProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$asyncLatestMediaHash();

  @$internal
  @override
  AsyncLatestMedia create() => AsyncLatestMedia();
}

String _$asyncLatestMediaHash() => r'636a817cecc98a0a60d36740f1d852e39067fb81';

abstract class _$AsyncLatestMedia extends $AsyncNotifier<List<VideoInfo>> {
  FutureOr<List<VideoInfo>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<VideoInfo>>, List<VideoInfo>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<VideoInfo>>, List<VideoInfo>>,
              AsyncValue<List<VideoInfo>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
