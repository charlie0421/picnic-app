// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/platform_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlatformInfo)
const platformInfoProvider = PlatformInfoProvider._();

final class PlatformInfoProvider
    extends $AsyncNotifierProvider<PlatformInfo, PackageInfo> {
  const PlatformInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'platformInfoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$platformInfoHash();

  @$internal
  @override
  PlatformInfo create() => PlatformInfo();
}

String _$platformInfoHash() => r'491cd7b94516091c9b95f4d4f6dc641500801cd7';

abstract class _$PlatformInfo extends $AsyncNotifier<PackageInfo> {
  FutureOr<PackageInfo> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<PackageInfo>, PackageInfo>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PackageInfo>, PackageInfo>,
              AsyncValue<PackageInfo>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
