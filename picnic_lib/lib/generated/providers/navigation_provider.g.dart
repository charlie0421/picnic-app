// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/navigation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NavigationInfo)
const navigationInfoProvider = NavigationInfoProvider._();

final class NavigationInfoProvider
    extends $NotifierProvider<NavigationInfo, Navigation> {
  const NavigationInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navigationInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navigationInfoHash();

  @$internal
  @override
  NavigationInfo create() => NavigationInfo();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Navigation value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Navigation>(value),
    );
  }
}

String _$navigationInfoHash() => r'd6136d69382f71497d9ea42491238e6710ba0cce';

abstract class _$NavigationInfo extends $Notifier<Navigation> {
  Navigation build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Navigation, Navigation>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Navigation, Navigation>,
              Navigation,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
