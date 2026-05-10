// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/anti_abuse_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// IpHashService singleton — anti-abuse hint 캐시.
///
/// 앱 부팅 직후 [IpHashService.fetchAndCache] 1회 prefetch (App._initializeAppBasics 에서
/// fire-and-forget) 후 보호 대상 호출에서 [IpHashService.current] 으로 조회.

@ProviderFor(ipHashService)
const ipHashServiceProvider = IpHashServiceProvider._();

/// IpHashService singleton — anti-abuse hint 캐시.
///
/// 앱 부팅 직후 [IpHashService.fetchAndCache] 1회 prefetch (App._initializeAppBasics 에서
/// fire-and-forget) 후 보호 대상 호출에서 [IpHashService.current] 으로 조회.

final class IpHashServiceProvider
    extends $FunctionalProvider<IpHashService, IpHashService, IpHashService>
    with $Provider<IpHashService> {
  /// IpHashService singleton — anti-abuse hint 캐시.
  ///
  /// 앱 부팅 직후 [IpHashService.fetchAndCache] 1회 prefetch (App._initializeAppBasics 에서
  /// fire-and-forget) 후 보호 대상 호출에서 [IpHashService.current] 으로 조회.
  const IpHashServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ipHashServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ipHashServiceHash();

  @$internal
  @override
  $ProviderElement<IpHashService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IpHashService create(Ref ref) {
    return ipHashService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IpHashService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IpHashService>(value),
    );
  }
}

String _$ipHashServiceHash() => r'c7b373cddee66e35019998a3fc3340a19de91b40';
