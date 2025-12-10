// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/screen_protector_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(IsScreenProtector)
const isScreenProtectorProvider = IsScreenProtectorProvider._();

final class IsScreenProtectorProvider
    extends $NotifierProvider<IsScreenProtector, bool> {
  const IsScreenProtectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isScreenProtectorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isScreenProtectorHash();

  @$internal
  @override
  IsScreenProtector create() => IsScreenProtector();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isScreenProtectorHash() => r'e3ec20de4f38b8a30a27cccf3d7e0a5604139d32';

abstract class _$IsScreenProtector extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
