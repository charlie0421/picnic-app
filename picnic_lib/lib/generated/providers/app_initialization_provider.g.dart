// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/app_initialization_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppInitialization)
const appInitializationProvider = AppInitializationProvider._();

final class AppInitializationProvider
    extends $NotifierProvider<AppInitialization, AppInitializationState> {
  const AppInitializationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appInitializationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appInitializationHash();

  @$internal
  @override
  AppInitialization create() => AppInitialization();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppInitializationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppInitializationState>(value),
    );
  }
}

String _$appInitializationHash() => r'9fb44682164a1e03f2b30f9ec4f02db40ee041b2';

abstract class _$AppInitialization extends $Notifier<AppInitializationState> {
  AppInitializationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AppInitializationState, AppInitializationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppInitializationState, AppInitializationState>,
              AppInitializationState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
