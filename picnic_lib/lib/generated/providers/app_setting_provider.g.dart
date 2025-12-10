// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/app_setting_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppSetting)
const appSettingProvider = AppSettingProvider._();

final class AppSettingProvider extends $NotifierProvider<AppSetting, Setting> {
  const AppSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appSettingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appSettingHash();

  @$internal
  @override
  AppSetting create() => AppSetting();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Setting value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Setting>(value),
    );
  }
}

String _$appSettingHash() => r'b2ea200487f6d843649b49f2fbd21ea3f0f3fbe7';

abstract class _$AppSetting extends $Notifier<Setting> {
  Setting build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<Setting, Setting>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Setting, Setting>,
              Setting,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
