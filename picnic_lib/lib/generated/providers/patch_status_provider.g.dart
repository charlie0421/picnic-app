// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/patch_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 패치 상태 관리 Notifier

@ProviderFor(PatchStatusNotifier)
const patchStatusProvider = PatchStatusNotifierProvider._();

/// 패치 상태 관리 Notifier
final class PatchStatusNotifierProvider
    extends $NotifierProvider<PatchStatusNotifier, PatchStatusInfo> {
  /// 패치 상태 관리 Notifier
  const PatchStatusNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'patchStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$patchStatusNotifierHash();

  @$internal
  @override
  PatchStatusNotifier create() => PatchStatusNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PatchStatusInfo value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PatchStatusInfo>(value),
    );
  }
}

String _$patchStatusNotifierHash() =>
    r'011f948160764bce379332e8374fe0da231295ba';

/// 패치 상태 관리 Notifier

abstract class _$PatchStatusNotifier extends $Notifier<PatchStatusInfo> {
  PatchStatusInfo build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<PatchStatusInfo, PatchStatusInfo>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PatchStatusInfo, PatchStatusInfo>,
              PatchStatusInfo,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
